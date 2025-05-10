import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/domain/entities/transaction.dart';

class TransactionCard extends StatelessWidget {
  final dynamic transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Map<String, ExpenseCategory> categories;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat(AppConstants.dateFormat);
    final numberFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    // Déterminer si c'est une dépense ou un revenu
    final isExpense = transaction is Expense;
    final amount = transaction.amount;
    final date = dateFormat.format(transaction.date);
    final description = transaction.description;

    // Configuration spécifique au type de transaction
    IconData icon;
    Color color;
    String subtitle;

    if (isExpense) {
      final category = categories[transaction.categoryId] ?? 
          AppConstants.expenseCategories.last;
      icon = category.icon;
      color = category.color;
      subtitle = category.name;
    } else {
      // Pour les revenus
      final income = transaction as Income;
      final isActive = income.isActive;
      final category = AppConstants.incomeCategories.firstWhere(
        (cat) => cat.id == income.source,
        orElse: () => AppConstants.incomeCategories.last,
      );
      icon = category.icon;
      color = isActive 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.secondary;
      subtitle = '${category.name} · ${income.isActive ? 'Actif' : 'Passif'}';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône de catégorie
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Montant et actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isExpense ? '- ${numberFormat.format(amount)}' : '+ ${numberFormat.format(amount)}',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: isExpense ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                        color: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Modifier',
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: onDelete,
                        color: Colors.red,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
