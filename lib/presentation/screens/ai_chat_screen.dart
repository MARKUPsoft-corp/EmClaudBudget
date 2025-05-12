import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:budget_express/services/ai_service.dart';
import 'package:budget_express/presentation/providers/transaction_provider.dart';
import 'package:budget_express/utils/feedback_utils.dart';
import 'package:budget_express/config/api_keys.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Clé API Groq provenant du fichier de configuration
  // Isolée dans un fichier séparé non versionné sur GitHub
  static final _groqApiKey = ApiKeys.groqApiKey;
  
  // Instance du service IA
  late AIService _aiService;
  
  @override
  void initState() {
    super.initState();
    _aiService = AIService(_groqApiKey);
    
    // Ajouter un message de bienvenue initial
    _messages.add(
      ChatMessage(
        text: "Bonjour ! Je suis votre assistant financier. Comment puis-je vous aider avec la gestion de vos finances aujourd'hui ?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Créer le contexte des transactions pour l'IA
  TransactionContext _getTransactionContext(TransactionProvider provider) {
    // Obtenir les 30 derniers jours
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    // Filtrer les transactions des 30 derniers jours
    final recentExpenses = provider.expenses
        .where((e) => e.date.isAfter(thirtyDaysAgo))
        .toList();
    
    final recentIncomes = provider.incomes
        .where((i) => i.date.isAfter(thirtyDaysAgo))
        .toList();
    
    // Calculer les totaux mensuels
    final monthlyExpenseTotal = recentExpenses.fold<double>(
      0, (sum, expense) => sum + expense.amount);
    
    final monthlyIncomeTotal = recentIncomes.fold<double>(
      0, (sum, income) => sum + income.amount);
    
    // Obtenir les 5 dernières dépenses, triées par date
    final lastExpenses = [...provider.expenses]
      ..sort((a, b) => b.date.compareTo(a.date))
      ..take(5).toList();
    
    // Obtenir les 5 derniers revenus, triés par date
    final lastIncomes = [...provider.incomes]
      ..sort((a, b) => b.date.compareTo(a.date))
      ..take(5).toList();
    
    // Créer une map des dépenses par catégorie
    final expensesByCategory = <String, double>{};
    for (var expense in recentExpenses) {
      expensesByCategory.update(
        expense.categoryId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    
    return TransactionContext(
      recentExpenses: lastExpenses,
      recentIncomes: lastIncomes,
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
    
    // Vibration pour l'action
    FeedbackUtils().provideFeedbackForAction();
    
    // Ajouter le message de l'utilisateur
    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
      _messageController.clear();
    });
    
    // Faire défiler vers le bas
    _scrollToBottom();
    
    try {
      // Obtenir le provider pour accéder aux données
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      
      // Créer le contexte des transactions
      final transactionContext = _getTransactionContext(provider);
      
      // Envoyer le message à l'IA avec le contexte
      final response = await _aiService.sendMessage(
        message: message,
        withContext: true,
        transactionContext: transactionContext,
      );
      
      // Ajouter la réponse de l'IA
      setState(() {
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      // Ajouter un message d'erreur
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Désolé, je n'ai pas pu traiter votre demande. Veuillez réessayer plus tard.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
    
    // Faire défiler vers le bas après avoir reçu la réponse
    _scrollToBottom();
  }
  
  // Faire défiler vers le bas de la conversation
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant IA'),
        actions: [
          // Bouton pour réinitialiser la conversation
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Vibration pour le menu
              FeedbackUtils().provideFeedbackForMenu();
              setState(() {
                _aiService.clearChatHistory();
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text: "Bonjour ! Je suis votre assistant financier. Comment puis-je vous aider avec la gestion de vos finances aujourd'hui ?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone d'information sur l'IA
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Je peux vous aider à analyser vos finances, comprendre vos dépenses, et vous donner des conseils budgétaires.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Indicateur de chargement
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          
          // Zone de saisie du message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Bouton pour activer le contexte
                  IconButton(
                    icon: Icon(
                      Icons.account_balance_wallet,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      FeedbackUtils().provideFeedbackForMenu();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contexte financier activé pour l\'assistant'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Inclure le contexte financier',
                  ),
                  // Champ de saisie
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Posez votre question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton d'envoi avec tag Hero unique
                  FloatingActionButton(
                    heroTag: 'ai_chat_send_button', // Tag Hero unique
                    onPressed: _sendMessage,
                    mini: true,
                    tooltip: 'Envoyer',
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Construire une bulle de message
  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    
    final dateFormat = DateFormat('HH:mm');
    final timeString = dateFormat.format(message.timestamp);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar de l'IA (seulement pour les messages de l'IA)
          if (!isUser)
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              radius: 16,
              child: const Icon(
                Icons.assistant,
                size: 18,
                color: Colors.white,
              ),
            ),
          
          const SizedBox(width: 8),
          
          // Bulle de message
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Contenu du message
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Horodatage
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Avatar de l'utilisateur (seulement pour les messages de l'utilisateur)
          if (isUser)
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              radius: 16,
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
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
