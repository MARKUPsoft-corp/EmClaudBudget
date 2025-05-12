import 'package:flutter/material.dart';
import 'package:budget_express/domain/models/conversation.dart';
import 'package:budget_express/services/conversation_service.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/utils/feedback_utils.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ConversationService _conversationService = ConversationService();
  bool _isLoading = true;
  List<Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    await _conversationService.initialize();
    
    setState(() {
      _conversations = _conversationService.conversations;
      _isLoading = false;
    });
  }

  Future<void> _createNewConversation() async {
    // Vibration uniquement pour la navigation (selon préférences utilisateur)
    await FeedbackUtils().provideFeedbackForMenu();
    
    // Afficher une boîte de dialogue pour nommer la conversation
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NewConversationDialog(),
    );

    // Si un titre est fourni, créer la conversation
    if (result != null && result.isNotEmpty) {
      final newConversation = await _conversationService.createConversation(title: result);
      
      // Mettre à jour l'UI
      setState(() {
        _conversations = _conversationService.conversations;
      });
      
      // Naviguer vers la nouvelle conversation
      if (mounted) {
        context.push('${AppConstants.aiChatRoute}/${newConversation.id}');
      }
    }
  }

  Future<void> _selectConversation(Conversation conversation) async {
    // Vibration uniquement pour la navigation (selon préférences utilisateur)
    await FeedbackUtils().provideFeedbackForMenu();
    
    await _conversationService.setActiveConversation(conversation.id);
    
    if (mounted) {
      context.push('${AppConstants.aiChatRoute}/${conversation.id}');
    }
  }

  Future<void> _renameConversation(Conversation conversation) async {
    // Vibration uniquement pour la navigation
    await FeedbackUtils().provideFeedbackForMenu();
    
    // Afficher une boîte de dialogue pour renommer
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RenameConversationDialog(initialTitle: conversation.title),
    );

    // Si un nouveau titre est fourni, renommer la conversation
    if (result != null && result.isNotEmpty) {
      await _conversationService.renameConversation(conversation.id, result);
      
      // Mettre à jour l'UI
      setState(() {
        _conversations = _conversationService.conversations;
      });
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    // Demander confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${conversation.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Vibration uniquement pour la navigation
      await FeedbackUtils().provideFeedbackForMenu();
      
      await _conversationService.deleteConversation(conversation.id);
      
      // Mettre à jour l'UI
      setState(() {
        _conversations = _conversationService.conversations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes conversations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune conversation',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Commencez une nouvelle conversation avec l\'assistant',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    // Extraire le dernier message pour le résumé
                    final lastMessage = conversation.lastMessage;
                    final lastContent = lastMessage != null 
                        ? (lastMessage['role'] == 'user' 
                            ? 'Vous: ${lastMessage['content']}' 
                            : lastMessage['content'])
                        : 'Nouvelle conversation';
                    
                    return Dismissible(
                      key: Key(conversation.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Supprimer la conversation'),
                            content: Text('Êtes-vous sûr de vouloir supprimer "${conversation.title}" ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        await _deleteConversation(conversation);
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: const Icon(Icons.chat),
                        ),
                        title: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          lastContent,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(conversation.lastUpdatedAt),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => _selectConversation(conversation),
                        onLongPress: () => _showContextMenu(context, conversation),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: "new_conversation_button",
        onPressed: _createNewConversation,
        tooltip: 'Nouvelle conversation',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Conversation conversation) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                title: const Text('Renommer'),
                onTap: () {
                  Navigator.pop(context);
                  _renameConversation(conversation);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteConversation(conversation);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NewConversationDialog extends StatefulWidget {
  @override
  _NewConversationDialogState createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<_NewConversationDialog> {
  final _controller = TextEditingController(text: 'Nouvelle conversation');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle conversation'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nom de la conversation',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

class _RenameConversationDialog extends StatefulWidget {
  final String initialTitle;

  const _RenameConversationDialog({required this.initialTitle});

  @override
  _RenameConversationDialogState createState() => _RenameConversationDialogState();
}

class _RenameConversationDialogState extends State<_RenameConversationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renommer la conversation'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nouveau nom',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Renommer'),
        ),
      ],
    );
  }
}
