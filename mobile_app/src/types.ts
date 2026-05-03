export type BannerActionKind = 'product' | 'category' | 'url';
export type AppTab = 'home' | 'shop' | 'cart' | 'account';
export type CheckoutStep = 'review' | 'address' | 'delivery' | 'payment' | 'result';
export type CheckoutStatus = 'pending' | 'success' | 'cancel' | 'error';

export interface MobileBanner {
  id: number;
  name: string;
  title: string;
  subtitle?: string;
  image_url: string;
  action_kind: BannerActionKind;
  product_tmpl_id?: number;
  category_id?: number;
  external_url?: string;
}

export interface MobileCategory {
  id: number;
  name: string;
  description?: string;
  image_url: string;
}

export interface MobileProduct {
  id: number;
  variant_id: number;
  name: string;
  default_code?: string;
  price: number;
  list_price: number;
  currency: string;
  description: string;
  short_description: string;
  image_url: string;
  extra_image_urls?: string[];
  website_url: string;
  category_ids: number[];
  category_names?: string[];
  checkout_url?: string;
}

export interface HomePayload {
  website: {
    id: number;
    name: string;
    currency: string;
    base_url: string;
  };
  banners: MobileBanner[];
  categories: MobileCategory[];
  featured_products: MobileProduct[];
}

export interface ProductListPayload {
  items: MobileProduct[];
  total: number;
  limit: number;
  offset: number;
}

export interface CartLine {
  id: number;
  product_tmpl_id: number;
  product_id: number;
  name: string;
  quantity: number;
  price_unit: number;
  subtotal: number;
  total: number;
  currency: string;
  image_url: string;
  is_delivery?: boolean;
}

export interface CartPayload {
  order_id: number | false;
  cart_quantity: number;
  amount_untaxed: number;
  amount_tax: number;
  amount_total: number;
  currency: string;
  checkout_url: string;
  requires_delivery: boolean;
  can_checkout: boolean;
  lines: CartLine[];
}

export interface PartnerSummary {
  id: number;
  name: string;
  email?: string;
  phone?: string;
}

export interface OrderSummary {
  id: number;
  name: string;
  date_order: string;
  state: string;
  amount_total: number;
  amount_tax: number;
  amount_untaxed: number;
  currency: string;
  lines: CartLine[];
}

export interface OrdersPayload {
  items: OrderSummary[];
  total: number;
}

export interface AccountPayload {
  partner: PartnerSummary;
  orders: OrderSummary[];
  orders_count: number;
}

export interface CheckoutError {
  title: string;
  message?: string;
  code?: string;
}

export interface CountryOption {
  id: number;
  name: string;
  code: string;
}

export interface StateOption {
  id: number;
  name: string;
  code?: string;
}

export interface PartnerAddress {
  id: number;
  name?: string;
  email?: string;
  phone?: string;
  street?: string;
  street2?: string;
  city?: string;
  zip?: string;
  country_id?: number;
  country_name?: string;
  state_id?: number;
  state_name?: string;
  company_name?: string;
  vat?: string;
}

export interface CheckoutAddressInput {
  name: string;
  email: string;
  phone: string;
  street: string;
  street2?: string;
  city: string;
  zip?: string;
  country_id: number | null;
  state_id?: number | null;
  company_name?: string;
  vat?: string;
}

export interface AddressSchema {
  address_type: 'billing' | 'delivery';
  selected_country_id: number | false;
  address_fields: string[];
  required_fields: string[];
  zip_before_city: boolean;
  phone_code: number | false;
  countries: CountryOption[];
  states: StateOption[];
}

export interface DeliveryMethod {
  id: number;
  name: string;
  amount: number;
  currency: string;
  selected: boolean;
}

export interface DeliveryMethodsPayload {
  items: DeliveryMethod[];
  selected_delivery_method: DeliveryMethod | false;
  order_id: number | false;
  amount_total: number;
  currency: string;
}

export interface PaymentOption {
  provider_id: number;
  provider_code: string;
  provider_name: string;
  payment_method_id: number;
  payment_method_code: string;
  payment_method_name: string;
  flow: 'redirect';
}

export interface PaymentOptionsPayload {
  items: PaymentOption[];
  errors: CheckoutError[];
  order_id: number | false;
  amount_total: number;
  currency: string;
}

export interface CheckoutState {
  order_id: number | false;
  order_name: string | false;
  access_token: string | false;
  login_required: boolean;
  is_authenticated: boolean;
  requires_delivery: boolean;
  payment_required: boolean;
  billing_complete: boolean;
  shipping_complete: boolean;
  billing_address: PartnerAddress | false;
  shipping_address: PartnerAddress | false;
  selected_delivery_method: DeliveryMethod | false;
  can_proceed_to_payment: boolean;
  can_finalize_without_payment: boolean;
  checkout_errors: CheckoutError[];
  cart: CartPayload;
  success?: boolean;
  partner_id?: number | false;
  invalid_fields?: string[];
  messages?: string[];
}

export interface PaymentSession {
  tx_id: number | false;
  order_id: number;
  payment_page_url: string | false;
  return_url: string;
  access_token: string;
  status: 'pending' | 'success';
}

export interface CheckoutResult {
  order_id: number | false;
  order_name: string | false;
  order_state: string | false;
  tx_id: number | false;
  tx_state: string | false;
  status: CheckoutStatus;
  access_token: string | false;
  message?: string | false;
}
