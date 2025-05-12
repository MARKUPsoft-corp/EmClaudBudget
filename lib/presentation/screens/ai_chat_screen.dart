import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:budget_express/services/ai_service.dart';
import 'package:budget_express/services/conversation_service.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/presentation/providers/transaction_provider.dart';
import 'package:budget_express/utils/feedback_utils.dart';
import 'package:budget_express/config/api_keys.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_express/presentation/widgets/typing_indicator.dart';
import 'package:budget_express/presentation/widgets/typing_animation.dart';
import 'package:budget_express/services/action_recognizer.dart';
import 'package:budget_express/domain/entities/transaction.dart';

class AIChatScreen extends StatefulWidget {
  final String? conversationId;

  const AIChatScreen({super.key, this.conversationId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late TextEditingController _messageController;
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false; // Indique si l'IA est en train de "taper"
  String _loadingMessage = "";
  bool _showScrollButton = false;

  // Service pour gérer les conversations multiples
  final ConversationService _conversationService = ConversationService();

  // Clé API Groq provenant du fichier de configuration
  static final _groqApiKey = ApiKeys.groqApiKey;

  // Instance du service IA
  late AIService _aiService;

  // Service de reconnaissance d'action
  final ActionRecognizer _actionRecognizer = ActionRecognizer();

  // Conversation active
  String? _activeConversationId;

  @override
  void initState() {
    super.initState();
    _aiService = AIService(_groqApiKey);
    _messageController = TextEditingController();

    // Définir l'ID de conversation active s'il est fourni via les params de navigation
    _activeConversationId = widget.conversationId;

    // Initialiser et charger la conversation
    _initConversation();

    // Écouter le défilement pour afficher/masquer le bouton de scroll
    _scrollController.addListener(_onScrollChanged);
  }

  // Initialiser la conversation active
  Future<void> _initConversation() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = "Chargement de la conversation...";
    });

