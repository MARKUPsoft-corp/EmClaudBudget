/// Modèle représentant un message dans une conversation
class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  /// Convertir le message en Map pour le stockage
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'role': isUser ? 'user' : 'assistant',
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Créer un message depuis les données stockées
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'] as String,
      isUser: json['role'] == 'user',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
