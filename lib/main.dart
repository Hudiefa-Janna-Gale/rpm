import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/providers.dart';
import 'app/theme.dart';
import 'features/ledger/presentation/startup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RpmApp()));
}

class RpmApp extends ConsumerWidget {
  const RpmApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Receipts & Payments Manager',
    debugShowCheckedModeBanner: false,
    theme: rpmTheme(Brightness.light),
    darkTheme: rpmTheme(Brightness.dark),
    themeMode: ref.watch(themeProvider),
    home: const StartupScreen(),
  );
}
