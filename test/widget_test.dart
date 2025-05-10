// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_express/main.dart';
import 'package:budget_express/data/datasources/app_database.dart';
import 'package:budget_express/data/repositories/transaction_repository_impl.dart';

void main() {
  testWidgets('Budget Express App Smoke Test', (WidgetTester tester) async {
    // Initialiser la base de données et le repository pour le test
    final database = AppDatabase();
    final transactionRepository = TransactionRepositoryImpl(database);
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(transactionRepository: transactionRepository));

    // Vérifier que l'application se lance correctement
    // (Tests minimalistes pour démarrer)
    expect(find.text('Budget Express'), findsOneWidget);
  });
}
