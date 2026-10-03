import 'package:ndk/ndk.dart' as ndk;

import '../../config/nostr_kinds.dart';
import '../../domain_layer/entities/user_location_report.dart';
import '../../domain_layer/repositories/location_report_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/user_location_report_model.dart';

class LocationReportRepositoryImpl implements LocationReportRepository {
  final DartNdkSource dartNdkSource;

  LocationReportRepositoryImpl(this.dartNdkSource);

  @override
  Stream<UserLocationReport> getLocationReports({
    required List<String> geohashes,
    required int since,
  }) {
    final filter = ndk.Filter(
      kinds: [kUserLocationReportKind],
      tags: {"#g": geohashes},
      since: since,
    );

    final subscriptionId = 'locationReports-${geohashes.join(',')}';
    final response = dartNdkSource.dartNdk.requests.subscription(
      filter: filter,
      name: subscriptionId,
      id: subscriptionId,
      cacheRead: true,
      cacheWrite: true,
    );

    return response.stream
        .map(UserLocationReportModel.fromNDKEvent)
        .where((report) => report != null)
        .cast<UserLocationReport>();
  }
}
