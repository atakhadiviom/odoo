import React, { useEffect, useState } from 'react';
import {
  Alert,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { odooApi } from '../lib/odoo';
import { theme } from '../theme';
import { HomePayload, MobileBanner } from '../types';
import { ProductCard } from '../components/ProductCard';

interface HomeScreenProps {
  onSelectProduct: (productId: number) => void;
  onOpenCategory: (categoryId: number) => void;
}

export function HomeScreen({
  onSelectProduct,
  onOpenCategory,
}: HomeScreenProps) {
  const [payload, setPayload] = useState<HomePayload | null>(null);

  useEffect(() => {
    odooApi
      .getHome()
      .then(setPayload)
      .catch((error: Error) => {
        Alert.alert('Unable to load home feed', error.message);
      });
  }, []);

  const handleBannerPress = (banner: MobileBanner) => {
    if (banner.action_kind === 'product' && banner.product_tmpl_id) {
      onSelectProduct(banner.product_tmpl_id);
      return;
    }
    if (banner.action_kind === 'category' && banner.category_id) {
      onOpenCategory(banner.category_id);
    }
  };

  return (
    <ScrollView
      contentContainerStyle={styles.content}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.hero}>
        <Text style={styles.eyebrow}>Odoo 19 mobile storefront</Text>
        <Text style={styles.title}>A warm, modern shopping surface on top of your Odoo site</Text>
        <Text style={styles.subtitle}>
          Browse categories, open product detail, manage a guest cart, and sign in to see orders.
        </Text>
      </View>

      <Text style={styles.sectionTitle}>Campaign banners</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        {(payload?.banners || []).map((banner) => (
          <Pressable
            key={banner.id}
            style={styles.banner}
            onPress={() => handleBannerPress(banner)}
          >
            <Image source={{ uri: banner.image_url }} style={styles.bannerImage} />
            <View style={styles.bannerCopy}>
              <Text style={styles.bannerTitle}>{banner.title}</Text>
              {!!banner.subtitle && (
                <Text style={styles.bannerSubtitle}>{banner.subtitle}</Text>
              )}
            </View>
          </Pressable>
        ))}
      </ScrollView>

      <Text style={styles.sectionTitle}>Shop by category</Text>
      <View style={styles.categoryRow}>
        {(payload?.categories || []).map((category) => (
          <Pressable
            key={category.id}
            style={styles.categoryChip}
            onPress={() => onOpenCategory(category.id)}
          >
            <Text style={styles.categoryText}>{category.name}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={styles.sectionTitle}>Featured products</Text>
      {(payload?.featured_products || []).map((product) => (
        <ProductCard
          key={product.id}
          product={product}
          onPress={onSelectProduct}
        />
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: {
    padding: theme.spacing.md,
    paddingBottom: theme.spacing.xl,
  },
  hero: {
    backgroundColor: theme.colors.ink,
    borderRadius: theme.radius.lg,
    marginBottom: theme.spacing.lg,
    padding: theme.spacing.lg,
  },
  eyebrow: {
    color: '#EEC17A',
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1,
    marginBottom: theme.spacing.xs,
    textTransform: 'uppercase',
  },
  title: {
    color: '#FFFFFF',
    fontSize: 28,
    fontWeight: '800',
    lineHeight: 34,
    marginBottom: theme.spacing.sm,
  },
  subtitle: {
    color: '#D9E1E5',
    fontSize: 15,
    lineHeight: 22,
  },
  sectionTitle: {
    color: theme.colors.ink,
    fontSize: 20,
    fontWeight: '800',
    marginBottom: theme.spacing.md,
    marginTop: theme.spacing.sm,
  },
  banner: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    marginRight: theme.spacing.md,
    overflow: 'hidden',
    width: 280,
  },
  bannerImage: {
    backgroundColor: theme.colors.surfaceStrong,
    height: 150,
    width: '100%',
  },
  bannerCopy: {
    padding: theme.spacing.md,
  },
  bannerTitle: {
    color: theme.colors.ink,
    fontSize: 18,
    fontWeight: '800',
  },
  bannerSubtitle: {
    color: theme.colors.muted,
    fontSize: 14,
    lineHeight: 20,
    marginTop: theme.spacing.xs,
  },
  categoryRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: theme.spacing.md,
  },
  categoryChip: {
    backgroundColor: '#EFD9B8',
    borderRadius: theme.radius.pill,
    marginBottom: theme.spacing.sm,
    marginRight: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  categoryText: {
    color: theme.colors.accentDark,
    fontSize: 13,
    fontWeight: '800',
  },
});