    try {
      // Initialiser le service de conversations
      await _conversationService.initialize();

      // Si un ID de conversation a été fourni, le définir comme conversation active
      if (_activeConversationId != null) {
        await _conversationService.setActiveConversation(
          _activeConversationId!,
        );
      }

      // Obtenir la conversation active ou en créer une nouvelle
      final activeConversation =
          _conversationService.activeConversation ??
          await _conversationService.createConversation(
            title: "Nouvelle conversation",
          );
      _activeConversationId = activeConversation.id;

      // Charger les messages de la conversation active
      final conversationMessages = activeConversation.messages;
      setState(() {
        _messages.clear();
        for (final msg in conversationMessages) {
          _messages.add(
            ChatMessage(
              text: msg['content'] as String,
              isUser: msg['role'] == 'user',
              timestamp: DateTime.parse(msg['timestamp'] as String),
            ),
          );
        }

        // Ajouter un message de bienvenue si la conversation est vide
        if (_messages.isEmpty) {
          _messages.add(
            ChatMessage(
              text:
                  "Bonjour, je suis votre assistant financier personnel. Je peux vous aider à analyser vos finances, suggérer des stratégies d'épargne, et répondre à vos questions sur votre budget. Comment puis-je vous aider aujourd'hui ?",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        }

        _isLoading = false;
      });

      // Faire défiler vers le bas après le chargement
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            text:
                "Une erreur est survenue lors du chargement de la conversation. Veuillez réessayer.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  // Vérifie la position de défilement pour afficher ou masquer le bouton
  void _onScrollChanged() {
    // Montrer le bouton uniquement quand il reste du contenu à voir en bas
    if (_scrollController.hasClients && _messages.length > 1) {
      // Calculer combien il reste de contenu à faire défiler
      final remainingScroll =
          _scrollController.position.maxScrollExtent - _scrollController.offset;
      // Afficher le bouton uniquement si on a une distance significative à défiler (plus de 200 pixels)
      final shouldShow = remainingScroll > 200;

      // Mettre à jour l'état si nécessaire
      if (shouldShow != _showScrollButton) {
        setState(() => _showScrollButton = shouldShow);
      }
    } else {
      // S'assurer que le bouton est masqué s'il n'y a pas assez de messages
      if (_showScrollButton) {
        setState(() => _showScrollButton = false);
      }
    }
  }

  // Faire défiler vers le bas de la liste de messages
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Envoyer un message à l'assistant IA
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Vibration pour la navigation (selon préférence utilisateur)
    FeedbackUtils().provideFeedbackForMenu();

    // Effacer le champ de texte
    _messageController.clear();

    // Créer un nouveau message
    final userMessage = {
      'content': message,
      'role': 'user',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Ajouter le message de l'utilisateur à l'interface
    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
      _loadingMessage = "L'assistant réfléchit...";
    });

    // Ajouter le message à la conversation active
    await _conversationService.addMessageToActiveConversation(userMessage);

    // Faire défiler pour voir le nouveau message
    _scrollToBottom();

    // Analyser si le message contient une demande d'action financière
    final action = _actionRecognizer.recognizeAction(message);
    bool actionExecuted = false;
    String? actionResponse;

    // Si une action a été reconnue et qu'elle est complète, l'exécuter
    if (action.type != ActionType.unknown && action.isComplete) {
      // Accéder au provider de transactions
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      switch (action.type) {
        case ActionType.addExpense:
          // Créer et ajouter la dépense
          final expense = action.toExpense();
          if (expense != null) {
            final success = await transactionProvider.addExpense(expense);
            actionExecuted = success;
            actionResponse = success
                ? action.feedbackMessage
                : "Désolé, je n'ai pas pu ajouter cette dépense. Veuillez réessayer plus tard.";
          }
          break;

        case ActionType.deleteExpense:
          // Rechercher et supprimer la dépense par description
          if (action.parameters.containsKey('description')) {
            final description = action.parameters['description'] as String;
            // Rechercher dans les dépenses existantes
            final expenseToDelete = transactionProvider.expenses.firstWhere(
              (e) => e.description.toLowerCase().contains(description.toLowerCase()),
              orElse: () => Expense(amount: 0, description: '', date: DateTime.now(), categoryId: ''),
            );

            if (expenseToDelete.id != null) {
              final success = await transactionProvider.deleteExpense(expenseToDelete.id!);
              actionExecuted = success;
              actionResponse = success
                  ? action.feedbackMessage
                  : "Désolé, je n'ai pas pu supprimer cette dépense. Veuillez réessayer plus tard.";
            } else {
              actionResponse = "Je n'ai pas trouvé de dépense correspondant à '${description}'.";
            }
          }
          break;

        case ActionType.addIncome:
          // Créer et ajouter le revenu
          final income = action.toIncome();
          if (income != null) {
            final success = await transactionProvider.addIncome(income);
            actionExecuted = success;
            actionResponse = success
                ? action.feedbackMessage
                : "Désolé, je n'ai pas pu ajouter ce revenu. Veuillez réessayer plus tard.";
          }
          break;

        case ActionType.deleteIncome:
          // Rechercher et supprimer le revenu par description
          if (action.parameters.containsKey('description')) {
            final description = action.parameters['description'] as String;
            // Rechercher dans les revenus existants
            final incomeToDelete = transactionProvider.incomes.firstWhere(
              (e) => e.description.toLowerCase().contains(description.toLowerCase()),
              orElse: () => Income(amount: 0, description: '', date: DateTime.now(), source: '', isActive: false),
            );

            if (incomeToDelete.id != null) {
              final success = await transactionProvider.deleteIncome(incomeToDelete.id!);
              actionExecuted = success;
              actionResponse = success
                  ? action.feedbackMessage
                  : "Désolé, je n'ai pas pu supprimer ce revenu. Veuillez réessayer plus tard.";
            } else {
              actionResponse = "Je n'ai pas trouvé de revenu correspondant à '${description}'.";
            }
          }
          break;

        default:
          break;
      }
    }

    try {
      // Si une action a été reconnue et exécutée avec succès, afficher directement sa réponse
      if (actionExecuted && actionResponse != null) {
        // Délai court pour simulation de traitement
        setState(() {
          _isTyping = true; // Activation de l'indicateur de frappe
        });
        
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Créer un message de réponse pour l'action
        final assistantMessage = {
          'content': actionResponse,
          'role': 'assistant',
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Désactiver l'indicateur de chargement
        setState(() {
          _isLoading = false;
        });
        
        // Ajouter le message de réponse d'action à l'interface
        final timestamp = DateTime.now();
        final chatMessage = ChatMessage(
          text: actionResponse,
          isUser: false,
          timestamp: timestamp,
          isAnimated: true,
        );

        // Ajouter le message avec l'animation à l'interface et désactiver l'indicateur de frappe
        setState(() {
          _messages.add(chatMessage);
          _isTyping = false;
        });
        
        // Ajouter le message à la conversation
        await _conversationService.addMessageToActiveConversation(assistantMessage);
        
        // Faire défiler pour voir la réponse
        _scrollToBottom();
        
        // Signal sonore et vibration pour action financière (comme pour ajout de dépense)
        FeedbackUtils().provideFeedbackForAction();
        
        return; // Sortir de la méthode car l'action a été traitée
      }
      
      // Pour les messages normaux ou actions incomplètes
      // Simuler l'effet de frappe
      setState(() {
        _isTyping = true; // Activation de l'indicateur de frappe
      });
      
      // Délai artificiel pour montrer l'indicateur de frappe (1-2 secondes)
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Un handler pour les messages de réessai
      _aiService.onRetry = (attempt, total, delay) {
        setState(() {
          _loadingMessage = "Limite de débit atteinte.\nRéessai $attempt/$total dans ${delay/1000} secondes...";
        });
      };
      
      // Obtenir le contexte des transactions si disponible
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final transactionContext = TransactionContext(
        recentExpenses: transactionProvider.expenses.take(5).toList(),
        recentIncomes: transactionProvider.incomes.take(5).toList(),
        currentBalance: transactionProvider.balance,
        monthlyExpenseTotal: transactionProvider.totalExpense,
        monthlyIncomeTotal: transactionProvider.totalIncome,
        expensesByCategory: transactionProvider.expensesByCategory.map((key, value) => 
          MapEntry(key, value)),
      );
      
      // Si une action a été reconnue mais est incomplète, ajouter un message spécial à l'IA
      String aiMessage = message;
      if (action.type != ActionType.unknown && !action.isComplete && actionResponse != null) {
        aiMessage = "$message [Action reconnue: ${action.type.toString().split('.').last}, Besoin de: $actionResponse]";
      }
      
      // Envoyer le message à l'IA avec contexte
      final response = await _aiService.sendMessage(
        message: aiMessage,
        withContext: true,
        transactionContext: transactionContext,
      );
      
      // Créer un message de réponse
      final assistantMessage = {
        'content': response,
        'role': 'assistant',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Désactiver l'indicateur de chargement, mais garder l'indicateur de frappe
      setState(() {
        _isLoading = false;
      });
      
      // Ajouter un message de l'assistant avec animation
      final timestamp = DateTime.now();
      final chatMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: timestamp,
        isAnimated: true, // Pour indiquer que ce message doit s'afficher progressivement
      );

      // Ajouter le message avec l'animation à l'interface et désactiver l'indicateur de frappe
      setState(() {
        _messages.add(chatMessage);
        _isTyping = false; // Désactiver l'indicateur de frappe pour montrer l'animation de texte
      });

      // Faire défiler pour voir le début de la réponse
      _scrollToBottom();

      // Ajouter le message de l'assistant à la conversation active
      await _conversationService.addMessageToActiveConversation(
        assistantMessage,
      );

      // Désactiver l'indicateur de frappe quand l'animation est terminée
      // (cela sera géré par le widget d'animation)

      // Renommer automatiquement la conversation après le premier échange
      if (_messages.length == 3) {
        // 1 message utilisateur + 1 message IA + 1 message de bienvenue initial
        // Générer un titre approprié basé sur le contenu du premier message
        String userMessageText = _messages[1].text;
        String title = '';

        // Limite la longueur du titre pour qu'il reste concis
        if (userMessageText.length > 30) {
          title = userMessageText.substring(0, 30) + '...';
        } else {
          title = userMessageText;
        }

        // Renommer la conversation avec ce nouveau titre
        if (_activeConversationId != null) {
          await _conversationService.renameConversation(
            _activeConversationId!,
            title,
          );
          setState(() {}); // Rafraîchir l'UI pour montrer le nouveau titre
        }
      }

      // Faire défiler pour voir la réponse
      _scrollToBottom();
    } catch (e) {
      print("Erreur lors de l'envoi du message: $e");

      // Créer un message d'erreur
      final errorMessage = {
        'content':
            "Désolé, je n'ai pas pu traiter votre demande. Veuillez réessayer.",
        'role': 'assistant',
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _messages.add(
          ChatMessage(
            text: errorMessage['content'] as String,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });

      // Ajouter le message d'erreur à la conversation active
      await _conversationService.addMessageToActiveConversation(errorMessage);

      // Faire défiler pour voir le message d'erreur
      _scrollToBottom();
    }
  }

  // Naviguer vers la liste des conversations
  void _navigateToConversationList() {
    // Vibration uniquement pour la navigation (selon préférence utilisateur)
    FeedbackUtils().provideFeedbackForMenu();
    context.push(AppConstants.conversationListRoute);
  }

  // Créer une nouvelle conversation
  Future<void> _createNewConversation() async {
    // Vibration uniquement pour la navigation (selon préférence utilisateur)
    FeedbackUtils().provideFeedbackForMenu();

    try {
      // Créer une nouvelle conversation
      final newConversation = await _conversationService.createConversation();

      // Rafraîchir l'interface
      setState(() {
        _messages.clear();
        _activeConversationId = newConversation.id;
        _messages.add(
          ChatMessage(
            text:
                "Bonjour, je suis votre assistant financier personnel. Je peux vous aider à analyser vos finances, suggérer des stratégies d'épargne, et répondre à vos questions sur votre budget. Comment puis-je vous aider aujourd'hui ?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      // Message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nouvelle conversation créée'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Erreur lors de la création d'une nouvelle conversation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _conversationService.activeConversation?.title ?? 'Assistant IA',
        ),
        actions: [
          // Bouton pour voir la liste des conversations
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique des conversations',
            onPressed: _navigateToConversationList,
          ),
          // Bouton pour créer une nouvelle conversation
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouvelle conversation',
            onPressed: _createNewConversation,
          ),
        ],
      ),
      // Bouton flottant pour aller à la fin de la conversation (apparaissant uniquement quand nécessaire)
      floatingActionButton:
          _showScrollButton
              ? Padding(
                padding: const EdgeInsets.only(
                  bottom: 80.0,
                ), // Décalage vers le haut pour éviter le champ de texte
                child: FloatingActionButton(
                  mini: true,
                  // Tag hero unique pour éviter les conflits avec d'autres FloatingActionButton
                  heroTag: "ai_chat_scroll_bottom",
                  // Semi-transparent comme demandé
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.7),
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                  elevation: 2.0, // Ombre réduite pour un aspect plus léger
                  onPressed: () {
                    // Vibration uniquement pour la navigation (sans son)
                    FeedbackUtils().provideFeedbackForMenu();
                    _scrollToBottom();
                  },
                  tooltip: "Aller à la fin de la conversation",
                  child: const Icon(Icons.keyboard_double_arrow_down),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child:
                _messages.isEmpty && !_isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun message',
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Posez une question pour commencer',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _messages.length) {
                          return MessageBubble(message: _messages[index]);
                        } else {
                          // Message de chargement
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Indicateur de frappe (3 points animés)
                                _isTyping
                                    ? const TypingIndicator() // Affiche les points de frappe
                                    : Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors
                                                .grey[800], // Même couleur que les bulles de message de l'IA
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Chargement...',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                if (_loadingMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8.0,
                                      left: 4.0,
                                    ),
                                    child: Text(
                                      _loadingMessage,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
          ),

          // Zone de saisie du message
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Champ de texte avec icône à gauche
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    // Configuration pour permettre plusieurs lignes
                    keyboardType: TextInputType.multiline,
                    maxLines: 4, // Limite à 4 lignes maximum
                    minLines: 1, // Commence avec 1 ligne
                    decoration: InputDecoration(
                      hintText: 'Poser une question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      // Ajout de l'icône à gauche
                      prefixIcon: const Icon(Icons.question_answer_outlined),
                    ),
                    textInputAction:
                        TextInputAction.newline, // Permet d'ajouter des lignes
                    // Gérer l'envoi avec Shift+Enter
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                // Bouton d'envoi
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher une bulle de message
class MessageBubble extends StatefulWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    // Si ce n'est pas un message animé, on considère que l'animation est déjà terminée
    _isAnimationComplete = !widget.message.isAnimated;
  }

  // Construction de l'animation d'affichage progressif du texte
  Widget _buildTypingAnimation() {
    return TypingAnimation(
      text: widget.message.text,
      style: const TextStyle(color: Colors.white),
      wordDelay: const Duration(
        milliseconds: 70,
      ), // Vitesse d'affichage des mots
      onCompleted: () {
        // Marquer l'animation comme terminée pour ne plus l'afficher
        if (mounted) {
          setState(() {
            _isAnimationComplete = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUserMessage = widget.message.isUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bulle de message
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color:
                  isUserMessage
                      ? const Color(0xFFFF8C00).withOpacity(
                        0.8,
                      ) // Orange translucide pour l'utilisateur
                      : Colors.grey[800], // Noir/gris foncé pour l'IA
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child:
                widget.message.isAnimated && !_isAnimationComplete
                    ? _buildTypingAnimation()
                    : Text(
                      widget.message.text,
                      style: const TextStyle(
                        color:
                            Colors
                                .white, // Texte blanc pour une meilleure lisibilité sur les deux fonds
                      ),
                    ),
          ),

          // Horodatage
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
            child: Text(
              DateFormat('HH:mm').format(widget.message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Classe pour représenter un message de chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool
  isAnimated; // Indique si le message doit s'afficher progressivement

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isAnimated = false,
  });
}
