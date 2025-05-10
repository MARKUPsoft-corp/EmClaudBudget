import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/domain/entities/transaction.dart';
import 'package:budget_express/presentation/providers/transaction_provider.dart';
import 'package:budget_express/presentation/widgets/transaction_card.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  // État pour le filtrage
  String _selectedSource = '';
  bool? _isActiveFilter;
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
      if (provider.incomes.isEmpty) {
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

    // Créer une Map des catégories pour un accès rapide
    final Map<String, ExpenseCategory> categoriesMap = {
      // Ajoutons des catégories virtuelles pour les revenus
      for (var category in AppConstants.incomeCategories) 
        category.id: ExpenseCategory(
          id: category.id,
          name: category.name,
          icon: category.icon,
          color: category.isActive ? Colors.green : Theme.of(context).colorScheme.secondary,
        )
    };
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenus'),
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
            onSelected: (value) => _sortIncomes(value),
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
          
          // Filtrer les revenus
          final filteredIncomes = _getFilteredIncomes(provider.incomes);
          
          if (filteredIncomes.isEmpty) {
            return RefreshIndicator(
              key: _refreshKey,
              onRefresh: () => provider.initialize(),
              child: Stack(
                children: [
                  // Liste vide pour permettre le pull-to-refresh
                  ListView(),
                  // Message "Aucun revenu"
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun revenu',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ajoutez des revenus en appuyant sur le bouton +',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push(AppConstants.addIncomeRoute),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un revenu'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Afficher le total des revenus filtrés
          final totalFilteredIncomes = filteredIncomes.fold<double>(
            0, (sum, income) => sum + income.amount);
            
          return Column(
            children: [
              // En-tête avec les filtres actifs et le total
              if (_hasActiveFilters() || _selectedSource.isNotEmpty || _isActiveFilter != null)
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
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (_selectedSource.isNotEmpty)
                                  _buildFilterChip(
                                    _getSourceName(_selectedSource),
                                    () => setState(() => _selectedSource = ''),
                                  ),
                                if (_isActiveFilter != null)
                                  _buildFilterChip(
                                    _isActiveFilter! ? 'Revenu actif' : 'Revenu passif',
                                    () => setState(() => _isActiveFilter = null),
                                  ),
                                if (_startDate != null)
                                  _buildFilterChip(
                                    'Depuis ${DateFormat(AppConstants.dateFormat).format(_startDate!)}',
                                    () => setState(() => _startDate = null),
                                  ),
                                if (_endDate != null)
                                  _buildFilterChip(
                                    'Jusqu\'au ${DateFormat(AppConstants.dateFormat).format(_endDate!)}',
                                    () => setState(() => _endDate = null),
                                  ),
                              ],
                            ),
                          ),
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
                            currencyFormat.format(totalFilteredIncomes),
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              // Liste des revenus
              Expanded(
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: () => provider.initialize(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredIncomes.length,
                    itemBuilder: (context, index) {
                      final income = filteredIncomes[index];
                      
                      return TransactionCard(
                        transaction: income,
                        onEdit: () => _editIncome(context, income),
                        onDelete: () => _deleteIncome(context, income),
                        categories: categoriesMap,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // FAB pour ajouter un nouveau revenu
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.addIncomeRoute),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  // Obtenir le nom de la source
  String _getSourceName(String sourceId) {
    final source = AppConstants.incomeCategories.firstWhere(
      (source) => source.id == sourceId,
      orElse: () => AppConstants.incomeCategories.first,
    );
    return source.name;
  }
  
  // Chip pour afficher un filtre actif
  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  // Filtrer les revenus selon les critères sélectionnés
  List<Income> _getFilteredIncomes(List<Income> incomes) {
    return incomes.where((income) {
      // Filtrer par source
      if (_selectedSource.isNotEmpty && 
          income.source != _selectedSource) {
        return false;
      }
      
      // Filtrer par type (actif/passif)
      if (_isActiveFilter != null && 
          income.isActive != _isActiveFilter) {
        return false;
      }
      
      // Filtrer par date de début
      if (_startDate != null) {
        final startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (income.date.isBefore(startOfDay)) {
          return false;
        }
      }
      
      // Filtrer par date de fin
      if (_endDate != null) {
        final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (income.date.isAfter(endOfDay)) {
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
      _selectedSource = '';
      _isActiveFilter = null;
      _startDate = null;
      _endDate = null;
    });
  }
  
  // Trier les revenus
  void _sortIncomes(String sortBy) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Créer une copie de la liste pour éviter de modifier la liste originale directement
    List<Income> sortedIncomes = List.from(provider.incomes);
    
    switch (sortBy) {
      case 'date_desc':
        sortedIncomes.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'date_asc':
        sortedIncomes.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        sortedIncomes.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        sortedIncomes.sort((a, b) => a.amount.compareTo(b.amount));
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
                    'Filtrer les revenus',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  // Filtre par source
                  Text(
                    'Source',
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
                        selected: _selectedSource.isEmpty,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _selectedSource = '';
                            });
                          }
                        },
                      ),
                      // Options pour chaque source
                      ...AppConstants.incomeCategories.map((source) {
                        return ChoiceChip(
                          label: Text(source.name),
                          selected: _selectedSource == source.id,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                _selectedSource = source.id;
                              });
                            }
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Filtre par type (actif/passif)
                  Text(
                    'Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Option "Tous"
                      ChoiceChip(
                        label: const Text('Tous les types'),
                        selected: _isActiveFilter == null,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _isActiveFilter = null;
                            });
                          }
                        },
                      ),
                      // Option "Actif"
                      ChoiceChip(
                        label: const Text('Revenus actifs'),
                        selected: _isActiveFilter == true,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _isActiveFilter = true;
                            });
                          }
                        },
                      ),
                      // Option "Passif"
                      ChoiceChip(
                        label: const Text('Revenus passifs'),
                        selected: _isActiveFilter == false,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _isActiveFilter = false;
                            });
                          }
                        },
                      ),
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
  
  // Éditer un revenu
  void _editIncome(BuildContext context, Income income) {
    final incomeData = {
      'id': income.id,
      'amount': income.amount,
      'description': income.description,
      'date': income.date,
      'source': income.source,
      'isActive': income.isActive,
      'frequency': income.frequency,
    };
    
    context.push(AppConstants.addIncomeRoute, extra: incomeData);
  }
  
  // Supprimer un revenu
  void _deleteIncome(BuildContext context, Income income) {
    // Demander confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le revenu'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce revenu ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final provider = Provider.of<TransactionProvider>(context, listen: false);
              final success = await provider.deleteIncome(income.id!);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Revenu supprimé avec succès'),
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
