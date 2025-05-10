import 'package:drift/drift.dart';
import 'package:budget_express/data/datasources/app_database.dart';
import 'package:budget_express/domain/entities/transaction.dart' as entity;
import 'package:budget_express/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _database;

  TransactionRepositoryImpl(this._database);

  // Méthodes pour les revenus
  @override
  Future<List<entity.Income>> getAllIncomes() async {
    final incomes = await _database.getAllIncomes();
    return incomes.map(_mapIncomeToEntity).toList();
  }

  @override
  Stream<List<entity.Income>> watchAllIncomes() {
    return _database.watchAllIncomes().map(
          (incomes) => incomes.map(_mapIncomeToEntity).toList(),
        );
  }

  @override
  Future<entity.Income> getIncomeById(int id) async {
    final income = await _database.getIncomeById(id);
    return _mapIncomeToEntity(income);
  }

  @override
  Future<int> addIncome(entity.Income income) {
    return _database.insertIncome(
      IncomesCompanion(
        amount: Value(income.amount),
        description: Value(income.description),
        date: Value(income.date),
        source: Value(income.source),
        isActive: Value(income.isActive),
        frequency: Value(income.frequency),
      ),
    );
  }

  @override
  Future<bool> updateIncome(entity.Income income) {
    if (income.id == null) throw Exception('Income ID cannot be null');
    
    return _database.updateIncome(
      IncomesCompanion(
        id: Value(income.id!),
        amount: Value(income.amount),
        description: Value(income.description),
        date: Value(income.date),
        source: Value(income.source),
        isActive: Value(income.isActive),
        frequency: Value(income.frequency),
      ),
    );
  }

  @override
  Future<int> deleteIncome(int id) {
    return _database.deleteIncome(id);
  }

  // Méthodes pour les dépenses
  @override
  Future<List<entity.Expense>> getAllExpenses() async {
    final expenses = await _database.getAllExpenses();
    return expenses.map(_mapExpenseToEntity).toList();
  }

  @override
  Stream<List<entity.Expense>> watchAllExpenses() {
    return _database.watchAllExpenses().map(
          (expenses) => expenses.map(_mapExpenseToEntity).toList(),
        );
  }

  @override
  Future<entity.Expense> getExpenseById(int id) async {
    final expense = await _database.getExpenseById(id);
    return _mapExpenseToEntity(expense);
  }

  @override
  Future<int> addExpense(entity.Expense expense) {
    return _database.insertExpense(
      ExpensesCompanion(
        amount: Value(expense.amount),
        description: Value(expense.description),
        date: Value(expense.date),
        categoryId: Value(expense.categoryId),
      ),
    );
  }

  @override
  Future<bool> updateExpense(entity.Expense expense) {
    if (expense.id == null) throw Exception('Expense ID cannot be null');
    
    return _database.updateExpense(
      ExpensesCompanion(
        id: Value(expense.id!),
        amount: Value(expense.amount),
        description: Value(expense.description),
        date: Value(expense.date),
        categoryId: Value(expense.categoryId),
      ),
    );
  }

  @override
  Future<int> deleteExpense(int id) {
    return _database.deleteExpense(id);
  }

  // Méthodes pour les statistiques
  @override
  Future<double> getTotalIncome() {
    return _database.getTotalIncome();
  }

  @override
  Future<double> getTotalExpense() {
    return _database.getTotalExpense();
  }

  @override
  Future<Map<String, double>> getExpensesByCategory() {
    return _database.getExpensesByCategory();
  }

  @override
  Stream<Map<String, double>> watchExpensesByCategory() {
    return _database.watchExpensesByCategory();
  }

  @override
  Future<Map<bool, double>> getIncomesByType() {
    return _database.getIncomesByType();
  }

  @override
  Stream<Map<bool, double>> watchIncomesByType() {
    return _database.watchIncomesByType();
  }

  @override
  Stream<double> watchBalance() {
    return _database.watchBalance();
  }

  // Méthodes pour mapper les objets de la base de données vers les entités du domaine
  entity.Income _mapIncomeToEntity(Income income) {
    return entity.Income(
      id: income.id,
      amount: income.amount,
      description: income.description,
      date: income.date,
      source: income.source,
      isActive: income.isActive,
      frequency: income.frequency,
    );
  }

  entity.Expense _mapExpenseToEntity(Expense expense) {
    return entity.Expense(
      id: expense.id,
      amount: expense.amount,
      description: expense.description,
      date: expense.date,
      categoryId: expense.categoryId,
    );
  }
}
