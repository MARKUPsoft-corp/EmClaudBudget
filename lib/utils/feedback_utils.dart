import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Classe utilitaire pour les retours haptiques et sonores
class FeedbackUtils {
  // Instance partagée pour éviter de créer plusieurs instances
  static final FeedbackUtils _instance = FeedbackUtils._internal();
  factory FeedbackUtils() => _instance;
  FeedbackUtils._internal();

  // AudioPlayer pour les effets sonores
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Vérifie si l'appareil prend en charge la vibration
  Future<bool> _hasVibrator() async {
    try {
      if (kIsWeb || Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        return false;
      }
      // Vérifier la disponibilité du vibrateur
      final hasVibrator = await Vibration.hasVibrator();
      return hasVibrator == true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la vibration: $e');
      return false;
    }
  }

  /// Joue un son de clic pour le menu
  Future<void> playMenuClickSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/menu_click.mp3'));
    } catch (e) {
      debugPrint('Erreur lors de la lecture du son: $e');
    }
  }

  /// Joue un son différent pour les boutons d'action
  Future<void> playActionSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/action_click.mp3'));
    } catch (e) {
      debugPrint('Erreur lors de la lecture du son: $e');
    }
  }

  /// Vibre brièvement pour un retour tactile
  Future<void> vibrate() async {
    try {
      if (await _hasVibrator()) {
        Vibration.vibrate(duration: 20); // Vibration courte
      }
    } catch (e) {
      debugPrint('Erreur lors de la vibration: $e');
    }
  }

  /// Uniquement retour haptique pour les éléments du menu
  Future<void> provideFeedbackForMenu() async {
    // Uniquement vibration pour les menus, sans son
    vibrate();
  }

  /// Combine le son et la vibration pour les actions
  Future<void> provideFeedbackForAction() async {
    playActionSound();
    vibrate();
  }

  /// Arrête tous les sons en cours
  void stopAllSounds() {
    _audioPlayer.stop();
  }

  /// Libère les ressources
  void dispose() {
    _audioPlayer.dispose();
  }
}
