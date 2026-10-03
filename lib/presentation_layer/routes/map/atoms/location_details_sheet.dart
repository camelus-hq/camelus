import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain_layer/entities/navigation_route.dart';
import '../../../routing/route_paths.dart';
import '../map_state_notifier.dart';

class LocationDetailsSheet extends ConsumerWidget {
  final DraggableScrollableController? controller;

  const LocationDetailsSheet({super.key, this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapStateProvider);
    final destination = state.destination;

    if (destination == null || !state.isLocationSheetOpen) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.35,
      minChildSize: 0.20,
      maxChildSize: 0.75,
      snap: true,
      builder: (context, scrollController) => Material(
        elevation: 16,
        shadowColor: Colors.black38,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: colorScheme.surface,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (destination.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          destination.address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Close details',
                  onPressed: ref
                      .read(mapStateProvider.notifier)
                      .closeLocationSheet,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SegmentedButton<TravelMode>(
              segments: const [
                ButtonSegment(
                  value: TravelMode.driving,
                  icon: Icon(Icons.directions_car),
                  label: Text('Drive'),
                ),
                ButtonSegment(
                  value: TravelMode.walking,
                  icon: Icon(Icons.directions_walk),
                  label: Text('Walk'),
                ),
                ButtonSegment(
                  value: TravelMode.cycling,
                  icon: Icon(Icons.directions_bike),
                  label: Text('Cycle'),
                ),
              ],
              selected: {state.travelMode},
              onSelectionChanged: (modes) => ref
                  .read(mapStateProvider.notifier)
                  .setTravelMode(modes.first),
            ),
            const SizedBox(height: 20),
            if (state.isRouting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.route != null)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => context.push(RoutePaths.mapNavigation()),
                icon: const Icon(Icons.navigation),
                label: Text(
                  'Start Navigation (${(state.route!.lengthMeters / 1000).toStringAsFixed(1)} km)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () =>
                    ref.read(mapStateProvider.notifier).calculateRoute(),
                icon: const Icon(Icons.directions),
                label: const Text(
                  'Get Directions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
