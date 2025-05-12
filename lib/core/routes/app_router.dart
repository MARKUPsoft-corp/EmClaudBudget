import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/presentation/screens/dashboard_screen.dart';
import 'package:budget_express/presentation/screens/income_list_screen.dart';
import 'package:budget_express/presentation/screens/expense_list_screen.dart';
import 'package:budget_express/presentation/screens/add_income_screen.dart';
import 'package:budget_express/presentation/screens/add_expense_screen.dart';
import 'package:budget_express/presentation/screens/settings_screen.dart';
import 'package:budget_express/presentation/screens/home_screen.dart';
import 'package:budget_express/presentation/screens/ai_chat_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppConstants.homeRoute,
    debugLogDiagnostics: true,
    routes: [
      // Configuration pour la navigation principale avec ShellRoute (pour Linux)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          // Route du tableau de bord
          GoRoute(
            path: AppConstants.dashboardRoute,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          // Route de la liste des revenus
          GoRoute(
            path: AppConstants.incomeRoute,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const IncomeListScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          // Route de la liste des dépenses
          GoRoute(
            path: AppConstants.expenseRoute,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ExpenseListScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          // Route des paramètres
          GoRoute(
            path: AppConstants.settingsRoute,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          // Route du chat IA
          GoRoute(
            path: AppConstants.aiChatRoute,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AIChatScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
      
      // Routes pour ajouter/modifier des revenus
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppConstants.addIncomeRoute,
        pageBuilder: (context, state) {
          final income = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddIncomeScreen(income: income),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),
      
      // Routes pour ajouter/modifier des dépenses
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppConstants.addExpenseRoute,
        pageBuilder: (context, state) {
          final expense = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddExpenseScreen(expense: expense),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),
      
      // Redirection par défaut
      GoRoute(
        path: AppConstants.homeRoute,
        redirect: (context, state) => AppConstants.dashboardRoute,
      ),
    ],
  );
}

class ErrorScreen extends StatelessWidget {
  final Exception error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.dashboardRoute),
              child: const Text('Retour au tableau de bord'),
            ),
          ],
        ),
      ),
    );
  }
}
