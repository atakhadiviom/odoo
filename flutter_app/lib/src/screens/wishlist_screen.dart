import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({
    super.key,
    required this.appState,
    required this.onSelectProduct,
    required this.onGoToAccount,
  });

  final AppState appState;
  final ValueChanged<int> onSelectProduct;
  final VoidCallback onGoToAccount;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<MobileProduct> _items = <MobileProduct>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    if (widget.appState.account == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await widget.appState.api.getWishlist();
      if (!mounted) return;
      setState(() {
        _items = payload.items;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appState.account == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Wishlist',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sign in to save your favorite products and sync them across all your devices.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onGoToAccount,
                child: const Text('Sign in now'),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        SectionTitle(
          title: 'Your Wishlist',
          trailing: IconButton(
            onPressed: _loadWishlist,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          RetryState(
            title: 'Unable to load wishlist',
            message: _error,
            actionLabel: 'Retry',
            onPressed: _loadWishlist,
          )
        else if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: MessageCard(
              title: 'Your wishlist is empty',
              message:
                  'Tap the heart icon on any product to save it for later.',
            ),
          )
        else
          for (final product in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ProductCard(
                product: product,
                onPressed: () => widget.onSelectProduct(product.id),
              ),
            ),
      ],
    );
  }
}
