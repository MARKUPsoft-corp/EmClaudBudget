import 'package:flutter/material.dart';

class AppConstants {
  // Noms des routes
  static const String homeRoute = '/';
  static const String dashboardRoute = '/dashboard';
  static const String incomeRoute = '/income';
  static const String expenseRoute = '/expense';
  static const String addIncomeRoute = '/add-income';
  static const String addExpenseRoute = '/add-expense';
  static const String settingsRoute = '/settings';
  static const String aiChatRoute = '/ai-chat';

  // Catégories de dépenses
  static final List<ExpenseCategory> expenseCategories = [
    ExpenseCategory(
      id: 'food',
      name: 'Alimentation',
      icon: Icons.shopping_basket,
      color: const Color(0xFFFF8C00),
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car,
      color: const Color(0xFFFF9E2C),
    ),
    ExpenseCategory(
      id: 'housing',
      name: 'Logement',
      icon: Icons.home,
      color: const Color(0xFFFFB05C),
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Loisirs',
      icon: Icons.sports_esports,
      color: const Color(0xFFFFC78C),
    ),
    ExpenseCategory(
      id: 'health',
      name: 'Santé',
      icon: Icons.favorite,
      color: const Color(0xFFFFD2A9),
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Divers',
      icon: Icons.more_horiz,
      color: const Color(0xFFFFBE7D),
    ),
  ];

  // Types de revenus
  static final List<IncomeCategory> incomeCategories = [
    IncomeCategory(
      id: 'salary',
      name: 'Salaire',
      icon: Icons.work,
      isActive: true,
    ),
    IncomeCategory(
      id: 'freelance',
      name: 'Freelance',
      icon: Icons.computer,
      isActive: true,
    ),
    IncomeCategory(
      id: 'investments',
      name: 'Investissements',
      icon: Icons.trending_up,
      isActive: false,
    ),
    IncomeCategory(
      id: 'rental',
      name: 'Location',
      icon: Icons.house,
      isActive: false,
    ),
    IncomeCategory(
      id: 'other',
      name: 'Autre',
      icon: Icons.attach_money,
      isActive: true,
    ),
  ];

  // Format de date
  static const String dateFormat = 'dd/MM/yyyy';
  
  // Périodicité des revenus
  static final List<String> incomeFrequencies = [
    'Unique',
    'Hebdomadaire',
    'Mensuel',
    'Trimestriel',
    'Annuel',
  ];
  
  // Raccourcis clavier (pour Linux)
  static final Map<String, String> keyboardShortcuts = {
    'Ctrl+N': 'Nouvelle dépense',
    'Ctrl+R': 'Nouveau revenu',
    'Ctrl+D': 'Tableau de bord',
    'Ctrl+I': 'Liste des revenus',
    'Ctrl+E': 'Liste des dépenses',
    'Ctrl+S': 'Paramètres',
  };
}

class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class IncomeCategory {
  final String id;
  final String name;
  final IconData icon;
  final bool isActive;

  IncomeCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.isActive,
  });
}
