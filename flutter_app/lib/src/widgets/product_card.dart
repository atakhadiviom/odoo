import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../utils/app_utils.dart';
import 'app_vector_icons.dart';
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
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: AppNetworkImage(url: product.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((product.brandName ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        product.brandName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      formatMoney(product.currency, product.price),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onToggleWishlist != null)
                IconButton(
                  onPressed: onToggleWishlist,
                  visualDensity: VisualDensity.compact,
                  icon: AppVectorIcon(
                    'wishlist',
                    selected: isWished,
                    color: isWished ? theme.colorScheme.primary : null,
                  ),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}
