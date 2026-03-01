import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import '../models/ai_card_result.dart';

/// Recognises loyalty-card information from a photo using:
///   1. Google MLKit Text Recognition (on-device OCR)
///   2. Gemini 1.5 Flash (cloud AI, parses the OCR text into structured JSON)
///
/// Call [recognizeCard] with an [XFile] from `image_picker`.
class AiCardService {
  AiCardService._();

  static const _geminiPrompt =
      'You are a loyalty card reader. The user photographed a physical loyalty card.\n'
      'Extract from the OCR text below:\n'
      '1. The store/merchant name (Turkish or English brand name, e.g. "Migros", "LC Waikiki")\n'
      '2. Any numeric card number or barcode value\n'
      '3. The barcode type (QR, CODE128, EAN13, EAN8, UPC_A, etc.) — '
      'if unknown, use "CODE128"\n\n'
      'Return ONLY valid JSON — no extra text, no markdown:\n'
      '{"merchantName":"...","barcodeValue":"...","barcodeType":"CODE128"}\n\n'
      'If a field cannot be determined, use an empty string.\n\n'
      'OCR text:\n';

  /// Takes an [XFile] photo, runs on-device OCR then Gemini, returns an [AiCardResult].
  ///
  /// Never throws — errors are caught and returned as a partial result or empty result.
  static Future<AiCardResult> recognizeCard(XFile image) async {
    // ── Step 1: MLKit on-device OCR ─────────────────────────────────────────
    final inputImage = InputImage.fromFilePath(image.path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    String rawText = '';
    try {
      final recognized = await recognizer.processImage(inputImage);
      rawText = recognized.text.trim();
      debugPrint('[AiCardService] OCR text: $rawText');
    } catch (e) {
      debugPrint('[AiCardService] OCR error: $e');
    } finally {
      recognizer.close();
    }

    if (rawText.isEmpty) return const AiCardResult();

    // ── Step 2: Gemini parsing ───────────────────────────────────────────────
    final apiKey = AppConstants.geminiApiKey;
    if (apiKey.isEmpty) {
      debugPrint('[AiCardService] Gemini API key not set — returning OCR fallback.');
      return AiCardResult(merchantName: rawText.split('\n').first.trim());
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      final response = await model.generateContent([
        Content.text('$_geminiPrompt$rawText'),
      ]);
      final jsonText = response.text ?? '';
      debugPrint('[AiCardService] Gemini response: $jsonText');

      // Strip markdown code fences if Gemini added them
      final clean = jsonText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final map = jsonDecode(clean) as Map<String, dynamic>;
      return AiCardResult(
        merchantName: (map['merchantName'] as String?)?.trim(),
        barcodeValue: (map['barcodeValue'] as String?)?.trim(),
        barcodeType: (map['barcodeType'] as String?)?.trim(),
      );
    } catch (e) {
      debugPrint('[AiCardService] Gemini error: $e');
      // Fallback: use first OCR line as merchant name
      return AiCardResult(merchantName: rawText.split('\n').first.trim());
    }
  }
}
