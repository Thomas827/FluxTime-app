import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluxtime/providers/task_provider.dart';
import 'package:fluxtime/providers/time_record_provider.dart';
import 'package:fluxtime/providers/energy_provider.dart';
import 'package:fluxtime/screens/home_screen.dart';
import 'package:fluxtime/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database;
  runApp(const FluxTimeApp());
}

class FluxTimeApp extends StatelessWidget {
  const FluxTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => TimeRecordProvider()),
        ChangeNotifierProvider(create: (_) => EnergyProvider()),
      ],
      child: MaterialApp(
        title: 'FluxTime',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
