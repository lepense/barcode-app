import 'package:flutter/material.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _selectedBarcodeType = 'QR';

  static const _barcodeTypes = [
    'QR',
    'CODE128',
    'CODE39',
    'EAN13',
    'EAN8',
    'UPC_A',
    'UPC_E',
    'PDF417',
    'AZTEC',
    'DATA_MATRIX',
  ];

  @override
  void dispose() {
    _merchantController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Card')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant Name',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : 'Enter merchant name',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBarcodeType,
                  decoration: const InputDecoration(
                    labelText: 'Barcode Type',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  items: _barcodeTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedBarcodeType = v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode Value',
                    prefixIcon: const Icon(Icons.dialpad),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: () {
                        // TODO: Open barcode scanner
                      },
                    ),
                  ),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : 'Enter barcode value',
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: Save card via repository
                    }
                  },
                  child: const Text('Save Card'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
