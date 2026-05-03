import { StatusBar } from 'expo-status-bar';
import * as Device from 'expo-device';
import * as Notifications from 'expo-notifications';
import React, { useEffect, useState } from 'react';
import {
  Linking,
  Platform,
  Pressable,
  SafeAreaView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { TabBar } from './src/components/TabBar';
import { CartProvider, useCart } from './src/context/CartContext';
import { SessionProvider } from './src/context/SessionContext';
import { config } from './src/config';
import { odooApi } from './src/lib/odoo';
import { AccountScreen } from './src/screens/AccountScreen';
import { CartScreen } from './src/screens/CartScreen';
import { CatalogScreen } from './src/screens/CatalogScreen';
import { CheckoutScreen } from './src/screens/CheckoutScreen';
import { HomeScreen } from './src/screens/HomeScreen';
import { ProductScreen } from './src/screens/ProductScreen';
import { theme } from './src/theme';
import { AppTab } from './src/types';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

async function registerForPushNotificationsAsync() {
  if (!Device.isDevice) {
    return null;
  }
  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;
  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }
  if (finalStatus !== 'granted') {
    return null;
  }
  
  // Get raw FCM/APNs token
  const token = (await Notifications.getDevicePushTokenAsync()).data;
  return token;
}

function MobileShell() {
  const [activeTab, setActiveTab] = useState<AppTab>('home');
  const [selectedProductId, setSelectedProductId] = useState<number | null>(null);
  
  useEffect(() => {
    registerForPushNotificationsAsync().then(token => {
      if (token) {
        odooApi.registerDevice({
          token,
          platform: Platform.OS as 'ios' | 'android',
        }).catch(err => console.warn('Failed to register device:', err));
      }
    });
  }, []);

  const [catalogSearch, setCatalogSearch] = useState('');
  const [catalogCategoryId, setCatalogCategoryId] = useState<number | null>(null);
  const [checkoutVisible, setCheckoutVisible] = useState(false);
  const [checkoutReturnUrl, setCheckoutReturnUrl] = useState<string | null>(null);
  const { cart } = useCart();

  useEffect(() => {
    const applyIncomingUrl = (url?: string | null) => {
      if (!url || !url.includes('checkout/result')) {
        return;
      }
      setCheckoutReturnUrl(url);
      setCheckoutVisible(true);
      setSelectedProductId(null);
      setActiveTab('cart');
    };

    Linking.getInitialURL()
      .then((url) => {
        applyIncomingUrl(url);
      })
      .catch(() => {
        setCheckoutReturnUrl(null);
      });

    const subscription = Linking.addEventListener('url', ({ url }) => {
      applyIncomingUrl(url);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  const openProduct = (productId: number) => {
    setSelectedProductId(productId);
    setCheckoutVisible(false);
  };

  const openCategory = (categoryId: number) => {
    setCatalogCategoryId(categoryId);
    setCatalogSearch('');
    setSelectedProductId(null);
    setCheckoutVisible(false);
    setActiveTab('shop');
  };

  const renderContent = () => {
    if (checkoutVisible) {
      return (
        <CheckoutScreen
          incomingResultUrl={checkoutReturnUrl}
          onIncomingResultHandled={() => setCheckoutReturnUrl(null)}
          onGoToAccount={() => {
            setCheckoutVisible(false);
            setCheckoutReturnUrl(null);
            setActiveTab('account');
          }}
        />
      );
    }

    if (selectedProductId) {
      return <ProductScreen productId={selectedProductId} />;
    }

    if (activeTab === 'shop') {
      return (
        <CatalogScreen
          searchSeed={catalogSearch}
          categorySeed={catalogCategoryId}
          onSelectProduct={openProduct}
        />
      );
    }

    if (activeTab === 'cart') {
      return (
        <CartScreen
          onStartCheckout={() => {
            setCheckoutVisible(true);
            setSelectedProductId(null);
            setCheckoutReturnUrl(null);
          }}
        />
      );
    }

    if (activeTab === 'account') {
      return <AccountScreen />;
    }

    return (
      <HomeScreen
        onSelectProduct={openProduct}
        onOpenCategory={openCategory}
      />
    );
  };

  const showingDetail = checkoutVisible || Boolean(selectedProductId);

  return (
    <SafeAreaView style={styles.shell}>
      <StatusBar style="dark" />
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          {showingDetail ? (
            <Pressable
              style={styles.backButton}
              onPress={() => {
                if (checkoutVisible) {
                  setCheckoutVisible(false);
                  setCheckoutReturnUrl(null);
                  return;
                }
                setSelectedProductId(null);
              }}
            >
              <Text style={styles.backButtonText}>Back</Text>
            </Pressable>
          ) : (
            <>
              <Text style={styles.brand}>Syntho Shop</Text>
              <Text style={styles.host}>
                {config.baseUrl.replace(/^https?:\/\//, '')}
              </Text>
            </>
          )}
        </View>
        {!showingDetail && (
          <Pressable
            style={styles.cartBadge}
            onPress={() => {
              setActiveTab('cart');
              setSelectedProductId(null);
            }}
          >
            <Text style={styles.cartBadgeText}>{Math.round(cart.cart_quantity)}</Text>
          </Pressable>
        )}
      </View>

      <View style={styles.content}>{renderContent()}</View>

      {!showingDetail && (
        <TabBar
          activeTab={activeTab}
          onTabPress={(tab) => {
            setActiveTab(tab);
            setSelectedProductId(null);
            setCheckoutVisible(false);
          }}
        />
      )}
    </SafeAreaView>
  );
}

export default function App() {
  return (
    <SessionProvider>
      <CartProvider>
        <MobileShell />
      </CartProvider>
    </SessionProvider>
  );
}

const styles = StyleSheet.create({
  shell: {
    backgroundColor: theme.colors.background,
    flex: 1,
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingTop: theme.spacing.sm,
  },
  headerLeft: {
    flex: 1,
  },
  brand: {
    color: theme.colors.ink,
    fontSize: 24,
    fontWeight: '900',
  },
  host: {
    color: theme.colors.muted,
    fontSize: 12,
    marginTop: 2,
  },
  backButton: {
    alignSelf: 'flex-start',
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.pill,
    borderWidth: 1,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  backButtonText: {
    color: theme.colors.ink,
    fontSize: 14,
    fontWeight: '800',
  },
  cartBadge: {
    alignItems: 'center',
    backgroundColor: theme.colors.accent,
    borderRadius: theme.radius.pill,
    height: 40,
    justifyContent: 'center',
    width: 40,
  },
  cartBadgeText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '900',
  },
  content: {
    flex: 1,
  },
});
