import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'styles/colors.dart';
import 'styles/theme_notifier.dart';
import 'auth_notifier.dart';
import 'views/Home/home_screen.dart';
import 'views/Search/search_screen.dart';
import 'views/Profile/profile_screen.dart';
import 'views/Profile/profile_logged_out_screen.dart';
import 'views/Layout/layout.dart';
import 'views/Home/start_page.dart';
import 'views/Home/home_screen_logged_out.dart';
import 'views/Login/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://sppnkiaybyqeetgpengh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwcG5raWF5YnlxZWV0Z3BlbmdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMwODA1MDYsImV4cCI6MjA0ODY1NjUwNn0.OEek-QDrpBhdENJ7lsIOi5InDi_thOrdqzISq1x2ld8',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'BookSwap',
      debugShowCheckedModeBanner: false,
      theme: AppColors.getThemeData(false), // Tema claro
      darkTheme: AppColors.getThemeData(true), // Tema oscuro
      themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(), // Usar el AuthWrapper como pantalla inicial
      routes: {
        '/start': (context) => const StartPage(),
        '/home': (context) => const HomeScreen(),
        '/homeLoggedOut': (context) => const HomeScreenLoggedOut(),
        '/search': (context) => const LayoutWrapper(index: 1),
        '/profile': (context) => const LayoutWrapper(index: 2),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

// AuthWrapper para manejar la lógica de inicio de sesión y navegación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);

    if (authNotifier.isLoggedIn) {
      // Si el usuario está autenticado, redirigir al HomeScreen dentro del Layout
      return const Layout(
        body: HomeScreen(),
        currentIndex: 0,
      );
    } else {
      // Si no está autenticado, redirigir a la pantalla de inicio de sesión
      return const LoginScreen();
    }
  }
}

// Wrapper para manejar las diferentes pantallas dentro del Layout
class LayoutWrapper extends StatelessWidget {
  final int index;
  const LayoutWrapper({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);

    final List<Widget> screens = [
      const HomeScreen(),
      const SearchScreen(),
      authNotifier.isLoggedIn
          ? const ProfileScreen()
          : const ProfileLoggedOutScreen(),
    ];

    return Layout(
      body: screens[index],
      currentIndex: index,
      onTabSelected: (selectedIndex) {
        // Navegación dinámica según la tab seleccionada
        String route;
        switch (selectedIndex) {
          case 0:
            route = '/home';
            break;
          case 1:
            route = '/search';
            break;
          case 2:
          default:
            route = '/profile';
            break;
        }
        if (selectedIndex != index) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
