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

  // Callback pour notifier des réessais (tentative, total, délai)
  Function(int, int, int)? onRetry;

  // Définit l'historique complet des messages (utilisé pour charger depuis le stockage local)
  set chatHistory(List<Map<String, dynamic>> history) {
    _chatHistory.clear();
    for (var msg in history) {
      _chatHistory.add({
        'role': msg['role'] as String,
        'content': msg['content'] as String,
      });
    }
  }

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
        final contextualMessage = _buildContextualPrompt(
          message,
          transactionContext,
        );
        _chatHistory.add({'role': 'user', 'content': contextualMessage});
      } else {
        _chatHistory.add({'role': 'user', 'content': message});
      }

      // Préparer les messages pour l'API en limitant l'historique pour éviter les limites de débit
      final messages = [
        {'role': 'system', 'content': _getSystemPrompt()},
        // Ne prendre que les 5 derniers messages pour éviter de dépasser la limite de tokens par minute
        ..._chatHistory.takeLast(5),
      ];

      // Appel à l'API Groq avec stratégie de réessai en cas d'erreur de limite de débit
      http.Response response;
      int maxRetries = 3;
      int currentRetry = 0;
      int retryDelayMs = 2000; // Délai initial de 2 secondes

      while (true) {
        try {
          response = await _client.post(
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
              // Réduire les max_tokens pour éviter de dépasser la limite par minute
              'max_tokens': 500,
            }),
          );

          // Vérifier si on a une erreur de limite de débit (429)
          if (response.statusCode == 429 && currentRetry < maxRetries) {
            currentRetry++;
            print(
              'Limite de débit atteinte. Réessai ${currentRetry}/${maxRetries} dans ${retryDelayMs / 1000} secondes...',
            );
            // Notifier l'interface utilisateur du réessai
            onRetry?.call(currentRetry, maxRetries, retryDelayMs);
            await Future.delayed(Duration(milliseconds: retryDelayMs));
            // Augmenter progressivement le délai de réessai (backoff exponentiel)
            retryDelayMs *= 2;
            continue;
          }

          // Si pas d'erreur 429 ou si on a dépassé le nombre de réessais, sortir de la boucle
          break;
        } catch (e) {
          if (currentRetry < maxRetries) {
            currentRetry++;
            print(
              'Erreur de connexion. Réessai ${currentRetry}/${maxRetries} dans ${retryDelayMs / 1000} secondes...',
            );
            // Notifier l'interface utilisateur du réessai
            onRetry?.call(currentRetry, maxRetries, retryDelayMs);
            await Future.delayed(Duration(milliseconds: retryDelayMs));
            retryDelayMs *= 2;
            continue;
          }
          rethrow;
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['choices'][0]['message']['content'];

        // Ajouter la réponse à l'historique
        _chatHistory.add({'role': 'assistant', 'content': responseText});

        return responseText;
      } else {
        final errorMsg =
            "Erreur API (${response.statusCode}): ${response.body}";
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
  String _buildContextualPrompt(String userQuery, TransactionContext context) {
    // Version simplifiée du contexte pour réduire le nombre de tokens
    final totalMonthlyIncome = context.monthlyIncomeTotal.toStringAsFixed(2);
    final totalMonthlyExpenses = context.monthlyExpenseTotal.toStringAsFixed(2);
    final balance = context.currentBalance.toStringAsFixed(2);

    // Réduire le nombre de revenus et dépenses inclus dans le contexte
    String recentIncomesText = '';
    for (final income in context.recentIncomes.take(3)) {
      recentIncomesText +=
          '- ${_formatDate(income.date)} : ${income.amount.toStringAsFixed(2)} FCFA - ${income.description}\n';
    }

    String recentExpensesText = '';
    for (final expense in context.recentExpenses.take(3)) {
      recentExpensesText +=
          '- ${_formatDate(expense.date)} : ${expense.amount.toStringAsFixed(2)} FCFA - ${expense.categoryId}\n';
    }

    // Simplifier les dépenses par catégorie pour inclure seulement les principales
    var topCategories =
        context.expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    String expensesByCategoryText = '';
    for (var entry in topCategories.take(3)) {
      expensesByCategoryText += '- ${entry.key}: ${entry.value.toStringAsFixed(2)} FCFA\n';
    }

    return '''
    Question: "$userQuery"
    Contexte: Solde=$balance FCFA, Revenus=$totalMonthlyIncome FCFA, Dépenses=$totalMonthlyExpenses FCFA
    Dépenses récentes: $recentExpensesText
    Revenus récents: $recentIncomesText
    Top catégories: $expensesByCategoryText
    ''';
  }

  /// Obtient le prompt système qui définit le comportement de l'IA
  String _getSystemPrompt() {
    return '''
Vous êtes un assistant financier personnel pour une application de suivi de budget utilisant le franc CFA (FCFA) comme devise.
Votre rôle est d'aider l'utilisateur à comprendre ses finances, analyser ses habitudes de dépenses,
proposer des stratégies d'épargne, et répondre aux questions liées au budget et aux finances personnelles.

INSTRUCTIONS IMPORTANTES :
1. Fournissez des réponses CONCISES et DIRECTES qui répondent EXACTEMENT à la question posée.
2. LIMITEZ vos réponses à 1-3 phrases courtes, sauf si plus de détails sont explicitement demandés.
3. Évitez les longues introductions et les formules de politesse inutiles.
4. Utilisez TOUJOURS le franc CFA (FCFA) comme devise dans vos réponses.
5. Soyez précis et factuel, sans être verbeux.
''';
  }

  /// Formater une date en format français
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  /// Réinitialise l'historique des conversations
  void clearChatHistory() {
    _chatHistory.clear();
    // Ajouter un message de bienvenue pour démarrer la conversation
    _chatHistory.add({
      'role': 'assistant',
      'content':
          "Bonjour, je suis votre assistant financier personnel. Je peux vous aider à analyser vos finances, suggérer des stratégies d'épargne, et répondre à vos questions sur votre budget. Comment puis-je vous aider aujourd'hui ?",
    });
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
