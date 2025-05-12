import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:budget_express/domain/entities/transaction.dart';

/// Service permettant l'interaction avec le modèle IA de Groq
class AIService {
  final String _apiKey;
  final http.Client _client = http.Client();
  
  // Historique des messages pour maintenir le contexte
  final List<Map<String, String>> _chatHistory = [];
  List<Map<String, String>> get chatHistory => List.unmodifiable(_chatHistory);
  
  AIService(this._apiKey);
  
  /// Envoie un message à l'IA et obtient une réponse
  /// 
  /// [message] est le message utilisateur
  /// [withContext] détermine si on inclut les données financières
  /// [transactionContext] fournit le contexte des données si withContext est true
  Future<String> sendMessage({
    required String message, 
    bool withContext = false,
    TransactionContext? transactionContext,
  }) async {
    try {
      // Ajouter le message au chat avec ou sans contexte financier
      if (withContext && transactionContext != null) {
        final contextualMessage = _buildContextualPrompt(message, transactionContext);
        _chatHistory.add({'role': 'user', 'content': contextualMessage});
      } else {
        _chatHistory.add({'role': 'user', 'content': message});
      }
      
      // Préparer les messages pour l'API en incluant l'historique
      final messages = [
        {'role': 'system', 'content': _getSystemPrompt()},
        ..._chatHistory.takeLast(10), // Limiter à 10 derniers messages pour éviter de dépasser le contexte
      ];

      // Appel à l'API Groq
      final response = await _client.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // Utilisation d'un modèle de production officiellement listé par Groq
          'model': 'llama-3.1-8b-instant',
          'messages': messages,
          'temperature': 0.4,
          'max_tokens': 1000
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['choices'][0]['message']['content'];
        
        // Ajouter la réponse à l'historique
        _chatHistory.add({'role': 'assistant', 'content': responseText});
        
        return responseText;
      } else {
        final errorMsg = "Erreur API (${response.statusCode}): ${response.body}";
        debugPrint(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      final errorMsg = "Impossible de communiquer avec l'assistant: $e";
      debugPrint(errorMsg);
      
      // On ajoute quand même l'erreur à l'historique pour garder la cohérence
      _chatHistory.add({'role': 'assistant', 'content': errorMsg});
      
      return errorMsg;
    }
  }
  
  /// Construit un prompt contextuel avec les données financières
  String _buildContextualPrompt(String userMessage, TransactionContext context) {
    // Formater les dernières dépenses
    final expensesList = context.recentExpenses
        .map((e) => "- ${e.description}: ${e.amount} FCFA (${_formatDate(e.date)}), catégorie: ${e.categoryId}")
        .join("\n");
    
    // Formater les derniers revenus
    final incomesList = context.recentIncomes
        .map((i) => "- ${i.description}: ${i.amount} FCFA (${_formatDate(i.date)}), type: ${i.isActive ? 'actif' : 'passif'}")
        .join("\n");
    
    // Construire le prompt avec le contexte
    return """
Contexte financier actuel:
Solde actuel: ${context.currentBalance} FCFA
Total dépenses (30 derniers jours): ${context.monthlyExpenseTotal} FCFA
Total revenus (30 derniers jours): ${context.monthlyIncomeTotal} FCFA

5 dernières dépenses:
$expensesList

5 derniers revenus:
$incomesList

Principales catégories de dépenses:
${context.expensesByCategory.entries.map((e) => "- ${e.key}: ${e.value} FCFA").join("\n")}

Question/demande: $userMessage
""";
  }
  
  /// Obtient le prompt système qui définit le comportement de l'IA
  String _getSystemPrompt() {
    return """
Tu es Claude, l'assistant financier intégré à l'application CashFlow. Tu aides les utilisateurs à mieux comprendre et gérer leurs finances personnelles.

Règles à respecter:
1. Sois concis et direct dans tes réponses
2. Réponds toujours en français
3. Focalise-toi sur les aspects financiers et budgétaires
4. Donne des conseils pratiques et personnalisés basés sur les données partagées
5. Respecte la vie privée de l'utilisateur
6. N'invente pas de données si elles ne sont pas fournies
7. Pour les montants, utilise toujours le format "XXX FCFA"

Quand l'utilisateur te pose une question sur ses finances, utilise le contexte donné (solde, revenus, dépenses) pour formuler une réponse pertinente.
""";
  }
  
  /// Formater une date en format français
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
  
  /// Vider l'historique de conversation
  void clearChatHistory() {
    _chatHistory.clear();
  }
}

/// Extension pour obtenir les derniers éléments d'une liste
extension ListExtension<T> on List<T> {
  List<T> takeLast(int n) {
    if (isEmpty) return [];
    if (length <= n) return this;
    return sublist(length - n);
  }
}

/// Classe pour regrouper toutes les données contextueltes pour l'IA
class TransactionContext {
  final List<Expense> recentExpenses;
  final List<Income> recentIncomes;
  final double currentBalance;
  final double monthlyExpenseTotal;
  final double monthlyIncomeTotal;
  final Map<String, double> expensesByCategory;
  
  TransactionContext({
    required this.recentExpenses,
    required this.recentIncomes,
    required this.currentBalance,
    required this.monthlyExpenseTotal,
    required this.monthlyIncomeTotal,
    required this.expensesByCategory,
  });
}
