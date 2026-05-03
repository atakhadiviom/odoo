import React from 'react';
import {
  Image,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { MobileProduct } from '../types';
import { theme } from '../theme';

interface ProductCardProps {
  product: MobileProduct;
  onPress: (productId: number) => void;
}

export function ProductCard({ product, onPress }: ProductCardProps) {
  return (
    <Pressable style={styles.card} onPress={() => onPress(product.id)}>
      <Image source={{ uri: product.image_url }} style={styles.image} />
      <Text style={styles.name}>{product.name}</Text>
      <Text style={styles.description} numberOfLines={2}>
        {product.short_description}
      </Text>
      <View style={styles.footer}>
        <Text style={styles.price}>
          {product.currency} {product.price.toFixed(2)}
        </Text>
        <Text style={styles.chevron}>View</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    borderColor: theme.colors.line,
    marginBottom: theme.spacing.md,
    overflow: 'hidden',
  },
  image: {
    width: '100%',
    height: 160,
    backgroundColor: theme.colors.surfaceStrong,
  },
  name: {
    color: theme.colors.ink,
    fontSize: 18,
    fontWeight: '700',
    paddingHorizontal: theme.spacing.md,
    paddingTop: theme.spacing.md,
  },
  description: {
    color: theme.colors.muted,
    fontSize: 14,
    lineHeight: 20,
    paddingHorizontal: theme.spacing.md,
    paddingTop: theme.spacing.xs,
  },
  footer: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: theme.spacing.md,
  },
  price: {
    color: theme.colors.accentDark,
    fontSize: 16,
    fontWeight: '800',
  },
  chevron: {
    color: theme.colors.accent,
    fontSize: 14,
    fontWeight: '700',
  },
});
