import 'package:flutter/material.dart';
import '../models/mobile_models.dart';

class CheckoutStepHeader extends StatelessWidget {
  const CheckoutStepHeader({super.key, required this.step});

  final CheckoutStep step;

  @override
  Widget build(BuildContext context) {
    const labels = <CheckoutStep, String>{
      CheckoutStep.review: 'Review',
      CheckoutStep.address: 'Address',
      CheckoutStep.delivery: 'Delivery',
      CheckoutStep.payment: 'Payment',
      CheckoutStep.result: 'Result',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CheckoutStep.values.map((item) {
          final selected = item.index <= step.index;
          final isCurrent = item == step;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              side: isCurrent
                  ? BorderSide(color: Theme.of(context).colorScheme.primary)
                  : null,
              backgroundColor: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              label: Text(
                labels[item]!,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LoginRequiredCard extends StatelessWidget {
  const LoginRequiredCard({super.key, required this.onGoToAccount});

  final VoidCallback onGoToAccount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Sign in required',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Checkout requires an authenticated customer account. Please sign in or create an account to continue.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGoToAccount,
                child: const Text('Go to account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressFormCard extends StatelessWidget {
  const AddressFormCard({
    super.key,
    required this.title,
    required this.schema,
    required this.value,
    required this.invalidFields,
    required this.onChanged,
    required this.onCountryChanged,
  });

  final String title;
  final AddressSchema schema;
  final CheckoutAddressInput value;
  final List<String> invalidFields;
  final ValueChanged<CheckoutAddressInput> onChanged;
  final ValueChanged<int?> onCountryChanged;

  bool _isRequired(String field) => schema.requiredFields.contains(field);

  String _label(String field) {
    const labels = <String, String>{
      'name': 'Full name',
      'email': 'Email address',
      'phone': 'Phone number',
      'street': 'Street address',
      'street2': 'Apartment, suite, unit (optional)',
      'city': 'City',
      'zip': 'ZIP / Postal code',
      'country_id': 'Country',
      'state_id': 'State / Province',
      'company_name': 'Company name (optional)',
      'vat': 'VAT / Tax ID (optional)',
    };
    return labels[field] ?? field;
  }

  InputDecoration _decoration(String field) {
    return InputDecoration(
      labelText: _isRequired(field) ? '${_label(field)} *' : _label(field),
      errorText: invalidFields.contains(field) ? 'Required for checkout' : null,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: _label(field),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 20),
            _buildField('name'),
            const SizedBox(height: 16),
            _buildField('email', type: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildField('phone', type: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField('street'),
            const SizedBox(height: 16),
            _buildField('street2'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: value.countryId,
              isExpanded: true,
              items: schema.countries
                  .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: onCountryChanged,
              decoration: _decoration('country_id'),
            ),
            if (schema.states.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: value.stateId,
                isExpanded: true,
                items: schema.states
                    .map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => onChanged(value.copyWith(stateId: v)),
                decoration: _decoration('state_id'),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildField('city')),
                const SizedBox(width: 12),
                Expanded(child: _buildField('zip')),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('company_name'),
            const SizedBox(height: 16),
            _buildField('vat'),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String field, {TextInputType? type}) {
    return TextField(
      controller: TextEditingController(text: _getValue(field))
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: _getValue(field)?.length ?? 0),
        ),
      keyboardType: type,
      onChanged: (text) => onChanged(_copyWith(field, text)),
      decoration: _decoration(field),
    );
  }

  String? _getValue(String field) {
    switch (field) {
      case 'name':
        return value.name;
      case 'email':
        return value.email;
      case 'phone':
        return value.phone;
      case 'street':
        return value.street;
      case 'street2':
        return value.street2;
      case 'city':
        return value.city;
      case 'zip':
        return value.zip;
      case 'company_name':
        return value.companyName;
      case 'vat':
        return value.vat;
      default:
        return null;
    }
  }

  CheckoutAddressInput _copyWith(String field, String text) {
    switch (field) {
      case 'name':
        return value.copyWith(name: text);
      case 'email':
        return value.copyWith(email: text);
      case 'phone':
        return value.copyWith(phone: text);
      case 'street':
        return value.copyWith(street: text);
      case 'street2':
        return value.copyWith(street2: text);
      case 'city':
        return value.copyWith(city: text);
      case 'zip':
        return value.copyWith(zip: text);
      case 'company_name':
        return value.copyWith(companyName: text);
      case 'vat':
        return value.copyWith(vat: text);
      default:
        return value;
    }
  }
}

class CheckoutErrorList extends StatelessWidget {
  const CheckoutErrorList({super.key, required this.errors});

  final List<CheckoutError> errors;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(Icons.error_outline,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Review required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final error in errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(error.message ?? error.title)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
