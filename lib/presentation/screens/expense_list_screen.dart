import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/core/theme/app_theme.dart';
import 'package:budget_express/domain/entities/transaction.dart';
import 'package:budget_express/presentation/providers/transaction_provider.dart';
import 'package:budget_express/presentation/widgets/transaction_card.dart';
import 'package:budget_express/utils/feedback_utils.dart';

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
  
  // État pour la recherche textuelle
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  
  // Clé pour le refresh indicator
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  // État pour le tri
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    
    // Initialiser les données de localisation pour le français
    initializeDateFormatting('fr_FR', null);
    
    // Initialiser les données au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      if (provider.expenses.isEmpty) {
        provider.initialize();
      }
    });
    
    // Configurer l'écoute des changements dans le champ de recherche
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  // Méthode appelée lorsque le texte de recherche change
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
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
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher une dépense...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) {
                  FeedbackUtils().provideFeedbackForAction();
                },
              )
            : const Text('Dépenses'),
        actions: [
          // Action pour la recherche
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
                FeedbackUtils().provideFeedbackForMenu();
              });
            },
            tooltip: _isSearching ? 'Annuler' : 'Rechercher',
          ),
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
                          _searchQuery.isNotEmpty 
                              ? 'Aucun résultat pour "$_searchQuery"'
                              : 'Aucune dépense',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Essayez avec un autre terme de recherche'
                              : 'Ajoutez des dépenses en appuyant sur le bouton +',
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
              
              // Liste des dépenses groupées par semaine
              Expanded(
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: () => provider.initialize(),
                  child: _buildWeeklyExpensesList(filteredExpenses, expenseCategoriesMap),
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
    var filtered = expenses.where((expense) {
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
      
      // Filtrer par texte de recherche
      if (_searchQuery.isNotEmpty) {
        final description = expense.description.toLowerCase();
        if (!description.contains(_searchQuery)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Trier les dépenses selon le mode de tri sélectionné
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    
    return filtered;
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
  
  // Construction de la liste des dépenses groupées par semaine
  Widget _buildWeeklyExpensesList(List<Expense> expenses, Map<String, ExpenseCategory> categoriesMap) {
    if (expenses.isEmpty) {
      return ListView();
    }

    // Regrouper les dépenses par semaine
    final Map<String, List<Expense>> weeklyExpenses = {};
    final DateFormat weekFormat = DateFormat("'Semaine du' d MMMM yyyy", 'fr_FR');
    final DateFormat monthFormat = DateFormat('MMMM yyyy', 'fr_FR');
    
    for (var expense in expenses) {
      // Trouver le premier jour de la semaine (lundi)
      final date = expense.date;
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = weekFormat.format(weekStart);
      
      if (!weeklyExpenses.containsKey(weekKey)) {
        weeklyExpenses[weekKey] = [];
      }
      weeklyExpenses[weekKey]!.add(expense);
    }

    // Trier les semaines par ordre chronologique décroissant (plus récent d'abord)
    final sortedWeeks = weeklyExpenses.keys.toList()
      ..sort((a, b) {
        // Extraire les dates des clés formatées
        final dateA = _extractDateFromWeekKey(a);
        final dateB = _extractDateFromWeekKey(b);
        return dateB.compareTo(dateA); // Ordre décroissant
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      // +1 pour chaque en-tête de semaine
      itemCount: weeklyExpenses.values.fold(0, (sum, weekExpenses) => sum + weekExpenses.length) + sortedWeeks.length,
      itemBuilder: (context, index) {
        // Calculer à quelle semaine et à quelle dépense cet index correspond
        int itemCount = 0;
        for (var weekKey in sortedWeeks) {
          final weekExpenses = weeklyExpenses[weekKey]!;
          
          // Si c'est l'index d'un en-tête de semaine
          if (index == itemCount) {
            // Calculer le total des dépenses pour cette semaine
            final weekTotal = weekExpenses.fold<double>(0, (sum, exp) => sum + exp.amount);
            final weekDate = _extractDateFromWeekKey(weekKey);
            final monthName = monthFormat.format(weekDate).toUpperCase();
            
            return _buildWeekHeader(weekKey, monthName, weekTotal);
          }
          
          itemCount += 1; // Pour l'en-tête
          
          // Si l'index correspond à une dépense dans cette semaine
          if (index < itemCount + weekExpenses.length) {
            final expense = weekExpenses[index - itemCount];
            // Ajouter un padding en haut de la première transaction de chaque semaine
            if (index == itemCount) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TransactionCard(
                  transaction: expense,
                  onEdit: () => _editExpense(context, expense),
                  onDelete: () => _deleteExpense(context, expense),
                  categories: categoriesMap,
                ),
              );
            }
            return TransactionCard(
              transaction: expense,
              onEdit: () => _editExpense(context, expense),
              onDelete: () => _deleteExpense(context, expense),
              categories: categoriesMap,
            );
          }
          
          itemCount += weekExpenses.length;
        }
        
        // Ne devrait jamais arriver
        return const SizedBox();
      },
    );
  }
  
  // Extraire la date à partir de la clé de semaine formatée
  DateTime _extractDateFromWeekKey(String weekKey) {
    // Format: "Semaine du dd MMMM yyyy"
    final regex = RegExp(r"Semaine du (\d+) ([a-zéûôâùA-Z]+) (\d{4})");
    final match = regex.firstMatch(weekKey);
    
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = _getMonthNumber(match.group(2)!);
      final year = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }
    
    // Fallback en cas d'erreur de parsing
    return DateTime.now();
  }
  
  // Convertir le nom du mois en français en numéro
  int _getMonthNumber(String monthName) {
    final months = {
      'janvier': 1, 'février': 2, 'mars': 3, 'avril': 4, 'mai': 5, 'juin': 6,
      'juillet': 7, 'août': 8, 'septembre': 9, 'octobre': 10, 'novembre': 11, 'décembre': 12
    };
    return months[monthName.toLowerCase()] ?? 1;
  }
  
  // Construction de l'en-tête de semaine adapté au mode sombre avec espace en dessous
  Widget _buildWeekHeader(String weekLabel, String monthName, double totalAmount) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary; // Orange
    final cardColor = theme.cardTheme.color ?? const Color(0xFF1E1E1E);
    final textColor = theme.colorScheme.onSurface; // Blanc en mode sombre
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du mois en haut avec style distinctif
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              monthName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // Entête de la semaine avec total
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label de la semaine avec icône
                Row(
                  children: [
                    Icon(
                      Icons.calendar_view_week,
                      size: 18,
                      color: primaryColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      weekLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Montant total avec style élaboré
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentRed.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total dépensé:',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        currencyFormat.format(totalAmount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Trier les dépenses
  void _sortExpenses(String sortBy) {
    // Mettre à jour le mode de tri et rafraîchir
    setState(() {
      _sortBy = sortBy;
      FeedbackUtils().provideFeedbackForMenu(); // Feedback haptique pour la navigation dans les menus
    });
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
