import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({
    super.key,
    required this.appState,
    required this.onSelectBrand,
  });

  final AppState appState;
  final void Function(ProductBrand brand) onSelectBrand;

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  List<ProductBrand> _items = <ProductBrand>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await widget.appState.api.getBrands(limit: 100);
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        Text(
          'Shop by Brand',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Discover products from your favorite manufacturers.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 32),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          RetryState(
            title: 'Unable to load brands',
            message: _error,
            actionLabel: 'Retry',
            onPressed: _loadBrands,
          )
        else if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: MessageCard(
              title: 'No brands found',
              message: 'Check back later for updated brand listings.',
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final brand = _items[index];
              return _BrandCard(
                brand: brand,
                onTap: () => widget.onSelectBrand(brand),
              );
            },
          ),
      ],
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.brand, required this.onTap});

  final ProductBrand brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: brand.logoUrl.isNotEmpty
                    ? AppNetworkImage(url: brand.logoUrl, fit: BoxFit.contain)
                    : Center(
                        child: Text(
                          brand.name.substring(0, 1).toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                              ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    brand.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${brand.productCount} items',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
