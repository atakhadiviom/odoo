import React, { createContext, useContext, useEffect, useState } from 'react';

import { odooApi } from '../lib/odoo';
import { CartPayload } from '../types';

const emptyCart: CartPayload = {
  order_id: false,
  cart_quantity: 0,
  amount_untaxed: 0,
  amount_tax: 0,
  amount_total: 0,
  currency: 'USD',
  checkout_url: '',
  requires_delivery: false,
  can_checkout: false,
  lines: [],
};

interface CartContextValue {
  cart: CartPayload;
  loading: boolean;
  refreshCart: () => Promise<void>;
  addToCart: (productId: number, quantity?: number) => Promise<void>;
  updateQuantity: (lineId: number, quantity: number) => Promise<void>;
}

const CartContext = createContext<CartContextValue | undefined>(undefined);

export function CartProvider({ children }: React.PropsWithChildren) {
  const [cart, setCart] = useState<CartPayload>(emptyCart);
  const [loading, setLoading] = useState(false);

  const refreshCart = async () => {
    setLoading(true);
    try {
      setCart(await odooApi.getCart());
    } finally {
      setLoading(false);
    }
  };

  const addToCart = async (productId: number, quantity = 1) => {
    setLoading(true);
    try {
      setCart(await odooApi.addToCart(productId, quantity));
    } finally {
      setLoading(false);
    }
  };

  const updateQuantity = async (lineId: number, quantity: number) => {
    setLoading(true);
    try {
      setCart(await odooApi.updateCartLine(lineId, quantity));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    refreshCart().catch(() => {
      setCart(emptyCart);
    });
  }, []);

  return (
    <CartContext.Provider
      value={{ cart, loading, refreshCart, addToCart, updateQuantity }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within CartProvider');
  }
  return context;
}
