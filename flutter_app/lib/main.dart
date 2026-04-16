import 'package:flutter/material.dart';

import 'src/screens/app_shell.dart';
import 'src/state/app_state.dart';
import 'src/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SynthoShopFlutterApp(appState: AppState()));
}

class SynthoShopFlutterApp extends StatelessWidget {
  const SynthoShopFlutterApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Syntho Shop',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(
            primaryColor: appState.primaryColor,
            accentColor: appState.accentColor,
          ),
          home: AppShell(appState: appState),
        );
      },
    );
  }
}
