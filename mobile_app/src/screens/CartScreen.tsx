import React from 'react';
import {
  Alert,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { useCart } from '../context/CartContext';
import { theme } from '../theme';

interface CartScreenProps {
  onStartCheckout: () => void;
}

export function CartScreen({ onStartCheckout }: CartScreenProps) {
  const { cart, loading, updateQuantity, refreshCart } = useCart();
  const canCheckout = cart.can_checkout && cart.lines.length > 0;

  const mutateQuantity = async (lineId: number, quantity: number) => {
    try {
      await updateQuantity(lineId, quantity);
    } catch (error) {
      Alert.alert('Unable to update cart', (error as Error).message);
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.content}>
      <View style={styles.headerRow}>
        <Text style={styles.title}>Your cart</Text>
        <Pressable onPress={() => refreshCart()}>
          <Text style={styles.refresh}>Refresh</Text>
        </Pressable>
      </View>

      {!cart.lines.length && (
        <View style={styles.emptyCard}>
          <Text style={styles.emptyTitle}>Your cart is empty</Text>
          <Text style={styles.emptyCopy}>
            Add a few products from the Shop tab and they will show up here.
          </Text>
        </View>
      )}

      {cart.lines.map((line) => (
        <View key={line.id} style={styles.lineCard}>
          <Image source={{ uri: line.image_url }} style={styles.lineImage} />
          <View style={styles.lineBody}>
            <Text style={styles.lineName}>{line.name}</Text>
            <Text style={styles.linePrice}>
              {line.currency} {line.total.toFixed(2)}
            </Text>
            <View style={styles.quantityRow}>
              <Pressable
                style={styles.quantityButton}
                onPress={() => mutateQuantity(line.id, Math.max(0, line.quantity - 1))}
              >
                <Text style={styles.quantityLabel}>-</Text>
              </Pressable>
              <Text style={styles.quantityValue}>{line.quantity}</Text>
              <Pressable
                style={styles.quantityButton}
                onPress={() => mutateQuantity(line.id, line.quantity + 1)}
              >
                <Text style={styles.quantityLabel}>+</Text>
              </Pressable>
            </View>
          </View>
        </View>
      ))}

      <View style={styles.summaryCard}>
        <Text style={styles.summaryTitle}>Order summary</Text>
        <Text style={styles.summaryLine}>
          Subtotal: {cart.currency} {cart.amount_untaxed.toFixed(2)}
        </Text>
        <Text style={styles.summaryLine}>
          Tax: {cart.currency} {cart.amount_tax.toFixed(2)}
        </Text>
        <Text style={styles.summaryTotal}>
          Total: {cart.currency} {cart.amount_total.toFixed(2)}
        </Text>
        <Pressable
          style={[
            styles.checkoutButton,
            !canCheckout || loading ? styles.checkoutButtonDisabled : undefined,
          ]}
          onPress={() => {
            if (canCheckout) {
              onStartCheckout();
            }
          }}
        >
          <Text style={styles.checkoutButtonText}>
            {loading ? 'Updating cart...' : 'Continue to mobile checkout'}
          </Text>
        </Pressable>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: {
    padding: theme.spacing.md,
    paddingBottom: theme.spacing.xl,
  },
  headerRow: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md,
  },
  title: {
    color: theme.colors.ink,
    fontSize: 28,
    fontWeight: '800',
  },
  refresh: {
    color: theme.colors.accent,
    fontSize: 14,
    fontWeight: '800',
  },
  emptyCard: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    marginBottom: theme.spacing.md,
    padding: theme.spacing.lg,
  },
  emptyTitle: {
    color: theme.colors.ink,
    fontSize: 20,
    fontWeight: '800',
    marginBottom: theme.spacing.xs,
  },
  emptyCopy: {
    color: theme.colors.muted,
    fontSize: 15,
    lineHeight: 22,
  },
  lineCard: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    flexDirection: 'row',
    marginBottom: theme.spacing.md,
    overflow: 'hidden',
  },
  lineImage: {
    backgroundColor: theme.colors.surfaceStrong,
    height: 120,
    width: 120,
  },
  lineBody: {
    flex: 1,
    justifyContent: 'space-between',
    padding: theme.spacing.md,
  },
  lineName: {
    color: theme.colors.ink,
    fontSize: 16,
    fontWeight: '700',
  },
  linePrice: {
    color: theme.colors.accentDark,
    fontSize: 16,
    fontWeight: '800',
    marginVertical: theme.spacing.xs,
  },
  quantityRow: {
    alignItems: 'center',
    flexDirection: 'row',
  },
  quantityButton: {
    alignItems: 'center',
    backgroundColor: '#EFD9B8',
    borderRadius: theme.radius.pill,
    height: 34,
    justifyContent: 'center',
    width: 34,
  },
  quantityLabel: {
    color: theme.colors.accentDark,
    fontSize: 18,
    fontWeight: '900',
  },
  quantityValue: {
    color: theme.colors.ink,
    fontSize: 16,
    fontWeight: '700',
    marginHorizontal: theme.spacing.md,
  },
  summaryCard: {
    backgroundColor: theme.colors.ink,
    borderRadius: theme.radius.lg,
    padding: theme.spacing.lg,
  },
  summaryTitle: {
    color: '#FFFFFF',
    fontSize: 22,
    fontWeight: '800',
    marginBottom: theme.spacing.md,
  },
  summaryLine: {
    color: '#D9E1E5',
    fontSize: 15,
    marginBottom: theme.spacing.xs,
  },
  summaryTotal: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '900',
    marginBottom: theme.spacing.lg,
    marginTop: theme.spacing.sm,
  },
  checkoutButton: {
    alignItems: 'center',
    backgroundColor: theme.colors.accent,
    borderRadius: theme.radius.md,
    paddingVertical: theme.spacing.md,
  },
  checkoutButtonDisabled: {
    opacity: 0.7,
  },
  checkoutButtonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
});
