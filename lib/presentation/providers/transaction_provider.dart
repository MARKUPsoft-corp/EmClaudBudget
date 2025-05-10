import 'package:flutter/foundation.dart';
import 'package:budget_express/domain/entities/transaction.dart';
import 'package:budget_express/domain/repositories/transaction_repository.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _repository;
  
  TransactionProvider(this._repository);
  
  // État pour les revenus
  List<Income> _incomes = [];
  List<Income> get incomes => _incomes;
  double _totalIncome = 0;
  double get totalIncome => _totalIncome;
  Map<bool, double> _incomesByType = {};
  Map<bool, double> get incomesByType => _incomesByType;
  
  // État pour les dépenses
  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;
  double _totalExpense = 0;
  double get totalExpense => _totalExpense;
  Map<String, double> _expensesByCategory = {};
  Map<String, double> get expensesByCategory => _expensesByCategory;
  
  // Solde (différence entre revenus et dépenses)
  double get balance => _totalIncome - _totalExpense;
  double _previousBalance = 0;
  double get previousBalance => _previousBalance;
  
  // État de chargement
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // État d'erreur
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Initialisation des données
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Charger les revenus
      _incomes = await _repository.getAllIncomes();
      _totalIncome = await _repository.getTotalIncome();
      _incomesByType = await _repository.getIncomesByType();
      
      // Charger les dépenses
      _expenses = await _repository.getAllExpenses();
      _totalExpense = await _repository.getTotalExpense();
      _expensesByCategory = await _repository.getExpensesByCategory();
      
      // Calculer le solde précédent (pour l'animation)
      _previousBalance = balance;
      
      // Configurer les flux de données
      _setupStreams();
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des données: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Configurer les flux pour les mises à jour en temps réel
  void _setupStreams() {
    // Flux pour les revenus
    _repository.watchAllIncomes().listen((data) {
      _incomes = data;
      notifyListeners();
    });
    
    // Flux pour les dépenses
    _repository.watchAllExpenses().listen((data) {
      _expenses = data;
      notifyListeners();
    });
    
    // Flux pour les statistiques
    _repository.watchIncomesByType().listen((data) {
      _incomesByType = data;
      notifyListeners();
    });
    
    _repository.watchExpensesByCategory().listen((data) {
      _expensesByCategory = data;
      notifyListeners();
    });
    
    // Flux pour le solde
    _repository.watchBalance().listen((data) {
      _previousBalance = balance;
      _totalIncome = data + _totalExpense; // Balance = Income - Expense
      notifyListeners();
    });
  }
  
  // Méthodes pour les revenus
  Future<bool> addIncome(Income income) async {
    try {
      await _repository.addIncome(income);
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout du revenu: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateIncome(Income income) async {
    try {
      final success = await _repository.updateIncome(income);
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du revenu: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteIncome(int id) async {
    try {
      await _repository.deleteIncome(id);
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression du revenu: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Méthodes pour les dépenses
  Future<bool> addExpense(Expense expense) async {
    try {
      await _repository.addExpense(expense);
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout de la dépense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateExpense(Expense expense) async {
    try {
      final success = await _repository.updateExpense(expense);
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour de la dépense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression de la dépense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Effacer les messages d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
