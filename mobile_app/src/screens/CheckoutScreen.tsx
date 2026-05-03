import * as WebBrowser from 'expo-web-browser';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Alert,
  AppState,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { config } from '../config';
import { useCart } from '../context/CartContext';
import { useSession } from '../context/SessionContext';
import { odooApi } from '../lib/odoo';
import { theme } from '../theme';
import {
  AddressSchema,
  CheckoutAddressInput,
  CheckoutError,
  CheckoutResult,
  CheckoutState,
  CheckoutStatus,
  CheckoutStep,
  DeliveryMethod,
  DeliveryMethodsPayload,
  PartnerAddress,
  PaymentOptionsPayload,
  PaymentSession,
} from '../types';

WebBrowser.maybeCompleteAuthSession();

interface CheckoutScreenProps {
  incomingResultUrl?: string | null;
  onIncomingResultHandled?: () => void;
  onGoToAccount: () => void;
}

interface SelectOption {
  label: string;
  value: number;
}

interface OptionPickerProps {
  label: string;
  placeholder: string;
  options: SelectOption[];
  required?: boolean;
  value: number | null | undefined;
  onChange: (value: number) => void;
  invalid?: boolean;
}

const EMPTY_ADDRESS: CheckoutAddressInput = {
  name: '',
  email: '',
  phone: '',
  street: '',
  street2: '',
  city: '',
  zip: '',
  country_id: null,
  state_id: null,
  company_name: '',
  vat: '',
};

const STEP_LABELS: Record<CheckoutStep, string> = {
  review: 'Review',
  address: 'Address',
  delivery: 'Delivery',
  payment: 'Payment',
  result: 'Result',
};

function formatMoney(currency: string, amount: number) {
  return `${currency} ${amount.toFixed(2)}`;
}

function buildAddressInput(address: PartnerAddress | false): CheckoutAddressInput {
  if (!address) {
    return EMPTY_ADDRESS;
  }

  return {
    name: address.name || '',
    email: address.email || '',
    phone: address.phone || '',
    street: address.street || '',
    street2: address.street2 || '',
    city: address.city || '',
    zip: address.zip || '',
    country_id: address.country_id || null,
    state_id: address.state_id || null,
    company_name: address.company_name || '',
    vat: address.vat || '',
  };
}

function areAddressesEquivalent(
  billing: PartnerAddress | false,
  shipping: PartnerAddress | false
) {
  if (!billing || !shipping) {
    return true;
  }

  return [
    'name',
    'email',
    'phone',
    'street',
    'street2',
    'city',
    'zip',
    'country_id',
    'state_id',
    'company_name',
    'vat',
  ].every((fieldName) => {
    const left = billing[fieldName as keyof PartnerAddress] || '';
    const right = shipping[fieldName as keyof PartnerAddress] || '';
    return left === right;
  });
}

function getResultTone(status: CheckoutStatus) {
  if (status === 'success') {
    return theme.colors.success;
  }
  if (status === 'pending') {
    return '#9A6A15';
  }
  return theme.colors.accentDark;
}

function getErrorMessage(errors: CheckoutError[]) {
  return errors.map((item) => item.message || item.title).join('\n');
}

function formatFieldLabel(fieldName: string) {
  const labels: Record<string, string> = {
    name: 'Full name',
    email: 'Email',
    phone: 'Phone',
    street: 'Street',
    street2: 'Apartment, suite, etc.',
    city: 'City',
    zip: 'ZIP code',
    country_id: 'Country',
    state_id: 'State / Region',
    company_name: 'Company',
    vat: 'VAT / Tax ID',
  };
  return labels[fieldName] || fieldName;
}

function OptionPicker({
  label,
  placeholder,
  options,
  required,
  value,
  onChange,
  invalid,
}: OptionPickerProps) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const selectedLabel =
    options.find((option) => option.value === value)?.label || placeholder;
  const filteredOptions = useMemo(() => {
    if (!query.trim()) {
      return options;
    }
    const search = query.trim().toLowerCase();
    return options.filter((option) =>
      option.label.toLowerCase().includes(search)
    );
  }, [options, query]);

  return (
    <View style={styles.fieldGroup}>
      <Text style={styles.fieldLabel}>
        {label}
        {required ? ' *' : ''}
      </Text>
      <Pressable
        style={[styles.selectField, invalid ? styles.fieldInvalid : undefined]}
        onPress={() => setOpen(true)}
      >
        <Text
          style={[
            styles.selectFieldText,
            !value ? styles.selectFieldPlaceholder : undefined,
          ]}
        >
          {selectedLabel}
        </Text>
      </Pressable>

      <Modal
        animationType="slide"
        transparent
        visible={open}
        onRequestClose={() => setOpen(false)}
      >
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>{label}</Text>
              <Pressable onPress={() => setOpen(false)}>
                <Text style={styles.modalAction}>Close</Text>
              </Pressable>
            </View>
            <TextInput
              placeholder={`Search ${label.toLowerCase()}`}
              placeholderTextColor={theme.colors.muted}
              style={styles.input}
              value={query}
              onChangeText={setQuery}
            />
            <ScrollView style={styles.modalList}>
              {filteredOptions.map((option) => (
                <Pressable
                  key={`${label}-${option.value}`}
                  style={styles.modalOption}
                  onPress={() => {
                    onChange(option.value);
                    setOpen(false);
                    setQuery('');
                  }}
                >
                  <Text style={styles.modalOptionText}>{option.label}</Text>
                </Pressable>
              ))}
              {!filteredOptions.length && (
                <Text style={styles.modalEmpty}>No matches found.</Text>
              )}
            </ScrollView>
          </View>
        </View>
      </Modal>
    </View>
  );
}

