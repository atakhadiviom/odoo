import { config } from '../config';
import {
  AccountPayload,
  AddressSchema,
  CartPayload,
  CheckoutAddressInput,
  CheckoutResult,
  CheckoutState,
  DeliveryMethodsPayload,
  HomePayload,
  MobileProduct,
  OrdersPayload,
  PaymentOptionsPayload,
  PaymentSession,
  ProductListPayload,
} from '../types';

interface JsonRpcEnvelope<T> {
  result?: T;
  error?: {
    message?: string;
    data?: {
      message?: string;
    };
  };
}

const buildUrl = (path: string) => `${config.baseUrl}${path}`;

async function callJsonRpc<T>(
  path: string,
  params: Record<string, unknown> = {}
): Promise<T> {
  const response = await fetch(buildUrl(path), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    credentials: 'include',
    body: JSON.stringify({
      jsonrpc: '2.0',
      method: 'call',
      params,
      id: Date.now(),
    }),
  });

  const payload = (await response.json()) as JsonRpcEnvelope<T>;
  if (!response.ok || payload.error) {
    throw new Error(
      payload.error?.data?.message ||
        payload.error?.message ||
        `Request failed: ${response.status}`
    );
  }

  return payload.result as T;
}

export const odooApi = {
  authenticate(login: string, password: string) {
    return callJsonRpc('/web/session/authenticate', {
      db: config.db,
      login,
      password,
    });
  },

  logout() {
    return callJsonRpc('/web/session/destroy');
  },

  loginWithGoogle(idToken: string) {
    return callJsonRpc<AccountPayload>('/mobile_api/auth/google', {
      token: idToken,
    });
  },

  getHome() {
    return callJsonRpc<HomePayload>('/mobile_api/home');
  },

  listProducts(params: {
    search?: string;
    category_id?: number | null;
    limit?: number;
    offset?: number;
  }) {
    return callJsonRpc<ProductListPayload>('/mobile_api/products', {
      search: params.search || '',
      category_id: params.category_id || false,
      limit: params.limit || 20,
      offset: params.offset || 0,
    });
  },

  getProduct(product_tmpl_id: number) {
    return callJsonRpc<MobileProduct>('/mobile_api/product', { product_tmpl_id });
  },

  getCart() {
    return callJsonRpc<CartPayload>('/mobile_api/cart');
  },

  addToCart(product_id: number, quantity = 1) {
    return callJsonRpc<CartPayload>('/mobile_api/cart/add', {
      product_id,
      quantity,
    });
  },

  updateCartLine(line_id: number, quantity: number) {
    return callJsonRpc<CartPayload>('/mobile_api/cart/update', {
      line_id,
      quantity,
    });
  },

  getCheckoutState() {
    return callJsonRpc<CheckoutState>('/mobile_api/checkout/state');
  },

  getAddressSchema(params: {
    address_type: 'billing' | 'delivery';
    country_id?: number | null;
  }) {
    return callJsonRpc<AddressSchema>('/mobile_api/checkout/address_schema', {
      address_type: params.address_type,
      country_id: params.country_id || false,
    });
  },

  upsertCheckoutAddress(params: {
    values: CheckoutAddressInput;
    address_type: 'billing' | 'delivery';
    partner_id?: number | false;
    use_delivery_as_billing?: boolean;
  }) {
    return callJsonRpc<CheckoutState>('/mobile_api/checkout/address_upsert', {
      values: params.values,
      address_type: params.address_type,
      partner_id: params.partner_id || false,
      use_delivery_as_billing: Boolean(params.use_delivery_as_billing),
    });
  },

  getDeliveryMethods() {
    return callJsonRpc<DeliveryMethodsPayload>('/mobile_api/checkout/delivery_methods');
  },

  selectDeliveryMethod(carrier_id: number) {
    return callJsonRpc<CheckoutState>('/mobile_api/checkout/delivery_select', {
      carrier_id,
    });
  },

  getPaymentOptions() {
    return callJsonRpc<PaymentOptionsPayload>('/mobile_api/checkout/payment_options');
  },

  createPaymentSession(params: {
    provider_id?: number;
    payment_method_id?: number;
    return_url?: string;
  }) {
    return callJsonRpc<PaymentSession>('/mobile_api/checkout/payment_session', {
      provider_id: params.provider_id || false,
      payment_method_id: params.payment_method_id || false,
      return_url: params.return_url || config.returnUrl,
    });
  },

  getPaymentStatus(params: {
    order_id: number;
    access_token: string;
    tx_id?: number | false;
  }) {
    return callJsonRpc<CheckoutResult>('/mobile_api/checkout/payment_status', {
      order_id: params.order_id,
      access_token: params.access_token,
      tx_id: params.tx_id || false,
    });
  },

  getAccount() {
    return callJsonRpc<AccountPayload>('/mobile_api/account');
  },

  registerDevice(params: { token: string; platform: 'ios' | 'android' | 'web' }) {
    return callJsonRpc('/mobile_api/device/register', {
      token: params.token,
      platform: params.platform,
    });
  },

  getOrders() {
    return callJsonRpc<OrdersPayload>('/mobile_api/orders');
  },
};
