import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../utils/app_utils.dart';
import '../widgets/common.dart';
import '../widgets/cart_widgets.dart';
import '../widgets/checkout_widgets.dart';

class CheckoutFlowScreen extends StatefulWidget {
  const CheckoutFlowScreen({
    super.key,
    required this.appState,
    required this.incomingUri,
    required this.onIncomingUriHandled,
    required this.onGoToAccount,
  });

  final AppState appState;
  final Uri? incomingUri;
  final VoidCallback onIncomingUriHandled;
  final VoidCallback onGoToAccount;

  @override
  State<CheckoutFlowScreen> createState() => _CheckoutFlowScreenState();
}

class _CheckoutFlowScreenState extends State<CheckoutFlowScreen>
    with WidgetsBindingObserver {
  CheckoutStep _step = CheckoutStep.review;
  CheckoutState? _checkoutState;
  AddressSchema? _billingSchema;
  AddressSchema? _shippingSchema;
  DeliveryMethodsPayload? _deliveryPayload;
  PaymentOptionsPayload? _paymentOptions;
  CheckoutAddressInput _billingForm = CheckoutAddressInput();
  CheckoutAddressInput _shippingForm = CheckoutAddressInput();
  bool _useBillingForShipping = true;
  String? _selectedPaymentKey;
  CheckoutResult? _result;

  bool _loading = true;
  bool _savingAddress = false;
  bool _savingDelivery = false;
  bool _startingPayment = false;
  bool _checkingStatus = false;

  PaymentSession? _pendingSession;
  String? _handledIncomingUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCheckout();
  }

  @override
  void didUpdateWidget(covariant CheckoutFlowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.incomingUri != null &&
        widget.incomingUri.toString() != oldWidget.incomingUri.toString()) {
      _handleIncomingUri(widget.incomingUri!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingSession != null) {
      _resolvePaymentStatus(_pendingSession!);
    }
  }

  Future<void> _loadCheckout() async {
    setState(() {
      _loading = true;
    });
    try {
      final state = await widget.appState.api.getCheckoutState();
      _hydrateFromState(state);
      await _loadSchemas();
      if (state.requiresDelivery) {
        await _loadDeliveryMethods();
      }
      if (state.canProceedToPayment || state.canFinalizeWithoutPayment) {
        await _loadPaymentOptions();
      }
      if (widget.incomingUri != null) {
        await _handleIncomingUri(widget.incomingUri!);
      }
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Unable to load checkout', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _hydrateFromState(CheckoutState state) {
    final billing = CheckoutAddressInput.fromPartner(state.billingAddress);
    final shipping = CheckoutAddressInput.fromPartner(
      state.shippingAddress ?? state.billingAddress,
    );
    final sameAddress =
        _addressesEqual(state.billingAddress, state.shippingAddress);
    setState(() {
      _checkoutState = state;
      _billingForm = billing;
      _shippingForm = shipping;
      _useBillingForShipping = !state.requiresDelivery || sameAddress;
    });
  }

  Future<void> _loadSchemas() async {
    final billing = await widget.appState.api.getAddressSchema(
      addressType: 'billing',
      countryId: _billingForm.countryId,
    );
    final shipping = await widget.appState.api.getAddressSchema(
      addressType: 'delivery',
      countryId: _shippingForm.countryId,
    );
    if (!mounted) return;
    setState(() {
      _billingSchema = billing;
      _shippingSchema = shipping;
      if (_billingForm.stateId != null &&
          !billing.states.any((state) => state.id == _billingForm.stateId)) {
        _billingForm = _billingForm.copyWith(stateId: null);
      }
      if (_shippingForm.stateId != null &&
          !shipping.states.any((state) => state.id == _shippingForm.stateId)) {
        _shippingForm = _shippingForm.copyWith(stateId: null);
      }
    });
  }

  Future<void> _loadDeliveryMethods() async {
    final payload = await widget.appState.api.getDeliveryMethods();
    if (!mounted) return;
    setState(() {
      _deliveryPayload = payload;
    });
  }

  Future<void> _loadPaymentOptions() async {
    final payload = await widget.appState.api.getPaymentOptions();
    if (!mounted) return;
    setState(() {
      _paymentOptions = payload;
      if (_selectedPaymentKey == null && payload.items.isNotEmpty) {
        final first = payload.items.firstWhere(
          (item) => item.providerCode == 'odoo_quotation',
          orElse: () => payload.items.first,
        );
        _selectedPaymentKey = first.selectionKey;
      }
    });
  }

  Future<void> _saveAddresses() async {
    final billingSchema = _billingSchema;
    if (billingSchema == null) return;

    setState(() {
      _savingAddress = true;
    });
    try {
      var state = await widget.appState.api.upsertCheckoutAddress(
        values: _billingForm,
        addressType: 'billing',
        useDeliveryAsBilling:
            _checkoutState?.requiresDelivery == true && _useBillingForShipping,
      );
      if (_checkoutState?.requiresDelivery == true && !_useBillingForShipping) {
        state = await widget.appState.api.upsertCheckoutAddress(
          values: _shippingForm,
          addressType: 'delivery',
        );
      }
      _hydrateFromState(state);
      await widget.appState.refreshCart();
      if (state.requiresDelivery) {
        await _loadDeliveryMethods();
      }
      if (mounted) {
        setState(() {
          _step = state.requiresDelivery
              ? CheckoutStep.delivery
              : CheckoutStep.payment;
        });
      }
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Unable to save addresses', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _savingAddress = false;
        });
      }
    }
  }

  Future<void> _selectDeliveryMethod(int carrierId) async {
    setState(() {
      _savingDelivery = true;
    });
    try {
      final state = await widget.appState.api.selectDeliveryMethod(carrierId);
      _hydrateFromState(state);
      await widget.appState.refreshCart();
      await _loadDeliveryMethods();
      await _loadPaymentOptions();
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Unable to update delivery', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _savingDelivery = false;
        });
      }
    }
  }

  Future<void> _startPayment() async {
    final state = _checkoutState;
    if (state == null) return;

    setState(() {
      _startingPayment = true;
    });
    try {
      final selectedOption = _selectedPaymentOption;
      final session = await widget.appState.api.createPaymentSession(
        providerId: selectedOption?.providerId,
        paymentMethodId: selectedOption?.paymentMethodId,
      );
      _pendingSession = session;

      if ((session.paymentPageUrl ?? '').isEmpty) {
        await _resolvePaymentStatus(session);
        return;
      }

      final launched = await _openPaymentPage(session.paymentPageUrl!);
      if (!launched && mounted) {
        _showErrorDialog(
          context,
          'Unable to open Odoo quotation',
          'The in-app browser could not open ${session.paymentPageUrl}.',
        );
      }
      await widget.appState.refreshAccount(silent: true);
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Unable to start payment', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _startingPayment = false;
        });
      }
    }
  }

  Future<bool> _openPaymentPage(String url) async {
    final uri = Uri.parse(url);
    try {
      final openedInApp = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        webOnlyWindowName: '_self',
      );
      if (openedInApp) {
        return true;
      }
    } catch (_) {
      // Web builds can reject in-app browser mode; fall back to same-tab launch.
    }
    return launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
  }

  Future<void> _resolvePaymentStatus(PaymentSession session) async {
    setState(() {
      _checkingStatus = true;
    });
    try {
      final result = await widget.appState.api.getPaymentStatus(
        orderId: session.orderId,
        accessToken: session.accessToken,
        txId: session.txId,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _step = CheckoutStep.result;
      });
      if (result.status == 'success') {
        _pendingSession = null;
        await widget.appState.refreshCart();
        await widget.appState.refreshAccount(silent: true);
        await _loadCheckout();
      } else if (result.status != 'pending') {
        _pendingSession = null;
      }
    } catch (error) {
      if (!mounted) return;
      _showErrorDialog(context, 'Unable to verify payment', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _checkingStatus = false;
        });
      }
    }
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    final raw = uri.toString();
    if (_handledIncomingUrl == raw) return;
    _handledIncomingUrl = raw;
    widget.onIncomingUriHandled();

    final orderId = int.tryParse(uri.queryParameters['order_id'] ?? '') ??
        _pendingSession?.orderId;
    final txId = int.tryParse(uri.queryParameters['tx_id'] ?? '');
    final accessToken =
        uri.queryParameters['access_token'] ?? _pendingSession?.accessToken;

    if (orderId == null || (accessToken ?? '').isEmpty) return;

    final session = PaymentSession(
      txId: txId ?? _pendingSession?.txId,
      orderId: orderId,
      paymentPageUrl: null,
      returnUrl: AppConfig.returnUrl,
      accessToken: accessToken!,
      status: 'pending',
    );
    _pendingSession = session;
    await _resolvePaymentStatus(session);
  }

  bool get _canGoBackInCheckout =>
      _step != CheckoutStep.review && _step != CheckoutStep.result;

  String get _checkoutBackLabel {
    switch (_step) {
      case CheckoutStep.address:
        return 'Back to review';
      case CheckoutStep.delivery:
        return 'Back to address';
      case CheckoutStep.payment:
        return _checkoutState?.requiresDelivery == true
            ? 'Back to delivery'
            : 'Back to address';
      case CheckoutStep.review:
      case CheckoutStep.result:
        return 'Back';
    }
  }

  void _goBackInCheckout() {
    setState(() {
      switch (_step) {
        case CheckoutStep.address:
          _step = CheckoutStep.review;
          break;
        case CheckoutStep.delivery:
          _step = CheckoutStep.address;
          break;
        case CheckoutStep.payment:
          _step = _checkoutState?.requiresDelivery == true
              ? CheckoutStep.delivery
              : CheckoutStep.address;
          break;
        case CheckoutStep.review:
        case CheckoutStep.result:
          break;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _checkoutState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final checkoutState = _checkoutState;
    if (checkoutState == null) {
      return RetryState(
        title: 'Checkout could not be loaded',
        actionLabel: 'Retry',
        onPressed: _loadCheckout,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        CheckoutStepHeader(
          step: _step,
          onBack: _canGoBackInCheckout ? _goBackInCheckout : null,
          backLabel: _checkoutBackLabel,
        ),
        const SizedBox(height: 24),
        if (checkoutState.loginRequired && !checkoutState.isAuthenticated)
          LoginRequiredCard(onGoToAccount: widget.onGoToAccount)
        else if (_step == CheckoutStep.review)
          _buildReviewStep(context, checkoutState)
        else if (_step == CheckoutStep.address)
          _buildAddressStep(context, checkoutState)
        else if (_step == CheckoutStep.delivery)
          _buildDeliveryStep(context, checkoutState)
        else if (_step == CheckoutStep.payment)
          _buildPaymentStep(context, checkoutState)
        else
          _buildResultStep(context),
      ],
    );
  }

  Widget _buildReviewStep(BuildContext context, CheckoutState checkoutState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionTitle(title: 'Review order items'),
        for (final line in checkoutState.cart.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: AppNetworkImage(url: line.imageUrl),
                  ),
                ),
                title: Text(line.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Quantity: ${line.quantity.toStringAsFixed(0)}'),
                trailing: Text(
                  formatMoney(line.currency, line.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        if (checkoutState.checkoutErrors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CheckoutErrorList(errors: checkoutState.checkoutErrors),
          ),
        const SizedBox(height: 12),
        SummaryPanel(cart: checkoutState.cart),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: checkoutState.cart.lines.isEmpty
                ? null
                : () {
                    setState(() {
                      _step = CheckoutStep.address;
                    });
                  },
            child: const Text('Continue to address'),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressStep(BuildContext context, CheckoutState checkoutState) {
    final billingSchema = _billingSchema;
    final shippingSchema = _shippingSchema;
    if (billingSchema == null || shippingSchema == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionTitle(title: 'Contact and shipping details'),
        if (checkoutState.messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: MessageCard(
              title: 'Important information',
              message: checkoutState.messages.join('\n'),
            ),
          ),
        AddressFormCard(
          title: 'Billing address',
          schema: billingSchema,
          value: _billingForm,
          invalidFields: checkoutState.invalidFields,
          onChanged: (next) => setState(() {
            _billingForm = next;
          }),
          onCountryChanged: (countryId) async {
            setState(() {
              _billingForm =
                  _billingForm.copyWith(countryId: countryId, stateId: null);
            });
            final schema = await widget.appState.api.getAddressSchema(
              addressType: 'billing',
              countryId: countryId,
            );
            if (mounted) {
              setState(() {
                _billingSchema = schema;
              });
            }
          },
        ),
        if (checkoutState.requiresDelivery) ...<Widget>[
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text('Use billing address for shipping'),
            value: _useBillingForShipping,
            onChanged: (value) {
              setState(() {
                _useBillingForShipping = value;
              });
            },
          ),
          if (!_useBillingForShipping) ...[
            const SizedBox(height: 8),
            AddressFormCard(
              title: 'Shipping address',
              schema: shippingSchema,
              value: _shippingForm,
              invalidFields: checkoutState.invalidFields,
              onChanged: (next) => setState(() {
                _shippingForm = next;
              }),
              onCountryChanged: (countryId) async {
                setState(() {
                  _shippingForm = _shippingForm.copyWith(
                      countryId: countryId, stateId: null);
                });
                final schema = await widget.appState.api.getAddressSchema(
                  addressType: 'delivery',
                  countryId: countryId,
                );
                if (mounted) {
                  setState(() {
                    _shippingSchema = schema;
                  });
                }
              },
            ),
          ],
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _savingAddress ? null : _saveAddresses,
            child: Text(
                _savingAddress ? 'Saving details...' : 'Continue to delivery'),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryStep(BuildContext context, CheckoutState checkoutState) {
    final payload = _deliveryPayload;
    if (payload == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionTitle(title: 'Choose delivery method'),
        if (payload.shippingCountry != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MessageCard(
              title: 'Shipping country',
              message:
                  'Showing Odoo delivery methods available for ${payload.shippingCountry!.name}.',
            ),
          ),
        if (payload.items.isEmpty)
          const MessageCard(
            title: 'No delivery methods available',
            message: 'Please verify your shipping address details.',
          )
        else
          for (final method in payload.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: RadioListTile<int>(
                  value: method.id,
                  groupValue: payload.selectedDeliveryMethod?.id ??
                      checkoutState.selectedDeliveryMethod?.id,
                  onChanged: _savingDelivery
                      ? null
                      : (value) {
                          if (value != null) {
                            _selectDeliveryMethod(value);
                          }
                        },
                  title: Text(method.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${formatMoney(method.currency, method.amount)}\n${method.countrySummary}',
                  ),
                ),
              ),
            ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (payload.selectedDeliveryMethod != null ||
                    checkoutState.selectedDeliveryMethod != null)
                ? () async {
                    await _loadPaymentOptions();
                    if (mounted) {
                      setState(() {
                        _step = CheckoutStep.payment;
                      });
                    }
                  }
                : null,
            child: Text(
                _savingDelivery ? 'Updating order...' : 'Continue to payment'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep(BuildContext context, CheckoutState checkoutState) {
    final payload = _paymentOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionTitle(title: 'Choose payment method'),
        if (!checkoutState.canProceedToPayment &&
            !checkoutState.canFinalizeWithoutPayment)
          _PaymentBlockedCard(
            checkoutState: checkoutState,
            onBack: _goBackInCheckout,
          )
        else if (checkoutState.canFinalizeWithoutPayment)
          const MessageCard(
            title: 'No payment required',
            message: 'This order can be confirmed without payment.',
          )
        else if (payload == null)
          const Center(child: CircularProgressIndicator())
        else ...<Widget>[
          if (payload.billingCountry != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MessageCard(
                title: 'Billing country',
                message:
                    'Showing Odoo payment methods available for ${payload.billingCountry!.name}.',
              ),
            ),
          if (payload.errors.isNotEmpty)
            CheckoutErrorList(errors: payload.errors),
          if (payload.items.isEmpty)
            const MessageCard(
              title: 'No payment methods available',
              message: 'Please contact support to complete your order.',
            )
          else
            for (final item in payload.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: RadioListTile<String>(
                    value: item.selectionKey,
                    groupValue: _selectedPaymentKey,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentKey = value;
                      });
                    },
                    title: Text(
                      item.paymentMethodName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.providerCode == 'odoo_quotation'
                          ? 'Opens your Odoo quotation in the in-app browser so you can pay there.'
                          : '${item.providerName}\n${item.countrySummary}',
                    ),
                  ),
                ),
              ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _startingPayment || _checkingStatus
                ? null
                : (checkoutState.canFinalizeWithoutPayment ||
                        (payload?.items.isNotEmpty ?? false))
                    ? _startPayment
                    : null,
            child: Text(
              _startingPayment
                  ? 'Initializing...'
                  : _checkingStatus
                      ? 'Verifying...'
                      : checkoutState.canFinalizeWithoutPayment
                          ? 'Confirm order'
                          : _selectedPaymentOption?.providerCode ==
                                  'odoo_quotation'
                              ? 'Open Odoo quotation'
                              : 'Pay securely',
            ),
          ),
        ),
      ],
    );
  }

  PaymentOption? get _selectedPaymentOption {
    final selectedKey = _selectedPaymentKey;
    if (selectedKey == null) return null;
    for (final item in _paymentOptions?.items ?? <PaymentOption>[]) {
      if (item.selectionKey == selectedKey) {
        return item;
      }
    }
    return null;
  }

  Widget _buildResultStep(BuildContext context) {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final Color tone;
    final IconData icon;
    switch (result.status) {
      case 'success':
        tone = theme.colorScheme.primary;
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        tone = Colors.orange.shade700;
        icon = Icons.hourglass_empty;
        break;
      default:
        tone = theme.colorScheme.error;
        icon = Icons.error_outline;
        break;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 64, color: tone),
            const SizedBox(height: 24),
            Text(
              result.status == 'success'
                  ? 'Payment successful!'
                  : result.status == 'pending'
                      ? 'Payment is pending'
                      : 'Payment failed',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: tone,
              ),
            ),
            const SizedBox(height: 12),
            if ((result.message ?? '').isNotEmpty)
              Text(
                result.message!,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (result.orderName != null)
                    _ResultRow(label: 'Order', value: result.orderName!),
                  if (result.orderState != null)
                    _ResultRow(label: 'Status', value: result.orderState!),
                  if (result.txState != null)
                    _ResultRow(label: 'Transaction', value: result.txState!),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await widget.appState.refreshCart();
                  await _loadCheckout();
                  if (mounted) {
                    setState(() {
                      _step = CheckoutStep.review;
                      _result = null;
                    });
                  }
                },
                child: const Text('Return to cart'),
              ),
            ),
            if (result.status == 'pending' && _pendingSession != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _resolvePaymentStatus(_pendingSession!),
                child: const Text('Check status again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _addressesEqual(PartnerAddress? left, PartnerAddress? right) {
    if (left == null || right == null) return true;
    return left.name == right.name &&
        left.email == right.email &&
        left.phone == right.phone &&
        left.street == right.street &&
        left.street2 == right.street2 &&
        left.city == right.city &&
        left.zip == right.zip &&
        left.countryId == right.countryId &&
        left.stateId == right.stateId &&
        left.companyName == right.companyName &&
        left.vat == right.vat;
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

class _PaymentBlockedCard extends StatelessWidget {
  const _PaymentBlockedCard({
    required this.checkoutState,
    required this.onBack,
  });

  final CheckoutState checkoutState;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final reasons = checkoutState.checkoutErrors
        .map((error) => error.message?.isNotEmpty == true
            ? '${error.title} ${error.message}'
            : error.title)
        .where((message) => message.trim().isNotEmpty)
        .toList();

    if (reasons.isEmpty) {
      if (!checkoutState.billingComplete) {
        reasons.add('Billing address is not complete.');
      }
      if (checkoutState.requiresDelivery && !checkoutState.shippingComplete) {
        reasons.add('Shipping address is not complete.');
      }
      if (checkoutState.requiresDelivery &&
          checkoutState.selectedDeliveryMethod == null) {
        reasons.add('Select a delivery method before payment.');
      }
    }

    return MessageCard(
      title: 'Payment is waiting for checkout details',
      message: reasons.isEmpty
          ? 'Go back and confirm the previous checkout step.'
          : reasons.join('\n'),
      action: TextButton(
        onPressed: onBack,
        child: const Text('Go back and fix'),
      ),
    );
  }
}
