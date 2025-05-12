import 'dart:math' as math;
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/domain/entities/transaction.dart';
import 'package:flutter/material.dart';

/// Types d'actions que l'assistant IA peut effectuer
enum ActionType {
  addExpense,    // Ajouter une dépense
  deleteExpense, // Supprimer une dépense
  addIncome,     // Ajouter un revenu
  deleteIncome,  // Supprimer un revenu
  unknown        // Action non reconnue
}

/// Structure pour contenir les détails d'une action reconnue
class RecognizedAction {
  final ActionType type;
  final Map<String, dynamic> parameters;
  final String originalMessage;
  final String feedbackMessage;

  RecognizedAction({
    required this.type,
    required this.parameters,
    required this.originalMessage,
    required this.feedbackMessage,
  });

  /// Vérifie si l'action a tous les paramètres nécessaires
  bool get isComplete {
    switch (type) {
      case ActionType.addExpense:
        return parameters.containsKey('amount') &&
            parameters.containsKey('description') &&
            parameters.containsKey('categoryId');
      case ActionType.deleteExpense:
        return parameters.containsKey('id') || parameters.containsKey('description');
      case ActionType.addIncome:
        return parameters.containsKey('amount') &&
            parameters.containsKey('description') &&
            parameters.containsKey('source');
      case ActionType.deleteIncome:
        return parameters.containsKey('id') || parameters.containsKey('description');
      case ActionType.unknown:
        return false;
    }
  }

  /// Convertit la reconnaissance en Expense utilisable par l'application
  Expense? toExpense() {
    if (type != ActionType.addExpense || !isComplete) return null;

    return Expense(
      amount: parameters['amount'] as double,
      description: parameters['description'] as String,
      date: parameters['date'] as DateTime? ?? DateTime.now(),
      categoryId: parameters['categoryId'] as String,
    );
  }

  /// Convertit la reconnaissance en Income utilisable par l'application
  Income? toIncome() {
    if (type != ActionType.addIncome || !isComplete) return null;

    return Income(
      amount: parameters['amount'] as double,
      description: parameters['description'] as String,
      date: parameters['date'] as DateTime? ?? DateTime.now(),
      source: parameters['source'] as String,
      isActive: parameters['isActive'] as bool? ?? true,
      frequency: parameters['frequency'] as String? ?? 'Unique',
    );
  }
}

/// Service qui analyse les messages pour détecter les intentions d'ajouter ou supprimer des transactions
class ActionRecognizer {
  /// Reconnaît les intentions liées aux transactions dans un message
  RecognizedAction recognizeAction(String message) {
    final lowercaseMessage = message.toLowerCase();
    
    // Détecter les intentions d'ajout de dépense
    if (_containsAddExpenseIntent(lowercaseMessage)) {
      return _recognizeAddExpense(message);
    }
    
    // Détecter les intentions de suppression de dépense
    else if (_containsDeleteExpenseIntent(lowercaseMessage)) {
      return _recognizeDeleteExpense(message);
    }
    
    // Détecter les intentions d'ajout de revenu
    else if (_containsAddIncomeIntent(lowercaseMessage)) {
      return _recognizeAddIncome(message);
    }
    
    // Détecter les intentions de suppression de revenu
    else if (_containsDeleteIncomeIntent(lowercaseMessage)) {
      return _recognizeDeleteIncome(message);
    }
    
    // Action non reconnue
    return RecognizedAction(
      type: ActionType.unknown,
      parameters: {},
      originalMessage: message,
      feedbackMessage: "Je n'ai pas détecté d'action liée à vos finances.",
    );
  }
  
  /// Vérifie si le message contient une intention d'ajouter une dépense
  bool _containsAddExpenseIntent(String message) {
    final patterns = [
      'ajoute',
      'crée',
      'enregistre',
      'nouvelle dépense',
      'dépenser',
      'acheter',
      'payer',
      'achat',
      'dépense'
    ];
    
    return patterns.any((pattern) => message.contains(pattern));
  }
  
  /// Vérifie si le message contient une intention de supprimer une dépense
  bool _containsDeleteExpenseIntent(String message) {
    final patterns = [
      'supprime',
      'annule',
      'efface',
      'retire',
      'enlève',
      'supprimer la dépense',
      'annuler la dépense'
    ];
    
    return patterns.any((pattern) => message.contains(pattern)) && 
           (message.contains('dépense') || message.contains('achat'));
  }
  
