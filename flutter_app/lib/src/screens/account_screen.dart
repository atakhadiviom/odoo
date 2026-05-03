import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../utils/app_utils.dart';
import '../widgets/app_vector_icons.dart';
import '../widgets/common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      await widget.appState.login(
        _loginController.text.trim(),
        _passwordController.text,
      );
      _passwordController.clear();
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Login failed', error.toString());
    }
  }

  Future<void> _loginWithGoogle() async {
    final app = widget.appState.bootstrap?.app;
    if (app == null || !app.googleLoginEnabled) {
      _showErrorDialog(context, 'Not available',
          'Google login is not enabled for this app.');
      return;
    }

    try {
      final googleSignIn = GoogleSignIn(
        clientId: app.googleClientId, // Web client ID for token verification
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      if (auth.idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      await widget.appState.loginWithGoogle(auth.idToken!);
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Google Sign-In failed', error.toString());
    }
  }

  Future<void> _openOrder(OrderSummary order) async {
    final url = order.portalUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      final openedInApp = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        webOnlyWindowName: '_self',
      );
      if (openedInApp) return;
    } catch (_) {
      // Web builds can reject in-app browser mode; fall back to same-tab launch.
    }
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.appState.account;
    if (account == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          Text(
            'Sign in',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back! Sign in to sync your orders and manage your profile.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _loginController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'user@example.com',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: '********',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.appState.accountLoading ? null : _login,
              child: Text(
                widget.appState.accountLoading ? 'Signing in...' : 'Sign in',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: Divider(
                      color: Theme.of(context).colorScheme.outlineVariant)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Expanded(
                  child: Divider(
                      color: Theme.of(context).colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed:
                  widget.appState.accountLoading ? null : _loginWithGoogle,
              icon: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.login),
              ),
              label: const Text('Sign in with Google'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        Text(
          'My Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    account.partner.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.partner.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.partner.email ?? 'No email provided',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        SectionTitle(
          title: 'Recent Orders',
          trailing: IconButton(
            onPressed: widget.appState.refreshAccount,
            icon: const AppVectorIcon('refresh', size: 20),
          ),
        ),
        if (account.orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('You haven\'t placed any orders yet.'),
          )
        else
          for (final order in account.orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  onTap:
                      order.portalUrl == null ? null : () => _openOrder(order),
                  title: Text(
                    order.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    order.needsPayment
                        ? 'Needs payment - ${order.dateOrder?.split('T').first ?? ''}'
                        : '${order.state.toUpperCase()} - ${order.dateOrder?.split('T').first ?? ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatMoney(order.currency, order.amountTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (order.needsPayment && order.portalUrl != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Open',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: widget.appState.accountLoading
              ? null
              : () => widget.appState.logout(),
          icon: const AppVectorIcon('logout', size: 20),
          label: Text(
            widget.appState.accountLoading ? 'Signing out...' : 'Sign out',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(
                color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
