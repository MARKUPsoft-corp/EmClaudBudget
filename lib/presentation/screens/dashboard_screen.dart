import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'dart:math' as math;
import 'package:budget_express/presentation/providers/transaction_provider.dart';
import 'package:budget_express/domain/entities/transaction.dart';

// Classe pour gérer les particules d'argent
class MoneyParticle {
  final Offset position;
  final double size;
  final double rotation;
  final double opacity;
  final Color color;
  final IconData icon;
  
  MoneyParticle({
    required this.position,
    required this.size,
    required this.rotation,
    required this.opacity,
    required this.color,
    required this.icon,
  });
}

// Animation contrôleur pour les particules
class MoneyParticleController {
  late List<MoneyParticle> particles;
  final double width;
  final double height;
  final math.Random random = math.Random();
  
  MoneyParticleController({required this.width, required this.height}) {
    _initParticles();
  }
  
  void _initParticles() {
    final particleCount = 15; // Nombre de particules
    particles = List.generate(particleCount, (_) => _createParticle());
  }
  
  MoneyParticle _createParticle() {
    final moneyIcons = [
      Icons.attach_money,
      Icons.attach_money,
      Icons.account_balance_wallet,
      Icons.credit_card,
    ];
    
    final position = Offset(
      random.nextDouble() * width,
      random.nextDouble() * height,
    );
    
    final size = random.nextDouble() * 15 + 6; // Taille entre 6 et 21
    final rotation = random.nextDouble() * 360; // Rotation aléatoire
    final opacity = random.nextDouble() * 0.4 + 0.2; // Opacité entre 0.2 et 0.6
    final color = Colors.white.withOpacity(opacity);
    final icon = moneyIcons[random.nextInt(moneyIcons.length)];
    
    return MoneyParticle(
      position: position,
      size: size,
      rotation: rotation,
      opacity: opacity,
      color: color,
      icon: icon,
    );
  }
  
  void updateParticles(double deltaTime) {
    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];
      
      // Mouvement léger vers le bas et dérive horizontale
      final newY = particle.position.dy + (deltaTime * 10 * (particle.size / 15));
      final newX = particle.position.dx + math.sin(deltaTime + i) * 0.5;
      
      // Réinitialiser si la particule sort de l'écran
      if (newY > height) {
        particles[i] = _createParticle();
        particles[i] = particles[i].copyWith(position: Offset(random.nextDouble() * width, 0));
      } else {
        particles[i] = particle.copyWith(position: Offset(newX, newY));
      }
    }
  }
}

// Extension pour copier une particule avec des propriétés modifiées
extension MoneyParticleCopy on MoneyParticle {
  MoneyParticle copyWith({
    Offset? position,
    double? size,
    double? rotation,
    double? opacity,
    Color? color,
    IconData? icon,
  }) {
    return MoneyParticle(
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

// Widget pour afficher les particules d'argent animées
class MoneyParticlesWidget extends StatefulWidget {
  final double width;
  final double height;
  
  const MoneyParticlesWidget({
    super.key,
    required this.width,
    required this.height,
  });
  
  @override
  State<MoneyParticlesWidget> createState() => _MoneyParticlesWidgetState();
}

class _MoneyParticlesWidgetState extends State<MoneyParticlesWidget>
    with TickerProviderStateMixin {
  late MoneyParticleController _controller;
  late AnimationController _animationController;
  double _lastTime = 0;
  
  @override
  void initState() {
    super.initState();
    _controller = MoneyParticleController(
      width: widget.width,
      height: widget.height,
    );
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _animationController.addListener(_updateParticles);
  }
  
  void _updateParticles() {
    final time = _animationController.value;
    final deltaTime = (time - _lastTime).abs();
    _controller.updateParticles(deltaTime * 10);
    _lastTime = time;
    setState(() {});
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: MoneyParticlePainter(particles: _controller.particles),
        ),
      ),
    );
  }
}

class MoneyParticlePainter extends CustomPainter {
  final List<MoneyParticle> particles;
  
