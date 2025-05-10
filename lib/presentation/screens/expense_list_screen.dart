import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/domain/entities/transaction.dart';
import 'package:budget_express/presentation/providers/transaction_provider.dart';
import 'package:budget_express/presentation/widgets/transaction_card.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  // État pour le filtrage
  String _selectedCategoryId = '';
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Clé pour le refresh indicator
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    
    // Initialiser les données au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      if (provider.expenses.isEmpty) {
        provider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Formateur pour les montants
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    // Créer une Map des catégories de dépenses pour un accès rapide
    final Map<String, ExpenseCategory> expenseCategoriesMap = {
      for (var category in AppConstants.expenseCategories) 
        category.id: category
    };
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        actions: [
          // Action pour filtrer
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
            tooltip: 'Filtrer',
          ),
          // Action pour trier
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier',
            onSelected: (value) => _sortExpenses(value),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'date_desc',
                child: Text('Date (plus récent)'),
              ),
              const PopupMenuItem<String>(
                value: 'date_asc',
                child: Text('Date (plus ancien)'),
              ),
              const PopupMenuItem<String>(
                value: 'amount_desc',
                child: Text('Montant (décroissant)'),
              ),
              const PopupMenuItem<String>(
                value: 'amount_asc',
                child: Text('Montant (croissant)'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (provider.errorMessage != null) {
            return Center(
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
                    'Erreur de chargement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          
          // Filtrer les dépenses
          final filteredExpenses = _getFilteredExpenses(provider.expenses);
          
          if (filteredExpenses.isEmpty) {
            return RefreshIndicator(
              key: _refreshKey,
              onRefresh: () => provider.initialize(),
              child: Stack(
                children: [
                  // Liste vide pour permettre le pull-to-refresh
                  ListView(),
                  // Message "Aucune dépense"
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune dépense',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ajoutez des dépenses en appuyant sur le bouton +',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push(AppConstants.addExpenseRoute),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une dépense'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Afficher le total des dépenses filtrées
          final totalFilteredExpenses = filteredExpenses.fold<double>(
            0, (sum, expense) => sum + expense.amount);
            
          return Column(
            children: [
              // En-tête avec les filtres actifs et le total
              if (_hasActiveFilters() || _selectedCategoryId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Afficher les filtres actifs
                      Row(
                        children: [
                          Text(
                            'Filtres actifs:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(width: 8),
                          if (_selectedCategoryId.isNotEmpty)
                            _buildFilterChip(
                              expenseCategoriesMap[_selectedCategoryId]?.name ?? 'Catégorie',
                              () => setState(() => _selectedCategoryId = ''),
                            ),
                          if (_startDate != null)
                            _buildFilterChip(
                              'Depuis le ${DateFormat(AppConstants.dateFormat).format(_startDate!)}',
                              () => setState(() => _startDate = null),
                            ),
                          if (_endDate != null)
                            _buildFilterChip(
                              'Jusqu\'au ${DateFormat(AppConstants.dateFormat).format(_endDate!)}',
                              () => setState(() => _endDate = null),
                            ),
                          const Spacer(),
                          // Réinitialiser tous les filtres
                          TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Réinitialiser'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Afficher le total filtré
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:'),
                          Text(
                            currencyFormat.format(totalFilteredExpenses),
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              // Liste des dépenses
              Expanded(
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: () => provider.initialize(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      
                      return TransactionCard(
                        transaction: expense,
                        onEdit: () => _editExpense(context, expense),
                        onDelete: () => _deleteExpense(context, expense),
                        categories: expenseCategoriesMap,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // FAB pour ajouter une nouvelle dépense
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.addExpenseRoute),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
  
  // Chip pour afficher un filtre actif
  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
  
  // Filtrer les dépenses selon les critères sélectionnés
  List<Expense> _getFilteredExpenses(List<Expense> expenses) {
    return expenses.where((expense) {
      // Filtrer par catégorie
      if (_selectedCategoryId.isNotEmpty && 
          expense.categoryId != _selectedCategoryId) {
        return false;
      }
      
      // Filtrer par date de début
      if (_startDate != null) {
        final startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (expense.date.isBefore(startOfDay)) {
          return false;
        }
      }
      
      // Filtrer par date de fin
      if (_endDate != null) {
        final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (expense.date.isAfter(endOfDay)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  // Vérifier si des filtres sont actifs
  bool _hasActiveFilters() {
    return _startDate != null || _endDate != null;
  }
  
  // Réinitialiser tous les filtres
  void _resetFilters() {
    setState(() {
      _selectedCategoryId = '';
      _startDate = null;
      _endDate = null;
    });
  }
  
  // Trier les dépenses
  void _sortExpenses(String sortBy) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Créer une copie de la liste pour éviter de modifier la liste originale directement
    List<Expense> sortedExpenses = List.from(provider.expenses);
    
    switch (sortBy) {
      case 'date_desc':
        sortedExpenses.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'date_asc':
        sortedExpenses.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        sortedExpenses.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        sortedExpenses.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    
    // Mettre à jour la liste dans le provider
    // Note: Dans une implémentation réelle, il faudrait ajouter une méthode dans le provider pour faire cela
    setState(() {});
  }
  
  // Afficher les options de filtrage
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filtrer les dépenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  // Filtre par catégorie
                  Text(
                    'Catégorie',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Option "Toutes"
                      ChoiceChip(
                        label: const Text('Toutes'),
                        selected: _selectedCategoryId.isEmpty,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _selectedCategoryId = '';
                            });
                          }
                        },
                      ),
                      // Options pour chaque catégorie
                      ...AppConstants.expenseCategories.map((category) {
                        return ChoiceChip(
                          label: Text(category.name),
                          selected: _selectedCategoryId == category.id,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                _selectedCategoryId = category.id;
                              });
                            }
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Filtre par période
                  Text(
                    'Période',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setModalState(() {
                                _startDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _startDate == null
                                        ? 'Date de début'
                                        : DateFormat(AppConstants.dateFormat).format(_startDate!),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_startDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setModalState(() {
                                        _startDate = null;
                                      });
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setModalState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _endDate == null
                                        ? 'Date de fin'
                                        : DateFormat(AppConstants.dateFormat).format(_endDate!),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_endDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setModalState(() {
                                        _endDate = null;
                                      });
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _resetFilters();
                          });
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // Les filtres sont déjà mis à jour dans le StatefulBuilder
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Appliquer'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  // Éditer une dépense
  void _editExpense(BuildContext context, Expense expense) {
    final expenseData = {
      'id': expense.id,
      'amount': expense.amount,
      'description': expense.description,
      'date': expense.date,
      'categoryId': expense.categoryId,
    };
    
    context.push(AppConstants.addExpenseRoute, extra: expenseData);
  }
  
  // Supprimer une dépense
  void _deleteExpense(BuildContext context, Expense expense) {
    // Demander confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la dépense'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette dépense ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final provider = Provider.of<TransactionProvider>(context, listen: false);
              final success = await provider.deleteExpense(expense.id!);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dépense supprimée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
