import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/store_provider.dart';
import 'screens/home_shell.dart';
import 'screens/paywall_screen.dart';
import 'state/billing_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreProvider()..load()),
        ChangeNotifierProvider(create: (_) => BillingProvider()..load()),
      ],
      child: const BigasanApp(),
    ),
  );
}

class BigasanApp extends StatelessWidget {
  const BigasanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bigasan POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF287A45),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFEFA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F7F3),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Color(0xFFFFFEFA),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFFFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFF287A45), width: 1.5),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
      home: const AccessGate(child: HomeShell()),
    );
  }
}