  MoneyParticlePainter({required this.particles});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Utiliser directement le canvas pour dessiner des icônes
      final painter = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;
        
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation * math.pi / 180);
      
      // Dessiner un simple cercle à la place du TextPainter qui cause des problèmes
      canvas.drawCircle(Offset.zero, particle.size / 2, painter);
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _balanceController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();

    // Initialiser l'animation pour le solde
    _balanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // L'animation sera mise à jour dans didChangeDependencies
    _balanceAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _balanceController, curve: Curves.easeOutCubic));

    // Initialiser les données au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      provider.initialize();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = Provider.of<TransactionProvider>(context);

    // Mettre à jour l'animation du solde quand les données changent
    if (_balanceAnimation.value != provider.balance) {
      _balanceAnimation = Tween<double>(
        begin: provider.previousBalance,
        end: provider.balance,
      ).animate(
        CurvedAnimation(parent: _balanceController, curve: Curves.easeOutCubic),
      );

      _balanceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Formateur pour les montants en FCFA
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              provider.initialize();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.initialize(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Hero - Solde
                  _buildBalanceCard(context, provider, currencyFormat),
                  const SizedBox(height: 24),

                  // Distributions des revenus et dépenses
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Adaptation à différentes tailles d'écran
                      final isWideScreen = constraints.maxWidth > 600;

                      if (isWideScreen) {
                        // Vue en deux colonnes pour les écrans larges (Linux)
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Colonne des revenus
                            Expanded(
                              child: _buildIncomeSection(
                                context,
                                provider,
                                currencyFormat,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Colonne des dépenses
                            Expanded(
                              child: _buildExpenseSection(
                                context,
                                provider,
                                currencyFormat,
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Vue en une colonne pour les écrans étroits (mobile)
                        return Column(
                          children: [
                            _buildIncomeSection(
                              context,
                              provider,
                              currencyFormat,
                            ),
                            const SizedBox(height: 24),
                            _buildExpenseSection(
                              context,
                              provider,
                              currencyFormat,
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Transactions récentes
                  _buildRecentTransactionsSection(
                    context,
                    provider,
                    currencyFormat,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Carte du solde avec animation et effets améliorés
  Widget _buildBalanceCard(
    BuildContext context,
    TransactionProvider provider,
    NumberFormat currencyFormat,
  ) {
    // Couleurs améliorées pour un meilleur contraste
    final darkOrange = const Color(0xFFD06000);
    final darkerOrange = const Color(0xFFC05000);
    
    return Card(
      elevation: 12,
      shadowColor: darkOrange.withOpacity(0.6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          hoverColor: Colors.white.withOpacity(0.1),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Stack(
            children: [
              // Background pattern avec icones d'argent
              Positioned.fill(
                child: _buildMoneyPattern(),
              ),
              // Container principal avec gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      darkOrange.withOpacity(0.9), // Légèrement transparent pour voir le pattern
                      darkerOrange.withOpacity(0.93),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: darkOrange.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Texte "Solde actuel" avec ombre pour meilleure visibilité
                        Text(
                          'Solde actuel',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        // Badge de tendance avec meilleur contraste
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icône plus visible avec fond contrasté
                              Container(
                                decoration: BoxDecoration(
                                  color: provider.balance >= 0 ? Colors.green[600] : Colors.red[600],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (provider.balance >= 0 ? Colors.green : Colors.red).withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  provider.balance >= 0 ? Icons.trending_up : Icons.trending_down,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Texte avec meilleure visibilité
                              Text(
                                provider.balance >= 0
                                    ? '+${provider.balance.toStringAsFixed(1)}%'
                                    : '${provider.balance.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Affichage du solde animé
                    AnimatedBuilder(
                      animation: _balanceAnimation,
                      builder: (context, child) {
                        return Row(
                          children: [
                            Text(
                              currencyFormat.format(_balanceAnimation.value),
                              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                                letterSpacing: -0.5,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Icône de tendance plus visible
                            if (_balanceAnimation.value > 0)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                              )
                            else if (_balanceAnimation.value < 0)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Ligne de séparation stylisée
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.15),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    const SizedBox(height: 8),
                    // Informations Revenus/Dépenses avec meilleur contraste
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 1,
                          child: _buildBalanceInfoItem(
                            context,
                            'Revenus',
                            currencyFormat.format(provider.totalIncome),
                            Icons.arrow_upward,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8), // Espacement entre les deux éléments
                        Flexible(
                          flex: 1,
                          child: _buildBalanceInfoItem(
                            context,
                            'Dépenses',
                            currencyFormat.format(provider.totalExpense),
                            Icons.arrow_downward,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Élément d'information sur le solde avec style amélioré
  Widget _buildBalanceInfoItem(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône avec contraste amélioré pour visibilité
            Container(
              padding: const EdgeInsets.all(6), // Taille réduite sur mobile
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 16), // Taille réduite
            ),
            const SizedBox(width: 6), // Espacement réduit
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Titre avec ombre pour meilleure visibilité
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Montant avec style amélioré
                Text(
                  amount,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // Section des revenus avec style amélioré et effets de survol
  // Motif d'icônes d'argent pour l'arrière-plan de la hero section
  Widget _buildMoneyPattern() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 1.0,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 30, // Nombre d'icônes
      itemBuilder: (context, index) {
        final random = math.Random(index);
        // Utiliser différentes icônes
        final icons = [
          Icons.money,
          Icons.attach_money,
          Icons.account_balance_wallet,
          Icons.credit_card,
          Icons.savings,
          Icons.payment,
        ];
        
        final icon = icons[random.nextInt(icons.length)];
        final rotation = random.nextDouble() * 45 - 22.5; // Rotation aléatoire
        
        return Center(
          child: Transform.rotate(
            angle: rotation * math.pi / 180,
            child: Opacity(
              opacity: 0.06 + random.nextDouble() * 0.08, // Opacité variable
              child: Icon(
                icon,
                color: Colors.white,
                size: 14 + random.nextDouble() * 8, // Taille variable
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildIncomeSection(
    BuildContext context,
    TransactionProvider provider,
    NumberFormat currencyFormat,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Card(
          elevation: 4,
          shadowColor: Colors.green.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.withOpacity(0.2), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withGreen(
                      Theme.of(context).colorScheme.surface.green + 5,
                    ),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête stylisé
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_upward,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Revenus',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            // Afficher plus d'informations sur les revenus
                          },
                          tooltip: 'Plus d\'infos',
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Distribution des revenus avec effets améliorés
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildIncomePieChart(context, provider),
                    ),
                    const SizedBox(height: 24),

                    // Section des types de revenus (actifs/passifs)
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnimatedIncomeTypeDetail(
                            context,
                            'Revenus actifs',
                            provider.incomesByType[true] ?? 0,
                            provider.totalIncome > 0
                                ? (provider.incomesByType[true] ?? 0) /
                                    provider.totalIncome
                                : 0,
                            currencyFormat,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAnimatedIncomeTypeDetail(
                            context,
                            'Revenus passifs',
                            provider.incomesByType[false] ?? 0,
                            provider.totalIncome > 0
                                ? (provider.incomesByType[false] ?? 0) /
                                    provider.totalIncome
                                : 0,
                            currencyFormat,
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Liste des opérations de revenus avec barre de défilement
                    Builder(builder: (context) {
                      // Récupérer toutes les opérations de revenus
                      final incomeList = provider.incomes;
                      
                      // Vérifier si la liste est vide
                      if (incomeList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Aucune opération de revenu pour le moment'),
                        );
                      }
                      
                      // Déterminer si on a besoin d'une barre de défilement
                      final hasScrollbar = incomeList.length > 4;
                      
                      // Trier les opérations par date (plus récente d'abord)
                      final sortedIncomes = List<Income>.from(incomeList)
                        ..sort((a, b) => b.date.compareTo(a.date));
                      
                      // Hauteur fixe pour la zone défilante
                      final containerHeight = hasScrollbar ? 400.0 : null;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Opérations de revenus (${sortedIncomes.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasScrollbar)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Défilez pour voir plus',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Container avec barre de défilement
                          Container(
                            height: containerHeight,
                            child: Scrollbar(
                              thumbVisibility: hasScrollbar,
                              thickness: hasScrollbar ? 6.0 : 0.0,
                              radius: const Radius.circular(8),
                              child: ListView.builder(
                                physics: hasScrollbar 
                                    ? const AlwaysScrollableScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                shrinkWrap: !hasScrollbar,
                                itemCount: sortedIncomes.length,
                                itemBuilder: (context, index) {
                                  final income = sortedIncomes[index];
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12, right: 8),
                                    child: _buildIncomeItem(
                                      context,
                                      income,
                                      currencyFormat,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Détail animé par type de revenu avec barre de progression
  Widget _buildAnimatedIncomeTypeDetail(
    BuildContext context,
    String title,
    double amount,
    double percentage,
    NumberFormat currencyFormat,
    Color color,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    currencyFormat.format(amount),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                width: double.infinity,
                color: color.withOpacity(0.1),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutQuart,
                      height: 8,
                      width:
                          (percentage.isNaN || percentage == double.infinity)
                              ? 0
                              : percentage,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall!.color!.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section des dépenses avec style amélioré et effets de survol
  Widget _buildExpenseSection(
    BuildContext context,
    TransactionProvider provider,
    NumberFormat currencyFormat,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Card(
          elevation: 4,
          shadowColor: Colors.red.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.withOpacity(0.2), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withRed(
                      Theme.of(context).colorScheme.surface.red + 5,
                    ),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête stylisé
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_downward,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Dépenses',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            // Afficher plus d'informations sur les dépenses
                          },
                          tooltip: 'Plus d\'infos',
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Graphique de répartition des dépenses avec effets améliorés
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildExpensePieChart(context, provider),
                    ),
                    const SizedBox(height: 24),

                    // Détail par catégorie avec animation et barre de défilement
                    // Récupérer uniquement les catégories avec des montants > 0
                    Builder(builder: (context) {
                      // Filtrer les catégories pour n'afficher que celles avec des dépenses
                      final activeCategories = AppConstants.expenseCategories
                          .where((category) => 
                              (provider.expensesByCategory[category.id] ?? 0) > 0)
                          .toList();
                      
                      // Vérifier s'il y a des opérations à afficher
                      if (activeCategories.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Aucune dépense par catégorie pour le moment'),
                        );
                      }
                      
                      // Déterminer si on a besoin d'une barre de défilement
                      final hasScrollbar = activeCategories.length > 4;
                      
                      // Hauteur fixe pour la zone défilante contenant 4 éléments
                      // Un élément a environ 80 pixels de hauteur + 16 de padding
                      final containerHeight = hasScrollbar ? 400.0 : null;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasScrollbar)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Détail par catégorie (${activeCategories.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Défilez pour voir plus',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (hasScrollbar) const SizedBox(height: 8),
                          
                          // Utilisation d'un container avec une hauteur fixe et une barre de défilement
                          Container(
                            height: containerHeight,
                            child: Scrollbar(
                              thumbVisibility: hasScrollbar,
                              thickness: hasScrollbar ? 6.0 : 0.0,
                              radius: const Radius.circular(8),
                              child: ListView.builder(
                                // Désactiver le défilement si on a moins de 5 éléments
                                physics: hasScrollbar 
                                    ? const AlwaysScrollableScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                shrinkWrap: !hasScrollbar,
                                itemCount: activeCategories.length,
                                itemBuilder: (context, index) {
                                  final category = activeCategories[index];
                                  final amount = provider.expensesByCategory[category.id] ?? 0;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16, right: 8),
                                    child: _buildAnimatedExpenseCategoryDetail(
                                      context,
                                      category.name,
                                      category.icon,
                                      amount,
                                      provider.totalExpense > 0
                                          ? amount / provider.totalExpense
                                          : 0,
                                      currencyFormat,
                                      category.color,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Détail animé par catégorie de dépense avec barre de progression
  Widget _buildAnimatedExpenseCategoryDetail(
    BuildContext context,
    String title,
    IconData icon,
    double amount,
    double percentage,
    NumberFormat currencyFormat,
    Color color,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    currencyFormat.format(amount),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                width: double.infinity,
                color: color.withOpacity(0.1),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutQuart,
                      height: 8,
                      width:
                          (percentage.isNaN || percentage == double.infinity)
                              ? 0
                              : percentage,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall!.color!.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Graphique en secteurs des dépenses par catégorie
  Widget _buildExpensePieChart(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final expensesByCategory = provider.expensesByCategory;

    if (expensesByCategory.isEmpty || provider.totalExpense <= 0) {
      return const Center(child: Text('Aucune dépense enregistrée'));
    }

    // Convertir la map en sections pour le graphique
    final sections = <PieChartSectionData>[];

    AppConstants.expenseCategories.forEach((category) {
      final amount = expensesByCategory[category.id] ?? 0;
      if (amount > 0) {
        sections.add(
          PieChartSectionData(
            value: amount,
            title: category.name.split(' ')[0],
            color: category.color,
            radius: 50,
          ),
        );
      }
    });

    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sections: sections,
        sectionsSpace: 2,
        startDegreeOffset: 270,
      ),
    );
  }

  // Cette méthode a été remplacée par _buildAnimatedExpenseCategoryDetail

  // Élément d'affichage d'une opération de revenu individuelle
  Widget _buildIncomeItem(
    BuildContext context,
    Income income,
    NumberFormat currencyFormat,
  ) {
    // Déterminer l'icône et la couleur selon le type de revenu
    final Color color = Colors.green;
    final IconData icon = income.isActive ? Icons.work : Icons.attach_money;
    final String typeLabel = income.isActive ? 'Revenu actif' : 'Revenu passif';
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // Action future pour voir les détails
        hoverColor: color.withOpacity(0.05),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Icône gauche
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Description et date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      income.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          flex: 2,
                          child: Text(
                            DateFormat('dd MMM yyyy').format(income.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Montant
              Text(
                currencyFormat.format(income.amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Graphique en anneau des revenus
  Widget _buildIncomePieChart(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final activeIncome = provider.incomesByType[true] ?? 0;
    final passiveIncome = provider.incomesByType[false] ?? 0;
    final totalIncome = activeIncome + passiveIncome;

    if (totalIncome <= 0) {
      return const Center(child: Text('Aucun revenu enregistré'));
    }

    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: activeIncome,
            title: 'Actifs',
            color: Colors.green,
            radius: 50,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            value: passiveIncome,
            title: 'Passifs',
            color: Theme.of(context).colorScheme.secondary,
            radius: 50,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        sectionsSpace: 2,
        startDegreeOffset: 270,
      ),
    );
  }

  // Section des transactions récentes
  Widget _buildRecentTransactionsSection(
    BuildContext context,
    TransactionProvider provider,
    NumberFormat currencyFormat,
  ) {
    // Combiner les transactions et les trier par date (les plus récentes d'abord)
    final List<dynamic> allTransactions = [
      ...provider.incomes,
      ...provider.expenses,
    ]..sort((a, b) => b.date.compareTo(a.date));

    // Prendre les 5 transactions les plus récentes
    final recentTransactions = allTransactions.take(5).toList();

    // Créer une Map des catégories de dépenses pour un accès rapide
    final Map<String, ExpenseCategory> expenseCategoriesMap = {
      for (var category in AppConstants.expenseCategories)
        category.id: category,
    };

    if (recentTransactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Aucune transaction récente')),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6), // Padding réduit
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: Colors.blue,
                          size: 16, // Taille réduite
                        ),
                      ),
                      const SizedBox(width: 8), // Espacement réduit
                      Flexible(
                        child: Text(
                          'Transactions récentes',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith( // Taille de police réduite
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Action pour voir toutes les transactions
                  },
                  child: const Text('Voir tout'),
                  style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8)), // Padding réduit
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            
            // Liste des transactions avec effet de survol
            ...recentTransactions.map((transaction) {
              final isExpense = transaction is Expense;

              // Déterminer l'icône et la couleur en fonction du type de transaction
              IconData icon;
              Color color;
              String category;

              if (isExpense) {
                final expenseCategory =
                    expenseCategoriesMap[transaction.categoryId]!;
                icon = expenseCategory.icon;
                color = expenseCategory.color;
                category = expenseCategory.name;
              } else {
                // Pour les revenus
                icon = Icons.arrow_upward;
                color = Colors.green;
                category =
                    (transaction as Income).isActive
                        ? 'Revenu actif'
                        : 'Revenu passif';
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {},
                  hoverColor: Colors.grey.withOpacity(0.05),
                  splashColor: Colors.grey.withOpacity(0.1),
                  highlightColor: Colors.grey.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Icône de la transaction
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 16),
                        // Description et catégorie
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${category} · ${DateFormat('dd/MM/yyyy').format(transaction.date)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Montant
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isExpense 
                                ? Colors.red.withOpacity(0.1) 
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isExpense
                                ? '- ${currencyFormat.format(transaction.amount)}'
                                : '+ ${currencyFormat.format(transaction.amount)}',
                            style: TextStyle(
                              color: isExpense ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
