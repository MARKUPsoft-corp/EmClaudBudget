import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import 'package:budget_express/core/routes/app_router.dart';
import 'package:budget_express/core/theme/app_theme.dart';
import 'package:budget_express/data/datasources/app_database.dart';
import 'package:budget_express/data/repositories/transaction_repository_impl.dart';
import 'package:budget_express/domain/repositories/transaction_repository.dart';
import 'package:budget_express/presentation/providers/transaction_provider.dart';
import 'package:budget_express/presentation/screens/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  // Assurer que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser l'état du thème adaptatif
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  
  // Définir l'orientation préférée (portrait pour mobile, libre pour desktop)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurer la couleur de la barre système
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  // Initialiser la base de données
  final database = AppDatabase();
  
  // Initialiser le repository
  final transactionRepository = TransactionRepositoryImpl(database);
  
  runApp(
    MyApp(
      savedThemeMode: savedThemeMode,
      transactionRepository: transactionRepository,
    ),
  );
}

class MyApp extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final TransactionRepository transactionRepository;

  const MyApp({
    super.key,
    this.savedThemeMode,
    required this.transactionRepository,
  });
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;
  
  void _onInitializationComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TransactionRepository>(
          create: (_) => widget.transactionRepository,
        ),
        ChangeNotifierProvider(
          create: (context) => TransactionProvider(
            Provider.of<TransactionRepository>(context, listen: false),
          ),
        ),
      ],
      child: AdaptiveTheme(
        light: AppTheme.darkTheme, // Utiliser le thème sombre même en mode clair
        dark: AppTheme.darkTheme,
        initial: AdaptiveThemeMode.dark, // Forcer le mode sombre au démarrage
        builder: (theme, darkTheme) => _showSplash 
          ? MaterialApp(
              title: 'EmClaud Budget',
              debugShowCheckedModeBanner: false,
              theme: darkTheme,
              home: SplashScreen(
                onInitializationComplete: _onInitializationComplete,
              ),
            )
          : MaterialApp.router(
          title: 'EmClaud Budget',
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
