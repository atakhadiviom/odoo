import React, { useEffect, useState } from 'react';
import {
  Alert,
  Dimensions,
  FlatList,
  Image,
  Pressable,
  ScrollView,
  Share,
  StyleSheet,
  Text,
  View,
} from 'react-native';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const GALLERY_WIDTH = SCREEN_WIDTH - theme.spacing.md * 2;
import { Ionicons } from '@expo/vector-icons';

import { useCart } from '../context/CartContext';
import { odooApi } from '../lib/odoo';
import { theme } from '../theme';
import { MobileProduct } from '../types';

interface ProductScreenProps {
  productId: number;
}

export function ProductScreen({ productId }: ProductScreenProps) {
  const [product, setProduct] = useState<MobileProduct | null>(null);
  const [activeImageIndex, setActiveImageIndex] = useState(0);
  const { addToCart, loading } = useCart();

  useEffect(() => {
    odooApi
      .getProduct(productId)
      .then(setProduct)
      .catch((error: Error) => {
        Alert.alert('Unable to load product', error.message);
      });
  }, [productId]);

  const handleAddToCart = async () => {
    if (!product) {
      return;
    }
    try {
      await addToCart(product.variant_id, 1);
      Alert.alert('Added to cart', `${product.name} was added to your cart.`);
    } catch (error) {
      Alert.alert('Unable to update cart', (error as Error).message);
    }
  };

  if (!product) {
    return (
      <View style={styles.emptyState}>
        <Text style={styles.emptyStateText}>Loading product...</Text>
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.content}>
      <View style={styles.galleryContainer}>
        <FlatList
          data={[product.image_url, ...(product.extra_image_urls || [])]}
          horizontal
          pagingEnabled
          showsHorizontalScrollIndicator={false}
          onMomentumScrollEnd={(e) => {
            const index = Math.round(e.nativeEvent.contentOffset.x / e.nativeEvent.layoutMeasurement.width);
            setActiveImageIndex(index);
          }}
          keyExtractor={(item) => item}
          renderItem={({ item }) => (
            <Image source={{ uri: item }} style={styles.image} />
          )}
        />
        {[product.image_url, ...(product.extra_image_urls || [])].length > 1 && (
          <View style={styles.pagination}>
            {[product.image_url, ...(product.extra_image_urls || [])].map((_, i) => (
              <View
                key={i}
                style={[
                  styles.paginationDot,
                  activeImageIndex === i ? styles.paginationDotActive : undefined,
                ]}
              />
            ))}
          </View>
        )}
      </View>
      <View style={styles.priceRibbon}>
        <Text style={styles.priceText}>
          {product.currency} {product.price.toFixed(2)}
        </Text>
      </View>
      <View style={styles.headerRow}>
        <View style={styles.headerLeft}>
          <Text style={styles.title}>{product.name}</Text>
        </View>
        <Pressable
          style={styles.shareButton}
          onPress={() => {
            Share.share({
              message: `Check out ${product.name} on Syntho Shop: ${product.website_url}`,
              title: product.name,
            });
          }}
        >
          <Ionicons name="share-social-outline" size={24} color={theme.colors.ink} />
        </Pressable>
      </View>
      {!!product.default_code && (
        <Text style={styles.meta}>SKU: {product.default_code}</Text>
      )}
      {!!product.category_names?.length && (
        <Text style={styles.meta}>
          Categories: {product.category_names.join(', ')}
        </Text>
      )}
      <Text style={styles.description}>{product.description || 'No description provided.'}</Text>
      <Pressable
        style={[styles.button, loading ? styles.buttonDisabled : undefined]}
        onPress={handleAddToCart}
      >
        <Text style={styles.buttonText}>
          {loading ? 'Updating cart...' : 'Add to cart'}
        </Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: {
    padding: theme.spacing.md,
    paddingBottom: theme.spacing.xl,
  },
  galleryContainer: {
    marginBottom: theme.spacing.md,
  },
  image: {
    backgroundColor: theme.colors.surfaceStrong,
    borderRadius: theme.radius.lg,
    height: 320,
    width: GALLERY_WIDTH,
  },
  pagination: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: theme.spacing.sm,
  },
  paginationDot: {
    backgroundColor: theme.colors.surfaceStrong,
    borderRadius: 4,
    height: 8,
    marginHorizontal: 4,
    width: 8,
  },
  paginationDotActive: {
    backgroundColor: theme.colors.accent,
    width: 20,
  },
  priceRibbon: {
    alignSelf: 'flex-start',
    backgroundColor: '#EFD9B8',
    borderRadius: theme.radius.pill,
    marginBottom: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  priceText: {
    color: theme.colors.accentDark,
    fontSize: 14,
    fontWeight: '900',
  },
  headerRow: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.sm,
  },
  headerLeft: {
    flex: 1,
    marginRight: theme.spacing.md,
  },
  title: {
    color: theme.colors.ink,
    fontSize: 30,
    fontWeight: '800',
    lineHeight: 36,
  },
  shareButton: {
    alignItems: 'center',
    backgroundColor: theme.colors.surfaceStrong,
    borderRadius: theme.radius.pill,
    height: 48,
    justifyContent: 'center',
    width: 48,
  },
  meta: {
    color: theme.colors.muted,
    fontSize: 14,
    marginBottom: theme.spacing.xs,
  },
  description: {
    color: theme.colors.ink,
    fontSize: 16,
    lineHeight: 24,
    marginBottom: theme.spacing.lg,
    marginTop: theme.spacing.sm,
  },
  button: {
    alignItems: 'center',
    backgroundColor: theme.colors.accent,
    borderRadius: theme.radius.md,
    paddingVertical: theme.spacing.md,
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '800',
  },
  emptyState: {
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
  emptyStateText: {
    color: theme.colors.muted,
    fontSize: 16,
    fontWeight: '700',
  },
});
