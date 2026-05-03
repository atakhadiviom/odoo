import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.appState,
    required this.searchSeed,
    required this.categorySeed,
    this.brandSeed,
    this.brandName,
    required this.onSelectProduct,
  });

  final AppState appState;
  final String searchSeed;
  final int? categorySeed;
  final int? brandSeed;
  final String? brandName;
  final ValueChanged<int> onSelectProduct;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final TextEditingController _searchController;
  List<MobileProduct> _items = <MobileProduct>[];
  bool _loading = true;
  String? _error;
  int? _selectedCategoryId;
  int? _selectedBrandId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchSeed);
    _selectedCategoryId = widget.categorySeed;
    _selectedBrandId = widget.brandSeed;
    _loadProducts();
  }

  @override
  void didUpdateWidget(covariant CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchSeed != widget.searchSeed) {
      _searchController.text = widget.searchSeed;
    }
    if (oldWidget.categorySeed != widget.categorySeed) {
      _selectedCategoryId = widget.categorySeed;
      _loadProducts();
    }
    if (oldWidget.brandSeed != widget.brandSeed) {
      _selectedBrandId = widget.brandSeed;
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await widget.appState.api.listProducts(
        search: _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        limit: 24,
      );
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.appState.home?.categories ?? <MobileCategory>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        Text(
          widget.brandName == null ? 'Shop the catalog' : widget.brandName!,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _loadProducts(),
                decoration: const InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Search'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: const Text('All items'),
                  selected:
                      _selectedCategoryId == null && _selectedBrandId == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryId = null;
                      _selectedBrandId = null;
                    });
                    _loadProducts();
                  },
                ),
              ),
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: _selectedCategoryId == category.id,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryId = category.id;
                        _selectedBrandId = null;
                      });
                      _loadProducts();
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          RetryState(
            title: 'Unable to load products',
            message: _error,
            actionLabel: 'Retry',
            onPressed: _loadProducts,
          )
        else ...<Widget>[
          Row(
            children: [
              Text(
                '${_items.length} products found',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: MessageCard(
                title: 'No products found',
                message: 'Try adjusting your search or category filters.',
              ),
            )
          else
            for (final product in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ProductCard(
                  product: product,
                  isWished: widget.appState.wishlistIds.contains(product.id),
                  onToggleWishlist: widget.appState.account == null
                      ? null
                      : () async {
                          await widget.appState.toggleWishlist(product.id);
                        },
                  onPressed: () => widget.onSelectProduct(product.id),
                ),
              ),
        ],
      ],
    );
  }
}
