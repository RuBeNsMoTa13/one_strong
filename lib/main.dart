import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes.dart';
import 'services/database_service.dart';
import 'config/mongodb_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Carregar variáveis de ambiente
    print('[Main] Carregando variáveis de ambiente...');
    await dotenv.load(fileName: ".env");
    
    // Verificar se as variáveis foram carregadas
    print('[Main] Variáveis de ambiente carregadas:');
    print('  MONGODB_USER: ${MongoDBConfig.username}');
    print('  MONGODB_PASSWORD: ${MongoDBConfig.password.replaceAll(RegExp(r'.'), '*')}'); // Oculta a senha
    print('  MONGODB_HOST: ${MongoDBConfig.host}');
    print('  MONGODB_DATABASE: ${MongoDBConfig.database}');
    print('  PORT: ${MongoDBConfig.port}');
    
    // Verificar string de conexão
    print('[Main] String de conexão montada:');
    final connString = MongoDBConfig.connectionString;
    final maskedConnString = connString.replaceAll(
      RegExp('${MongoDBConfig.password}'), 
      '*' * MongoDBConfig.password.length
    );
    print('  $maskedConnString');
    
    // Testar conexão com o banco de dados
    print('[Main] Testando conexão com o banco de dados...');
    final connected = await DatabaseService.testConnection();
    if (!connected) {
      print('[Main] ERRO: Não foi possível conectar ao banco de dados');
    } else {
      print('[Main] Conexão com o banco de dados estabelecida com sucesso');
    }
  } catch (e, stackTrace) {
    print('[Main] Erro na inicialização do app:');
    print('Erro: $e');
    print('Stack trace: $stackTrace');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strong One',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          background: Colors.grey[900]!,
          surface: Colors.grey[850]!,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.amber,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.amber,
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.grey[850],
          indicatorColor: Colors.amber.withOpacity(0.3),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(color: Colors.amber),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.grey[850],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.amber),
          prefixIconColor: Colors.amber,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
