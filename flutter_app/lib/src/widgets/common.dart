import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/mobile_models.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
      {super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.photo_outlined, size: 36),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      errorWidget: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined, size: 36),
      ),
      placeholder: (context, _) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (message.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class RetryState extends StatelessWidget {
  const RetryState({
    super.key,
    required this.title,
    this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String? message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            if ((message ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroCard extends StatefulWidget {
  const HeroCard({
    super.key,
    required this.payload,
    required this.bootstrap,
    this.banners = const <MobileBanner>[],
    this.onSelectProduct,
    this.onOpenCategory,
  });

  final HomePayload? payload;
  final BootstrapPayload? bootstrap;
  final List<MobileBanner> banners;
  final ValueChanged<int>? onSelectProduct;
  final ValueChanged<int>? onOpenCategory;

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> {
  late final PageController _controller;
  Timer? _timer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _scheduleAutoSlide();
  }

  @override
  void didUpdateWidget(covariant HeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _activeIndex = 0;
      _timer?.cancel();
      _scheduleAutoSlide();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoSlide() {
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextIndex = (_activeIndex + 1) % widget.banners.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openBanner(MobileBanner banner) {
    if (banner.actionKind == 'product' && banner.productTemplateId != null) {
      widget.onSelectProduct?.call(banner.productTemplateId!);
    } else if (banner.actionKind == 'category' && banner.categoryId != null) {
      widget.onOpenCategory?.call(banner.categoryId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final banners = widget.banners;
    if (banners.isEmpty) {
      return SizedBox(
        height: 180,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: _HeroCopy(
            eyebrow: 'Syntho Mobile Storefront',
            title: 'A modern shopping experience powered by Odoo',
            subtitle:
                'Website: ${widget.bootstrap?.website.name ?? widget.payload?.website.name ?? 'Odoo website'}',
            useSpacer: false,
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                _activeIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _HeroBannerSlide(
                  banner: banner,
                  websiteName: widget.bootstrap?.website.name ??
                      widget.payload?.website.name ??
                      'Odoo website',
                  onTap: () => _openBanner(banner),
                ),
              );
            },
          ),
          if (banners.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: _activeIndex == index ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _activeIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroBannerSlide extends StatelessWidget {
  const _HeroBannerSlide({
    required this.banner,
    required this.websiteName,
    required this.onTap,
  });

  final MobileBanner banner;
  final String websiteName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (banner.imageUrl.isNotEmpty)
                  AppNetworkImage(url: banner.imageUrl)
                else
                  const SizedBox.shrink(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        theme.colorScheme.secondary.withOpacity(0.96),
                        theme.colorScheme.secondary.withOpacity(0.76),
                        theme.colorScheme.secondary.withOpacity(0.38),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: _HeroCopy(
                    eyebrow: banner.name.isNotEmpty
                        ? banner.name
                        : 'Syntho Mobile Storefront',
                    title: banner.title.isNotEmpty
                        ? banner.title
                        : 'A modern shopping experience powered by Odoo',
                    subtitle: banner.subtitle.isNotEmpty
                        ? banner.subtitle
                        : 'Website: $websiteName',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.useSpacer = true,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final bool useSpacer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (useSpacer) const Spacer() else const SizedBox(height: 16),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
