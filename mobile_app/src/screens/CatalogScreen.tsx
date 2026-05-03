import React, { useEffect, useState } from 'react';
import {
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { ProductCard } from '../components/ProductCard';
import { odooApi } from '../lib/odoo';
import { theme } from '../theme';
import { MobileCategory, MobileProduct } from '../types';

interface CatalogScreenProps {
  searchSeed: string;
  categorySeed: number | null;
  onSelectProduct: (productId: number) => void;
}

export function CatalogScreen({
  searchSeed,
  categorySeed,
  onSelectProduct,
}: CatalogScreenProps) {
  const [searchText, setSearchText] = useState(searchSeed);
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | null>(
    categorySeed
  );
  const [categories, setCategories] = useState<MobileCategory[]>([]);
  const [items, setItems] = useState<MobileProduct[]>([]);

  const loadProducts = async (searchValue = searchText, categoryId = selectedCategoryId) => {
    try {
      const payload = await odooApi.listProducts({
        search: searchValue,
        category_id: categoryId,
        limit: 24,
      });
      setItems(payload.items);
    } catch (error) {
      Alert.alert('Unable to load products', (error as Error).message);
    }
  };

  useEffect(() => {
    setSearchText(searchSeed);
    setSelectedCategoryId(categorySeed);
    loadProducts(searchSeed, categorySeed).catch(() => undefined);
  }, [searchSeed, categorySeed]);

  useEffect(() => {
    odooApi
      .getHome()
      .then((payload) => setCategories(payload.categories))
      .catch(() => setCategories([]));
  }, []);

  return (
    <ScrollView contentContainerStyle={styles.content}>
      <Text style={styles.title}>Shop the catalog</Text>
      <View style={styles.searchRow}>
        <TextInput
          placeholder="Search products"
          placeholderTextColor={theme.colors.muted}
          style={styles.searchInput}
          value={searchText}
          onChangeText={setSearchText}
          onSubmitEditing={() => loadProducts()}
        />
        <Pressable style={styles.searchButton} onPress={() => loadProducts()}>
          <Text style={styles.searchButtonText}>Search</Text>
        </Pressable>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <Pressable
          style={[
            styles.filterChip,
            selectedCategoryId === null ? styles.filterChipActive : undefined,
          ]}
          onPress={() => {
            setSelectedCategoryId(null);
            loadProducts(searchText, null).catch(() => undefined);
          }}
        >
          <Text
            style={[
              styles.filterChipText,
              selectedCategoryId === null ? styles.filterChipTextActive : undefined,
            ]}
          >
            All
          </Text>
        </Pressable>
        {categories.map((category) => (
          <Pressable
            key={category.id}
            style={[
              styles.filterChip,
              selectedCategoryId === category.id ? styles.filterChipActive : undefined,
            ]}
            onPress={() => {
              setSelectedCategoryId(category.id);
              loadProducts(searchText, category.id).catch(() => undefined);
            }}
          >
            <Text
              style={[
                styles.filterChipText,
                selectedCategoryId === category.id
                  ? styles.filterChipTextActive
                  : undefined,
              ]}
            >
              {category.name}
            </Text>
          </Pressable>
        ))}
      </ScrollView>

      <View style={styles.resultsHeader}>
        <Text style={styles.resultsTitle}>{items.length} products</Text>
      </View>
      {items.map((product) => (
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
  title: {
    color: theme.colors.ink,
    fontSize: 28,
    fontWeight: '800',
    marginBottom: theme.spacing.md,
  },
  searchRow: {
    flexDirection: 'row',
    marginBottom: theme.spacing.md,
  },
  searchInput: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    color: theme.colors.ink,
    flex: 1,
    fontSize: 16,
    marginRight: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  searchButton: {
    alignItems: 'center',
    backgroundColor: theme.colors.accent,
    borderRadius: theme.radius.md,
    justifyContent: 'center',
    paddingHorizontal: theme.spacing.md,
  },
  searchButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '800',
  },
  filterChip: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.pill,
    borderWidth: 1,
    marginBottom: theme.spacing.md,
    marginRight: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  filterChipActive: {
    backgroundColor: theme.colors.ink,
  },
  filterChipText: {
    color: theme.colors.ink,
    fontSize: 13,
    fontWeight: '700',
  },
  filterChipTextActive: {
    color: '#FFFFFF',
  },
  resultsHeader: {
    marginBottom: theme.spacing.sm,
  },
  resultsTitle: {
    color: theme.colors.muted,
    fontSize: 14,
    fontWeight: '700',
  },
});
