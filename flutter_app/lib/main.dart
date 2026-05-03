import 'package:flutter/material.dart';

import 'src/screens/app_shell.dart';
import 'src/state/app_state.dart';
import 'src/theme/app_theme.dart';
import 'src/services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  int? lastRegisteredPartnerId;

  // Initialize Push Notifications
  await PushService.initialize(appState);
  appState.addListener(() {
    final partnerId = appState.account?.partner.id;
    if (partnerId != null && partnerId != lastRegisteredPartnerId) {
      lastRegisteredPartnerId = partnerId;
      PushService.registerCurrentDevice(appState);
    }
    if (partnerId == null) {
      lastRegisteredPartnerId = null;
    }
  });

  runApp(SynthoShopFlutterApp(appState: appState));
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
