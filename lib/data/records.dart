/// Records that belong to the app, not the finance engine.
library;

enum AuditActor { user, sms, ai, system }

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.at,
    required this.actor,
    required this.action,
    required this.entity,
    this.entityId,
    required this.summary,
    this.beforeJson,
    this.afterJson,
  });

  final String id;

  /// 'YYYY-MM-DDTHH:mm:ss', local time.
  final String at;
  final AuditActor actor;

  /// Machine-readable verb, e.g. 'transaction.add', 'account.archive'.
  final String action;
  final String entity;
  final String? entityId;
  final String summary;
  final String? beforeJson;
  final String? afterJson;
}

/// The configurable lists that share the generic ConfigItem table.
abstract final class ConfigList {
  static const accountTypes = 'account_types';
  static const contributionTypes = 'contribution_types';
  static const classificationRules = 'classification_rules';
  static const banks = 'banks';
}

class ConfigItem {
  const ConfigItem({
    required this.id,
    required this.listKey,
    required this.name,
    this.description = '',
    this.active = true,
    this.isDefault = false,
  });

  final String id;
  final String listKey;
  final String name;
  final String description;
  final bool active;
  final bool isDefault;
}
