/// Every mutation the app has made, newest first.
///
/// Deliberately buried — it is reached through a dashed row at the bottom of
/// Settings, and it shows the data as stored rather than as meant. Grouped by
/// day, because "what happened yesterday" is the only question anyone brings
/// to it.
///
/// This half only fetches; [AuditLogBody] draws.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../providers/database_providers.dart';
import 'audit_log_body.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<AuditLogEntry>>(
      future: ref.read(appDatabaseProvider).auditLogDao.all(),
      builder: (context, snapshot) => AuditLogBody(
        entries: snapshot.connectionState == ConnectionState.done
            ? (snapshot.data ?? const <AuditLogEntry>[])
            : null,
        now: DateTime.now(),
      ),
    );
  }
}
