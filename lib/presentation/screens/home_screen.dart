import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:budget_express/utils/feedback_utils.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Configuration des raccourcis clavier pour Linux
    if (defaultTargetPlatform == TargetPlatform.linux) {
      _setupKeyboardShortcuts();
    }
  }

  void _setupKeyboardShortcuts() {
    // Les raccourcis clavier sont gérés via les actions et intents
    // Cette fonction pourrait être étendue si nécessaire
  }

  @override
  Widget build(BuildContext context) {
    // Déterminer si l'application est exécutée sur desktop (Linux)
    final isDesktop = defaultTargetPlatform == TargetPlatform.linux;

    // Routes pour la navigation
    final routes = [
      NavigationDestination(
        route: AppConstants.dashboardRoute,
        icon: Icons.dashboard,
        selectedIcon: Icons.dashboard,
        label: 'Tableau de bord',
      ),
      NavigationDestination(
        route: AppConstants.incomeRoute,
        icon: Icons.arrow_upward,
        selectedIcon: Icons.arrow_upward,
        label: 'Revenus',
      ),
      NavigationDestination(
        route: AppConstants.expenseRoute,
        icon: Icons.arrow_downward,
        selectedIcon: Icons.arrow_downward,
        label: 'Dépenses',
      ),
      NavigationDestination(
        route: AppConstants.aiChatRoute,
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        label: 'Assistant IA',
      ),
      NavigationDestination(
        route: AppConstants.settingsRoute,
        icon: Icons.settings,
        selectedIcon: Icons.settings,
        label: 'Paramètres',
      ),
    ];

    // Mettre à jour l'index sélectionné en fonction de la route actuelle
    final router = GoRouter.of(context);
    final String location = router.routeInformationProvider.value.uri.path;
    for (int i = 0; i < routes.length; i++) {
      if (location == routes[i].route) {
        _selectedIndex = i;
        break;
      }
    }

    // Navigation adaptative selon la plateforme
    return Scaffold(
      body: isDesktop
          ? _buildDesktopLayout(context, routes)
          : _buildMobileLayout(context, routes),
    );
  }

  // Layout pour desktop (Linux) avec style amélioré
  Widget _buildDesktopLayout(
      BuildContext context, List<NavigationDestination> routes) {
    return Row(
      children: [
        // Barre de navigation latérale stylisée
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // En-tête avec logo et nom de l'application
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Theme.of(context).colorScheme.primary,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Logo animé
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SvgPicture.asset(
                          'assets/images/emclaud_logo.svg',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        'EmClaud Budget',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Menu de navigation stylisé
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    final isSelected = _selectedIndex == index;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.15) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                                context.go(routes[index].route);
                              });
                            },
                            hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Indicateur de sélection
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: 4,
                                    height: isSelected ? 20 : 0,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Icon(
                                    isSelected ? route.selectedIcon : route.icon,
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.primary 
                                        : Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    route.label,
                                    style: TextStyle(
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.primary 
                                          : Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Pied de page avec version
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Contenu principal
        Expanded(child: widget.child),
      ],
    );
  }

  // Layout pour mobile (Android)
  Widget _buildMobileLayout(
      BuildContext context, List<NavigationDestination> routes) {
    return Column(
      children: [
        // Contenu principal
        Expanded(child: widget.child),
        // Barre de navigation inférieure
        BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) async {
            // Activer les retours haptiques et sonores sur mobile
            await FeedbackUtils().provideFeedbackForMenu();
            
            setState(() {
              _selectedIndex = index;
              context.go(routes[index].route);
            });
          },
          items: routes
              .map((route) => BottomNavigationBarItem(
                    icon: Icon(route.icon),
                    activeIcon: Icon(route.selectedIcon),
                    label: route.label,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// Widget pour afficher un raccourci clavier
class KeyboardShortcutRow extends StatelessWidget {
  final String shortcut;
  final String label;

  const KeyboardShortcutRow({
    super.key,
    required this.shortcut,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// Classe pour stocker les informations de destination de navigation
class NavigationDestination {
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  NavigationDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
