import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_express/domain/models/conversation.dart';

/// Service pour gérer les conversations multiples
class ConversationService {
  static const String _storageKey = 'ai_conversations';
  List<Conversation> _conversations = [];
  String? _activeConversationId;

  // Getters
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  Conversation? get activeConversation {
    if (_conversations.isEmpty) return null;
    
    if (_activeConversationId != null) {
      try {
        return _conversations.firstWhere((c) => c.id == _activeConversationId);
      } catch (_) {
        // Conversation active non trouvée, utiliser la première
        return _conversations.first;
      }
    } else {
      // Aucune conversation active définie, utiliser la première
      return _conversations.first;
    }
  }

  /// Initialiser le service et charger les conversations depuis le stockage
  Future<void> initialize() async {
    await loadConversations();
    
    // S'assurer qu'il y a toujours au moins une conversation
    if (_conversations.isEmpty) {
      _conversations.add(Conversation.create(title: 'Nouvelle conversation'));
      await saveConversations();
    }
    
    // Définir la conversation active si aucune n'est définie
    if (_activeConversationId == null || 
        !_conversations.any((c) => c.id == _activeConversationId)) {
      _activeConversationId = _conversations.first.id;
    }
  }

  /// Charger les conversations depuis le stockage local
  Future<void> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_storageKey);
    
    if (jsonData == null || jsonData.isEmpty) {
      _conversations = [];
      return;
    }
    
    try {
      final List<dynamic> conversationsJson = jsonDecode(jsonData);
      _conversations = conversationsJson
          .map((json) => Conversation.fromJson(json))
          .toList();
      
      // Trier par date de dernière mise à jour (plus récente d'abord)
      _conversations.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
      
      // Récupérer la conversation active
      _activeConversationId = prefs.getString('active_conversation_id');
    } catch (e) {
      print('Erreur lors du chargement des conversations: $e');
      _conversations = [];
    }
  }

  /// Sauvegarder les conversations dans le stockage local
  Future<void> saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(_conversations.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, jsonData);
    
    // Sauvegarder l'ID de la conversation active
    if (_activeConversationId != null) {
      await prefs.setString('active_conversation_id', _activeConversationId!);
    }
  }

  /// Créer une nouvelle conversation
  Future<Conversation> createConversation({String? title}) async {
    final newConversation = Conversation.create(
      title: title ?? 'Conversation ${_conversations.length + 1}',
    );
    _conversations.insert(0, newConversation);
    _activeConversationId = newConversation.id;
    await saveConversations();
    return newConversation;
  }

  /// Définir la conversation active
  Future<void> setActiveConversation(String conversationId) async {
    if (_conversations.any((c) => c.id == conversationId)) {
      _activeConversationId = conversationId;
      await saveConversations();
    }
  }

  /// Ajouter un message à la conversation active
  Future<void> addMessageToActiveConversation(Map<String, dynamic> message) async {
    if (activeConversation == null) {
      await createConversation();
    }
    
    final currentMessages = [...activeConversation!.messages, message];
    final updatedConversation = activeConversation!.copyWith(
      lastUpdatedAt: DateTime.now(),
      messages: currentMessages,
    );
    
    // Mettre à jour la conversation dans la liste
    final index = _conversations.indexWhere((c) => c.id == updatedConversation.id);
    if (index >= 0) {
      _conversations[index] = updatedConversation;
      
      // Déplacer la conversation en haut de la liste
      if (index > 0) {
        _conversations.removeAt(index);
        _conversations.insert(0, updatedConversation);
      }
      
      await saveConversations();
    }
  }

  /// Renommer une conversation
  Future<void> renameConversation(String conversationId, String newTitle) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index >= 0) {
      _conversations[index] = _conversations[index].copyWith(
        title: newTitle,
        lastUpdatedAt: DateTime.now(),
      );
      await saveConversations();
    }
  }

  /// Supprimer une conversation
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    
    // Si la conversation active a été supprimée, définir une nouvelle conversation active
    if (_activeConversationId == conversationId && _conversations.isNotEmpty) {
      _activeConversationId = _conversations.first.id;
    } else if (_conversations.isEmpty) {
      // Créer une nouvelle conversation si toutes ont été supprimées
      await createConversation();
    }
    
    await saveConversations();
  }
}
