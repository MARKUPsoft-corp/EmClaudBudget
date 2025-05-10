import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/domain/entities/transaction.dart';
import 'package:budget_express/presentation/providers/transaction_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs du formulaire
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;
  String _selectedCategoryId = '';
  
  // État du formulaire
  bool _isEditing = false;
  int? _expenseId;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // Initialiser la date avec la date du jour
    _selectedDate = DateTime.now();
    
    // Si un expense est fourni, pré-remplir le formulaire
    if (widget.expense != null) {
      _isEditing = true;
      _expenseId = widget.expense!['id'] as int?;
      _amountController.text = (widget.expense!['amount'] as double).toString();
      _descriptionController.text = widget.expense!['description'] as String;
      _selectedDate = widget.expense!['date'] as DateTime;
      _selectedCategoryId = widget.expense!['categoryId'] as String;
    }
    
    // Par défaut, sélectionner la première catégorie
    if (_selectedCategoryId.isEmpty) {
      _selectedCategoryId = AppConstants.expenseCategories.first.id;
    }
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la dépense' : 'Ajouter une dépense'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _isEditing ? 'Modifier la dépense' : 'Nouvelle dépense',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Champ montant
                    _buildAmountField(),
                    const SizedBox(height: 24),
                    
                    // Sélecteur de catégorie
                    _buildCategorySelector(),
                    const SizedBox(height: 24),
                    
                    // Champ date
                    _buildDateField(),
                    const SizedBox(height: 24),
                    
                    // Champ description
                    _buildDescriptionField(),
                    const SizedBox(height: 32),
                    
                    // Boutons d'action
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Champ pour le montant
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: const Icon(Icons.euro),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un montant';
            }
            
            // Vérifier que le montant est un nombre valide
            final amount = double.tryParse(value.replaceAll(',', '.'));
            if (amount == null) {
              return 'Veuillez entrer un montant valide';
            }
            
            if (amount <= 0) {
              return 'Le montant doit être supérieur à 0';
            }
            
            return null;
          },
          onTap: () {
            if (_amountController.text.isEmpty) {
              _amountController.text = '';
            }
          },
        ),
      ],
    );
  }
  
  // Sélecteur de catégorie
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.3,
            ),
            itemCount: AppConstants.expenseCategories.length,
            itemBuilder: (context, index) {
              final category = AppConstants.expenseCategories[index];
              final isSelected = category.id == _selectedCategoryId;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? category.color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        color: category.color,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Champ pour la date
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat(AppConstants.dateFormat).format(_selectedDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Méthode pour ouvrir le sélecteur de date
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
  
  // Champ pour la description
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Entrez une description...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer une description';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  // Boutons d'action
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Bouton Annuler
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        // Bouton Enregistrer
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _saveExpense,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_isEditing ? 'Mettre à jour' : 'Enregistrer'),
          ),
        ),
      ],
    );
  }
  
  // Enregistrer la dépense
  void _saveExpense() async {
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Récupérer les valeurs du formulaire
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final description = _descriptionController.text;
      
      // Créer l'objet Expense
      final expense = Expense(
        id: _expenseId,
        amount: amount,
        description: description,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
      );
      
      // Enregistrer dans le provider
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      bool success;
      
      if (_isEditing) {
        success = await provider.updateExpense(expense);
      } else {
        success = await provider.addExpense(expense);
      }
      
      if (success) {
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // Afficher une erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Une erreur est survenue',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Gérer les erreurs de parsing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez vérifier les valeurs saisies'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
