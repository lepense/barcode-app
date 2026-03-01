/// Result returned by [AiCardService.recognizeCard].
///
/// Any field can be null/empty if the AI could not determine it from the photo.
class AiCardResult {
  final String? merchantName;
  final String? barcodeValue;
  final String? barcodeType;

  const AiCardResult({
    this.merchantName,
    this.barcodeValue,
    this.barcodeType,
  });

  /// True if at least one meaningful field was extracted.
  bool get hasData =>
      (merchantName?.isNotEmpty ?? false) ||
      (barcodeValue?.isNotEmpty ?? false);

  @override
  String toString() =>
      'AiCardResult(merchant: $merchantName, '
      'value: $barcodeValue, type: $barcodeType)';
}
