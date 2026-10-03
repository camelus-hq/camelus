import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'location_puck_images.dart';
import 'location_puck_state.dart';

final locationPuckProvider =
    NotifierProvider<LocationPuckController, LocationPuckState>(
      LocationPuckController.new,
    );

/// Configures Mapbox's native location component (puck, accuracy ring and
/// pulse) so everything is drawn by the map in sync with the camera.
class LocationPuckController extends Notifier<LocationPuckState> {
  static const _color = Color(0xFF2F80ED);

  mb.MapboxMap? _map;

  @override
  LocationPuckState build() => const LocationPuckState();

  Future<void> attachMap(mb.MapboxMap map) async {
    _map = map;
    await _apply();
  }

  void detachMap() => _map = null;

  Future<void> setMode(LocationPuckMode mode) async {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode);
    await _apply();
  }

  Future<void> _apply() async {
    final map = _map;
    if (map == null) return;
    final mode = state.mode;
    final dot = await LocationPuckImages.dot(_color);
    final arrow = mode == LocationPuckMode.arrow
        ? await LocationPuckImages.arrow(_color)
        : null;
    if (_map != map) return;
    await map.location.updateSettings(
      mb.LocationComponentSettings(
        enabled: true,
        showAccuracyRing: true,
        accuracyRingColor: _color.withValues(alpha: .15).toARGB32(),
        accuracyRingBorderColor: _color.withValues(alpha: .3).toARGB32(),
        pulsingEnabled: true,
        pulsingColor: _color.toARGB32(),
        pulsingMaxRadius: 40,
        puckBearingEnabled: arrow != null,
        puckBearing: mb.PuckBearing.HEADING,
        locationPuck: mb.LocationPuck(
          locationPuck2D: mb.LocationPuck2D(
            topImage: arrow ?? dot,
            bearingImage: arrow,
          ),
        ),
      ),
    );
  }
}
