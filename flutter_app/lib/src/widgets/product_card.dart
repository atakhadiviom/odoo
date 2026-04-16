import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../utils/app_utils.dart';
import 'common.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onPressed,
    this.isWished = false,
    this.onToggleWishlist,
  });

  final MobileProduct product;
  final VoidCallback onPressed;
  final bool isWished;
  final VoidCallback? onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 120,
              height: 120,
              child: AppNetworkImage(url: product.imageUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if ((product.brandName ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        product.brandName!,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      product.shortDescription.isEmpty
                          ? 'View more details.'
                          : product.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatMoney(product.currency, product.price),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    if (product.ratingCount > 0) ...<Widget>[
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.star_rounded,
                              size: 16, color: Color(0xFFF5A623)),
                          const SizedBox(width: 4),
                          Text(
                            '${product.avgRating.toStringAsFixed(1)} (${product.ratingCount})',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onToggleWishlist != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: onToggleWishlist,
                  icon: Icon(isWished ? Icons.favorite : Icons.favorite_border),
                  color:
                      isWished ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
