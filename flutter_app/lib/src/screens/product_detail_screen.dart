import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../utils/app_utils.dart';
import '../widgets/common.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.appState,
    required this.productTemplateId,
  });

  final AppState appState;
  final int productTemplateId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  MobileProduct? _product;
  String? _error;
  bool _loading = true;
  bool _adding = false;
  bool _ratingSubmitting = false;
  int _selectedRating = 5;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final product =
          await widget.appState.api.getProduct(widget.productTemplateId);
      if (!mounted) return;
      setState(() {
        _product = product;
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

  Future<void> _addToCart() async {
    final product = _product;
    if (product == null) return;

    setState(() {
      _adding = true;
    });
    try {
      await widget.appState.addToCart(product.variantId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Unable to update cart', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  Future<void> _toggleWishlist() async {
    final product = _product;
    if (product == null) return;
    try {
      final wished = await widget.appState.toggleWishlist(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wished ? 'Saved to wishlist' : 'Removed from wishlist'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Wishlist requires sign in', error.toString());
    }
  }

  Future<void> _submitRating() async {
    final product = _product;
    if (product == null) return;
    setState(() {
      _ratingSubmitting = true;
    });
    try {
      final updated = await widget.appState.api.rateProduct(
        productId: product.id,
        rating: _selectedRating,
        review: _reviewController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _product = updated;
        _reviewController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your review'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Sign in to review', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _ratingSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return RetryState(
        title: 'Unable to load product',
        message: _error,
        actionLabel: 'Retry',
        onPressed: _loadProduct,
      );
    }
    final product = _product;
    if (product == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: <Widget>[
        Hero(
          tag: 'product_${product.id}',
          child: Card(
            elevation: 8,
            shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: AppNetworkImage(url: product.imageUrl),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatMoney(product.currency, product.price),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                IconButton(
                  onPressed:
                      widget.appState.account == null ? null : _toggleWishlist,
                  icon: Icon(
                    widget.appState.wishlistIds.contains(product.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: widget.appState.account == null
                      ? 'Sign in to use wishlist'
                      : 'Toggle wishlist',
                ),
              ],
            ),
          ],
        ),
        if ((product.brandName ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            product.brandName!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
        if (product.ratingCount > 0) ...<Widget>[
          const SizedBox(height: 12),
          _RatingSummary(product: product),
        ],
        const SizedBox(height: 12),
        if (product.categoryNames.isNotEmpty)
          Wrap(
            spacing: 8,
            children: product.categoryNames
                .map((name) => Text(
                      name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ))
                .toList(),
          ),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Description'),
        Text(
          product.description.isEmpty
              ? 'No description available for this product.'
              : product.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 32),
        _ReviewPanel(
          product: product,
          selectedRating: _selectedRating,
          reviewController: _reviewController,
          submitting: _ratingSubmitting,
          signedIn: widget.appState.account != null,
          onRatingChanged: (rating) {
            setState(() {
              _selectedRating = rating;
            });
          },
          onSubmit: _submitRating,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _adding ? null : _addToCart,
            icon: _adding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add_shopping_cart_rounded),
            label: Text(_adding ? 'Updating...' : 'Add to cart'),
            style: ElevatedButton.styleFrom(
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if ((product.defaultCode ?? '').isNotEmpty) ...[
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Product Code: ${product.defaultCode}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
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

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.product});

  final MobileProduct product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var index = 1; index <= 5; index++)
          Icon(
            index <= product.avgRating.round()
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: 20,
            color: const Color(0xFFF5A623),
          ),
        const SizedBox(width: 8),
        Text(
          '${product.avgRating.toStringAsFixed(1)} from ${product.ratingCount} reviews',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.product,
    required this.selectedRating,
    required this.reviewController,
    required this.submitting,
    required this.signedIn,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final MobileProduct product;
  final int selectedRating;
  final TextEditingController reviewController;
  final bool submitting;
  final bool signedIn;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionTitle(title: 'Ratings and reviews'),
            if (product.ratings.isEmpty)
              Text(
                'No reviews yet. Be the first to review this product.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              for (final rating in product.ratings.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            rating.partnerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          for (var index = 1; index <= 5; index++)
                            Icon(
                              index <= rating.rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 16,
                              color: const Color(0xFFF5A623),
                            ),
                        ],
                      ),
                      if (rating.review.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(rating.review),
                      ],
                    ],
                  ),
                ),
            const Divider(height: 28),
            Text(
              signedIn ? 'Write a review' : 'Sign in to write a review',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                for (var index = 1; index <= 5; index++)
                  IconButton(
                    onPressed: signedIn ? () => onRatingChanged(index) : null,
                    icon: Icon(
                      index <= selectedRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFF5A623),
                    ),
                  ),
              ],
            ),
            TextField(
              controller: reviewController,
              enabled: signedIn,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Share what you liked about this product',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: signedIn && !submitting ? onSubmit : null,
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rate_review_outlined),
              label: Text(submitting ? 'Submitting...' : 'Submit review'),
            ),
          ],
        ),
      ),
    );
  }
}