  /// Vérifie si le message contient une intention d'ajouter un revenu
  bool _containsAddIncomeIntent(String message) {
    final patterns = [
      'ajoute',
      'crée',
      'enregistre',
      'nouveau revenu',
      'nouvelle entrée',
      'nouvelle rentrée',
      'reçu',
      'gagné',
      'salaire',
      'revenu'
    ];
    
    return patterns.any((pattern) => message.contains(pattern)) && 
           (message.contains('revenu') || message.contains('argent') || 
            message.contains('salaire') || message.contains('rentrée'));
  }
  
  /// Vérifie si le message contient une intention de supprimer un revenu
  bool _containsDeleteIncomeIntent(String message) {
    final patterns = [
      'supprime',
      'annule',
      'efface',
      'retire',
      'enlève',
      'supprimer le revenu',
      'annuler le revenu'
    ];
    
    return patterns.any((pattern) => message.contains(pattern)) && 
           (message.contains('revenu') || message.contains('salaire'));
  }
  
  /// Reconnaît les paramètres d'ajout de dépense
  RecognizedAction _recognizeAddExpense(String message) {
    final parameters = <String, dynamic>{};
    final lowercaseMessage = message.toLowerCase();
    
    // Reconnaître le montant
    final amountRegex = RegExp(r'(\d+(?:[,.]\d+)?)\s*(fcfa|cfa|f|franc|francs)?');
    final amountMatch = amountRegex.firstMatch(message);
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)!.replaceAll(',', '.');
      parameters['amount'] = double.parse(amountStr);
    }
    
    // Reconnaître la description
    String? description;
    
    // Méthode simplifiée pour extraire la description
    // Essayer de trouver une description après "pour"
    final pourRegex = RegExp(r'pour\s+([\w\s]+)');
    final pourMatch = pourRegex.firstMatch(lowercaseMessage);
    if (pourMatch != null) {
      description = pourMatch.group(1)?.trim();
    }
    
    // Sinon essayer après "de"
    if (description == null) {
      final deRegex = RegExp(r'de\s+([\w\s]+)');
      final deMatch = deRegex.firstMatch(lowercaseMessage);
      if (deMatch != null) {
        description = deMatch.group(1)?.trim();
      }
    }
    
    // Sinon essayer après "en"
    if (description == null) {
      final enRegex = RegExp(r'en\s+([\w\s]+)');
      final enMatch = enRegex.firstMatch(lowercaseMessage);
      if (enMatch != null) {
        description = enMatch.group(1)?.trim();
      }
    }
    
    // Si on n'a toujours pas trouvé, prendre les mots après le montant
    if (description == null && amountMatch != null) {
      final afterAmount = message.substring(amountMatch.end);
      final words = afterAmount.split(' ').where((word) => word.isNotEmpty).toList();
      if (words.length > 1) {
        final maxIndex = math.min(5, words.length);
        description = words.getRange(0, maxIndex).join(' ').trim();
      }
    }
    
    if (description != null) {
      parameters['description'] = description;
    }
    
    // Reconnaître la catégorie
    final categories = AppConstants.expenseCategories;
    String? categoryId;
    
    for (var category in categories) {
      if (lowercaseMessage.contains(category.name.toLowerCase())) {
        categoryId = category.id;
        break;
      }
    }
    
    // Si pas de catégorie identifiée, appliquer une heuristique
    if (categoryId == null) {
      if (lowercaseMessage.contains('nourriture') || 
          lowercaseMessage.contains('repas') || 
          lowercaseMessage.contains('manger') ||
          lowercaseMessage.contains('cuisine')) {
        categoryId = 'food';
      } else if (lowercaseMessage.contains('voiture') || 
                lowercaseMessage.contains('taxi') || 
                lowercaseMessage.contains('bus') ||
                lowercaseMessage.contains('transport')) {
        categoryId = 'transport';
      } else if (lowercaseMessage.contains('maison') || 
                lowercaseMessage.contains('appartement') || 
                lowercaseMessage.contains('loyer') ||
                lowercaseMessage.contains('electricité') ||
                lowercaseMessage.contains('eau')) {
        categoryId = 'housing';
      } else if (lowercaseMessage.contains('jeu') || 
                lowercaseMessage.contains('sortie') || 
                lowercaseMessage.contains('cinema') ||
                lowercaseMessage.contains('restaurant') ||
                lowercaseMessage.contains('loisir')) {
        categoryId = 'entertainment';
      } else if (lowercaseMessage.contains('docteur') || 
                lowercaseMessage.contains('médecin') || 
                lowercaseMessage.contains('pharmacie') ||
                lowercaseMessage.contains('hôpital') ||
                lowercaseMessage.contains('santé')) {
        categoryId = 'health';
      } else {
        categoryId = 'other';
      }
    }
    
    parameters['categoryId'] = categoryId;
    
    // Reconnaître la date (par défaut aujourd'hui)
    parameters['date'] = DateTime.now();
    
    // Créer le message de feedback basé sur les paramètres reconnus
    String feedbackMessage;
    if (parameters.containsKey('amount') && parameters.containsKey('description') && parameters.containsKey('categoryId')) {
      final category = categories.firstWhere((c) => c.id == parameters['categoryId']);
      feedbackMessage = "J'ai ajouté une dépense de ${parameters['amount']} FCFA pour \"${parameters['description']}\" dans la catégorie ${category.name}.";
    } else {
      List<String> missingParams = [];
      if (!parameters.containsKey('amount')) missingParams.add("le montant");
      if (!parameters.containsKey('description')) missingParams.add("la description");
      if (!parameters.containsKey('categoryId')) missingParams.add("la catégorie");
      
      feedbackMessage = "Je vais ajouter une dépense, mais il me manque ${missingParams.join(', ')}. Pouvez-vous préciser?";
    }
    
    return RecognizedAction(
      type: ActionType.addExpense,
      parameters: parameters,
      originalMessage: message,
      feedbackMessage: feedbackMessage,
    );
  }
  
  /// Reconnaît les paramètres de suppression de dépense
  RecognizedAction _recognizeDeleteExpense(String message) {
    final parameters = <String, dynamic>{};
    final lowercaseMessage = message.toLowerCase();
    
    // Reconnaître la description pour retrouver la dépense
    String? description;
    
    // Méthode simplifiée pour extraire la description
    final pourRegex = RegExp(r'pour\s+([\w\s]+)');
    final pourMatch = pourRegex.firstMatch(lowercaseMessage);
    if (pourMatch != null) {
      description = pourMatch.group(1)?.trim();
    }
    
    if (description == null) {
      final deRegex = RegExp(r'de\s+([\w\s]+)');
      final deMatch = deRegex.firstMatch(lowercaseMessage);
      if (deMatch != null) {
        description = deMatch.group(1)?.trim();
      }
    }
    
    if (description == null) {
      final depenseRegex = RegExp(r'la dépense\s+(?:de|pour)?\s*([\w\s]+)');
      final depenseMatch = depenseRegex.firstMatch(lowercaseMessage);
      if (depenseMatch != null) {
        description = depenseMatch.group(1)?.trim();
      }
    }
    
    if (description == null) {
      // Utiliser un guilllemet double pour la chaîne afin d'éviter les problèmes d'échappement
      final achatRegex = RegExp(r"l'achat\s+(?:de|pour)?\s*([\w\s]+)");
      final achatMatch = achatRegex.firstMatch(lowercaseMessage);
      if (achatMatch != null) {
        description = achatMatch.group(1)?.trim();
      }
    }
    
    if (description != null) {
      parameters['description'] = description;
    }
    
    // Créer le message de feedback basé sur les paramètres reconnus
    String feedbackMessage;
    if (parameters.containsKey('description')) {
      feedbackMessage = "J'ai supprimé la dépense associée à \"${parameters['description']}\".";
    } else {
      feedbackMessage = "Je dois supprimer une dépense, mais je ne sais pas laquelle. Pouvez-vous me donner plus de détails?";
    }
    
    return RecognizedAction(
      type: ActionType.deleteExpense,
      parameters: parameters,
      originalMessage: message,
      feedbackMessage: feedbackMessage,
    );
  }
  
  /// Reconnaît les paramètres d'ajout de revenu
  RecognizedAction _recognizeAddIncome(String message) {
    final parameters = <String, dynamic>{};
    final lowercaseMessage = message.toLowerCase();
    
    // Reconnaître le montant
    final amountRegex = RegExp(r'(\d+(?:[,.]\d+)?)\s*(fcfa|cfa|f|franc|francs)?');
    final amountMatch = amountRegex.firstMatch(message);
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)!.replaceAll(',', '.');
      parameters['amount'] = double.parse(amountStr);
    }
    
    // Reconnaître la description
    String? description;
    
    // Méthode simplifiée pour extraire la description
    final pourRegex = RegExp(r'pour\s+([\w\s]+)');
    final pourMatch = pourRegex.firstMatch(lowercaseMessage);
    if (pourMatch != null) {
      description = pourMatch.group(1)?.trim();
    }
    
    if (description == null) {
      final deRegex = RegExp(r'de\s+([\w\s]+)');
      final deMatch = deRegex.firstMatch(lowercaseMessage);
      if (deMatch != null) {
        description = deMatch.group(1)?.trim();
      }
    }
    
    if (description == null) {
      final duRegex = RegExp(r'du\s+([\w\s]+)');
      final duMatch = duRegex.firstMatch(lowercaseMessage);
      if (duMatch != null) {
        description = duMatch.group(1)?.trim();
      }
    }
    
    // Si on n'a toujours pas trouvé, prendre les mots après le montant
    if (description == null && amountMatch != null) {
      final afterAmount = message.substring(amountMatch.end);
      final words = afterAmount.split(' ').where((word) => word.isNotEmpty).toList();
      if (words.length > 1) {
        final maxIndex = math.min(5, words.length);
        description = words.getRange(0, maxIndex).join(' ').trim();
      }
    }
    
    if (description != null) {
      parameters['description'] = description;
    }
    
    // Source par défaut
    parameters['source'] = 'travail'; // ID d'une source par défaut
    parameters['isActive'] = true;
    parameters['frequency'] = 'Unique';
    
    // Créer le message de feedback basé sur les paramètres reconnus
    String feedbackMessage;
    if (parameters.containsKey('amount') && parameters.containsKey('description')) {
      feedbackMessage = "J'ai ajouté un revenu de ${parameters['amount']} FCFA pour \"${parameters['description']}\".";
    } else {
      List<String> missingParams = [];
      if (!parameters.containsKey('amount')) missingParams.add("le montant");
      if (!parameters.containsKey('description')) missingParams.add("la description");
      
      feedbackMessage = "Je vais ajouter un revenu, mais il me manque ${missingParams.join(', ')}. Pouvez-vous préciser?";
    }
    
    return RecognizedAction(
      type: ActionType.addIncome,
      parameters: parameters,
      originalMessage: message,
      feedbackMessage: feedbackMessage,
    );
  }
  
  /// Reconnaît les paramètres de suppression de revenu
  RecognizedAction _recognizeDeleteIncome(String message) {
    final parameters = <String, dynamic>{};
    final lowercaseMessage = message.toLowerCase();
    
    // Reconnaître la description pour retrouver le revenu
    String? description;
    
    // Méthode simplifiée pour extraire la description
    final pourRegex = RegExp(r'pour\s+([\w\s]+)');
    final pourMatch = pourRegex.firstMatch(lowercaseMessage);
    if (pourMatch != null) {
      description = pourMatch.group(1)?.trim();
    }
    
    if (description == null) {
      final deRegex = RegExp(r'de\s+([\w\s]+)');
      final deMatch = deRegex.firstMatch(lowercaseMessage);
      if (deMatch != null) {
        description = deMatch.group(1)?.trim();
      }
    }
    
    if (description == null) {
      final revenuRegex = RegExp(r'le revenu\s+(?:de|pour)?\s*([\w\s]+)');
      final revenuMatch = revenuRegex.firstMatch(lowercaseMessage);
      if (revenuMatch != null) {
        description = revenuMatch.group(1)?.trim();
      }
    }
    
    if (description == null) {
      final salaireRegex = RegExp(r'le salaire\s+(?:de|pour)?\s*([\w\s]+)');
      final salaireMatch = salaireRegex.firstMatch(lowercaseMessage);
      if (salaireMatch != null) {
        description = salaireMatch.group(1)?.trim();
      }
    }
    
    if (description != null) {
      parameters['description'] = description;
    }
    
    // Créer le message de feedback basé sur les paramètres reconnus
    String feedbackMessage;
    if (parameters.containsKey('description')) {
      feedbackMessage = "J'ai supprimé le revenu associé à \"${parameters['description']}\".";
    } else {
      feedbackMessage = "Je dois supprimer un revenu, mais je ne sais pas lequel. Pouvez-vous me donner plus de détails?";
    }
    
    return RecognizedAction(
      type: ActionType.deleteIncome,
      parameters: parameters,
      originalMessage: message,
      feedbackMessage: feedbackMessage,
    );
  }
}