export function CheckoutScreen({
  incomingResultUrl,
  onIncomingResultHandled,
  onGoToAccount,
}: CheckoutScreenProps) {
  const { refreshCart } = useCart();
  const { refresh: refreshSession } = useSession();

  const [step, setStep] = useState<CheckoutStep>('review');
  const [checkoutState, setCheckoutState] = useState<CheckoutState | null>(null);
  const [billingSchema, setBillingSchema] = useState<AddressSchema | null>(null);
  const [shippingSchema, setShippingSchema] = useState<AddressSchema | null>(null);
  const [deliveryPayload, setDeliveryPayload] = useState<DeliveryMethodsPayload | null>(
    null
  );
  const [paymentOptions, setPaymentOptions] = useState<PaymentOptionsPayload | null>(
    null
  );
  const [billingForm, setBillingForm] = useState<CheckoutAddressInput>(EMPTY_ADDRESS);
  const [shippingForm, setShippingForm] = useState<CheckoutAddressInput>(EMPTY_ADDRESS);
  const [useBillingForShipping, setUseBillingForShipping] = useState(true);
  const [selectedPaymentKey, setSelectedPaymentKey] = useState<string | null>(null);
  const [result, setResult] = useState<CheckoutResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [savingAddress, setSavingAddress] = useState(false);
  const [savingDelivery, setSavingDelivery] = useState(false);
  const [startingPayment, setStartingPayment] = useState(false);
  const [checkingStatus, setCheckingStatus] = useState(false);

  const pendingPaymentRef = useRef<PaymentSession | null>(null);
  const handledUrlRef = useRef<string | null>(null);

  const invalidFields = new Set(checkoutState?.invalid_fields || []);
  const activeDeliveryMethodId =
    deliveryPayload?.selected_delivery_method?.id ||
    checkoutState?.selected_delivery_method?.id ||
    null;

  const hydrateFromState = useCallback((state: CheckoutState) => {
    const sameAddress =
      !state.requires_delivery ||
      areAddressesEquivalent(state.billing_address, state.shipping_address);

    setCheckoutState(state);
    setBillingForm(buildAddressInput(state.billing_address));
    setShippingForm(buildAddressInput(state.shipping_address || state.billing_address));
    setUseBillingForShipping(sameAddress);
  }, []);

  const loadBillingSchema = useCallback(
    async (countryId?: number | null) => {
      const schema = await odooApi.getAddressSchema({
        address_type: 'billing',
        country_id: countryId || undefined,
      });
      setBillingSchema(schema);
      if (
        billingForm.state_id &&
        !schema.states.some((item) => item.id === billingForm.state_id)
      ) {
        setBillingForm((current) => ({ ...current, state_id: null }));
      }
    },
    [billingForm.state_id]
  );

  const loadShippingSchema = useCallback(
    async (countryId?: number | null) => {
      const schema = await odooApi.getAddressSchema({
        address_type: 'delivery',
        country_id: countryId || undefined,
      });
      setShippingSchema(schema);
      if (
        shippingForm.state_id &&
        !schema.states.some((item) => item.id === shippingForm.state_id)
      ) {
        setShippingForm((current) => ({ ...current, state_id: null }));
      }
    },
    [shippingForm.state_id]
  );

  const loadCheckoutState = useCallback(async () => {
    setLoading(true);
    try {
      const state = await odooApi.getCheckoutState();
      hydrateFromState(state);
    } catch (error) {
      Alert.alert('Unable to load checkout', (error as Error).message);
    } finally {
      setLoading(false);
    }
  }, [hydrateFromState]);

  const loadDeliveryMethods = useCallback(async () => {
    try {
      const payload = await odooApi.getDeliveryMethods();
      setDeliveryPayload(payload);
    } catch (error) {
      Alert.alert('Unable to load delivery methods', (error as Error).message);
    }
  }, []);

  const loadPaymentOptions = useCallback(async () => {
    try {
      const payload = await odooApi.getPaymentOptions();
      setPaymentOptions(payload);
      setSelectedPaymentKey((current) => {
        const stillSelected = payload.items.find(
          (item) =>
            `${item.provider_id}:${item.payment_method_id}` === current
        );
        if (stillSelected) {
          return current;
        }
        const firstItem = payload.items[0];
        return firstItem
          ? `${firstItem.provider_id}:${firstItem.payment_method_id}`
          : null;
      });
    } catch (error) {
      Alert.alert('Unable to load payment options', (error as Error).message);
    }
  }, []);

  const resolvePaymentStatus = useCallback(
    async (session: {
      order_id: number;
      access_token: string;
      tx_id?: number | false;
    }) => {
      setCheckingStatus(true);
      try {
        const status = await odooApi.getPaymentStatus({
          order_id: session.order_id,
          access_token: session.access_token,
          tx_id: session.tx_id || false,
        });
        setResult(status);
        setStep('result');
        if (status.status === 'success') {
          pendingPaymentRef.current = null;
          await Promise.all([refreshCart(), refreshSession()]);
          await loadCheckoutState();
        } else if (status.status === 'pending') {
          pendingPaymentRef.current = {
            tx_id: status.tx_id || session.tx_id || false,
            order_id: session.order_id,
            access_token: session.access_token,
            payment_page_url: false,
            return_url: config.returnUrl,
            status: 'pending',
          };
        } else {
          pendingPaymentRef.current = null;
          await refreshCart();
        }
      } catch (error) {
        Alert.alert('Unable to verify payment', (error as Error).message);
      } finally {
        setCheckingStatus(false);
      }
    },
    [loadCheckoutState, refreshCart, refreshSession]
  );

  const handleIncomingResultUrl = useCallback(
    async (url: string, fallbackSession?: PaymentSession | null) => {
      if (!url || handledUrlRef.current === url) {
        return;
      }
      handledUrlRef.current = url;

      const queryString = url.split('?')[1] || '';
      const params = new URLSearchParams(queryString);
      const orderId = Number(
        params.get('order_id') || fallbackSession?.order_id || 0
      );
      const accessToken =
        params.get('access_token') || fallbackSession?.access_token || '';
      const txIdValue = params.get('tx_id');
      const txId = txIdValue
        ? Number(txIdValue)
        : fallbackSession?.tx_id || false;

      if (!orderId || !accessToken) {
        return;
      }

      await resolvePaymentStatus({
        order_id: orderId,
        access_token: accessToken,
        tx_id: txId,
      });
    },
    [resolvePaymentStatus]
  );

  useEffect(() => {
    loadCheckoutState().catch(() => {
      // Alert handling lives in loadCheckoutState.
    });
  }, [loadCheckoutState]);

  useEffect(() => {
    if (!checkoutState) {
      return;
    }
    loadBillingSchema(billingForm.country_id || undefined).catch((error: Error) => {
      Alert.alert('Unable to load billing countries', error.message);
    });
  }, [billingForm.country_id, checkoutState, loadBillingSchema]);

  useEffect(() => {
    if (!checkoutState?.requires_delivery || useBillingForShipping) {
      return;
    }
    loadShippingSchema(shippingForm.country_id || undefined).catch((error: Error) => {
      Alert.alert('Unable to load shipping regions', error.message);
    });
  }, [
    checkoutState?.requires_delivery,
    loadShippingSchema,
    shippingForm.country_id,
    useBillingForShipping,
  ]);

  useEffect(() => {
    if (!incomingResultUrl) {
      return;
    }
    handleIncomingResultUrl(incomingResultUrl, pendingPaymentRef.current)
      .catch((error: Error) => {
        Alert.alert('Unable to handle payment return', error.message);
      })
      .finally(() => {
        onIncomingResultHandled?.();
      });
  }, [handleIncomingResultUrl, incomingResultUrl, onIncomingResultHandled]);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', (nextState) => {
      if (nextState === 'active' && pendingPaymentRef.current) {
        resolvePaymentStatus({
          order_id: pendingPaymentRef.current.order_id,
          access_token: pendingPaymentRef.current.access_token,
          tx_id: pendingPaymentRef.current.tx_id,
        }).catch(() => {
          // Alert handling lives in resolvePaymentStatus.
        });
      }
    });

    return () => {
      subscription.remove();
    };
  }, [resolvePaymentStatus]);

  const billingCountryOptions = useMemo<SelectOption[]>(
    () =>
      (billingSchema?.countries || []).map((country) => ({
        label: country.name,
        value: country.id,
      })),
    [billingSchema]
  );

  const billingStateOptions = useMemo<SelectOption[]>(
    () =>
      (billingSchema?.states || []).map((state) => ({
        label: state.name,
        value: state.id,
      })),
    [billingSchema]
  );

  const shippingCountryOptions = useMemo<SelectOption[]>(
    () =>
      (shippingSchema?.countries || []).map((country) => ({
        label: country.name,
        value: country.id,
      })),
    [shippingSchema]
  );

  const shippingStateOptions = useMemo<SelectOption[]>(
    () =>
      (shippingSchema?.states || []).map((state) => ({
        label: state.name,
        value: state.id,
      })),
    [shippingSchema]
  );

  const selectedPaymentOption = useMemo(() => {
    return (
      paymentOptions?.items.find(
        (item) =>
          `${item.provider_id}:${item.payment_method_id}` === selectedPaymentKey
      ) || null
    );
  }, [paymentOptions?.items, selectedPaymentKey]);

  const setBillingField = <K extends keyof CheckoutAddressInput>(
    field: K,
    value: CheckoutAddressInput[K]
  ) => {
    setBillingForm((current) => ({ ...current, [field]: value }));
  };

  const setShippingField = <K extends keyof CheckoutAddressInput>(
    field: K,
    value: CheckoutAddressInput[K]
  ) => {
    setShippingForm((current) => ({ ...current, [field]: value }));
  };

  const handleSaveAddresses = async () => {
    if (!checkoutState) {
      return;
    }
    setSavingAddress(true);
    try {
      let nextState = await odooApi.upsertCheckoutAddress({
        values: billingForm,
        address_type: 'billing',
        partner_id: checkoutState.billing_address?.id || false,
        use_delivery_as_billing:
          checkoutState.requires_delivery && useBillingForShipping,
      });
      hydrateFromState(nextState);

      if (!nextState.success) {
        Alert.alert(
          'Address needs attention',
          (nextState.messages || []).join('\n') || 'Please update the highlighted fields.'
        );
        return;
      }

      if (nextState.requires_delivery && !useBillingForShipping) {
        nextState = await odooApi.upsertCheckoutAddress({
          values: shippingForm,
          address_type: 'delivery',
          partner_id: nextState.shipping_address?.id || false,
          use_delivery_as_billing: false,
        });
        hydrateFromState(nextState);
        if (!nextState.success) {
          Alert.alert(
            'Shipping address needs attention',
            (nextState.messages || []).join('\n') || 'Please review the shipping fields.'
          );
          return;
        }
      }

      await refreshCart();
      if (nextState.requires_delivery) {
        await loadDeliveryMethods();
        setStep('delivery');
      } else if (nextState.payment_required) {
        await loadPaymentOptions();
        setStep('payment');
      } else {
        const session = await odooApi.createPaymentSession({
          return_url: config.returnUrl,
        });
        await resolvePaymentStatus({
          order_id: session.order_id,
          access_token: session.access_token,
          tx_id: session.tx_id,
        });
      }
    } catch (error) {
      Alert.alert('Unable to save address', (error as Error).message);
    } finally {
      setSavingAddress(false);
    }
  };

  const handleSelectDeliveryMethod = async (method: DeliveryMethod) => {
    setSavingDelivery(true);
    try {
      const nextState = await odooApi.selectDeliveryMethod(method.id);
      hydrateFromState(nextState);
      await Promise.all([refreshCart(), loadDeliveryMethods()]);
    } catch (error) {
      Alert.alert('Unable to update delivery', (error as Error).message);
    } finally {
      setSavingDelivery(false);
    }
  };

  const handleContinueFromDelivery = async () => {
    if (!checkoutState) {
      return;
    }
    if (
      checkoutState.requires_delivery &&
      !checkoutState.selected_delivery_method &&
      !activeDeliveryMethodId
    ) {
      Alert.alert(
        'Choose a delivery method',
        'Pick a shipping option before moving to payment.'
      );
      return;
    }

    if (checkoutState.payment_required) {
      await loadPaymentOptions();
      setStep('payment');
      return;
    }

    try {
      setStartingPayment(true);
      const session = await odooApi.createPaymentSession({
        return_url: config.returnUrl,
      });
      await resolvePaymentStatus({
        order_id: session.order_id,
        access_token: session.access_token,
        tx_id: session.tx_id,
      });
    } catch (error) {
      Alert.alert('Unable to place order', (error as Error).message);
    } finally {
      setStartingPayment(false);
    }
  };

  const handleStartPayment = async () => {
    if (!selectedPaymentOption) {
      Alert.alert(
        'Select a payment method',
        'Choose a payment option before continuing.'
      );
      return;
    }

    setStartingPayment(true);
    try {
      const session = await odooApi.createPaymentSession({
        provider_id: selectedPaymentOption.provider_id,
        payment_method_id: selectedPaymentOption.payment_method_id,
        return_url: config.returnUrl,
      });

      if (session.status === 'success' || !session.payment_page_url) {
        await resolvePaymentStatus({
          order_id: session.order_id,
          access_token: session.access_token,
          tx_id: session.tx_id,
        });
        return;
      }

      pendingPaymentRef.current = session;
      const browserResult = await WebBrowser.openAuthSessionAsync(
        session.payment_page_url,
        session.return_url
      );

      if (browserResult.type === 'success' && 'url' in browserResult) {
        await handleIncomingResultUrl(browserResult.url, session);
      } else {
        await resolvePaymentStatus({
          order_id: session.order_id,
          access_token: session.access_token,
          tx_id: session.tx_id,
        });
      }
    } catch (error) {
      Alert.alert('Unable to start payment', (error as Error).message);
    } finally {
      setStartingPayment(false);
    }
  };

  const renderTextField = (
    label: string,
    value: string,
    onChange: (nextValue: string) => void,
    options?: {
      required?: boolean;
      invalid?: boolean;
      keyboardType?: 'default' | 'email-address' | 'phone-pad' | 'numeric';
      autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
      multiline?: boolean;
    }
  ) => (
    <View style={styles.fieldGroup}>
      <Text style={styles.fieldLabel}>
        {label}
        {options?.required ? ' *' : ''}
      </Text>
      <TextInput
        autoCapitalize={options?.autoCapitalize || 'sentences'}
        keyboardType={options?.keyboardType || 'default'}
        multiline={options?.multiline}
        placeholder={label}
        placeholderTextColor={theme.colors.muted}
        style={[styles.input, options?.invalid ? styles.fieldInvalid : undefined]}
        value={value}
        onChangeText={onChange}
      />
    </View>
  );

  const renderAddressForm = (
    title: string,
    form: CheckoutAddressInput,
    schema: AddressSchema | null,
    setField: <K extends keyof CheckoutAddressInput>(
      field: K,
      value: CheckoutAddressInput[K]
    ) => void,
    options: {
      countryOptions: SelectOption[];
      stateOptions: SelectOption[];
    }
  ) => {
    const requiredFields = new Set(schema?.required_fields || []);
    const orderedCityFields = schema?.zip_before_city
      ? (['zip', 'city'] as const)
      : (['city', 'zip'] as const);
    const showStreet2 = schema?.address_fields.includes('street2') ?? true;
    const showState =
      Boolean(options.stateOptions.length) || requiredFields.has('state_id');

    return (
      <View style={styles.addressCard}>
        <Text style={styles.sectionTitle}>{title}</Text>
        {renderTextField(
          formatFieldLabel('name'),
          form.name,
          (value) => setField('name', value),
          {
            required: true,
            invalid: invalidFields.has('name'),
            autoCapitalize: 'words',
          }
        )}
        {renderTextField(
          formatFieldLabel('email'),
          form.email,
          (value) => setField('email', value),
          {
            required: true,
            invalid: invalidFields.has('email'),
            keyboardType: 'email-address',
            autoCapitalize: 'none',
          }
        )}
        {renderTextField(
          formatFieldLabel('phone'),
          form.phone,
          (value) => setField('phone', value),
          {
            required: true,
            invalid: invalidFields.has('phone'),
            keyboardType: 'phone-pad',
          }
        )}
        {renderTextField(
          formatFieldLabel('company_name'),
          form.company_name || '',
          (value) => setField('company_name', value)
        )}
        {renderTextField(
          formatFieldLabel('vat'),
          form.vat || '',
          (value) => setField('vat', value),
          {
            autoCapitalize: 'characters',
            invalid: invalidFields.has('vat'),
          }
        )}
        {renderTextField(
          formatFieldLabel('street'),
          form.street,
          (value) => setField('street', value),
          {
            required: requiredFields.has('street'),
            invalid: invalidFields.has('street'),
          }
        )}
        {showStreet2 &&
          renderTextField(
            formatFieldLabel('street2'),
            form.street2 || '',
            (value) => setField('street2', value)
          )}
        {orderedCityFields.map((fieldName) =>
          renderTextField(
            formatFieldLabel(fieldName),
            (form[fieldName] as string) || '',
            (value) => setField(fieldName, value),
            {
              required: requiredFields.has(fieldName),
              invalid: invalidFields.has(fieldName),
            }
          )
        )}
        <OptionPicker
          label={formatFieldLabel('country_id')}
          placeholder="Choose a country"
          options={options.countryOptions}
          required={requiredFields.has('country_id')}
          value={form.country_id}
          invalid={invalidFields.has('country_id')}
          onChange={(value) => {
            setField('country_id', value);
            setField('state_id', null);
          }}
        />
        {showState && (
          <OptionPicker
            label={formatFieldLabel('state_id')}
            placeholder="Choose a state"
            options={options.stateOptions}
            required={requiredFields.has('state_id')}
            value={form.state_id}
            invalid={invalidFields.has('state_id')}
            onChange={(value) => setField('state_id', value)}
          />
        )}
      </View>
    );
  };

  const stepOrder = useMemo<CheckoutStep[]>(() => {
    return ['review', 'address', 'delivery', 'payment', 'result'].filter((item) => {
      if (item === 'delivery') {
        return checkoutState?.requires_delivery ?? true;
      }
      return true;
    });
  }, [checkoutState?.requires_delivery]);

  if (loading && !checkoutState) {
    return (
      <View style={styles.emptyState}>
        <Text style={styles.emptyTitle}>Loading checkout...</Text>
      </View>
    );
  }

  if (!checkoutState || !checkoutState.order_id) {
    return (
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Checkout</Text>
        <View style={styles.emptyCard}>
          <Text style={styles.emptyTitle}>Your cart is not ready yet</Text>
          <Text style={styles.emptyCopy}>
            Add products from the shop first, then come back here to complete checkout.
          </Text>
        </View>
      </ScrollView>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.content}>
      <Text style={styles.title}>Checkout</Text>
      <Text style={styles.copy}>
        Order {checkoutState.order_name} for {formatMoney(
          checkoutState.cart.currency,
          checkoutState.cart.amount_total
        )}
      </Text>

      <View style={styles.stepRow}>
        {stepOrder.map((item) => (
          <View
            key={item}
            style={[
              styles.stepPill,
              item === step ? styles.stepPillActive : undefined,
            ]}
          >
            <Text
              style={[
                styles.stepPillText,
                item === step ? styles.stepPillTextActive : undefined,
              ]}
            >
              {STEP_LABELS[item]}
            </Text>
          </View>
        ))}
      </View>

      {!!checkoutState.checkout_errors.length && step !== 'result' && (
        <View style={styles.alertCard}>
          <Text style={styles.alertTitle}>Checkout notes</Text>
          <Text style={styles.alertCopy}>
            {getErrorMessage(checkoutState.checkout_errors)}
          </Text>
        </View>
      )}

      {step === 'review' && (
        <>
          <View style={styles.sectionCard}>
            <Text style={styles.sectionTitle}>Cart review</Text>
            {checkoutState.cart.lines.map((line) => (
              <View key={line.id} style={styles.reviewLine}>
                <View style={styles.reviewLineBody}>
                  <Text style={styles.reviewLineName}>{line.name}</Text>
                  <Text style={styles.reviewLineMeta}>
                    Qty {line.quantity}
                    {line.is_delivery ? ' · Delivery' : ''}
                  </Text>
                </View>
                <Text style={styles.reviewLineTotal}>
                  {formatMoney(line.currency, line.total)}
                </Text>
              </View>
            ))}
          </View>

          <View style={styles.summaryCard}>
            <Text style={styles.summaryTitle}>Order summary</Text>
            <Text style={styles.summaryLine}>
              Subtotal: {formatMoney(checkoutState.cart.currency, checkoutState.cart.amount_untaxed)}
            </Text>
            <Text style={styles.summaryLine}>
              Tax: {formatMoney(checkoutState.cart.currency, checkoutState.cart.amount_tax)}
            </Text>
            <Text style={styles.summaryTotal}>
              Total: {formatMoney(checkoutState.cart.currency, checkoutState.cart.amount_total)}
            </Text>
            <Pressable
              style={styles.primaryButton}
              onPress={() => {
                if (checkoutState.login_required && !checkoutState.is_authenticated) {
                  onGoToAccount();
                  return;
                }
                setStep('address');
              }}
            >
              <Text style={styles.primaryButtonText}>
                {checkoutState.login_required && !checkoutState.is_authenticated
                  ? 'Sign in to continue'
                  : 'Continue to address'}
              </Text>
            </Pressable>
          </View>
        </>
      )}

      {step === 'address' && (
        <>
          {renderAddressForm('Billing address', billingForm, billingSchema, setBillingField, {
            countryOptions: billingCountryOptions,
            stateOptions: billingStateOptions,
          })}

          {checkoutState.requires_delivery && (
            <View style={styles.sectionCard}>
              <Text style={styles.sectionTitle}>Shipping preference</Text>
              <Pressable
                style={styles.toggleRow}
                onPress={() => setUseBillingForShipping((current) => !current)}
              >
                <View
                  style={[
                    styles.toggleDot,
                    useBillingForShipping ? styles.toggleDotActive : undefined,
                  ]}
                />
                <Text style={styles.toggleLabel}>Use the billing address for delivery</Text>
              </Pressable>
            </View>
          )}

          {checkoutState.requires_delivery &&
            !useBillingForShipping &&
            renderAddressForm(
              'Shipping address',
              shippingForm,
              shippingSchema,
              setShippingField,
              {
                countryOptions: shippingCountryOptions,
                stateOptions: shippingStateOptions,
              }
            )}

          <Pressable
            style={[
              styles.primaryButton,
              savingAddress ? styles.buttonDisabled : undefined,
            ]}
            onPress={handleSaveAddresses}
          >
            <Text style={styles.primaryButtonText}>
              {savingAddress ? 'Saving address...' : 'Save and continue'}
            </Text>
          </Pressable>
        </>
      )}

      {step === 'delivery' && (
        <>
          <View style={styles.sectionCard}>
            <Text style={styles.sectionTitle}>Delivery methods</Text>
            {!!deliveryPayload?.items.length ? (
              deliveryPayload.items.map((method) => {
                const selected = activeDeliveryMethodId === method.id;
                return (
                  <Pressable
                    key={method.id}
                    style={[
                      styles.optionCard,
                      selected ? styles.optionCardSelected : undefined,
                    ]}
                    onPress={() => handleSelectDeliveryMethod(method)}
                  >
                    <View style={styles.optionHeader}>
                      <Text style={styles.optionTitle}>{method.name}</Text>
                      <Text style={styles.optionAmount}>
                        {formatMoney(method.currency, method.amount)}
                      </Text>
                    </View>
                    <Text style={styles.optionMeta}>
                      {selected ? 'Selected for this order' : 'Tap to choose this delivery method'}
                    </Text>
                  </Pressable>
                );
              })
            ) : (
              <Text style={styles.copy}>
                No delivery method is currently available for this address.
              </Text>
            )}
          </View>

          <Pressable
            style={[
              styles.primaryButton,
              savingDelivery || startingPayment ? styles.buttonDisabled : undefined,
            ]}
            onPress={handleContinueFromDelivery}
          >
            <Text style={styles.primaryButtonText}>
              {savingDelivery
                ? 'Updating delivery...'
                : startingPayment
                  ? 'Finishing order...'
                  : checkoutState.payment_required
                    ? 'Continue to payment'
                    : 'Place order'}
            </Text>
          </Pressable>
        </>
      )}

      {step === 'payment' && (
        <>
          <View style={styles.sectionCard}>
            <Text style={styles.sectionTitle}>Payment options</Text>
            {!!paymentOptions?.errors.length && (
              <Text style={styles.copy}>{getErrorMessage(paymentOptions.errors)}</Text>
            )}
            {!!paymentOptions?.items.length ? (
              paymentOptions.items.map((option) => {
                const optionKey = `${option.provider_id}:${option.payment_method_id}`;
                const selected = selectedPaymentKey === optionKey;
                return (
                  <Pressable
                    key={optionKey}
                    style={[
                      styles.optionCard,
                      selected ? styles.optionCardSelected : undefined,
                    ]}
                    onPress={() => setSelectedPaymentKey(optionKey)}
                  >
                    <Text style={styles.optionTitle}>{option.provider_name}</Text>
                    <Text style={styles.optionMeta}>{option.payment_method_name}</Text>
                  </Pressable>
                );
              })
            ) : (
              <Text style={styles.copy}>
                No redirect-based provider is available yet for this order.
              </Text>
            )}
          </View>

          <View style={styles.summaryCard}>
            <Text style={styles.summaryTitle}>Ready to pay</Text>
            <Text style={styles.summaryLine}>
              Billing: {checkoutState.billing_address?.name || 'Not set'}
            </Text>
            <Text style={styles.summaryLine}>
              Delivery:{' '}
              {checkoutState.selected_delivery_method?.name ||
                (checkoutState.requires_delivery ? 'Not selected' : 'Not required')}
            </Text>
            <Text style={styles.summaryTotal}>
              Total: {formatMoney(checkoutState.cart.currency, checkoutState.cart.amount_total)}
            </Text>
            <Pressable
              style={[
                styles.primaryButton,
                startingPayment ? styles.buttonDisabled : undefined,
              ]}
              onPress={handleStartPayment}
            >
              <Text style={styles.primaryButtonText}>
                {startingPayment ? 'Opening payment...' : 'Continue to secure payment'}
              </Text>
            </Pressable>
          </View>
        </>
      )}

      {step === 'result' && result && (
        <>
          <View style={styles.resultCard}>
            <Text style={[styles.resultBadge, { color: getResultTone(result.status) }]}>
              {result.status.toUpperCase()}
            </Text>
            <Text style={styles.resultTitle}>
              {result.status === 'success'
                ? 'Your order is confirmed'
                : result.status === 'pending'
                  ? 'Your payment is still processing'
                  : result.status === 'cancel'
                    ? 'Payment was canceled'
                    : 'Payment needs attention'}
            </Text>
            <Text style={styles.resultCopy}>
              {result.message ||
                (result.status === 'success'
                  ? 'We have your order and refreshed the app with the latest cart and order state.'
                  : 'You can check the latest payment status again from here.')}
            </Text>
            <Text style={styles.resultMeta}>Order: {result.order_name || 'Unknown order'}</Text>
            {!!result.tx_state && (
              <Text style={styles.resultMeta}>Transaction: {result.tx_state}</Text>
            )}
          </View>

          <Pressable
            style={[
              styles.primaryButton,
              checkingStatus ? styles.buttonDisabled : undefined,
            ]}
            onPress={() => {
              if (!result.order_id || !result.access_token) {
                return;
              }
              resolvePaymentStatus({
                order_id: result.order_id,
                access_token: result.access_token,
                tx_id: result.tx_id,
              }).catch(() => {
                // Alert handling lives in resolvePaymentStatus.
              });
            }}
          >
            <Text style={styles.primaryButtonText}>
              {checkingStatus ? 'Checking status...' : 'Check latest status'}
            </Text>
          </Pressable>

          <Pressable
            style={styles.secondaryButton}
            onPress={() => {
              setStep('review');
              setResult(null);
            }}
          >
            <Text style={styles.secondaryButtonText}>Back to checkout</Text>
          </Pressable>
        </>
      )}
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
  },
  copy: {
    color: theme.colors.muted,
    fontSize: 15,
    lineHeight: 22,
    marginTop: theme.spacing.xs,
  },
  stepRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.xs,
    marginTop: theme.spacing.md,
    marginBottom: theme.spacing.md,
  },
  stepPill: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.pill,
    borderWidth: 1,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.xs,
  },
  stepPillActive: {
    backgroundColor: theme.colors.ink,
    borderColor: theme.colors.ink,
  },
  stepPillText: {
    color: theme.colors.muted,
    fontSize: 12,
    fontWeight: '800',
  },
  stepPillTextActive: {
    color: '#FFFFFF',
  },
  alertCard: {
    backgroundColor: '#FFF1E6',
    borderColor: '#E2B089',
    borderRadius: theme.radius.md,
    borderWidth: 1,
    marginBottom: theme.spacing.md,
    padding: theme.spacing.md,
  },
  alertTitle: {
    color: theme.colors.accentDark,
    fontSize: 16,
    fontWeight: '800',
    marginBottom: theme.spacing.xs,
  },
  alertCopy: {
    color: theme.colors.accentDark,
    fontSize: 14,
    lineHeight: 21,
  },
  sectionCard: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    marginBottom: theme.spacing.md,
    padding: theme.spacing.lg,
  },
  addressCard: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    marginBottom: theme.spacing.md,
    padding: theme.spacing.lg,
  },
  sectionTitle: {
    color: theme.colors.ink,
    fontSize: 20,
    fontWeight: '800',
    marginBottom: theme.spacing.md,
  },
  reviewLine: {
    alignItems: 'center',
    borderBottomColor: theme.colors.line,
    borderBottomWidth: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: theme.spacing.sm,
  },
  reviewLineBody: {
    flex: 1,
    paddingRight: theme.spacing.md,
  },
  reviewLineName: {
    color: theme.colors.ink,
    fontSize: 15,
    fontWeight: '700',
  },
  reviewLineMeta: {
    color: theme.colors.muted,
    fontSize: 13,
    marginTop: 2,
  },
  reviewLineTotal: {
    color: theme.colors.accentDark,
    fontSize: 14,
    fontWeight: '800',
  },
  summaryCard: {
    backgroundColor: theme.colors.ink,
    borderRadius: theme.radius.lg,
    marginBottom: theme.spacing.md,
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
  primaryButton: {
    alignItems: 'center',
    backgroundColor: theme.colors.accent,
    borderRadius: theme.radius.md,
    paddingVertical: theme.spacing.md,
  },
  primaryButtonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
  secondaryButton: {
    alignItems: 'center',
    borderColor: theme.colors.ink,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    marginTop: theme.spacing.sm,
    paddingVertical: theme.spacing.md,
  },
  secondaryButtonText: {
    color: theme.colors.ink,
    fontSize: 15,
    fontWeight: '800',
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  fieldGroup: {
    marginBottom: theme.spacing.sm,
  },
  fieldLabel: {
    color: theme.colors.ink,
    fontSize: 14,
    fontWeight: '700',
    marginBottom: theme.spacing.xs,
  },
  input: {
    backgroundColor: '#FFFFFF',
    borderColor: theme.colors.line,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    color: theme.colors.ink,
    fontSize: 16,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.md,
  },
  selectField: {
    backgroundColor: '#FFFFFF',
    borderColor: theme.colors.line,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    minHeight: 52,
    justifyContent: 'center',
    paddingHorizontal: theme.spacing.md,
  },
  selectFieldText: {
    color: theme.colors.ink,
    fontSize: 16,
  },
  selectFieldPlaceholder: {
    color: theme.colors.muted,
  },
  fieldInvalid: {
    borderColor: theme.colors.accentDark,
    borderWidth: 2,
  },
  toggleRow: {
    alignItems: 'center',
    flexDirection: 'row',
  },
  toggleDot: {
    backgroundColor: '#FFFFFF',
    borderColor: theme.colors.line,
    borderRadius: theme.radius.pill,
    borderWidth: 2,
    height: 20,
    marginRight: theme.spacing.sm,
    width: 20,
  },
  toggleDotActive: {
    backgroundColor: theme.colors.accent,
    borderColor: theme.colors.accent,
  },
  toggleLabel: {
    color: theme.colors.ink,
    flex: 1,
    fontSize: 15,
    fontWeight: '600',
  },
  optionCard: {
    backgroundColor: '#FFFFFF',
    borderColor: theme.colors.line,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    marginBottom: theme.spacing.sm,
    padding: theme.spacing.md,
  },
  optionCardSelected: {
    borderColor: theme.colors.accent,
    borderWidth: 2,
  },
  optionHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.xs,
  },
  optionTitle: {
    color: theme.colors.ink,
    fontSize: 16,
    fontWeight: '800',
  },
  optionAmount: {
    color: theme.colors.accentDark,
    fontSize: 14,
    fontWeight: '800',
  },
  optionMeta: {
    color: theme.colors.muted,
    fontSize: 13,
    lineHeight: 20,
  },
  resultCard: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    marginBottom: theme.spacing.md,
    padding: theme.spacing.lg,
  },
  resultBadge: {
    fontSize: 13,
    fontWeight: '900',
    letterSpacing: 1,
    marginBottom: theme.spacing.sm,
  },
  resultTitle: {
    color: theme.colors.ink,
    fontSize: 24,
    fontWeight: '800',
    marginBottom: theme.spacing.sm,
  },
  resultCopy: {
    color: theme.colors.muted,
    fontSize: 15,
    lineHeight: 22,
    marginBottom: theme.spacing.md,
  },
  resultMeta: {
    color: theme.colors.ink,
    fontSize: 14,
    marginBottom: theme.spacing.xs,
  },
  emptyState: {
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
  emptyCard: {
    backgroundColor: theme.colors.surface,
    borderColor: theme.colors.line,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    marginTop: theme.spacing.md,
    padding: theme.spacing.lg,
  },
  emptyTitle: {
    color: theme.colors.ink,
    fontSize: 22,
    fontWeight: '800',
    marginBottom: theme.spacing.xs,
  },
  emptyCopy: {
    color: theme.colors.muted,
    fontSize: 15,
    lineHeight: 22,
  },
  modalBackdrop: {
    backgroundColor: 'rgba(24, 33, 38, 0.45)',
    flex: 1,
    justifyContent: 'flex-end',
  },
  modalCard: {
    backgroundColor: theme.colors.background,
    borderTopLeftRadius: theme.radius.lg,
    borderTopRightRadius: theme.radius.lg,
    maxHeight: '78%',
    padding: theme.spacing.md,
  },
  modalHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.sm,
  },
  modalTitle: {
    color: theme.colors.ink,
    fontSize: 18,
    fontWeight: '800',
  },
  modalAction: {
    color: theme.colors.accent,
    fontSize: 15,
    fontWeight: '800',
  },
  modalList: {
    marginTop: theme.spacing.sm,
  },
  modalOption: {
    backgroundColor: '#FFFFFF',
    borderColor: theme.colors.line,
    borderRadius: theme.radius.md,
    borderWidth: 1,
    marginBottom: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.md,
  },
  modalOptionText: {
    color: theme.colors.ink,
    fontSize: 15,
    fontWeight: '600',
  },
  modalEmpty: {
    color: theme.colors.muted,
    fontSize: 14,
    paddingVertical: theme.spacing.lg,
    textAlign: 'center',
  },
});
