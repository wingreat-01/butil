import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/store_provider.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => StoreProvider()..load(),
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
        colorSchemeSeed: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF5F7F3),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const HomeShell(),
    );
  }
}
