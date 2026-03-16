import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/deal.dart';
import '../providers/deals_provider.dart';
import '../providers/psf_provider.dart';
import '../widgets/croc_loader.dart';

class PsfSendScreen extends ConsumerStatefulWidget {
  const PsfSendScreen({super.key});

  @override
  ConsumerState<PsfSendScreen> createState() => _PsfSendScreenState();
}

class _PsfSendScreenState extends ConsumerState<PsfSendScreen> {
  final _formKey = GlobalKey<FormState>();
  Deal? _selectedDeal;

  final _holderName = TextEditingController();
  final _holderDba = TextEditingController();
  final _signerEmail = TextEditingController();
  final _amount = TextEditingController();
  final _bankName = TextEditingController();
  final _routing = TextEditingController();
  final _account = TextEditingController();

  @override
  void dispose() {
    _holderName.dispose();
    _holderDba.dispose();
    _signerEmail.dispose();
    _amount.dispose();
    _bankName.dispose();
    _routing.dispose();
    _account.dispose();
    super.dispose();
  }

  void _onDealSelected(Deal? deal) {
    setState(() => _selectedDeal = deal);
    if (deal == null) return;

    // Pre-fill from application_json
    final app = deal.applicationJson;
    final name = app['owner_name']?.toString() ??
        '${app['owner_0_first'] ?? ''} ${app['owner_0_last'] ?? ''}'.trim();
    final email = app['owner_email']?.toString() ??
        app['owner_0_email']?.toString() ?? '';
    final dba = deal.businessName ?? app['business_name']?.toString() ?? '';

    if (name.isNotEmpty) _holderName.text = name;
    if (email.isNotEmpty) _signerEmail.text = email;
    if (dba.isNotEmpty) _holderDba.text = dba;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDeal == null) {
      if (_selectedDeal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a deal'), backgroundColor: C.declined),
        );
      }
      return;
    }

    await ref.read(sendPsfProvider.notifier).send(
          dealId: _selectedDeal!.id,
          amount: double.parse(_amount.text.replaceAll(',', '')),
          bankName: _bankName.text.trim(),
          routingNumber: _routing.text.trim(),
          accountNumber: _account.text.trim(),
          holderName: _holderName.text,
          holderDba: _holderDba.text,
          signerEmail: _signerEmail.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(dealsProvider);
    final sendState = ref.watch(sendPsfProvider);

    ref.listen(sendPsfProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: C.declined,
          ),
        );
      }
      if (next.hasValue && next.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PSF sent successfully!'), backgroundColor: C.approved),
        );
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Send PSF')),
      body: dealsAsync.when(
        loading: () => const Center(child: CrocLoader(message: 'Loading deals...')),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (deals) {
          if (deals.isEmpty) {
            return const Center(
              child: Text('No deals available', style: TextStyle(color: C.textSecondary)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Deal picker
                  _sectionLabel('Select Deal'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Deal>(
                    decoration: const InputDecoration(hintText: 'Choose a deal...'),
                    isExpanded: true,
                    items: deals.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d.displayName, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: _onDealSelected,
                    validator: (_) => _selectedDeal == null ? 'Required' : null,
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('Signer Information'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _holderName,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _holderDba,
                    decoration: const InputDecoration(
                      labelText: 'DBA / Business Name',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _signerEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Signer Email',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('PSF Details'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = double.tryParse(v.replaceAll(',', ''));
                      if (n == null || n <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('Bank Details'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bankName,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _routing,
                    keyboardType: TextInputType.number,
                    maxLength: 9,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Routing Number',
                      prefixIcon: Icon(Icons.tag, size: 20),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.length != 9) return 'Must be 9 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _account,
                    keyboardType: TextInputType.number,
                    maxLength: 17,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                      prefixIcon: Icon(Icons.numbers, size: 20),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.length < 5 || v.length > 17) return '5-17 digits';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: sendState.isLoading ? null : _submit,
                    child: sendState.isLoading
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Send PSF'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: C.textSecondary, letterSpacing: 0.3));
  }
}
