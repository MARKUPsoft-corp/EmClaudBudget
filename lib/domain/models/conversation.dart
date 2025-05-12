// Modèle de conversation

/// Modèle représentant une conversation avec l'IA
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final List<Map<String, dynamic>> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.messages,
  });

  /// Créer une nouvelle conversation vide
  factory Conversation.create({required String title}) {
    final now = DateTime.now();
    return Conversation(
      id: 'conv_${now.millisecondsSinceEpoch}',
      title: title,
      createdAt: now,
      lastUpdatedAt: now,
      messages: [],
    );
  }

  /// Obtenir le dernier message de la conversation (ou null si vide)
  Map<String, dynamic>? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }

  /// Créer une copie de la conversation avec des modifications
  Conversation copyWith({
    String? title,
    DateTime? lastUpdatedAt,
    List<Map<String, dynamic>>? messages,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      messages: messages ?? this.messages,
    );
  }

  /// Convertir la conversation en Map pour le stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'messages': messages,
    };
  }

  /// Créer une conversation depuis les données stockées
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      messages: (json['messages'] as List).cast<Map<String, dynamic>>(),
    );
  }
}
