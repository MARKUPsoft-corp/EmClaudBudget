import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:budget_express/services/ai_service.dart';
import 'package:budget_express/services/conversation_history_service.dart';
import 'package:budget_express/presentation/providers/transaction_provider.dart';
import 'package:budget_express/utils/feedback_utils.dart';
import 'package:budget_express/config/api_keys.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late TextEditingController _messageController;
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Service pour gérer l'historique des conversations
  final ConversationHistoryService _historyService = ConversationHistoryService();
  
  // Clé API Groq provenant du fichier de configuration
  static final _groqApiKey = ApiKeys.groqApiKey;
  
  // Instance du service IA
  late AIService _aiService;
  
  @override
  void initState() {
    super.initState();
    _aiService = AIService(_groqApiKey);
    _messageController = TextEditingController();
    _loadConversationHistory();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // S'assurer que le défilement se fait automatiquement après le rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  // Faire défiler vers le bas de la conversation
  void _scrollToBottom() {
    if (_scrollController.hasClients && _messages.isNotEmpty) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  // Charge l'historique des conversations depuis le stockage local
  Future<void> _loadConversationHistory() async {
    try {
      final conversations = await _historyService.getConversations();
      
      // Si aucune conversation n'existe, initialiser avec un message de bienvenue
      if (conversations.isEmpty) {
        _aiService.clearChatHistory(); // Ajoute le message de bienvenue dans le service
        setState(() {
          _messages.add(ChatMessage(
            text: "Bonjour, je suis votre assistant financier personnel. Je peux vous aider à analyser vos finances, suggérer des stratégies d'épargne, et répondre à vos questions sur votre budget. Comment puis-je vous aider aujourd'hui ?",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        return;
      }
      
      // Sinon, charger l'historique existant
      final historyForAI = <Map<String, dynamic>>[];
      setState(() {
        _messages.clear();
        for (var message in conversations) {
          _messages.add(ChatMessage(
            text: message['content'] as String,
            isUser: message['role'] == 'user',
            timestamp: DateTime.parse(message['timestamp'] as String),
          ));
          
          // Préparer l'historique pour le service AI
          historyForAI.add({
            'role': message['role'] as String,
            'content': message['content'] as String,
          });
        }
      });
      
      // Synchroniser l'historique avec le service IA pour maintenir le contexte
      _aiService.chatHistory = historyForAI;
    } catch (e) {
      print('Erreur lors du chargement de l\'historique: $e');
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Obtenir le contexte des transactions pour l'IA
  Future<TransactionContext> _getTransactionContextForAI(TransactionProvider provider) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final recentExpenses = provider.expenses
        .where((e) => e.date.isAfter(thirtyDaysAgo))
        .toList();
    final recentIncomes = provider.incomes
        .where((i) => i.date.isAfter(thirtyDaysAgo))
        .toList();
    
    final monthlyExpenseTotal = recentExpenses.fold<double>(
      0, (sum, expense) => sum + expense.amount);
    
    final monthlyIncomeTotal = recentIncomes.fold<double>(
      0, (sum, income) => sum + income.amount);
    
    final expensesByCategory = <String, double>{};
    for (var expense in recentExpenses) {
      expensesByCategory.update(
        expense.categoryId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    
    return TransactionContext(
      recentExpenses: recentExpenses,
      recentIncomes: recentIncomes,
      currentBalance: provider.balance,
      monthlyExpenseTotal: monthlyExpenseTotal,
      monthlyIncomeTotal: monthlyIncomeTotal,
      expensesByCategory: expensesByCategory,
    );
  }
  
  // Envoyer un message à l'IA
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Efface le contrôleur de texte
    _messageController.clear();
    
    final DateTime now = DateTime.now();
    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: now,
    );

    setState(() {
      // Ajoute le message utilisateur
      _messages.add(userMessage);
      _isLoading = true;
    });
    
    // Sauvegarde le message utilisateur dans l'historique
    await _historyService.addMessage({
      'role': 'user',
      'content': message,
      'timestamp': now.toIso8601String(),
    });
    
    // Faire défiler vers le bas après ajout du message
    _scrollToBottom();

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final transactionContext = await _getTransactionContextForAI(transactionProvider);

      // Envoie le message à l'IA avec le contexte des transactions
      final response = await _aiService.sendMessage(
        message: message, 
        withContext: true,
        transactionContext: transactionContext,
      );
      
      final DateTime responseTime = DateTime.now();
      final assistantMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: responseTime,
      );

      // Ajoute la réponse de l'assistant
      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });
      
      // Sauvegarde la réponse de l'assistant dans l'historique
      await _historyService.addMessage({
        'role': 'assistant',
        'content': response,
        'timestamp': responseTime.toIso8601String(),
      });

      // Retour haptique + son pour cette action importante
      await FeedbackUtils().provideFeedbackForAction();
      
      // Faire défiler vers le bas après avoir reçu la réponse
      _scrollToBottom();
      
    } catch (e) {
      final DateTime errorTime = DateTime.now();
      final errorMessage = ChatMessage(
        text: "Impossible de communiquer avec l'assistant: $e",
        isUser: false,
        timestamp: errorTime,
      );
      
      // Gestion des erreurs
      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
      
      // Sauvegarde le message d'erreur dans l'historique
      await _historyService.addMessage({
        'role': 'system',
        'content': "Impossible de communiquer avec l'assistant: $e",
        'timestamp': errorTime.toIso8601String(),
      });
      
      print("Erreur: $e");
      
      // Faire défiler vers le bas même en cas d'erreur
      _scrollToBottom();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant IA'),
        actions: [
          // Bouton pour effacer l'historique des conversations
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              // Confirmation avant de supprimer
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Effacer l\'historique'),
                  content: const Text('Voulez-vous vraiment effacer tout l\'historique des conversations ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Effacer'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                // Effacer l'historique de stockage local
                await _historyService.clearHistory();
                // Retour haptique (vibration uniquement) pour la navigation
                await FeedbackUtils().provideFeedbackForMenu();
                
                // Réinitialiser le service IA (ajoute aussi un message de bienvenue)
                _aiService.clearChatHistory();
                
                // Afficher le nouveau message de bienvenue
                setState(() {
                  _messages.clear();
                  _messages.add(ChatMessage(
                    text: "Bonjour, je suis votre assistant financier personnel. Je peux vous aider à analyser vos finances, suggérer des stratégies d'épargne, et répondre à vos questions sur votre budget. Comment puis-je vous aider aujourd'hui ?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ));
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message,
                  previousIsSameSender: index > 0 && _messages[index - 1].isUser == message.isUser,
                );
              },
            ),
          ),
          
          // Indicateur de chargement
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Zone de saisie du message
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Champ de texte
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Poser une question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
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
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool previousIsSameSender;

  const MessageBubble({
    super.key,
    required this.message,
    this.previousIsSameSender = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    
    return Padding(
      padding: EdgeInsets.only(
        top: previousIsSameSender ? 4 : 12,
        bottom: 4,
        left: 8,
        right: 8,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Information de temps
          if (!previousIsSameSender)
            Padding(
              padding: EdgeInsets.only(
                bottom: 4,
                left: isUser ? 0 : 12,
                right: isUser ? 12 : 0,
              ),
              child: Text(
                DateFormat('dd/MM HH:mm').format(message.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          
          // Bulle de message
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary.withOpacity(0.9)
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              message.text,
              style: TextStyle(
                color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
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

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
