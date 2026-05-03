import 'package:flutter/material.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../widgets/app_vector_icons.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.appState,
    required this.onSelectProduct,
    required this.onOpenCategory,
    required this.onSearchProducts,
  });

  final AppState appState;
  final ValueChanged<int> onSelectProduct;
  final ValueChanged<int> onOpenCategory;
  final ValueChanged<String> onSearchProducts;

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

    final heroBanners = _heroBanners(payload, bootstrap);

    return RefreshIndicator(
      onRefresh: () async {
        await appState.refreshBootstrap();
        await appState.refreshHome();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          HomeSearchBar(onSearch: onSearchProducts),
          const SizedBox(height: 12),
          HeroCard(
            payload: payload,
            bootstrap: bootstrap,
            banners: heroBanners,
            onSelectProduct: onSelectProduct,
            onOpenCategory: onOpenCategory,
          ),
          const SizedBox(height: 24),
          if ((bootstrap?.homeSections ?? <ManagedHomeSection>[]).isNotEmpty)
            for (final section in bootstrap!.homeSections.where((section) =>
                section.sectionKind != 'hero_banners')) ...<Widget>[
              _ManagedHomeSectionWidget(
                section: section,
                appState: appState,
                onSelectProduct: onSelectProduct,
                onOpenCategory: onOpenCategory,
              ),
              const SizedBox(height: 24),
            ]
          else if (payload != null) ...<Widget>[
            const SectionTitle(title: 'Shop by category'),
            const SizedBox(height: 8),
            CategoryScroller(
              categories: payload.categories,
              onOpenCategory: onOpenCategory,
            ),
            const SizedBox(height: 24),
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
        ],
      ),
    );
  }
}

List<MobileBanner> _heroBanners(
    HomePayload? payload, BootstrapPayload? bootstrap) {
  final managedSections = bootstrap?.homeSections ?? <ManagedHomeSection>[];
  for (final section in managedSections) {
    if (section.sectionKind == 'hero_banners') {
      return section.banners;
    }
  }
  return payload?.banners ?? <MobileBanner>[];
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
          CategoryScroller(
            categories: categories,
            onOpenCategory: onOpenCategory,
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

class CategoryScroller extends StatelessWidget {
  const CategoryScroller({
    super.key,
    required this.categories,
    required this.onOpenCategory,
  });

  final List<MobileCategory> categories;
  final ValueChanged<int> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories
          .map(
            (category) => ActionChip(
              label: Text(category.name),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: () => onOpenCategory(category.id),
            ),
          )
          .toList(),
    );
  }
}

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return TextField(
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        final query = value.trim();
        if (query.isNotEmpty) {
          onSearch(query);
        }
      },
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Padding(
          padding: EdgeInsets.all(14),
          child: AppVectorIcon('search', size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
      ),
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
