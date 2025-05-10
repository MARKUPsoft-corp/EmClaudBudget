import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

part 'app_database.g.dart';

class Incomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get source => text()();
  BoolColumn get isActive => boolean()();
  TextColumn get frequency => text().nullable()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get categoryId => text()();
}

@DriftDatabase(tables: [Incomes, Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Méthodes pour les Incomes
  Future<List<Income>> getAllIncomes() => select(incomes).get();
  
  Stream<List<Income>> watchAllIncomes() => select(incomes).watch();
  
  Future<Income> getIncomeById(int id) => 
      (select(incomes)..where((tbl) => tbl.id.equals(id))).getSingle();
      
  Future<int> insertIncome(IncomesCompanion income) => 
      into(incomes).insert(income);
      
  Future<bool> updateIncome(IncomesCompanion income) => 
      update(incomes).replace(income);
      
  Future<int> deleteIncome(int id) => 
      (delete(incomes)..where((tbl) => tbl.id.equals(id))).go();
  
  // Méthodes pour les Expenses
  Future<List<Expense>> getAllExpenses() => select(expenses).get();
  
  Stream<List<Expense>> watchAllExpenses() => select(expenses).watch();
  
  Future<Expense> getExpenseById(int id) => 
      (select(expenses)..where((tbl) => tbl.id.equals(id))).getSingle();
      
  Future<int> insertExpense(ExpensesCompanion expense) => 
      into(expenses).insert(expense);
      
  Future<bool> updateExpense(ExpensesCompanion expense) => 
      update(expenses).replace(expense);
      
  Future<int> deleteExpense(int id) => 
      (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();
  
  // Requêtes spécifiques
  Future<double> getTotalIncome() async {
    final query = selectOnly(incomes)..addColumns([incomes.amount.sum()]);
    final row = await query.getSingle();
    return row.read(incomes.amount.sum()) ?? 0.0;
  }
  
  Future<double> getTotalExpense() async {
    final query = selectOnly(expenses)..addColumns([expenses.amount.sum()]);
    final row = await query.getSingle();
    return row.read(expenses.amount.sum()) ?? 0.0;
  }
  
  Future<Map<String, double>> getExpensesByCategory() async {
    final query = selectOnly(expenses)
      ..addColumns([expenses.categoryId, expenses.amount.sum()]);
    query.groupBy([expenses.categoryId]);
    
    final rows = await query.get();
    final result = <String, double>{};
    
    for (final row in rows) {
      final categoryId = row.read(expenses.categoryId)!;
      final total = row.read(expenses.amount.sum()) ?? 0.0;
      result[categoryId] = total;
    }
    
    return result;
  }
  
  Stream<Map<String, double>> watchExpensesByCategory() {
    final query = selectOnly(expenses)
      ..addColumns([expenses.categoryId, expenses.amount.sum()]);
    query.groupBy([expenses.categoryId]);
    
    return query.watch().map((rows) {
      final result = <String, double>{};
      for (final row in rows) {
        final categoryId = row.read(expenses.categoryId)!;
        final total = row.read(expenses.amount.sum()) ?? 0.0;
        result[categoryId] = total;
      }
      return result;
    });
  }
  
  Future<Map<bool, double>> getIncomesByType() async {
    final query = selectOnly(incomes)
      ..addColumns([incomes.isActive, incomes.amount.sum()]);
    query.groupBy([incomes.isActive]);
    
    final rows = await query.get();
    final result = <bool, double>{};
    
    for (final row in rows) {
      final isActive = row.read(incomes.isActive)!;
      final total = row.read(incomes.amount.sum()) ?? 0.0;
      result[isActive] = total;
    }
    
    return result;
  }
  
  Stream<Map<bool, double>> watchIncomesByType() {
    final query = selectOnly(incomes)
      ..addColumns([incomes.isActive, incomes.amount.sum()]);
    query.groupBy([incomes.isActive]);
    
    return query.watch().map((rows) {
      final result = <bool, double>{};
      for (final row in rows) {
        final isActive = row.read(incomes.isActive)!;
        final total = row.read(incomes.amount.sum()) ?? 0.0;
        result[isActive] = total;
      }
      return result;
    });
  }
  
  Stream<double> watchBalance() {
    final incomeStream = watchTotalIncome();
    final expenseStream = watchTotalExpense();
    
    return Rx.combineLatest2(
      incomeStream, 
      expenseStream, 
      (double income, double expense) => income - expense
    );
  }
  
  Stream<double> watchTotalIncome() {
    final query = selectOnly(incomes)..addColumns([incomes.amount.sum()]);
    return query.watch().map((rows) => rows.first.read(incomes.amount.sum()) ?? 0.0);
  }
  
  Stream<double> watchTotalExpense() {
    final query = selectOnly(expenses)..addColumns([expenses.amount.sum()]);
    return query.watch().map((rows) => rows.first.read(expenses.amount.sum()) ?? 0.0);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budget_express.sqlite'));
    return NativeDatabase(file);
  });
}
