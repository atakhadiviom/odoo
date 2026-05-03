import React, { useState } from 'react';
import {
  Alert,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { GoogleSignin } from '@react-native-google-signin/google-signin';

import { useSession } from '../context/SessionContext';
import { theme } from '../theme';

export function AccountScreen() {
  const { account, loading, login, logout, refresh } = useSession();
  const [loginValue, setLoginValue] = useState('');
  const [password, setPassword] = useState('');

  const handleLogin = async () => {
    try {
      await login(loginValue, password);
      setPassword('');
    } catch (error) {
      Alert.alert('Login failed', (error as Error).message);
    }
  };

  if (!account) {
    return (
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Sign in</Text>
        <Text style={styles.copy}>
          Use your Odoo website customer account to sync orders and account details.
        </Text>
        <TextInput
          autoCapitalize="none"
          keyboardType="email-address"
          placeholder="Email"
          placeholderTextColor={theme.colors.muted}
          style={styles.input}
          value={loginValue}
          onChangeText={setLoginValue}
        />
        <TextInput
          placeholder="Password"
          placeholderTextColor={theme.colors.muted}
          secureTextEntry
          style={styles.input}
          value={password}
          onChangeText={setPassword}
        />
        <Pressable style={styles.primaryButton} onPress={handleLogin}>
          <Text style={styles.primaryButtonText}>
            {loading ? 'Signing in...' : 'Sign in'}
          </Text>
        </Pressable>
      </ScrollView>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.content}>
      <Text style={styles.title}>Account</Text>
      <View style={styles.profileCard}>
        <Text style={styles.profileName}>{account.partner.name}</Text>
        {!!account.partner.email && (
          <Text style={styles.profileMeta}>{account.partner.email}</Text>
        )}
        {!!account.partner.phone && (
          <Text style={styles.profileMeta}>{account.partner.phone}</Text>
        )}
      </View>

      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Recent orders</Text>
        <Pressable onPress={() => refresh()}>
          <Text style={styles.sectionAction}>Refresh</Text>
        </Pressable>
      </View>
      {account.orders.map((order) => (
        <View key={order.id} style={styles.orderCard}>
          <Text style={styles.orderName}>{order.name}</Text>
          <Text style={styles.orderMeta}>{order.state}</Text>
          <Text style={styles.orderMeta}>
            {order.currency} {order.amount_total.toFixed(2)}
          </Text>
          {!!order.date_order && (
            <Text style={styles.orderMeta}>
              {new Date(order.date_order).toLocaleDateString()}
            </Text>
          )}
        </View>
      ))}
      {!account.orders.length && (
        <Text style={styles.copy}>No website orders found for this account yet.</Text>
      )}

      <Pressable style={styles.secondaryButton} onPress={() => logout()}>
        <Text style={styles.secondaryButtonText}>
          {loading ? 'Signing out...' : 'Sign out'}
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
  title: {
    color: theme.colors.ink,
    fontSize: 28,
    fontWeight: '800',
    marginBottom: theme.spacing.sm,
  },
  copy: {
    color: theme.colors.muted,
    fontSize: 15,
    lineHeight: 22,
    marginBottom: theme.spacing.md,
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    color: theme.colors.ink,
    fontSize: 16,
    marginBottom: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.md,
  },
  primaryButton: {
    alignItems: 'center',
    backgroundColor: theme.colors.accent,
    borderRadius: theme.radius.md,
    paddingVertical: theme.spacing.md,
  },
  primaryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '800',
  },
  profileCard: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    marginBottom: theme.spacing.lg,
    padding: theme.spacing.lg,
  },
  profileName: {
    color: theme.colors.ink,
    fontSize: 24,
    fontWeight: '800',
    marginBottom: theme.spacing.xs,
  },
  profileMeta: {
    color: theme.colors.muted,
    fontSize: 14,
    marginBottom: theme.spacing.xs,
  },
  sectionHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md,
  },
  sectionTitle: {
    color: theme.colors.ink,
    fontSize: 20,
    fontWeight: '800',
  },
  sectionAction: {
    color: theme.colors.accent,
    fontSize: 14,
    fontWeight: '800',
  },
  orderCard: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    marginBottom: theme.spacing.sm,
    padding: theme.spacing.md,
  },
  orderName: {
    color: theme.colors.ink,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: theme.spacing.xs,
  },
  orderMeta: {
    color: theme.colors.muted,
    fontSize: 14,
    marginBottom: 2,
  },
  secondaryButton: {
    alignItems: 'center',
    borderColor: theme.colors.ink,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    marginTop: theme.spacing.lg,
    paddingVertical: theme.spacing.md,
  },
  secondaryButtonText: {
    color: theme.colors.ink,
    fontSize: 16,
    fontWeight: '800',
  },
});
