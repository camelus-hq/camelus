import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../providers/metadata_provider.dart';
import '../map_state_notifier.dart';
import 'user_location_pin.dart';

class LocationReportDetailsSheet extends ConsumerWidget {
  final DraggableScrollableController? controller;

  const LocationReportDetailsSheet({super.key, this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapStateProvider);
    final report = state.selectedLocationReport;

    if (report == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metadataStream = ref
        .read(metadataProvider)
        .getMetadataByPubkey(report.pubkey);

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
        child: StreamBuilder<UserMetadata>(
          stream: metadataStream,
          builder: (context, snapshot) {
            final metadata = snapshot.data;
            final displayName =
                (metadata?.name != null && metadata!.name!.isNotEmpty)
                ? metadata.name!
                : '${report.pubkey.substring(0, 12)}...';

            return ListView(
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
                    UserLocationPin(
                      pubkey: report.pubkey,
                      imageUrl: metadata?.picture,
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(
                              DateTime.fromMillisecondsSinceEpoch(
                                report.createdAt * 1000,
                              ),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Close details',
                      onPressed: ref
                          .read(mapStateProvider.notifier)
                          .closeLocationReportSheet,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (report.content.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(report.content, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                Text(
                  '${report.coordinate.latitude.toStringAsFixed(5)}, '
                  '${report.coordinate.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
