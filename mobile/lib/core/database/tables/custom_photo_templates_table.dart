import 'package:drift/drift.dart';

/// Stores user-saved photo templates that appear in the Design Browser.
///
/// Each row represents one photo (with pan/zoom positioning) that the user
/// has saved from their gallery or camera.  Templates persist independently
/// of any card so they can be re-applied whenever needed.
class CustomPhotoTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Absolute path to the image file stored in the app documents directory.
  TextColumn get imagePath => text()();

  /// Pan offset X in logical pixels relative to the card centre.
  RealColumn get offsetX => real().withDefault(const Constant(0.0))();

  /// Pan offset Y in logical pixels relative to the card centre.
  RealColumn get offsetY => real().withDefault(const Constant(0.0))();

  /// Zoom scale (1.0 = no zoom, >1 = zoomed in, <1 = zoomed out).
  RealColumn get scale => real().withDefault(const Constant(1.0))();

  /// Unix epoch milliseconds — used to sort templates newest-first.
  IntColumn get createdAt => integer()();
}
