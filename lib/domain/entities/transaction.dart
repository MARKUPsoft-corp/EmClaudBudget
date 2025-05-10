import 'package:flutter/foundation.dart';

/// Classe de base pour toutes les transactions financières
abstract class Transaction {
  final int? id;
  final double amount;
  final String description;
  final DateTime date;
  
  const Transaction({
    this.id,
    required this.amount,
    required this.description,
    required this.date,
  });
}

/// Représente un revenu
class Income extends Transaction {
  final String source;
  final bool isActive; // Revenu actif ou passif
  final String? frequency; // Fréquence pour les revenus récurrents
  
  const Income({
    super.id,
    required super.amount,
    required super.description,
    required super.date,
    required this.source,
    required this.isActive,
    this.frequency,
  });
  
  /// Crée une copie de l'objet Income avec des propriétés modifiées
  Income copyWith({
    int? id,
    double? amount,
    String? description,
    DateTime? date,
    String? source,
    bool? isActive,
    String? frequency,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      source: source ?? this.source,
      isActive: isActive ?? this.isActive,
      frequency: frequency ?? this.frequency,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Income &&
        other.id == id &&
        other.amount == amount &&
        other.description == description &&
        other.date == date &&
        other.source == source &&
        other.isActive == isActive &&
        other.frequency == frequency;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        description.hashCode ^
        date.hashCode ^
        source.hashCode ^
        isActive.hashCode ^
        frequency.hashCode;
  }
}

/// Représente une dépense
class Expense extends Transaction {
  final String categoryId;
  
  const Expense({
    super.id,
    required super.amount,
    required super.description,
    required super.date,
    required this.categoryId,
  });
  
  /// Crée une copie de l'objet Expense avec des propriétés modifiées
  Expense copyWith({
    int? id,
    double? amount,
    String? description,
    DateTime? date,
    String? categoryId,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Expense &&
        other.id == id &&
        other.amount == amount &&
        other.description == description &&
        other.date == date &&
        other.categoryId == categoryId;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        description.hashCode ^
        date.hashCode ^
        categoryId.hashCode;
  }
}
