import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.appState,
    required this.onSelectProduct,
    required this.onOpenCategory,
  });

  final AppState appState;
  final ValueChanged<int> onSelectProduct;
  final ValueChanged<int> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    if (appState.homeLoading &&
        appState.home == null &&
        appState.bootstrap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final payload = appState.home;
    final bootstrap = appState.bootstrap;
    if (payload == null && bootstrap == null) {
      return RetryState(
        title: 'Unable to load the home feed',
        actionLabel: 'Retry',
        onPressed: () async {
          await appState.refreshBootstrap();
          await appState.refreshHome();
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        HeroCard(payload: payload, bootstrap: bootstrap),
        const SizedBox(height: 32),
        if ((bootstrap?.homeSections ?? <ManagedHomeSection>[]).isNotEmpty)
          for (final section in bootstrap!.homeSections) ...<Widget>[
            _ManagedHomeSectionWidget(
              section: section,
              appState: appState,
              onSelectProduct: onSelectProduct,
              onOpenCategory: onOpenCategory,
            ),
            const SizedBox(height: 24),
          ]
        else if (payload != null) ...<Widget>[
          const SectionTitle(title: 'Campaign banners'),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: payload.banners.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final banner = payload.banners[index];
                return _BannerCard(
                  banner: banner,
                  onTap: () {
                    if (banner.actionKind == 'product' &&
                        banner.productTemplateId != null) {
                      onSelectProduct(banner.productTemplateId!);
                    } else if (banner.actionKind == 'category' &&
                        banner.categoryId != null) {
                      onOpenCategory(banner.categoryId!);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          const SectionTitle(title: 'Shop by category'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: payload.categories
                .map(
                  (category) => ActionChip(
                    label: Text(category.name),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onPressed: () => onOpenCategory(category.id),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          const SectionTitle(title: 'Featured products'),
          const SizedBox(height: 8),
          for (final product in payload.featuredProducts)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ProductCard(
                product: product,
                isWished: appState.wishlistIds.contains(product.id),
                onToggleWishlist: appState.account == null
                    ? null
                    : () async {
                        await appState.toggleWishlist(product.id);
                      },
                onPressed: () => onSelectProduct(product.id),
              ),
            ),
        ],
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: () async {
              await appState.refreshBootstrap();
              await appState.refreshHome();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh home'),
          ),
        ),
      ],
    );
  }
}

class _ManagedHomeSectionWidget extends StatelessWidget {
  const _ManagedHomeSectionWidget({
    required this.section,
    required this.appState,
    required this.onSelectProduct,
    required this.onOpenCategory,
  });

  final ManagedHomeSection section;
  final AppState appState;
  final ValueChanged<int> onSelectProduct;
  final ValueChanged<int> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    if (section.sectionKind == 'hero_banners') {
      final banners = section.banners;
      if (banners.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionTitle(title: section.title),
          if (section.subtitle.isNotEmpty) ...<Widget>[
            Text(
              section.subtitle,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: banners.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final banner = banners[index];
                return _BannerCard(
                  banner: banner,
                  onTap: () {
                    if (banner.actionKind == 'product' &&
                        banner.productTemplateId != null) {
                      onSelectProduct(banner.productTemplateId!);
                    } else if (banner.actionKind == 'category' &&
                        banner.categoryId != null) {
                      onOpenCategory(banner.categoryId!);
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    if (section.sectionKind == 'featured_categories') {
      final categories = section.categories;
      if (categories.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionTitle(title: section.title),
          if (section.subtitle.isNotEmpty) ...<Widget>[
            Text(
              section.subtitle,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories
                .map(
                  (category) => ActionChip(
                    label: Text(category.name),
                    onPressed: () => onOpenCategory(category.id),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

    if (section.sectionKind == 'content_page') {
      final pages = section.contentPages;
      if (pages.isEmpty) return const SizedBox.shrink();
      final page = pages.first;
      return MessageCard(
        title: section.title.isNotEmpty ? section.title : page.title,
        message: page.summary.isNotEmpty ? page.summary : page.title,
      );
    }

    final products = section.products;
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionTitle(title: section.title),
        if (section.subtitle.isNotEmpty) ...<Widget>[
          Text(
            section.subtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
        ],
        for (final product in products)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProductCard(
              product: product,
              isWished: appState.wishlistIds.contains(product.id),
              onToggleWishlist: appState.account == null
                  ? null
                  : () async {
                      await appState.toggleWishlist(product.id);
                    },
              onPressed: () => onSelectProduct(product.id),
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.onTap});

  final MobileBanner banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: AppNetworkImage(url: banner.imageUrl)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      banner.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (banner.subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        banner.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
