import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/domain/entities/transaction.dart';
import 'package:budget_express/presentation/providers/transaction_provider.dart';

class AddIncomeScreen extends StatefulWidget {
  final Map<String, dynamic>? income;

  const AddIncomeScreen({super.key, this.income});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs du formulaire
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;
  String _selectedSource = '';
  bool _isActive = true;
  String _frequency = 'Unique';
  
  // État du formulaire
  bool _isEditing = false;
  int? _incomeId;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // Initialiser la date avec la date du jour
    _selectedDate = DateTime.now();
    
    // Si un revenu est fourni, pré-remplir le formulaire
    if (widget.income != null) {
      _isEditing = true;
      _incomeId = widget.income!['id'] as int?;
      _amountController.text = (widget.income!['amount'] as double).toString();
      _descriptionController.text = widget.income!['description'] as String;
      _selectedDate = widget.income!['date'] as DateTime;
      _selectedSource = widget.income!['source'] as String;
      _isActive = widget.income!['isActive'] as bool;
      _frequency = widget.income!['frequency'] as String? ?? 'Unique';
    }
    
    // Par défaut, sélectionner la première source
    if (_selectedSource.isEmpty) {
      _selectedSource = AppConstants.incomeCategories.first.id;
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
        title: Text(_isEditing ? 'Modifier le revenu' : 'Ajouter un revenu'),
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
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Colors.green,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _isEditing ? 'Modifier le revenu' : 'Nouveau revenu',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Champ montant
                    _buildAmountField(),
                    const SizedBox(height: 24),
                    
                    // Type de revenu (Actif/Passif)
                    _buildIncomeTypeSelector(),
                    const SizedBox(height: 24),
                    
                    // Sélecteur de source
                    _buildSourceSelector(),
                    const SizedBox(height: 24),
                    
                    // Sélecteur de fréquence
                    _buildFrequencySelector(),
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
            prefixIcon: const Icon(Icons.attach_money),
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
  
  // Sélecteur de type de revenu
  Widget _buildIncomeTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de revenu',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                isActive: true,
                label: 'Revenu actif',
                description: 'Nécessite votre temps et effort',
                icon: Icons.work,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTypeOption(
                isActive: false,
                label: 'Revenu passif',
                description: 'Généré sans effort direct',
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Option pour le type de revenu
  Widget _buildTypeOption({
    required bool isActive,
    required String label,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _isActive == isActive;
    final color = isActive ? Colors.green : Theme.of(context).colorScheme.secondary;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _isActive = isActive;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Sélecteur de source de revenu (version dropdown)
  Widget _buildSourceSelector() {
    // Identifier la source sélectionnée
    final selectedSource = AppConstants.incomeCategories
        .firstWhere((cat) => cat.id == _selectedSource,
                 orElse: () => AppConstants.incomeCategories.first);
    final color = selectedSource.isActive ? 
                Colors.green : Theme.of(context).colorScheme.secondary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<String>(
                value: _selectedSource,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.keyboard_arrow_down),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                menuMaxHeight: 300,
                elevation: 3,
                items: AppConstants.incomeCategories.map((category) {
                  final itemColor = category.isActive ? 
                      Colors.green : Theme.of(context).colorScheme.secondary;
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(category.icon, color: itemColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSource = value;
                    });
                  }
                },
                // Afficher la source sélectionnée avec son icône
                selectedItemBuilder: (BuildContext context) {
                  return AppConstants.incomeCategories.map<Widget>((category) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(selectedSource.icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedSource.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Sélecteur de fréquence
  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fréquence',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _frequency,
              items: AppConstants.incomeFrequencies.map((frequency) {
                return DropdownMenuItem<String>(
                  value: frequency,
                  child: Text(frequency),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _frequency = value;
                  });
                }
              },
              icon: Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
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
            onPressed: _isSubmitting ? null : _saveIncome,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.green,
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
  
  // Enregistrer le revenu
  void _saveIncome() async {
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
      
      // Créer l'objet Income
      final income = Income(
        id: _incomeId,
        amount: amount,
        description: description,
        date: _selectedDate,
        source: _selectedSource,
        isActive: _isActive,
        frequency: _frequency == 'Unique' ? null : _frequency,
      );
      
      // Enregistrer dans le provider
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      bool success;
      
      if (_isEditing) {
        success = await provider.updateIncome(income);
      } else {
        success = await provider.addIncome(income);
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
