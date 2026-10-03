/// How the user's location is drawn. Extend with e.g. a compass cone later.
enum LocationPuckMode { dot, arrow }

class LocationPuckState {
  const LocationPuckState({this.mode = LocationPuckMode.dot});

  final LocationPuckMode mode;

  LocationPuckState copyWith({LocationPuckMode? mode}) =>
      LocationPuckState(mode: mode ?? this.mode);
}
