import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../utils/app_utils.dart';
import '../widgets/common.dart';
import '../widgets/cart_widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.appState,
    required this.onStartCheckout,
  });

  final AppState appState;
  final VoidCallback onStartCheckout;

  @override
  Widget build(BuildContext context) {
    final cart = appState.cart;
    final canCheckout = cart.canCheckout && cart.lines.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        SectionTitle(
          title: 'Your Shopping Cart',
          trailing: TextButton.icon(
            onPressed: appState.refreshCart,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Sync'),
          ),
        ),
        if (cart.lines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: MessageCard(
              title: 'Your cart is empty',
              message:
                  'Browse our catalog and add items to your cart to see them here.',
            ),
          )
        else ...[
          for (final line in cart.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CartLineCard(appState: appState, line: line),
            ),
          const SizedBox(height: 16),
          DarkSummaryCard(
            title: 'Order total',
            lines: <String>[
              'Subtotal: ${formatMoney(cart.currency, cart.amountUntaxed)}',
              'Tax: ${formatMoney(cart.currency, cart.amountTax)}',
            ],
            total:
                'Total amount: ${formatMoney(cart.currency, cart.amountTotal)}',
            actionLabel: appState.cartLoading
                ? 'Syncing cart...'
                : 'Proceed to checkout',
            enabled: canCheckout && !appState.cartLoading,
            onPressed: onStartCheckout,
          ),
        ],
      ],
    );
  }
}
