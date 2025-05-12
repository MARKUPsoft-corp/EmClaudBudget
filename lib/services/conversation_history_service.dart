import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationHistoryService {
  static const String _storageKey = 'ai_chat_history';
  
  // Sauvegarde l'historique complet des conversations
  Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(conversations);
    await prefs.setString(_storageKey, jsonData);
  }
  
  // Récupère l'historique complet des conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_storageKey);
    
    if (jsonData == null || jsonData.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decodedData = jsonDecode(jsonData);
      return decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }
  
  // Ajoute un nouveau message à l'historique et sauvegarde
  Future<void> addMessage(Map<String, dynamic> message) async {
    final conversations = await getConversations();
    conversations.add(message);
    await saveConversations(conversations);
  }
  
  // Supprime tout l'historique des conversations
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
