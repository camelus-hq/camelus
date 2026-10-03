import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../domain_layer/entities/map_coordinate.dart';
import '../../../domain_layer/entities/map_place.dart';
import '../../../domain_layer/entities/user_location_report.dart';
import '../../../domain_layer/entities/user_metadata.dart';
import '../../providers/metadata_provider.dart';
import 'atoms/location_action_button.dart';
import 'atoms/location_details_sheet.dart';
import 'atoms/location_report_details_sheet.dart';
import 'atoms/map_error_banner.dart';
import 'package:go_router/go_router.dart';
import 'atoms/map_search_bar.dart';
import 'atoms/navigation_action_button.dart';
import 'map_location_reports_notifier.dart';
import 'map_state_notifier.dart';
import 'utils/map_pin_generator.dart';
import 'user_location_puck/location_puck_controller.dart';
import 'utils/user_location_pin_generator.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _searchController = TextEditingController();
  late final DraggableScrollableController _sheetController;
  MapboxMap? _map;
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _lineManager;
  PointAnnotationManager? _reportManager;
  TypedFeaturesetFeature<StandardPOIs>? _selectedPoi;
  Uint8List? _cachedPinBytes;
  final Map<String, PointAnnotation> _reportAnnotationsByEventId = {};
  final Map<String, UserLocationReport> _reportsByAnnotationId = {};
  final Map<String, StreamSubscription<UserMetadata>>
  _metadataSubscriptionsByEventId = {};
  Timer? _viewportDebounce;
  double _reportOpacity = 0;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _sheetController.addListener(_onSheetChanged);
  }

  void _onSheetChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewportDebounce?.cancel();
    for (final subscription in _metadataSubscriptionsByEventId.values) {
      subscription.cancel();
    }
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    if (!mounted) return;
    _map = map;
    map.addInteraction(
      TapInteraction(StandardPOIs(), _onStandardPoiTap),
      interactionID: 'select-standard-poi',
    );
    map.addInteraction(
      TapInteraction.onMap(_selectMapLocation),
      interactionID: 'select-map-location',
    );
    if (!mounted || _map != map) return;
    _pointManager = await map.annotations.createPointAnnotationManager();
    if (!mounted || _map != map) return;
    _lineManager = await map.annotations.createPolylineAnnotationManager();
    if (!mounted || _map != map) return;
    _reportManager = await map.annotations.createPointAnnotationManager();
    _reportManager?.tapEvents(onTap: _onReportAnnotationTap);
    await _reportManager?.setIconOpacity(_reportOpacity);
    if (!mounted || _map != map) return;
    await ref.read(locationPuckProvider.notifier).attachMap(map);
    if (!mounted || _map != map) return;
    await _render(ref.read(mapStateProvider));
    await _onViewportSettled();
  }

  void _scheduleViewportUpdate() {
    _viewportDebounce?.cancel();
    _viewportDebounce = Timer(
      const Duration(milliseconds: 400),
      _onViewportSettled,
    );
  }

  Future<void> _onViewportSettled() async {
    final map = _map;
    if (map == null || !mounted) return;
    final cameraState = await map.getCameraState();
    if (!mounted || _map != map) return;
    _onCameraChanged(cameraState.zoom);
    final center = MapCoordinate(
      latitude: cameraState.center.coordinates.lat.toDouble(),
      longitude: cameraState.center.coordinates.lng.toDouble(),
    );
    ref
        .read(mapLocationReportsProvider.notifier)
        .onViewportChanged(center, cameraState.zoom);
  }

  // pins are fully transparent at minZoomForReports and fully opaque one
  // zoom level above it, so they fade in/out proportionally while zooming
  double _reportOpacityForZoom(double zoom) {
    const minZoom = MapLocationReportsNotifier.minZoomForReports;
    const fullZoom = minZoom + 1;
    if (zoom <= minZoom) return 0;
    if (zoom >= fullZoom) return 1;
    return zoom - minZoom;
  }

  void _onCameraChanged(double zoom) {
    final opacity = _reportOpacityForZoom(zoom);
    if ((opacity - _reportOpacity).abs() > 0.001) {
      _reportOpacity = opacity;
      final manager = _reportManager;
      if (manager != null) {
        unawaited(manager.setIconOpacity(opacity));
      }
    }
  }

  void _onReportAnnotationTap(PointAnnotation annotation) {
    final report = _reportsByAnnotationId[annotation.id];
    if (report == null) return;
    _selectLocationReport(report);
  }

  Future<void> _selectLocationReport(UserLocationReport report) async {
    await _deselectStandardPoi();
    if (!mounted) return;
    ref.read(mapStateProvider.notifier).selectLocationReport(report);
  }

  Future<void> _deselectStandardPoi() async {
    final selectedPoi = _selectedPoi;
    final map = _map;
    _selectedPoi = null;
    if (selectedPoi == null || map == null) return;

    await map.setFeatureStateForFeaturesetFeature(
      selectedPoi,
      StandardPOIsState(hide: false),
    );
  }

  Future<void> _openSearch() async {
    final place = await context.push<MapPlace>('/map/search');
    if (place == null || !mounted) return;
    _searchController.text = place.name;
    await _selectDestination(place);
  }

  Future<void> _selectDestination(
    MapPlace destination, {
    TypedFeaturesetFeature<StandardPOIs>? poi,
  }) async {
    await _deselectStandardPoi();

    final map = _map;
    if (poi != null && map != null) {
      await map.setFeatureStateForFeaturesetFeature(
        poi,
        StandardPOIsState(hide: true),
      );
      if (!mounted || _map != map) return;
      _selectedPoi = poi;
    }

    if (!mounted) return;
    ref.read(mapStateProvider.notifier).selectDestination(destination);
    await _focusPlace(destination.coordinate);
  }

  Future<void> _onStandardPoiTap(
    TypedFeaturesetFeature<StandardPOIs> poi,
    MapContentGestureContext _,
  ) async {
    final rawCoordinates = poi.geometry['coordinates'];
    if (rawCoordinates is! List ||
        rawCoordinates.length < 2 ||
        rawCoordinates[0] is! num ||
        rawCoordinates[1] is! num) {
      return;
    }
    final longitude = (rawCoordinates[0] as num).toDouble();
    final latitude = (rawCoordinates[1] as num).toDouble();
    final category = poi.category;
    final group = poi.group;
    await _selectDestination(
      MapPlace(
        name: poi.name ?? 'Point of interest',
        address: [category, group].whereType<String>().join(' · '),
        coordinate: MapCoordinate(longitude: longitude, latitude: latitude),
      ),
      poi: poi,
    );
  }

  Future<void> _syncReportAnnotations(List<UserLocationReport> reports) async {
    final manager = _reportManager;
    if (manager == null || !mounted) return;
    final ringColor = Theme.of(context).colorScheme.secondary;

    final currentEventIds = reports.map((report) => report.eventId).toSet();
    final removedEventIds = _reportAnnotationsByEventId.keys
        .where((eventId) => !currentEventIds.contains(eventId))
        .toList();
    for (final eventId in removedEventIds) {
      final annotation = _reportAnnotationsByEventId.remove(eventId);
      if (annotation != null) {
        _reportsByAnnotationId.remove(annotation.id);
        await manager.delete(annotation);
      }
      await _metadataSubscriptionsByEventId.remove(eventId)?.cancel();
    }

    for (final report in reports) {
      if (_reportAnnotationsByEventId.containsKey(report.eventId)) continue;

      // show a pin right away; the avatar is filled in once metadata streams in
      final placeholderBytes =
          await UserLocationPinGenerator.createPlaceholderPinImage(
            ringColor: ringColor,
          );
      if (!mounted || _reportManager != manager) return;
      if (_reportAnnotationsByEventId.containsKey(report.eventId)) continue;

      final annotation = await manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: _position(report.coordinate)),
          image: placeholderBytes,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
      _reportAnnotationsByEventId[report.eventId] = annotation;
      _reportsByAnnotationId[annotation.id] = report;

      _metadataSubscriptionsByEventId[report.eventId] = ref
          .read(metadataProvider)
          .getMetadataByPubkey(report.pubkey)
          .listen((metadata) => _onReportMetadata(report, metadata, ringColor));
    }
  }

  Future<void> _onReportMetadata(
    UserLocationReport report,
    UserMetadata metadata,
    Color ringColor,
  ) async {
    final manager = _reportManager;
    final annotation = _reportAnnotationsByEventId[report.eventId];
    if (manager == null || annotation == null || !mounted) return;

    final pinBytes = await UserLocationPinGenerator.createPinImage(
      pubkey: report.pubkey,
      avatarUrl: metadata.picture,
      ringColor: ringColor,
    );
    if (!mounted || _reportManager != manager) return;
    if (_reportAnnotationsByEventId[report.eventId] != annotation) return;

    annotation.image = pinBytes;
    await manager.update(annotation);
  }

  Future<void> _render(MapState state) async {
    final map = _map;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary.toARGB32();
    if (!mounted || map == null) return;
    await _pointManager?.deleteAll();
    if (!mounted || _map != map) return;
    await _lineManager?.deleteAll();
    if (!mounted || _map != map) return;

    final destination = state.destination;
    if (destination != null) {
      _cachedPinBytes ??= await MapPinGenerator.createPinImage(
        colorScheme.error,
      );
      if (!mounted || _map != map) return;
      await _pointManager?.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              destination.coordinate.longitude,
              destination.coordinate.latitude,
            ),
          ),
          image: _cachedPinBytes!,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
    }
    if (!mounted || _map != map) return;
    final route = state.route;
    if (route != null && route.geometry.length > 1) {
      await _lineManager?.create(
        PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: route.geometry.map(_position).toList(),
          ),
          lineColor: primaryColor,
          lineWidth: 6,
        ),
      );
    }
  }

  Position _position(MapCoordinate coordinate) =>
      Position(coordinate.longitude, coordinate.latitude);

  Future<void> _flyToLocation(MapCoordinate location) async {
    final map = _map;
    if (map == null || !mounted) return;
    await map.flyTo(
      CameraOptions(center: Point(coordinates: _position(location)), zoom: 15),
      MapAnimationOptions(duration: 650),
    );
  }

  Future<void> _handleLocationFabTap() async {
    await ref.read(mapStateProvider.notifier).onLocationFabPressed();
    final currentState = ref.read(mapStateProvider);
    if (currentState.currentLocation != null &&
        currentState.locationStatus == LocationLockStatus.lockedCentered) {
      await _flyToLocation(currentState.currentLocation!);
    }
  }

  Future<void> _selectMapLocation(MapContentGestureContext context) async {
    if (!mounted) return;
    final coordinate = MapCoordinate(
      longitude: context.point.coordinates.lng.toDouble(),
      latitude: context.point.coordinates.lat.toDouble(),
    );
    await _deselectStandardPoi();
    if (!mounted) return;
    ref.read(mapStateProvider.notifier).selectMapLocation(coordinate);
    await _focusPlace(coordinate);
  }

  Future<void> _focusPlace(MapCoordinate coordinate) =>
      _map?.flyTo(
        CameraOptions(
          center: Point(coordinates: _position(coordinate)),
          zoom: 15,
        ),
        MapAnimationOptions(duration: 650),
      ) ??
      Future.value();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapStateProvider);

    ref.listen<MapState>(mapStateProvider, (previous, next) {
      if (previous?.destination != next.destination ||
          previous?.route != next.route) {
        _render(next);
      }

      if (previous?.destination != null && next.destination == null) {
        _deselectStandardPoi();
      }

      if (next.destination == null && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }

      final location = next.currentLocation;
      if (location != null) {
        final becameLocked =
            previous?.locationStatus != LocationLockStatus.lockedCentered &&
            next.locationStatus == LocationLockStatus.lockedCentered;
        if (becameLocked) {
          _flyToLocation(location);
        }
      }
    });

    ref.listen<MapLocationReportsState>(mapLocationReportsProvider, (
      previous,
      next,
    ) {
      _syncReportAnnotations(next.reports);
    });

    final hasRoute = state.route != null;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isDestinationSheetOpen =
        state.destination != null && state.isLocationSheetOpen;
    final isReportSheetOpen = state.selectedLocationReport != null;
    final isSheetOpen = isDestinationSheetOpen || isReportSheetOpen;

    final double currentSheetExtent = isSheetOpen && _sheetController.isAttached
        ? _sheetController.size
        : (isSheetOpen ? 0.35 : 0.0);

    final double fabBottom = isSheetOpen
        ? (currentSheetExtent * screenHeight) + 16.0
        : 24.0;

    final bool hideFabGroup = isSheetOpen && currentSheetExtent >= 0.50;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            onScrollListener: (_) {
              ref.read(mapStateProvider.notifier).onMapMovedByUser();
            },
            onCameraChangeListener: (data) {
              _onCameraChanged(data.cameraState.zoom);
              _scheduleViewportUpdate();
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MapSearchBar(
                        controller: _searchController,
                        onTap: _openSearch,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: fabBottom,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: hideFabGroup ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: hideFabGroup,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    NavigationActionButton(
                      onPressed: () {
                        // Start route navigation (no logic for now)
                      },
                    ),
                    const SizedBox(height: 12),
                    LocationActionButton(
                      onPressed: _handleLocationFabTap,
                      hasActiveRoute: hasRoute,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isDestinationSheetOpen)
            LocationDetailsSheet(controller: _sheetController),
          if (isReportSheetOpen)
            LocationReportDetailsSheet(controller: _sheetController),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: MapErrorBanner(),
          ),
        ],
      ),
    );
  }
}
