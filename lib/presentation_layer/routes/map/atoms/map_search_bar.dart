import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../map_state_notifier.dart';

class MapSearchBar extends ConsumerWidget {
  final TextEditingController controller;

  final bool isSearchPage;
  final VoidCallback? onTap;

  const MapSearchBar({
    super.key,
    required this.controller,
    this.isSearchPage = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapStateProvider);

    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(28),
      color: Theme.of(context).colorScheme.surface,
      child: TextField(
        controller: controller,
        readOnly: !isSearchPage,
        autofocus: isSearchPage,
        onTap: onTap,
        onChanged: ref.read(mapStateProvider.notifier).setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search destination...',
          prefixIcon: isSearchPage
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                )
              : const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSearchPage && state.isSearching)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (isSearchPage && controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    ref.read(mapStateProvider.notifier).setQuery('');
                  },
                ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                tooltip: 'Profile',
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
