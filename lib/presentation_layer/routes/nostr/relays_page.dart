import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RelaysPage extends ConsumerStatefulWidget {
  const RelaysPage({super.key});

  @override
  ConsumerState<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends ConsumerState<RelaysPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ndk = ref.watch(ndkProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context)!.relays),
      ),
      body: SafeArea(
        child: StreamBuilder<List<RelayConnectivity>>(
          stream: ndk.connectivity.relayConnectivityChanges,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final relays = snapshot.data!;

              return ListView.builder(
                itemCount: relays.length,
                itemBuilder: (context, index) {
                  final relay = relays[index];
                  final url = relay.url;

                  return FutureBuilder<RelayInfo?>(
                    future: ndk.connectivity.getRelayInfo(url),
                    builder: (context, infoSnapshot) {
                      final relayInfo = infoSnapshot.data;
                      final hasPrivacyPolicy =
                          relayInfo?.privacyPolicy.isNotEmpty ?? false;
                      final hasTermsOfService =
                          relayInfo?.termsOfService.isNotEmpty ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  relayInfo?.icon != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                          child: Image.network(
                                            relayInfo!.icon,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: 50,
                                                    height: 50,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inverseSurface,
                                                    child: Icon(
                                                      PhosphorIcons.globe,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.inverseSurface,
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                          child: Icon(
                                            PhosphorIcons.globe,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                          ),
                                        ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (relayInfo?.name.isNotEmpty ?? false)
                                              ? relayInfo!.name
                                              : url,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          url,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.inverseSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    relay.isConnected
                                        ? PhosphorIcons.plugsConnected
                                        : PhosphorIcons.plugs,
                                    color: relay.isConnected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors
                                              .orangeAccent, //! hard coded color
                                    size: 28,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatItem(
                                    context: context,
                                    icon: PhosphorIcons.arrowDown,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.eventsRead,
                                    value: relay.stats.eventsRead.toString(),
                                  ),
                                  _StatItem(
                                    context: context,
                                    icon: PhosphorIcons.arrowUp,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.eventsWritten,
                                    value: relay.stats.eventsWritten.toString(),
                                  ),
                                  _StatItem(
                                    context: context,
                                    icon: PhosphorIcons.lighthouse,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.connectionSource,
                                    value: relay.relay.connectionSource.name,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (relayInfo?.description.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    relayInfo!.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.inverseSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              if (relayInfo?.contact.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    "contact: ${relayInfo!.contact}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.inverseSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              // Only show policy links section if at least one link is available
                              if (hasPrivacyPolicy || hasTermsOfService)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (hasPrivacyPolicy)
                                        TextButton(
                                          onPressed: () async {
                                            launchUrlString(
                                              relayInfo!.privacyPolicy,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.privacyPolicy,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      if (hasPrivacyPolicy && hasTermsOfService)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            '•',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                            ),
                                          ),
                                        ),
                                      if (hasTermsOfService)
                                        TextButton(
                                          onPressed: () async {
                                            launchUrlString(
                                              relayInfo!.termsOfService,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.termsOfService,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }

            return Center(
              child: Text(AppLocalizations.of(context)!.noDataAvailable),
            );
          },
        ),
      ),
    );
  }
}

// Helper widget for stats display
class _StatItem extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String label;
  final String value;
  final double maxWidth = 120;

  const _StatItem({
    required this.context,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.inverseSurface,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
