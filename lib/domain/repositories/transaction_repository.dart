import 'package:budget_express/domain/entities/transaction.dart';

abstract class TransactionRepository {
  // Méthodes pour les revenus
  Future<List<Income>> getAllIncomes();
  Stream<List<Income>> watchAllIncomes();
  Future<Income> getIncomeById(int id);
  Future<int> addIncome(Income income);
  Future<bool> updateIncome(Income income);
  Future<int> deleteIncome(int id);
  
  // Méthodes pour les dépenses
  Future<List<Expense>> getAllExpenses();
  Stream<List<Expense>> watchAllExpenses();
  Future<Expense> getExpenseById(int id);
  Future<int> addExpense(Expense expense);
  Future<bool> updateExpense(Expense expense);
  Future<int> deleteExpense(int id);
  
  // Méthodes pour les statistiques
  Future<double> getTotalIncome();
  Future<double> getTotalExpense();
  Future<Map<String, double>> getExpensesByCategory();
  Stream<Map<String, double>> watchExpensesByCategory();
  Future<Map<bool, double>> getIncomesByType();
  Stream<Map<bool, double>> watchIncomesByType();
  Stream<double> watchBalance();
}
