import 'package:flutter/material.dart';

/// Widget qui affiche le texte progressivement, mot par mot
class TypingAnimation extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration wordDelay;
  final Function? onCompleted;

  const TypingAnimation({
    Key? key,
    required this.text,
    this.style,
    this.wordDelay = const Duration(milliseconds: 100),
    this.onCompleted,
  }) : super(key: key);

  @override
  State<TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<TypingAnimation> {
  String _displayText = '';
  late List<String> _words;
  int _wordIndex = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _words = widget.text.split(' ');
    _startTypingAnimation();
  }

  @override
  void didUpdateWidget(TypingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _displayText = '';
      _wordIndex = 0;
      _isComplete = false;
      _words = widget.text.split(' ');
      _startTypingAnimation();
    }
  }

  void _startTypingAnimation() {
    // Arrêt si la liste est vide ou si l'animation est déjà terminée
    if (_words.isEmpty || _isComplete) return;

    // Fonction pour ajouter le prochain mot après un délai
    Future.delayed(widget.wordDelay, () {
      if (!mounted) return;

      setState(() {
        // Ajouter un espace uniquement si ce n'est pas le premier mot
        if (_displayText.isNotEmpty) {
          _displayText += ' ';
        }
        _displayText += _words[_wordIndex];
        _wordIndex++;

        // Vérifier si c'est le dernier mot
        if (_wordIndex >= _words.length) {
          _isComplete = true;
          widget.onCompleted?.call();
        } else {
          _startTypingAnimation(); // Continuer avec le mot suivant
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
    );
  }
}
