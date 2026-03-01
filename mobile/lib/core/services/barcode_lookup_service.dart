import 'dart:convert';

import 'package:http/http.dart' as http;

/// Tries to resolve a human-readable merchant / product name from a raw
/// barcode value and its detected format type string.
///
/// Sources used:
///  • EAN-13 / EAN-8 / UPC-A / UPC-E  → Open Food Facts (free, no key)
///  • QR code that contains a URL      → extracts brand from hostname
///  • Everything else                  → returns null (user types name)
class BarcodeLookupService {
  static const _timeout = Duration(seconds: 4);

  /// Returns a suggested name or `null` if none could be found.
  static Future<String?> lookupName(
    String value,
    String barcodeType,
  ) async {
    try {
      if (['EAN13', 'EAN8', 'UPC_A', 'UPC_E'].contains(barcodeType)) {
        return await _lookupEan(value);
      }
      if (barcodeType == 'QR') {
        return _extractFromQr(value);
      }
    } catch (_) {
      // Network failure, JSON error, timeout — silently fall through
    }
    return null;
  }

  // ── EAN / UPC lookup via Open Food Facts ────────────────────────────────

  static Future<String?> _lookupEan(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
      '?fields=brands,product_name',
    );
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 1) return null;

    final product = (data['product'] as Map<String, dynamic>?) ?? {};

    // Prefer brand name; fall back to product name
    final brand = (product['brands'] as String?)?.split(',').first.trim();
    if (brand != null && brand.isNotEmpty) return brand;

    final productName = (product['product_name'] as String?)?.trim();
    if (productName != null && productName.isNotEmpty) return productName;

    return null;
  }

  // ── QR: extract brand name from URL hostname ─────────────────────────────

  static String? _extractFromQr(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;

    // Strip 'www.' prefix, take the first segment of the hostname
    // e.g. 'www.migros.com.tr' → 'migros' → 'Migros'
    final host = uri.host.replaceFirst('www.', '');
    final segment = host.split('.').first;
    if (segment.length < 2) return null;

    return segment[0].toUpperCase() + segment.substring(1).toLowerCase();
  }
}
