import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../providers/database_providers.dart';

/// The buried, advanced-users-only log of every mutation (Settings §
/// Audit log — "deliberately buried, not a main section"). Read-only list,
/// newest first.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  static final _fmt = DateFormat('MMM d, h:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text('Audit log', style: AppTextStyles.screenTitle.copyWith(color: colors.text))),
      body: FutureBuilder<List<AuditLogEntry>>(
        future: ref.read(appDatabaseProvider).auditLogDao.all(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const [];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entries.isEmpty) {
            return Center(child: Text('No activity yet', style: AppTextStyles.body.copyWith(color: colors.textMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpace.screenPadding),
            itemCount: entries.length,
            separatorBuilder: (_, __) => Divider(color: colors.divider, height: 1),
            itemBuilder: (context, i) {
              final e = entries[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.action} · ${e.entityType}', style: AppTextStyles.body.copyWith(color: colors.text)),
                    const SizedBox(height: 2),
                    Text(_fmt.format(e.timestamp), style: AppTextStyles.meta.copyWith(color: colors.textMuted, fontSize: 11)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
