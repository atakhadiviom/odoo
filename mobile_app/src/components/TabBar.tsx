import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { theme } from '../theme';
import { AppTab } from '../types';

interface TabBarProps {
  activeTab: AppTab;
  onTabPress: (tab: AppTab) => void;
}

const tabs: Array<{ key: AppTab; label: string; icon: keyof typeof Ionicons.glyphMap }> = [
  { key: 'home', label: 'Home', icon: 'home-outline' },
  { key: 'shop', label: 'Shop', icon: 'storefront-outline' },
  { key: 'cart', label: 'Cart', icon: 'cart-outline' },
  { key: 'account', label: 'Account', icon: 'person-outline' },
];

const activeIcons: Record<AppTab, keyof typeof Ionicons.glyphMap> = {
  home: 'home',
  shop: 'storefront',
  cart: 'cart',
  account: 'person',
};

export function TabBar({ activeTab, onTabPress }: TabBarProps) {
  return (
    <View style={styles.bar}>
      {tabs.map((tab) => {
        const isActive = activeTab === tab.key;
        const iconName = isActive ? activeIcons[tab.key] : tab.icon;
        
        return (
          <Pressable
            key={tab.key}
            onPress={() => onTabPress(tab.key)}
            style={[
              styles.tab,
              isActive ? styles.tabActive : undefined,
            ]}
          >
            <Ionicons 
              name={iconName} 
              size={20} 
              color={isActive ? '#FFFFFF' : theme.colors.muted} 
            />
            <Text
              style={[
                styles.label,
                isActive ? styles.labelActive : undefined,
              ]}
            >
              {tab.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    flexDirection: 'row',
    margin: theme.spacing.md,
    padding: theme.spacing.xs,
    justifyContent: 'space-around',
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
  },
  tab: {
    alignItems: 'center',
    borderRadius: theme.radius.md,
    flex: 1,
    paddingVertical: theme.spacing.sm,
    gap: 4,
  },
  tabActive: {
    backgroundColor: theme.colors.ink,
  },
  label: {
    color: theme.colors.muted,
    fontSize: 10,
    fontWeight: '700',
  },
  labelActive: {
    color: '#FFFFFF',
  },
});
