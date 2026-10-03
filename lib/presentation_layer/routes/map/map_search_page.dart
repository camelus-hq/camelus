import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'atoms/map_search_bar.dart';
import 'atoms/map_search_results.dart';
import 'map_state_notifier.dart';

class MapSearchPage extends ConsumerStatefulWidget {
  const MapSearchPage({super.key});

  @override
  ConsumerState<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends ConsumerState<MapSearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(mapStateProvider).query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MapSearchBar(controller: _controller, isSearchPage: true),
                  const SizedBox(height: 8),
                  MapSearchResults(onPlaceTap: (place) => context.pop(place)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
