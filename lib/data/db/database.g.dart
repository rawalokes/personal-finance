// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortNameMeta = const VerificationMeta(
    'shortName',
  );
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
    'short_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _institutionMeta = const VerificationMeta(
    'institution',
  );
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountTypeIdMeta = const VerificationMeta(
    'accountTypeId',
  );
  @override
  late final GeneratedColumn<String> accountTypeId = GeneratedColumn<String>(
    'account_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountGroupMeta = const VerificationMeta(
    'accountGroup',
  );
  @override
  late final GeneratedColumn<String> accountGroup = GeneratedColumn<String>(
    'account_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maskedNumberMeta = const VerificationMeta(
    'maskedNumber',
  );
  @override
  late final GeneratedColumn<String> maskedNumber = GeneratedColumn<String>(
    'masked_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _smsSenderMeta = const VerificationMeta(
    'smsSender',
  );
  @override
  late final GeneratedColumn<String> smsSender = GeneratedColumn<String>(
    'sms_sender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoUpdateFromSmsMeta = const VerificationMeta(
    'autoUpdateFromSms',
  );
  @override
  late final GeneratedColumn<bool> autoUpdateFromSms = GeneratedColumn<bool>(
    'auto_update_from_sms',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_update_from_sms" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<int> openingBalance = GeneratedColumn<int>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<int> creditLimit = GeneratedColumn<int>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statementDueDateMeta = const VerificationMeta(
    'statementDueDate',
  );
  @override
  late final GeneratedColumn<String> statementDueDate = GeneratedColumn<String>(
    'statement_due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastReconciledMeta = const VerificationMeta(
    'lastReconciled',
  );
  @override
  late final GeneratedColumn<String> lastReconciled = GeneratedColumn<String>(
    'last_reconciled',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    shortName,
    institution,
    accountTypeId,
    accountGroup,
    kind,
    maskedNumber,
    smsSender,
    autoUpdateFromSms,
    openingBalance,
    balance,
    creditLimit,
    statementDueDate,
    note,
    archived,
    lastReconciled,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('short_name')) {
      context.handle(
        _shortNameMeta,
        shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta),
      );
    } else if (isInserting) {
      context.missing(_shortNameMeta);
    }
    if (data.containsKey('institution')) {
      context.handle(
        _institutionMeta,
        institution.isAcceptableOrUnknown(
          data['institution']!,
          _institutionMeta,
        ),
      );
    }
    if (data.containsKey('account_type_id')) {
      context.handle(
        _accountTypeIdMeta,
        accountTypeId.isAcceptableOrUnknown(
          data['account_type_id']!,
          _accountTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('account_group')) {
      context.handle(
        _accountGroupMeta,
        accountGroup.isAcceptableOrUnknown(
          data['account_group']!,
          _accountGroupMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountGroupMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('masked_number')) {
      context.handle(
        _maskedNumberMeta,
        maskedNumber.isAcceptableOrUnknown(
          data['masked_number']!,
          _maskedNumberMeta,
        ),
      );
    }
    if (data.containsKey('sms_sender')) {
      context.handle(
        _smsSenderMeta,
        smsSender.isAcceptableOrUnknown(data['sms_sender']!, _smsSenderMeta),
      );
    }
    if (data.containsKey('auto_update_from_sms')) {
      context.handle(
        _autoUpdateFromSmsMeta,
        autoUpdateFromSms.isAcceptableOrUnknown(
          data['auto_update_from_sms']!,
          _autoUpdateFromSmsMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingBalanceMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('statement_due_date')) {
      context.handle(
        _statementDueDateMeta,
        statementDueDate.isAcceptableOrUnknown(
          data['statement_due_date']!,
          _statementDueDateMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('last_reconciled')) {
      context.handle(
        _lastReconciledMeta,
        lastReconciled.isAcceptableOrUnknown(
          data['last_reconciled']!,
          _lastReconciledMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_name'],
      )!,
      institution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution'],
      ),
      accountTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type_id'],
      ),
      accountGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_group'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      maskedNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}masked_number'],
      ),
      smsSender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sms_sender'],
      ),
      autoUpdateFromSms: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_update_from_sms'],
      )!,
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit'],
      ),
      statementDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statement_due_date'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      lastReconciled: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_reconciled'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String name;
  final String shortName;
  final String? institution;
  final String? accountTypeId;
  final String accountGroup;
  final String kind;
  final String? maskedNumber;
  final String? smsSender;
  final bool autoUpdateFromSms;
  final int openingBalance;
  final int balance;
  final int? creditLimit;
  final String? statementDueDate;
  final String? note;
  final bool archived;
  final String? lastReconciled;

  /// Display order (Home cards, Accounts groups). New accounts go last.
  final int sortOrder;
  const AccountRow({
    required this.id,
    required this.name,
    required this.shortName,
    this.institution,
    this.accountTypeId,
    required this.accountGroup,
    required this.kind,
    this.maskedNumber,
    this.smsSender,
    required this.autoUpdateFromSms,
    required this.openingBalance,
    required this.balance,
    this.creditLimit,
    this.statementDueDate,
    this.note,
    required this.archived,
    this.lastReconciled,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['short_name'] = Variable<String>(shortName);
    if (!nullToAbsent || institution != null) {
      map['institution'] = Variable<String>(institution);
    }
    if (!nullToAbsent || accountTypeId != null) {
      map['account_type_id'] = Variable<String>(accountTypeId);
    }
    map['account_group'] = Variable<String>(accountGroup);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || maskedNumber != null) {
      map['masked_number'] = Variable<String>(maskedNumber);
    }
    if (!nullToAbsent || smsSender != null) {
      map['sms_sender'] = Variable<String>(smsSender);
    }
    map['auto_update_from_sms'] = Variable<bool>(autoUpdateFromSms);
    map['opening_balance'] = Variable<int>(openingBalance);
    map['balance'] = Variable<int>(balance);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<int>(creditLimit);
    }
    if (!nullToAbsent || statementDueDate != null) {
      map['statement_due_date'] = Variable<String>(statementDueDate);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || lastReconciled != null) {
      map['last_reconciled'] = Variable<String>(lastReconciled);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      shortName: Value(shortName),
      institution: institution == null && nullToAbsent
          ? const Value.absent()
          : Value(institution),
      accountTypeId: accountTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountTypeId),
      accountGroup: Value(accountGroup),
      kind: Value(kind),
      maskedNumber: maskedNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(maskedNumber),
      smsSender: smsSender == null && nullToAbsent
          ? const Value.absent()
          : Value(smsSender),
      autoUpdateFromSms: Value(autoUpdateFromSms),
      openingBalance: Value(openingBalance),
      balance: Value(balance),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      statementDueDate: statementDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDueDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      archived: Value(archived),
      lastReconciled: lastReconciled == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReconciled),
      sortOrder: Value(sortOrder),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      shortName: serializer.fromJson<String>(json['shortName']),
      institution: serializer.fromJson<String?>(json['institution']),
      accountTypeId: serializer.fromJson<String?>(json['accountTypeId']),
      accountGroup: serializer.fromJson<String>(json['accountGroup']),
      kind: serializer.fromJson<String>(json['kind']),
      maskedNumber: serializer.fromJson<String?>(json['maskedNumber']),
      smsSender: serializer.fromJson<String?>(json['smsSender']),
      autoUpdateFromSms: serializer.fromJson<bool>(json['autoUpdateFromSms']),
      openingBalance: serializer.fromJson<int>(json['openingBalance']),
      balance: serializer.fromJson<int>(json['balance']),
      creditLimit: serializer.fromJson<int?>(json['creditLimit']),
      statementDueDate: serializer.fromJson<String?>(json['statementDueDate']),
      note: serializer.fromJson<String?>(json['note']),
      archived: serializer.fromJson<bool>(json['archived']),
      lastReconciled: serializer.fromJson<String?>(json['lastReconciled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'shortName': serializer.toJson<String>(shortName),
      'institution': serializer.toJson<String?>(institution),
      'accountTypeId': serializer.toJson<String?>(accountTypeId),
      'accountGroup': serializer.toJson<String>(accountGroup),
      'kind': serializer.toJson<String>(kind),
      'maskedNumber': serializer.toJson<String?>(maskedNumber),
      'smsSender': serializer.toJson<String?>(smsSender),
      'autoUpdateFromSms': serializer.toJson<bool>(autoUpdateFromSms),
      'openingBalance': serializer.toJson<int>(openingBalance),
      'balance': serializer.toJson<int>(balance),
      'creditLimit': serializer.toJson<int?>(creditLimit),
      'statementDueDate': serializer.toJson<String?>(statementDueDate),
      'note': serializer.toJson<String?>(note),
      'archived': serializer.toJson<bool>(archived),
      'lastReconciled': serializer.toJson<String?>(lastReconciled),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AccountRow copyWith({
    String? id,
    String? name,
    String? shortName,
    Value<String?> institution = const Value.absent(),
    Value<String?> accountTypeId = const Value.absent(),
    String? accountGroup,
    String? kind,
    Value<String?> maskedNumber = const Value.absent(),
    Value<String?> smsSender = const Value.absent(),
    bool? autoUpdateFromSms,
    int? openingBalance,
    int? balance,
    Value<int?> creditLimit = const Value.absent(),
    Value<String?> statementDueDate = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? archived,
    Value<String?> lastReconciled = const Value.absent(),
    int? sortOrder,
  }) => AccountRow(
    id: id ?? this.id,
    name: name ?? this.name,
    shortName: shortName ?? this.shortName,
    institution: institution.present ? institution.value : this.institution,
    accountTypeId: accountTypeId.present
        ? accountTypeId.value
        : this.accountTypeId,
    accountGroup: accountGroup ?? this.accountGroup,
    kind: kind ?? this.kind,
    maskedNumber: maskedNumber.present ? maskedNumber.value : this.maskedNumber,
    smsSender: smsSender.present ? smsSender.value : this.smsSender,
    autoUpdateFromSms: autoUpdateFromSms ?? this.autoUpdateFromSms,
    openingBalance: openingBalance ?? this.openingBalance,
    balance: balance ?? this.balance,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    statementDueDate: statementDueDate.present
        ? statementDueDate.value
        : this.statementDueDate,
    note: note.present ? note.value : this.note,
    archived: archived ?? this.archived,
    lastReconciled: lastReconciled.present
        ? lastReconciled.value
        : this.lastReconciled,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
      institution: data.institution.present
          ? data.institution.value
          : this.institution,
      accountTypeId: data.accountTypeId.present
          ? data.accountTypeId.value
          : this.accountTypeId,
      accountGroup: data.accountGroup.present
          ? data.accountGroup.value
          : this.accountGroup,
      kind: data.kind.present ? data.kind.value : this.kind,
      maskedNumber: data.maskedNumber.present
          ? data.maskedNumber.value
          : this.maskedNumber,
      smsSender: data.smsSender.present ? data.smsSender.value : this.smsSender,
      autoUpdateFromSms: data.autoUpdateFromSms.present
          ? data.autoUpdateFromSms.value
          : this.autoUpdateFromSms,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      balance: data.balance.present ? data.balance.value : this.balance,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      statementDueDate: data.statementDueDate.present
          ? data.statementDueDate.value
          : this.statementDueDate,
      note: data.note.present ? data.note.value : this.note,
      archived: data.archived.present ? data.archived.value : this.archived,
      lastReconciled: data.lastReconciled.present
          ? data.lastReconciled.value
          : this.lastReconciled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName, ')
          ..write('institution: $institution, ')
          ..write('accountTypeId: $accountTypeId, ')
          ..write('accountGroup: $accountGroup, ')
          ..write('kind: $kind, ')
          ..write('maskedNumber: $maskedNumber, ')
          ..write('smsSender: $smsSender, ')
          ..write('autoUpdateFromSms: $autoUpdateFromSms, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('balance: $balance, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('statementDueDate: $statementDueDate, ')
          ..write('note: $note, ')
          ..write('archived: $archived, ')
          ..write('lastReconciled: $lastReconciled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    shortName,
    institution,
    accountTypeId,
    accountGroup,
    kind,
    maskedNumber,
    smsSender,
    autoUpdateFromSms,
    openingBalance,
    balance,
    creditLimit,
    statementDueDate,
    note,
    archived,
    lastReconciled,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.shortName == this.shortName &&
          other.institution == this.institution &&
          other.accountTypeId == this.accountTypeId &&
          other.accountGroup == this.accountGroup &&
          other.kind == this.kind &&
          other.maskedNumber == this.maskedNumber &&
          other.smsSender == this.smsSender &&
          other.autoUpdateFromSms == this.autoUpdateFromSms &&
          other.openingBalance == this.openingBalance &&
          other.balance == this.balance &&
          other.creditLimit == this.creditLimit &&
          other.statementDueDate == this.statementDueDate &&
          other.note == this.note &&
          other.archived == this.archived &&
          other.lastReconciled == this.lastReconciled &&
          other.sortOrder == this.sortOrder);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> shortName;
  final Value<String?> institution;
  final Value<String?> accountTypeId;
  final Value<String> accountGroup;
  final Value<String> kind;
  final Value<String?> maskedNumber;
  final Value<String?> smsSender;
  final Value<bool> autoUpdateFromSms;
  final Value<int> openingBalance;
  final Value<int> balance;
  final Value<int?> creditLimit;
  final Value<String?> statementDueDate;
  final Value<String?> note;
  final Value<bool> archived;
  final Value<String?> lastReconciled;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.shortName = const Value.absent(),
    this.institution = const Value.absent(),
    this.accountTypeId = const Value.absent(),
    this.accountGroup = const Value.absent(),
    this.kind = const Value.absent(),
    this.maskedNumber = const Value.absent(),
    this.smsSender = const Value.absent(),
    this.autoUpdateFromSms = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.balance = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.statementDueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.archived = const Value.absent(),
    this.lastReconciled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    required String shortName,
    this.institution = const Value.absent(),
    this.accountTypeId = const Value.absent(),
    required String accountGroup,
    required String kind,
    this.maskedNumber = const Value.absent(),
    this.smsSender = const Value.absent(),
    this.autoUpdateFromSms = const Value.absent(),
    required int openingBalance,
    required int balance,
    this.creditLimit = const Value.absent(),
    this.statementDueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.archived = const Value.absent(),
    this.lastReconciled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       shortName = Value(shortName),
       accountGroup = Value(accountGroup),
       kind = Value(kind),
       openingBalance = Value(openingBalance),
       balance = Value(balance);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? shortName,
    Expression<String>? institution,
    Expression<String>? accountTypeId,
    Expression<String>? accountGroup,
    Expression<String>? kind,
    Expression<String>? maskedNumber,
    Expression<String>? smsSender,
    Expression<bool>? autoUpdateFromSms,
    Expression<int>? openingBalance,
    Expression<int>? balance,
    Expression<int>? creditLimit,
    Expression<String>? statementDueDate,
    Expression<String>? note,
    Expression<bool>? archived,
    Expression<String>? lastReconciled,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (shortName != null) 'short_name': shortName,
      if (institution != null) 'institution': institution,
      if (accountTypeId != null) 'account_type_id': accountTypeId,
      if (accountGroup != null) 'account_group': accountGroup,
      if (kind != null) 'kind': kind,
      if (maskedNumber != null) 'masked_number': maskedNumber,
      if (smsSender != null) 'sms_sender': smsSender,
      if (autoUpdateFromSms != null) 'auto_update_from_sms': autoUpdateFromSms,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (balance != null) 'balance': balance,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (statementDueDate != null) 'statement_due_date': statementDueDate,
      if (note != null) 'note': note,
      if (archived != null) 'archived': archived,
      if (lastReconciled != null) 'last_reconciled': lastReconciled,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? shortName,
    Value<String?>? institution,
    Value<String?>? accountTypeId,
    Value<String>? accountGroup,
    Value<String>? kind,
    Value<String?>? maskedNumber,
    Value<String?>? smsSender,
    Value<bool>? autoUpdateFromSms,
    Value<int>? openingBalance,
    Value<int>? balance,
    Value<int?>? creditLimit,
    Value<String?>? statementDueDate,
    Value<String?>? note,
    Value<bool>? archived,
    Value<String?>? lastReconciled,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      institution: institution ?? this.institution,
      accountTypeId: accountTypeId ?? this.accountTypeId,
      accountGroup: accountGroup ?? this.accountGroup,
      kind: kind ?? this.kind,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      smsSender: smsSender ?? this.smsSender,
      autoUpdateFromSms: autoUpdateFromSms ?? this.autoUpdateFromSms,
      openingBalance: openingBalance ?? this.openingBalance,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDueDate: statementDueDate ?? this.statementDueDate,
      note: note ?? this.note,
      archived: archived ?? this.archived,
      lastReconciled: lastReconciled ?? this.lastReconciled,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (accountTypeId.present) {
      map['account_type_id'] = Variable<String>(accountTypeId.value);
    }
    if (accountGroup.present) {
      map['account_group'] = Variable<String>(accountGroup.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (maskedNumber.present) {
      map['masked_number'] = Variable<String>(maskedNumber.value);
    }
    if (smsSender.present) {
      map['sms_sender'] = Variable<String>(smsSender.value);
    }
    if (autoUpdateFromSms.present) {
      map['auto_update_from_sms'] = Variable<bool>(autoUpdateFromSms.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<int>(openingBalance.value);
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<int>(creditLimit.value);
    }
    if (statementDueDate.present) {
      map['statement_due_date'] = Variable<String>(statementDueDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (lastReconciled.present) {
      map['last_reconciled'] = Variable<String>(lastReconciled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName, ')
          ..write('institution: $institution, ')
          ..write('accountTypeId: $accountTypeId, ')
          ..write('accountGroup: $accountGroup, ')
          ..write('kind: $kind, ')
          ..write('maskedNumber: $maskedNumber, ')
          ..write('smsSender: $smsSender, ')
          ..write('autoUpdateFromSms: $autoUpdateFromSms, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('balance: $balance, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('statementDueDate: $statementDueDate, ')
          ..write('note: $note, ')
          ..write('archived: $archived, ')
          ..write('lastReconciled: $lastReconciled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TxnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _counterAccountIdMeta = const VerificationMeta(
    'counterAccountId',
  );
  @override
  late final GeneratedColumn<String> counterAccountId = GeneratedColumn<String>(
    'counter_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _incomeTypeIdMeta = const VerificationMeta(
    'incomeTypeId',
  );
  @override
  late final GeneratedColumn<String> incomeTypeId = GeneratedColumn<String>(
    'income_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loanIdMeta = const VerificationMeta('loanId');
  @override
  late final GeneratedColumn<String> loanId = GeneratedColumn<String>(
    'loan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _principalMeta = const VerificationMeta(
    'principal',
  );
  @override
  late final GeneratedColumn<int> principal = GeneratedColumn<int>(
    'principal',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interestMeta = const VerificationMeta(
    'interest',
  );
  @override
  late final GeneratedColumn<int> interest = GeneratedColumn<int>(
    'interest',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smsIdMeta = const VerificationMeta('smsId');
  @override
  late final GeneratedColumn<String> smsId = GeneratedColumn<String>(
    'sms_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    time,
    title,
    type,
    direction,
    accountId,
    counterAccountId,
    categoryId,
    incomeTypeId,
    loanId,
    amount,
    principal,
    interest,
    status,
    source,
    smsId,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TxnRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('counter_account_id')) {
      context.handle(
        _counterAccountIdMeta,
        counterAccountId.isAcceptableOrUnknown(
          data['counter_account_id']!,
          _counterAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('income_type_id')) {
      context.handle(
        _incomeTypeIdMeta,
        incomeTypeId.isAcceptableOrUnknown(
          data['income_type_id']!,
          _incomeTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('loan_id')) {
      context.handle(
        _loanIdMeta,
        loanId.isAcceptableOrUnknown(data['loan_id']!, _loanIdMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('principal')) {
      context.handle(
        _principalMeta,
        principal.isAcceptableOrUnknown(data['principal']!, _principalMeta),
      );
    }
    if (data.containsKey('interest')) {
      context.handle(
        _interestMeta,
        interest.isAcceptableOrUnknown(data['interest']!, _interestMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('sms_id')) {
      context.handle(
        _smsIdMeta,
        smsId.isAcceptableOrUnknown(data['sms_id']!, _smsIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TxnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TxnRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      counterAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      incomeTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}income_type_id'],
      ),
      loanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loan_id'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      principal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal'],
      ),
      interest: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interest'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      smsId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sms_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TxnRow extends DataClass implements Insertable<TxnRow> {
  final String id;
  final String date;
  final String time;
  final String title;
  final String type;
  final String? direction;
  final String accountId;
  final String? counterAccountId;
  final String? categoryId;
  final String? incomeTypeId;
  final String? loanId;
  final int amount;
  final int? principal;
  final int? interest;
  final String status;
  final String source;
  final String? smsId;
  final String? note;
  final String createdAt;
  final String updatedAt;
  const TxnRow({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
    required this.type,
    this.direction,
    required this.accountId,
    this.counterAccountId,
    this.categoryId,
    this.incomeTypeId,
    this.loanId,
    required this.amount,
    this.principal,
    this.interest,
    required this.status,
    required this.source,
    this.smsId,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['time'] = Variable<String>(time);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || direction != null) {
      map['direction'] = Variable<String>(direction);
    }
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || counterAccountId != null) {
      map['counter_account_id'] = Variable<String>(counterAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || incomeTypeId != null) {
      map['income_type_id'] = Variable<String>(incomeTypeId);
    }
    if (!nullToAbsent || loanId != null) {
      map['loan_id'] = Variable<String>(loanId);
    }
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || principal != null) {
      map['principal'] = Variable<int>(principal);
    }
    if (!nullToAbsent || interest != null) {
      map['interest'] = Variable<int>(interest);
    }
    map['status'] = Variable<String>(status);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || smsId != null) {
      map['sms_id'] = Variable<String>(smsId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      date: Value(date),
      time: Value(time),
      title: Value(title),
      type: Value(type),
      direction: direction == null && nullToAbsent
          ? const Value.absent()
          : Value(direction),
      accountId: Value(accountId),
      counterAccountId: counterAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(counterAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      incomeTypeId: incomeTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(incomeTypeId),
      loanId: loanId == null && nullToAbsent
          ? const Value.absent()
          : Value(loanId),
      amount: Value(amount),
      principal: principal == null && nullToAbsent
          ? const Value.absent()
          : Value(principal),
      interest: interest == null && nullToAbsent
          ? const Value.absent()
          : Value(interest),
      status: Value(status),
      source: Value(source),
      smsId: smsId == null && nullToAbsent
          ? const Value.absent()
          : Value(smsId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TxnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TxnRow(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      time: serializer.fromJson<String>(json['time']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      direction: serializer.fromJson<String?>(json['direction']),
      accountId: serializer.fromJson<String>(json['accountId']),
      counterAccountId: serializer.fromJson<String?>(json['counterAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      incomeTypeId: serializer.fromJson<String?>(json['incomeTypeId']),
      loanId: serializer.fromJson<String?>(json['loanId']),
      amount: serializer.fromJson<int>(json['amount']),
      principal: serializer.fromJson<int?>(json['principal']),
      interest: serializer.fromJson<int?>(json['interest']),
      status: serializer.fromJson<String>(json['status']),
      source: serializer.fromJson<String>(json['source']),
      smsId: serializer.fromJson<String?>(json['smsId']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'time': serializer.toJson<String>(time),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'direction': serializer.toJson<String?>(direction),
      'accountId': serializer.toJson<String>(accountId),
      'counterAccountId': serializer.toJson<String?>(counterAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'incomeTypeId': serializer.toJson<String?>(incomeTypeId),
      'loanId': serializer.toJson<String?>(loanId),
      'amount': serializer.toJson<int>(amount),
      'principal': serializer.toJson<int?>(principal),
      'interest': serializer.toJson<int?>(interest),
      'status': serializer.toJson<String>(status),
      'source': serializer.toJson<String>(source),
      'smsId': serializer.toJson<String?>(smsId),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  TxnRow copyWith({
    String? id,
    String? date,
    String? time,
    String? title,
    String? type,
    Value<String?> direction = const Value.absent(),
    String? accountId,
    Value<String?> counterAccountId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> incomeTypeId = const Value.absent(),
    Value<String?> loanId = const Value.absent(),
    int? amount,
    Value<int?> principal = const Value.absent(),
    Value<int?> interest = const Value.absent(),
    String? status,
    String? source,
    Value<String?> smsId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => TxnRow(
    id: id ?? this.id,
    date: date ?? this.date,
    time: time ?? this.time,
    title: title ?? this.title,
    type: type ?? this.type,
    direction: direction.present ? direction.value : this.direction,
    accountId: accountId ?? this.accountId,
    counterAccountId: counterAccountId.present
        ? counterAccountId.value
        : this.counterAccountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    incomeTypeId: incomeTypeId.present ? incomeTypeId.value : this.incomeTypeId,
    loanId: loanId.present ? loanId.value : this.loanId,
    amount: amount ?? this.amount,
    principal: principal.present ? principal.value : this.principal,
    interest: interest.present ? interest.value : this.interest,
    status: status ?? this.status,
    source: source ?? this.source,
    smsId: smsId.present ? smsId.value : this.smsId,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TxnRow copyWithCompanion(TransactionsCompanion data) {
    return TxnRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      time: data.time.present ? data.time.value : this.time,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      direction: data.direction.present ? data.direction.value : this.direction,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      counterAccountId: data.counterAccountId.present
          ? data.counterAccountId.value
          : this.counterAccountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      incomeTypeId: data.incomeTypeId.present
          ? data.incomeTypeId.value
          : this.incomeTypeId,
      loanId: data.loanId.present ? data.loanId.value : this.loanId,
      amount: data.amount.present ? data.amount.value : this.amount,
      principal: data.principal.present ? data.principal.value : this.principal,
      interest: data.interest.present ? data.interest.value : this.interest,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      smsId: data.smsId.present ? data.smsId.value : this.smsId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TxnRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('direction: $direction, ')
          ..write('accountId: $accountId, ')
          ..write('counterAccountId: $counterAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('incomeTypeId: $incomeTypeId, ')
          ..write('loanId: $loanId, ')
          ..write('amount: $amount, ')
          ..write('principal: $principal, ')
          ..write('interest: $interest, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('smsId: $smsId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    time,
    title,
    type,
    direction,
    accountId,
    counterAccountId,
    categoryId,
    incomeTypeId,
    loanId,
    amount,
    principal,
    interest,
    status,
    source,
    smsId,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TxnRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.time == this.time &&
          other.title == this.title &&
          other.type == this.type &&
          other.direction == this.direction &&
          other.accountId == this.accountId &&
          other.counterAccountId == this.counterAccountId &&
          other.categoryId == this.categoryId &&
          other.incomeTypeId == this.incomeTypeId &&
          other.loanId == this.loanId &&
          other.amount == this.amount &&
          other.principal == this.principal &&
          other.interest == this.interest &&
          other.status == this.status &&
          other.source == this.source &&
          other.smsId == this.smsId &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<TxnRow> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> time;
  final Value<String> title;
  final Value<String> type;
  final Value<String?> direction;
  final Value<String> accountId;
  final Value<String?> counterAccountId;
  final Value<String?> categoryId;
  final Value<String?> incomeTypeId;
  final Value<String?> loanId;
  final Value<int> amount;
  final Value<int?> principal;
  final Value<int?> interest;
  final Value<String> status;
  final Value<String> source;
  final Value<String?> smsId;
  final Value<String?> note;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.time = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.direction = const Value.absent(),
    this.accountId = const Value.absent(),
    this.counterAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.incomeTypeId = const Value.absent(),
    this.loanId = const Value.absent(),
    this.amount = const Value.absent(),
    this.principal = const Value.absent(),
    this.interest = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.smsId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String date,
    required String time,
    required String title,
    required String type,
    this.direction = const Value.absent(),
    required String accountId,
    this.counterAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.incomeTypeId = const Value.absent(),
    this.loanId = const Value.absent(),
    required int amount,
    this.principal = const Value.absent(),
    this.interest = const Value.absent(),
    required String status,
    required String source,
    this.smsId = const Value.absent(),
    this.note = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       time = Value(time),
       title = Value(title),
       type = Value(type),
       accountId = Value(accountId),
       amount = Value(amount),
       status = Value(status),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TxnRow> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? time,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? direction,
    Expression<String>? accountId,
    Expression<String>? counterAccountId,
    Expression<String>? categoryId,
    Expression<String>? incomeTypeId,
    Expression<String>? loanId,
    Expression<int>? amount,
    Expression<int>? principal,
    Expression<int>? interest,
    Expression<String>? status,
    Expression<String>? source,
    Expression<String>? smsId,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (direction != null) 'direction': direction,
      if (accountId != null) 'account_id': accountId,
      if (counterAccountId != null) 'counter_account_id': counterAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (incomeTypeId != null) 'income_type_id': incomeTypeId,
      if (loanId != null) 'loan_id': loanId,
      if (amount != null) 'amount': amount,
      if (principal != null) 'principal': principal,
      if (interest != null) 'interest': interest,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (smsId != null) 'sms_id': smsId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? time,
    Value<String>? title,
    Value<String>? type,
    Value<String?>? direction,
    Value<String>? accountId,
    Value<String?>? counterAccountId,
    Value<String?>? categoryId,
    Value<String?>? incomeTypeId,
    Value<String?>? loanId,
    Value<int>? amount,
    Value<int?>? principal,
    Value<int?>? interest,
    Value<String>? status,
    Value<String>? source,
    Value<String?>? smsId,
    Value<String?>? note,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      title: title ?? this.title,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      accountId: accountId ?? this.accountId,
      counterAccountId: counterAccountId ?? this.counterAccountId,
      categoryId: categoryId ?? this.categoryId,
      incomeTypeId: incomeTypeId ?? this.incomeTypeId,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      principal: principal ?? this.principal,
      interest: interest ?? this.interest,
      status: status ?? this.status,
      source: source ?? this.source,
      smsId: smsId ?? this.smsId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (counterAccountId.present) {
      map['counter_account_id'] = Variable<String>(counterAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (incomeTypeId.present) {
      map['income_type_id'] = Variable<String>(incomeTypeId.value);
    }
    if (loanId.present) {
      map['loan_id'] = Variable<String>(loanId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (principal.present) {
      map['principal'] = Variable<int>(principal.value);
    }
    if (interest.present) {
      map['interest'] = Variable<int>(interest.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (smsId.present) {
      map['sms_id'] = Variable<String>(smsId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('time: $time, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('direction: $direction, ')
          ..write('accountId: $accountId, ')
          ..write('counterAccountId: $counterAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('incomeTypeId: $incomeTypeId, ')
          ..write('loanId: $loanId, ')
          ..write('amount: $amount, ')
          ..write('principal: $principal, ')
          ..write('interest: $interest, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('smsId: $smsId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoansTable extends Loans with TableInfo<$LoansTable, LoanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loanTypeIdMeta = const VerificationMeta(
    'loanTypeId',
  );
  @override
  late final GeneratedColumn<String> loanTypeId = GeneratedColumn<String>(
    'loan_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lenderMeta = const VerificationMeta('lender');
  @override
  late final GeneratedColumn<String> lender = GeneratedColumn<String>(
    'lender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _principalMeta = const VerificationMeta(
    'principal',
  );
  @override
  late final GeneratedColumn<int> principal = GeneratedColumn<int>(
    'principal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outstandingMeta = const VerificationMeta(
    'outstanding',
  );
  @override
  late final GeneratedColumn<int> outstanding = GeneratedColumn<int>(
    'outstanding',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratePctMeta = const VerificationMeta(
    'ratePct',
  );
  @override
  late final GeneratedColumn<double> ratePct = GeneratedColumn<double>(
    'rate_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installmentMeta = const VerificationMeta(
    'installment',
  );
  @override
  late final GeneratedColumn<int> installment = GeneratedColumn<int>(
    'installment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maturityDateMeta = const VerificationMeta(
    'maturityDate',
  );
  @override
  late final GeneratedColumn<String> maturityDate = GeneratedColumn<String>(
    'maturity_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextDueDateMeta = const VerificationMeta(
    'nextDueDate',
  );
  @override
  late final GeneratedColumn<String> nextDueDate = GeneratedColumn<String>(
    'next_due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repaymentAccountIdMeta =
      const VerificationMeta('repaymentAccountId');
  @override
  late final GeneratedColumn<String> repaymentAccountId =
      GeneratedColumn<String>(
        'repayment_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _feesAndPrepaymentMeta = const VerificationMeta(
    'feesAndPrepayment',
  );
  @override
  late final GeneratedColumn<String> feesAndPrepayment =
      GeneratedColumn<String>(
        'fees_and_prepayment',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _closedMeta = const VerificationMeta('closed');
  @override
  late final GeneratedColumn<bool> closed = GeneratedColumn<bool>(
    'closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loanTypeId,
    name,
    lender,
    principal,
    outstanding,
    ratePct,
    method,
    installment,
    frequency,
    startDate,
    maturityDate,
    nextDueDate,
    repaymentAccountId,
    feesAndPrepayment,
    closed,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loans';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('loan_type_id')) {
      context.handle(
        _loanTypeIdMeta,
        loanTypeId.isAcceptableOrUnknown(
          data['loan_type_id']!,
          _loanTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_loanTypeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lender')) {
      context.handle(
        _lenderMeta,
        lender.isAcceptableOrUnknown(data['lender']!, _lenderMeta),
      );
    } else if (isInserting) {
      context.missing(_lenderMeta);
    }
    if (data.containsKey('principal')) {
      context.handle(
        _principalMeta,
        principal.isAcceptableOrUnknown(data['principal']!, _principalMeta),
      );
    } else if (isInserting) {
      context.missing(_principalMeta);
    }
    if (data.containsKey('outstanding')) {
      context.handle(
        _outstandingMeta,
        outstanding.isAcceptableOrUnknown(
          data['outstanding']!,
          _outstandingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outstandingMeta);
    }
    if (data.containsKey('rate_pct')) {
      context.handle(
        _ratePctMeta,
        ratePct.isAcceptableOrUnknown(data['rate_pct']!, _ratePctMeta),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('installment')) {
      context.handle(
        _installmentMeta,
        installment.isAcceptableOrUnknown(
          data['installment']!,
          _installmentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installmentMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('maturity_date')) {
      context.handle(
        _maturityDateMeta,
        maturityDate.isAcceptableOrUnknown(
          data['maturity_date']!,
          _maturityDateMeta,
        ),
      );
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
        _nextDueDateMeta,
        nextDueDate.isAcceptableOrUnknown(
          data['next_due_date']!,
          _nextDueDateMeta,
        ),
      );
    }
    if (data.containsKey('repayment_account_id')) {
      context.handle(
        _repaymentAccountIdMeta,
        repaymentAccountId.isAcceptableOrUnknown(
          data['repayment_account_id']!,
          _repaymentAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('fees_and_prepayment')) {
      context.handle(
        _feesAndPrepaymentMeta,
        feesAndPrepayment.isAcceptableOrUnknown(
          data['fees_and_prepayment']!,
          _feesAndPrepaymentMeta,
        ),
      );
    }
    if (data.containsKey('closed')) {
      context.handle(
        _closedMeta,
        closed.isAcceptableOrUnknown(data['closed']!, _closedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      loanTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loan_type_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lender'],
      )!,
      principal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal'],
      )!,
      outstanding: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outstanding'],
      )!,
      ratePct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate_pct'],
      ),
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      installment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      maturityDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}maturity_date'],
      ),
      nextDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_due_date'],
      ),
      repaymentAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repayment_account_id'],
      ),
      feesAndPrepayment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fees_and_prepayment'],
      ),
      closed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}closed'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $LoansTable createAlias(String alias) {
    return $LoansTable(attachedDatabase, alias);
  }
}

class LoanRow extends DataClass implements Insertable<LoanRow> {
  final String id;
  final String loanTypeId;
  final String name;
  final String lender;
  final int principal;
  final int outstanding;
  final double? ratePct;
  final String method;
  final int installment;
  final String frequency;
  final String? startDate;
  final String? maturityDate;
  final String? nextDueDate;
  final String? repaymentAccountId;
  final String? feesAndPrepayment;
  final bool closed;
  final int sortOrder;
  const LoanRow({
    required this.id,
    required this.loanTypeId,
    required this.name,
    required this.lender,
    required this.principal,
    required this.outstanding,
    this.ratePct,
    required this.method,
    required this.installment,
    required this.frequency,
    this.startDate,
    this.maturityDate,
    this.nextDueDate,
    this.repaymentAccountId,
    this.feesAndPrepayment,
    required this.closed,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['loan_type_id'] = Variable<String>(loanTypeId);
    map['name'] = Variable<String>(name);
    map['lender'] = Variable<String>(lender);
    map['principal'] = Variable<int>(principal);
    map['outstanding'] = Variable<int>(outstanding);
    if (!nullToAbsent || ratePct != null) {
      map['rate_pct'] = Variable<double>(ratePct);
    }
    map['method'] = Variable<String>(method);
    map['installment'] = Variable<int>(installment);
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || maturityDate != null) {
      map['maturity_date'] = Variable<String>(maturityDate);
    }
    if (!nullToAbsent || nextDueDate != null) {
      map['next_due_date'] = Variable<String>(nextDueDate);
    }
    if (!nullToAbsent || repaymentAccountId != null) {
      map['repayment_account_id'] = Variable<String>(repaymentAccountId);
    }
    if (!nullToAbsent || feesAndPrepayment != null) {
      map['fees_and_prepayment'] = Variable<String>(feesAndPrepayment);
    }
    map['closed'] = Variable<bool>(closed);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      loanTypeId: Value(loanTypeId),
      name: Value(name),
      lender: Value(lender),
      principal: Value(principal),
      outstanding: Value(outstanding),
      ratePct: ratePct == null && nullToAbsent
          ? const Value.absent()
          : Value(ratePct),
      method: Value(method),
      installment: Value(installment),
      frequency: Value(frequency),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      maturityDate: maturityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(maturityDate),
      nextDueDate: nextDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueDate),
      repaymentAccountId: repaymentAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(repaymentAccountId),
      feesAndPrepayment: feesAndPrepayment == null && nullToAbsent
          ? const Value.absent()
          : Value(feesAndPrepayment),
      closed: Value(closed),
      sortOrder: Value(sortOrder),
    );
  }

  factory LoanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoanRow(
      id: serializer.fromJson<String>(json['id']),
      loanTypeId: serializer.fromJson<String>(json['loanTypeId']),
      name: serializer.fromJson<String>(json['name']),
      lender: serializer.fromJson<String>(json['lender']),
      principal: serializer.fromJson<int>(json['principal']),
      outstanding: serializer.fromJson<int>(json['outstanding']),
      ratePct: serializer.fromJson<double?>(json['ratePct']),
      method: serializer.fromJson<String>(json['method']),
      installment: serializer.fromJson<int>(json['installment']),
      frequency: serializer.fromJson<String>(json['frequency']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      maturityDate: serializer.fromJson<String?>(json['maturityDate']),
      nextDueDate: serializer.fromJson<String?>(json['nextDueDate']),
      repaymentAccountId: serializer.fromJson<String?>(
        json['repaymentAccountId'],
      ),
      feesAndPrepayment: serializer.fromJson<String?>(
        json['feesAndPrepayment'],
      ),
      closed: serializer.fromJson<bool>(json['closed']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'loanTypeId': serializer.toJson<String>(loanTypeId),
      'name': serializer.toJson<String>(name),
      'lender': serializer.toJson<String>(lender),
      'principal': serializer.toJson<int>(principal),
      'outstanding': serializer.toJson<int>(outstanding),
      'ratePct': serializer.toJson<double?>(ratePct),
      'method': serializer.toJson<String>(method),
      'installment': serializer.toJson<int>(installment),
      'frequency': serializer.toJson<String>(frequency),
      'startDate': serializer.toJson<String?>(startDate),
      'maturityDate': serializer.toJson<String?>(maturityDate),
      'nextDueDate': serializer.toJson<String?>(nextDueDate),
      'repaymentAccountId': serializer.toJson<String?>(repaymentAccountId),
      'feesAndPrepayment': serializer.toJson<String?>(feesAndPrepayment),
      'closed': serializer.toJson<bool>(closed),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LoanRow copyWith({
    String? id,
    String? loanTypeId,
    String? name,
    String? lender,
    int? principal,
    int? outstanding,
    Value<double?> ratePct = const Value.absent(),
    String? method,
    int? installment,
    String? frequency,
    Value<String?> startDate = const Value.absent(),
    Value<String?> maturityDate = const Value.absent(),
    Value<String?> nextDueDate = const Value.absent(),
    Value<String?> repaymentAccountId = const Value.absent(),
    Value<String?> feesAndPrepayment = const Value.absent(),
    bool? closed,
    int? sortOrder,
  }) => LoanRow(
    id: id ?? this.id,
    loanTypeId: loanTypeId ?? this.loanTypeId,
    name: name ?? this.name,
    lender: lender ?? this.lender,
    principal: principal ?? this.principal,
    outstanding: outstanding ?? this.outstanding,
    ratePct: ratePct.present ? ratePct.value : this.ratePct,
    method: method ?? this.method,
    installment: installment ?? this.installment,
    frequency: frequency ?? this.frequency,
    startDate: startDate.present ? startDate.value : this.startDate,
    maturityDate: maturityDate.present ? maturityDate.value : this.maturityDate,
    nextDueDate: nextDueDate.present ? nextDueDate.value : this.nextDueDate,
    repaymentAccountId: repaymentAccountId.present
        ? repaymentAccountId.value
        : this.repaymentAccountId,
    feesAndPrepayment: feesAndPrepayment.present
        ? feesAndPrepayment.value
        : this.feesAndPrepayment,
    closed: closed ?? this.closed,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LoanRow copyWithCompanion(LoansCompanion data) {
    return LoanRow(
      id: data.id.present ? data.id.value : this.id,
      loanTypeId: data.loanTypeId.present
          ? data.loanTypeId.value
          : this.loanTypeId,
      name: data.name.present ? data.name.value : this.name,
      lender: data.lender.present ? data.lender.value : this.lender,
      principal: data.principal.present ? data.principal.value : this.principal,
      outstanding: data.outstanding.present
          ? data.outstanding.value
          : this.outstanding,
      ratePct: data.ratePct.present ? data.ratePct.value : this.ratePct,
      method: data.method.present ? data.method.value : this.method,
      installment: data.installment.present
          ? data.installment.value
          : this.installment,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      maturityDate: data.maturityDate.present
          ? data.maturityDate.value
          : this.maturityDate,
      nextDueDate: data.nextDueDate.present
          ? data.nextDueDate.value
          : this.nextDueDate,
      repaymentAccountId: data.repaymentAccountId.present
          ? data.repaymentAccountId.value
          : this.repaymentAccountId,
      feesAndPrepayment: data.feesAndPrepayment.present
          ? data.feesAndPrepayment.value
          : this.feesAndPrepayment,
      closed: data.closed.present ? data.closed.value : this.closed,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoanRow(')
          ..write('id: $id, ')
          ..write('loanTypeId: $loanTypeId, ')
          ..write('name: $name, ')
          ..write('lender: $lender, ')
          ..write('principal: $principal, ')
          ..write('outstanding: $outstanding, ')
          ..write('ratePct: $ratePct, ')
          ..write('method: $method, ')
          ..write('installment: $installment, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('repaymentAccountId: $repaymentAccountId, ')
          ..write('feesAndPrepayment: $feesAndPrepayment, ')
          ..write('closed: $closed, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    loanTypeId,
    name,
    lender,
    principal,
    outstanding,
    ratePct,
    method,
    installment,
    frequency,
    startDate,
    maturityDate,
    nextDueDate,
    repaymentAccountId,
    feesAndPrepayment,
    closed,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoanRow &&
          other.id == this.id &&
          other.loanTypeId == this.loanTypeId &&
          other.name == this.name &&
          other.lender == this.lender &&
          other.principal == this.principal &&
          other.outstanding == this.outstanding &&
          other.ratePct == this.ratePct &&
          other.method == this.method &&
          other.installment == this.installment &&
          other.frequency == this.frequency &&
          other.startDate == this.startDate &&
          other.maturityDate == this.maturityDate &&
          other.nextDueDate == this.nextDueDate &&
          other.repaymentAccountId == this.repaymentAccountId &&
          other.feesAndPrepayment == this.feesAndPrepayment &&
          other.closed == this.closed &&
          other.sortOrder == this.sortOrder);
}

class LoansCompanion extends UpdateCompanion<LoanRow> {
  final Value<String> id;
  final Value<String> loanTypeId;
  final Value<String> name;
  final Value<String> lender;
  final Value<int> principal;
  final Value<int> outstanding;
  final Value<double?> ratePct;
  final Value<String> method;
  final Value<int> installment;
  final Value<String> frequency;
  final Value<String?> startDate;
  final Value<String?> maturityDate;
  final Value<String?> nextDueDate;
  final Value<String?> repaymentAccountId;
  final Value<String?> feesAndPrepayment;
  final Value<bool> closed;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.loanTypeId = const Value.absent(),
    this.name = const Value.absent(),
    this.lender = const Value.absent(),
    this.principal = const Value.absent(),
    this.outstanding = const Value.absent(),
    this.ratePct = const Value.absent(),
    this.method = const Value.absent(),
    this.installment = const Value.absent(),
    this.frequency = const Value.absent(),
    this.startDate = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.repaymentAccountId = const Value.absent(),
    this.feesAndPrepayment = const Value.absent(),
    this.closed = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoansCompanion.insert({
    required String id,
    required String loanTypeId,
    required String name,
    required String lender,
    required int principal,
    required int outstanding,
    this.ratePct = const Value.absent(),
    required String method,
    required int installment,
    required String frequency,
    this.startDate = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.repaymentAccountId = const Value.absent(),
    this.feesAndPrepayment = const Value.absent(),
    this.closed = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       loanTypeId = Value(loanTypeId),
       name = Value(name),
       lender = Value(lender),
       principal = Value(principal),
       outstanding = Value(outstanding),
       method = Value(method),
       installment = Value(installment),
       frequency = Value(frequency);
  static Insertable<LoanRow> custom({
    Expression<String>? id,
    Expression<String>? loanTypeId,
    Expression<String>? name,
    Expression<String>? lender,
    Expression<int>? principal,
    Expression<int>? outstanding,
    Expression<double>? ratePct,
    Expression<String>? method,
    Expression<int>? installment,
    Expression<String>? frequency,
    Expression<String>? startDate,
    Expression<String>? maturityDate,
    Expression<String>? nextDueDate,
    Expression<String>? repaymentAccountId,
    Expression<String>? feesAndPrepayment,
    Expression<bool>? closed,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loanTypeId != null) 'loan_type_id': loanTypeId,
      if (name != null) 'name': name,
      if (lender != null) 'lender': lender,
      if (principal != null) 'principal': principal,
      if (outstanding != null) 'outstanding': outstanding,
      if (ratePct != null) 'rate_pct': ratePct,
      if (method != null) 'method': method,
      if (installment != null) 'installment': installment,
      if (frequency != null) 'frequency': frequency,
      if (startDate != null) 'start_date': startDate,
      if (maturityDate != null) 'maturity_date': maturityDate,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (repaymentAccountId != null)
        'repayment_account_id': repaymentAccountId,
      if (feesAndPrepayment != null) 'fees_and_prepayment': feesAndPrepayment,
      if (closed != null) 'closed': closed,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoansCompanion copyWith({
    Value<String>? id,
    Value<String>? loanTypeId,
    Value<String>? name,
    Value<String>? lender,
    Value<int>? principal,
    Value<int>? outstanding,
    Value<double?>? ratePct,
    Value<String>? method,
    Value<int>? installment,
    Value<String>? frequency,
    Value<String?>? startDate,
    Value<String?>? maturityDate,
    Value<String?>? nextDueDate,
    Value<String?>? repaymentAccountId,
    Value<String?>? feesAndPrepayment,
    Value<bool>? closed,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return LoansCompanion(
      id: id ?? this.id,
      loanTypeId: loanTypeId ?? this.loanTypeId,
      name: name ?? this.name,
      lender: lender ?? this.lender,
      principal: principal ?? this.principal,
      outstanding: outstanding ?? this.outstanding,
      ratePct: ratePct ?? this.ratePct,
      method: method ?? this.method,
      installment: installment ?? this.installment,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      repaymentAccountId: repaymentAccountId ?? this.repaymentAccountId,
      feesAndPrepayment: feesAndPrepayment ?? this.feesAndPrepayment,
      closed: closed ?? this.closed,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (loanTypeId.present) {
      map['loan_type_id'] = Variable<String>(loanTypeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lender.present) {
      map['lender'] = Variable<String>(lender.value);
    }
    if (principal.present) {
      map['principal'] = Variable<int>(principal.value);
    }
    if (outstanding.present) {
      map['outstanding'] = Variable<int>(outstanding.value);
    }
    if (ratePct.present) {
      map['rate_pct'] = Variable<double>(ratePct.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (installment.present) {
      map['installment'] = Variable<int>(installment.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (maturityDate.present) {
      map['maturity_date'] = Variable<String>(maturityDate.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<String>(nextDueDate.value);
    }
    if (repaymentAccountId.present) {
      map['repayment_account_id'] = Variable<String>(repaymentAccountId.value);
    }
    if (feesAndPrepayment.present) {
      map['fees_and_prepayment'] = Variable<String>(feesAndPrepayment.value);
    }
    if (closed.present) {
      map['closed'] = Variable<bool>(closed.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('loanTypeId: $loanTypeId, ')
          ..write('name: $name, ')
          ..write('lender: $lender, ')
          ..write('principal: $principal, ')
          ..write('outstanding: $outstanding, ')
          ..write('ratePct: $ratePct, ')
          ..write('method: $method, ')
          ..write('installment: $installment, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('repaymentAccountId: $repaymentAccountId, ')
          ..write('feesAndPrepayment: $feesAndPrepayment, ')
          ..write('closed: $closed, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncomeTypesTable extends IncomeTypes
    with TableInfo<$IncomeTypesTable, IncomeTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomeTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultAccountIdMeta = const VerificationMeta(
    'defaultAccountId',
  );
  @override
  late final GeneratedColumn<String> defaultAccountId = GeneratedColumn<String>(
    'default_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurringMeta = const VerificationMeta(
    'recurring',
  );
  @override
  late final GeneratedColumn<bool> recurring = GeneratedColumn<bool>(
    'recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("recurring" IN (0, 1))',
    ),
  );
  static const VerificationMeta _expectedAmountMeta = const VerificationMeta(
    'expectedAmount',
  );
  @override
  late final GeneratedColumn<int> expectedAmount = GeneratedColumn<int>(
    'expected_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedDayMeta = const VerificationMeta(
    'expectedDay',
  );
  @override
  late final GeneratedColumn<String> expectedDay = GeneratedColumn<String>(
    'expected_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _applicableDeductionIdsMeta =
      const VerificationMeta('applicableDeductionIds');
  @override
  late final GeneratedColumn<String> applicableDeductionIds =
      GeneratedColumn<String>(
        'applicable_deduction_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    icon,
    color,
    defaultAccountId,
    recurring,
    expectedAmount,
    frequency,
    expectedDay,
    applicableDeductionIds,
    active,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'income_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncomeTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('default_account_id')) {
      context.handle(
        _defaultAccountIdMeta,
        defaultAccountId.isAcceptableOrUnknown(
          data['default_account_id']!,
          _defaultAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('recurring')) {
      context.handle(
        _recurringMeta,
        recurring.isAcceptableOrUnknown(data['recurring']!, _recurringMeta),
      );
    } else if (isInserting) {
      context.missing(_recurringMeta);
    }
    if (data.containsKey('expected_amount')) {
      context.handle(
        _expectedAmountMeta,
        expectedAmount.isAcceptableOrUnknown(
          data['expected_amount']!,
          _expectedAmountMeta,
        ),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('expected_day')) {
      context.handle(
        _expectedDayMeta,
        expectedDay.isAcceptableOrUnknown(
          data['expected_day']!,
          _expectedDayMeta,
        ),
      );
    }
    if (data.containsKey('applicable_deduction_ids')) {
      context.handle(
        _applicableDeductionIdsMeta,
        applicableDeductionIds.isAcceptableOrUnknown(
          data['applicable_deduction_ids']!,
          _applicableDeductionIdsMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncomeTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncomeTypeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      defaultAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_account_id'],
      ),
      recurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recurring'],
      )!,
      expectedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_amount'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      expectedDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_day'],
      ),
      applicableDeductionIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}applicable_deduction_ids'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $IncomeTypesTable createAlias(String alias) {
    return $IncomeTypesTable(attachedDatabase, alias);
  }
}

class IncomeTypeRow extends DataClass implements Insertable<IncomeTypeRow> {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final int color;
  final String? defaultAccountId;
  final bool recurring;
  final int? expectedAmount;
  final String frequency;
  final String? expectedDay;

  /// JSON array of deduction ids.
  final String applicableDeductionIds;
  final bool active;
  final int sortOrder;
  const IncomeTypeRow({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    this.defaultAccountId,
    required this.recurring,
    this.expectedAmount,
    required this.frequency,
    this.expectedDay,
    required this.applicableDeductionIds,
    required this.active,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || defaultAccountId != null) {
      map['default_account_id'] = Variable<String>(defaultAccountId);
    }
    map['recurring'] = Variable<bool>(recurring);
    if (!nullToAbsent || expectedAmount != null) {
      map['expected_amount'] = Variable<int>(expectedAmount);
    }
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || expectedDay != null) {
      map['expected_day'] = Variable<String>(expectedDay);
    }
    map['applicable_deduction_ids'] = Variable<String>(applicableDeductionIds);
    map['active'] = Variable<bool>(active);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  IncomeTypesCompanion toCompanion(bool nullToAbsent) {
    return IncomeTypesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: Value(icon),
      color: Value(color),
      defaultAccountId: defaultAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultAccountId),
      recurring: Value(recurring),
      expectedAmount: expectedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedAmount),
      frequency: Value(frequency),
      expectedDay: expectedDay == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedDay),
      applicableDeductionIds: Value(applicableDeductionIds),
      active: Value(active),
      sortOrder: Value(sortOrder),
    );
  }

  factory IncomeTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncomeTypeRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int>(json['color']),
      defaultAccountId: serializer.fromJson<String?>(json['defaultAccountId']),
      recurring: serializer.fromJson<bool>(json['recurring']),
      expectedAmount: serializer.fromJson<int?>(json['expectedAmount']),
      frequency: serializer.fromJson<String>(json['frequency']),
      expectedDay: serializer.fromJson<String?>(json['expectedDay']),
      applicableDeductionIds: serializer.fromJson<String>(
        json['applicableDeductionIds'],
      ),
      active: serializer.fromJson<bool>(json['active']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int>(color),
      'defaultAccountId': serializer.toJson<String?>(defaultAccountId),
      'recurring': serializer.toJson<bool>(recurring),
      'expectedAmount': serializer.toJson<int?>(expectedAmount),
      'frequency': serializer.toJson<String>(frequency),
      'expectedDay': serializer.toJson<String?>(expectedDay),
      'applicableDeductionIds': serializer.toJson<String>(
        applicableDeductionIds,
      ),
      'active': serializer.toJson<bool>(active),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  IncomeTypeRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? icon,
    int? color,
    Value<String?> defaultAccountId = const Value.absent(),
    bool? recurring,
    Value<int?> expectedAmount = const Value.absent(),
    String? frequency,
    Value<String?> expectedDay = const Value.absent(),
    String? applicableDeductionIds,
    bool? active,
    int? sortOrder,
  }) => IncomeTypeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    defaultAccountId: defaultAccountId.present
        ? defaultAccountId.value
        : this.defaultAccountId,
    recurring: recurring ?? this.recurring,
    expectedAmount: expectedAmount.present
        ? expectedAmount.value
        : this.expectedAmount,
    frequency: frequency ?? this.frequency,
    expectedDay: expectedDay.present ? expectedDay.value : this.expectedDay,
    applicableDeductionIds:
        applicableDeductionIds ?? this.applicableDeductionIds,
    active: active ?? this.active,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  IncomeTypeRow copyWithCompanion(IncomeTypesCompanion data) {
    return IncomeTypeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      defaultAccountId: data.defaultAccountId.present
          ? data.defaultAccountId.value
          : this.defaultAccountId,
      recurring: data.recurring.present ? data.recurring.value : this.recurring,
      expectedAmount: data.expectedAmount.present
          ? data.expectedAmount.value
          : this.expectedAmount,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      expectedDay: data.expectedDay.present
          ? data.expectedDay.value
          : this.expectedDay,
      applicableDeductionIds: data.applicableDeductionIds.present
          ? data.applicableDeductionIds.value
          : this.applicableDeductionIds,
      active: data.active.present ? data.active.value : this.active,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncomeTypeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('defaultAccountId: $defaultAccountId, ')
          ..write('recurring: $recurring, ')
          ..write('expectedAmount: $expectedAmount, ')
          ..write('frequency: $frequency, ')
          ..write('expectedDay: $expectedDay, ')
          ..write('applicableDeductionIds: $applicableDeductionIds, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    icon,
    color,
    defaultAccountId,
    recurring,
    expectedAmount,
    frequency,
    expectedDay,
    applicableDeductionIds,
    active,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncomeTypeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.defaultAccountId == this.defaultAccountId &&
          other.recurring == this.recurring &&
          other.expectedAmount == this.expectedAmount &&
          other.frequency == this.frequency &&
          other.expectedDay == this.expectedDay &&
          other.applicableDeductionIds == this.applicableDeductionIds &&
          other.active == this.active &&
          other.sortOrder == this.sortOrder);
}

class IncomeTypesCompanion extends UpdateCompanion<IncomeTypeRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> icon;
  final Value<int> color;
  final Value<String?> defaultAccountId;
  final Value<bool> recurring;
  final Value<int?> expectedAmount;
  final Value<String> frequency;
  final Value<String?> expectedDay;
  final Value<String> applicableDeductionIds;
  final Value<bool> active;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const IncomeTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.defaultAccountId = const Value.absent(),
    this.recurring = const Value.absent(),
    this.expectedAmount = const Value.absent(),
    this.frequency = const Value.absent(),
    this.expectedDay = const Value.absent(),
    this.applicableDeductionIds = const Value.absent(),
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncomeTypesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String icon,
    required int color,
    this.defaultAccountId = const Value.absent(),
    required bool recurring,
    this.expectedAmount = const Value.absent(),
    required String frequency,
    this.expectedDay = const Value.absent(),
    this.applicableDeductionIds = const Value.absent(),
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       icon = Value(icon),
       color = Value(color),
       recurring = Value(recurring),
       frequency = Value(frequency);
  static Insertable<IncomeTypeRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<String>? defaultAccountId,
    Expression<bool>? recurring,
    Expression<int>? expectedAmount,
    Expression<String>? frequency,
    Expression<String>? expectedDay,
    Expression<String>? applicableDeductionIds,
    Expression<bool>? active,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (defaultAccountId != null) 'default_account_id': defaultAccountId,
      if (recurring != null) 'recurring': recurring,
      if (expectedAmount != null) 'expected_amount': expectedAmount,
      if (frequency != null) 'frequency': frequency,
      if (expectedDay != null) 'expected_day': expectedDay,
      if (applicableDeductionIds != null)
        'applicable_deduction_ids': applicableDeductionIds,
      if (active != null) 'active': active,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncomeTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? icon,
    Value<int>? color,
    Value<String?>? defaultAccountId,
    Value<bool>? recurring,
    Value<int?>? expectedAmount,
    Value<String>? frequency,
    Value<String?>? expectedDay,
    Value<String>? applicableDeductionIds,
    Value<bool>? active,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return IncomeTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      defaultAccountId: defaultAccountId ?? this.defaultAccountId,
      recurring: recurring ?? this.recurring,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      frequency: frequency ?? this.frequency,
      expectedDay: expectedDay ?? this.expectedDay,
      applicableDeductionIds:
          applicableDeductionIds ?? this.applicableDeductionIds,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (defaultAccountId.present) {
      map['default_account_id'] = Variable<String>(defaultAccountId.value);
    }
    if (recurring.present) {
      map['recurring'] = Variable<bool>(recurring.value);
    }
    if (expectedAmount.present) {
      map['expected_amount'] = Variable<int>(expectedAmount.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (expectedDay.present) {
      map['expected_day'] = Variable<String>(expectedDay.value);
    }
    if (applicableDeductionIds.present) {
      map['applicable_deduction_ids'] = Variable<String>(
        applicableDeductionIds.value,
      );
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomeTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('defaultAccountId: $defaultAccountId, ')
          ..write('recurring: $recurring, ')
          ..write('expectedAmount: $expectedAmount, ')
          ..write('frequency: $frequency, ')
          ..write('expectedDay: $expectedDay, ')
          ..write('applicableDeductionIds: $applicableDeductionIds, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpenseCategoriesTable extends ExpenseCategories
    with TableInfo<$ExpenseCategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthlyBudgetMeta = const VerificationMeta(
    'monthlyBudget',
  );
  @override
  late final GeneratedColumn<int> monthlyBudget = GeneratedColumn<int>(
    'monthly_budget',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _essentialMeta = const VerificationMeta(
    'essential',
  );
  @override
  late final GeneratedColumn<bool> essential = GeneratedColumn<bool>(
    'essential',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("essential" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _systemMeta = const VerificationMeta('system');
  @override
  late final GeneratedColumn<String> system = GeneratedColumn<String>(
    'system',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _customMeta = const VerificationMeta('custom');
  @override
  late final GeneratedColumn<bool> custom = GeneratedColumn<bool>(
    'custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    parentId,
    monthlyBudget,
    essential,
    system,
    active,
    custom,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('monthly_budget')) {
      context.handle(
        _monthlyBudgetMeta,
        monthlyBudget.isAcceptableOrUnknown(
          data['monthly_budget']!,
          _monthlyBudgetMeta,
        ),
      );
    }
    if (data.containsKey('essential')) {
      context.handle(
        _essentialMeta,
        essential.isAcceptableOrUnknown(data['essential']!, _essentialMeta),
      );
    }
    if (data.containsKey('system')) {
      context.handle(
        _systemMeta,
        system.isAcceptableOrUnknown(data['system']!, _systemMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('custom')) {
      context.handle(
        _customMeta,
        custom.isAcceptableOrUnknown(data['custom']!, _customMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      monthlyBudget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_budget'],
      ),
      essential: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}essential'],
      )!,
      system: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      custom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}custom'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ExpenseCategoriesTable createAlias(String alias) {
    return $ExpenseCategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String icon;
  final String? parentId;
  final int? monthlyBudget;
  final bool essential;

  /// 'loan_interest' for the automatic Loan Interest category.
  final String? system;
  final bool active;
  final bool custom;
  final int sortOrder;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.icon,
    this.parentId,
    this.monthlyBudget,
    required this.essential,
    this.system,
    required this.active,
    required this.custom,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || monthlyBudget != null) {
      map['monthly_budget'] = Variable<int>(monthlyBudget);
    }
    map['essential'] = Variable<bool>(essential);
    if (!nullToAbsent || system != null) {
      map['system'] = Variable<String>(system);
    }
    map['active'] = Variable<bool>(active);
    map['custom'] = Variable<bool>(custom);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ExpenseCategoriesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      monthlyBudget: monthlyBudget == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyBudget),
      essential: Value(essential),
      system: system == null && nullToAbsent
          ? const Value.absent()
          : Value(system),
      active: Value(active),
      custom: Value(custom),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      monthlyBudget: serializer.fromJson<int?>(json['monthlyBudget']),
      essential: serializer.fromJson<bool>(json['essential']),
      system: serializer.fromJson<String?>(json['system']),
      active: serializer.fromJson<bool>(json['active']),
      custom: serializer.fromJson<bool>(json['custom']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'parentId': serializer.toJson<String?>(parentId),
      'monthlyBudget': serializer.toJson<int?>(monthlyBudget),
      'essential': serializer.toJson<bool>(essential),
      'system': serializer.toJson<String?>(system),
      'active': serializer.toJson<bool>(active),
      'custom': serializer.toJson<bool>(custom),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    String? icon,
    Value<String?> parentId = const Value.absent(),
    Value<int?> monthlyBudget = const Value.absent(),
    bool? essential,
    Value<String?> system = const Value.absent(),
    bool? active,
    bool? custom,
    int? sortOrder,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    parentId: parentId.present ? parentId.value : this.parentId,
    monthlyBudget: monthlyBudget.present
        ? monthlyBudget.value
        : this.monthlyBudget,
    essential: essential ?? this.essential,
    system: system.present ? system.value : this.system,
    active: active ?? this.active,
    custom: custom ?? this.custom,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CategoryRow copyWithCompanion(ExpenseCategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      monthlyBudget: data.monthlyBudget.present
          ? data.monthlyBudget.value
          : this.monthlyBudget,
      essential: data.essential.present ? data.essential.value : this.essential,
      system: data.system.present ? data.system.value : this.system,
      active: data.active.present ? data.active.value : this.active,
      custom: data.custom.present ? data.custom.value : this.custom,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('parentId: $parentId, ')
          ..write('monthlyBudget: $monthlyBudget, ')
          ..write('essential: $essential, ')
          ..write('system: $system, ')
          ..write('active: $active, ')
          ..write('custom: $custom, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    icon,
    parentId,
    monthlyBudget,
    essential,
    system,
    active,
    custom,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.parentId == this.parentId &&
          other.monthlyBudget == this.monthlyBudget &&
          other.essential == this.essential &&
          other.system == this.system &&
          other.active == this.active &&
          other.custom == this.custom &&
          other.sortOrder == this.sortOrder);
}

class ExpenseCategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<String?> parentId;
  final Value<int?> monthlyBudget;
  final Value<bool> essential;
  final Value<String?> system;
  final Value<bool> active;
  final Value<bool> custom;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ExpenseCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.parentId = const Value.absent(),
    this.monthlyBudget = const Value.absent(),
    this.essential = const Value.absent(),
    this.system = const Value.absent(),
    this.active = const Value.absent(),
    this.custom = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseCategoriesCompanion.insert({
    required String id,
    required String name,
    required String icon,
    this.parentId = const Value.absent(),
    this.monthlyBudget = const Value.absent(),
    this.essential = const Value.absent(),
    this.system = const Value.absent(),
    this.active = const Value.absent(),
    this.custom = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       icon = Value(icon);
  static Insertable<CategoryRow> createCustom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? parentId,
    Expression<int>? monthlyBudget,
    Expression<bool>? essential,
    Expression<String>? system,
    Expression<bool>? active,
    Expression<bool>? custom,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (parentId != null) 'parent_id': parentId,
      if (monthlyBudget != null) 'monthly_budget': monthlyBudget,
      if (essential != null) 'essential': essential,
      if (system != null) 'system': system,
      if (active != null) 'active': active,
      if (custom != null) 'custom': custom,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<String?>? parentId,
    Value<int?>? monthlyBudget,
    Value<bool>? essential,
    Value<String?>? system,
    Value<bool>? active,
    Value<bool>? custom,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ExpenseCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      essential: essential ?? this.essential,
      system: system ?? this.system,
      active: active ?? this.active,
      custom: custom ?? this.custom,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (monthlyBudget.present) {
      map['monthly_budget'] = Variable<int>(monthlyBudget.value);
    }
    if (essential.present) {
      map['essential'] = Variable<bool>(essential.value);
    }
    if (system.present) {
      map['system'] = Variable<String>(system.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (custom.present) {
      map['custom'] = Variable<bool>(custom.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('parentId: $parentId, ')
          ..write('monthlyBudget: $monthlyBudget, ')
          ..write('essential: $essential, ')
          ..write('system: $system, ')
          ..write('active: $active, ')
          ..write('custom: $custom, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoanTypesTable extends LoanTypes
    with TableInfo<$LoanTypesTable, LoanTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoanTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultMethodMeta = const VerificationMeta(
    'defaultMethod',
  );
  @override
  late final GeneratedColumn<String> defaultMethod = GeneratedColumn<String>(
    'default_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    icon,
    defaultMethod,
    active,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loan_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoanTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('default_method')) {
      context.handle(
        _defaultMethodMeta,
        defaultMethod.isAcceptableOrUnknown(
          data['default_method']!,
          _defaultMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultMethodMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoanTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoanTypeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      defaultMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_method'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $LoanTypesTable createAlias(String alias) {
    return $LoanTypesTable(attachedDatabase, alias);
  }
}

class LoanTypeRow extends DataClass implements Insertable<LoanTypeRow> {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String defaultMethod;
  final bool active;
  final int sortOrder;
  const LoanTypeRow({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.defaultMethod,
    required this.active,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['icon'] = Variable<String>(icon);
    map['default_method'] = Variable<String>(defaultMethod);
    map['active'] = Variable<bool>(active);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LoanTypesCompanion toCompanion(bool nullToAbsent) {
    return LoanTypesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: Value(icon),
      defaultMethod: Value(defaultMethod),
      active: Value(active),
      sortOrder: Value(sortOrder),
    );
  }

  factory LoanTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoanTypeRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<String>(json['icon']),
      defaultMethod: serializer.fromJson<String>(json['defaultMethod']),
      active: serializer.fromJson<bool>(json['active']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<String>(icon),
      'defaultMethod': serializer.toJson<String>(defaultMethod),
      'active': serializer.toJson<bool>(active),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LoanTypeRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? icon,
    String? defaultMethod,
    bool? active,
    int? sortOrder,
  }) => LoanTypeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon ?? this.icon,
    defaultMethod: defaultMethod ?? this.defaultMethod,
    active: active ?? this.active,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LoanTypeRow copyWithCompanion(LoanTypesCompanion data) {
    return LoanTypeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      defaultMethod: data.defaultMethod.present
          ? data.defaultMethod.value
          : this.defaultMethod,
      active: data.active.present ? data.active.value : this.active,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoanTypeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('defaultMethod: $defaultMethod, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    icon,
    defaultMethod,
    active,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoanTypeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.defaultMethod == this.defaultMethod &&
          other.active == this.active &&
          other.sortOrder == this.sortOrder);
}

class LoanTypesCompanion extends UpdateCompanion<LoanTypeRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> icon;
  final Value<String> defaultMethod;
  final Value<bool> active;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LoanTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.defaultMethod = const Value.absent(),
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoanTypesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String icon,
    required String defaultMethod,
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       icon = Value(icon),
       defaultMethod = Value(defaultMethod);
  static Insertable<LoanTypeRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<String>? defaultMethod,
    Expression<bool>? active,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (defaultMethod != null) 'default_method': defaultMethod,
      if (active != null) 'active': active,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoanTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? icon,
    Value<String>? defaultMethod,
    Value<bool>? active,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return LoanTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      defaultMethod: defaultMethod ?? this.defaultMethod,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (defaultMethod.present) {
      map['default_method'] = Variable<String>(defaultMethod.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoanTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('defaultMethod: $defaultMethod, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringRulesTable extends RecurringRules
    with TableInfo<$RecurringRulesTable, RecurringRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _incomeTypeIdMeta = const VerificationMeta(
    'incomeTypeId',
  );
  @override
  late final GeneratedColumn<String> incomeTypeId = GeneratedColumn<String>(
    'income_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextDateMeta = const VerificationMeta(
    'nextDate',
  );
  @override
  late final GeneratedColumn<String> nextDate = GeneratedColumn<String>(
    'next_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    amount,
    categoryId,
    incomeTypeId,
    accountId,
    frequency,
    nextDate,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('income_type_id')) {
      context.handle(
        _incomeTypeIdMeta,
        incomeTypeId.isAcceptableOrUnknown(
          data['income_type_id']!,
          _incomeTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('next_date')) {
      context.handle(
        _nextDateMeta,
        nextDate.isAcceptableOrUnknown(data['next_date']!, _nextDateMeta),
      );
    } else if (isInserting) {
      context.missing(_nextDateMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      incomeTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}income_type_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      nextDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_date'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $RecurringRulesTable createAlias(String alias) {
    return $RecurringRulesTable(attachedDatabase, alias);
  }
}

class RecurringRow extends DataClass implements Insertable<RecurringRow> {
  final String id;
  final String name;
  final String type;
  final int amount;
  final String? categoryId;
  final String? incomeTypeId;
  final String accountId;
  final String frequency;
  final String nextDate;
  final bool active;
  const RecurringRow({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.categoryId,
    this.incomeTypeId,
    required this.accountId,
    required this.frequency,
    required this.nextDate,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || incomeTypeId != null) {
      map['income_type_id'] = Variable<String>(incomeTypeId);
    }
    map['account_id'] = Variable<String>(accountId);
    map['frequency'] = Variable<String>(frequency);
    map['next_date'] = Variable<String>(nextDate);
    map['active'] = Variable<bool>(active);
    return map;
  }

  RecurringRulesCompanion toCompanion(bool nullToAbsent) {
    return RecurringRulesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      amount: Value(amount),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      incomeTypeId: incomeTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(incomeTypeId),
      accountId: Value(accountId),
      frequency: Value(frequency),
      nextDate: Value(nextDate),
      active: Value(active),
    );
  }

  factory RecurringRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<int>(json['amount']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      incomeTypeId: serializer.fromJson<String?>(json['incomeTypeId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      frequency: serializer.fromJson<String>(json['frequency']),
      nextDate: serializer.fromJson<String>(json['nextDate']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<int>(amount),
      'categoryId': serializer.toJson<String?>(categoryId),
      'incomeTypeId': serializer.toJson<String?>(incomeTypeId),
      'accountId': serializer.toJson<String>(accountId),
      'frequency': serializer.toJson<String>(frequency),
      'nextDate': serializer.toJson<String>(nextDate),
      'active': serializer.toJson<bool>(active),
    };
  }

  RecurringRow copyWith({
    String? id,
    String? name,
    String? type,
    int? amount,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> incomeTypeId = const Value.absent(),
    String? accountId,
    String? frequency,
    String? nextDate,
    bool? active,
  }) => RecurringRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    incomeTypeId: incomeTypeId.present ? incomeTypeId.value : this.incomeTypeId,
    accountId: accountId ?? this.accountId,
    frequency: frequency ?? this.frequency,
    nextDate: nextDate ?? this.nextDate,
    active: active ?? this.active,
  );
  RecurringRow copyWithCompanion(RecurringRulesCompanion data) {
    return RecurringRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      incomeTypeId: data.incomeTypeId.present
          ? data.incomeTypeId.value
          : this.incomeTypeId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      nextDate: data.nextDate.present ? data.nextDate.value : this.nextDate,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('incomeTypeId: $incomeTypeId, ')
          ..write('accountId: $accountId, ')
          ..write('frequency: $frequency, ')
          ..write('nextDate: $nextDate, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    amount,
    categoryId,
    incomeTypeId,
    accountId,
    frequency,
    nextDate,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId &&
          other.incomeTypeId == this.incomeTypeId &&
          other.accountId == this.accountId &&
          other.frequency == this.frequency &&
          other.nextDate == this.nextDate &&
          other.active == this.active);
}

class RecurringRulesCompanion extends UpdateCompanion<RecurringRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int> amount;
  final Value<String?> categoryId;
  final Value<String?> incomeTypeId;
  final Value<String> accountId;
  final Value<String> frequency;
  final Value<String> nextDate;
  final Value<bool> active;
  final Value<int> rowid;
  const RecurringRulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.incomeTypeId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.frequency = const Value.absent(),
    this.nextDate = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringRulesCompanion.insert({
    required String id,
    required String name,
    required String type,
    required int amount,
    this.categoryId = const Value.absent(),
    this.incomeTypeId = const Value.absent(),
    required String accountId,
    required String frequency,
    required String nextDate,
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       amount = Value(amount),
       accountId = Value(accountId),
       frequency = Value(frequency),
       nextDate = Value(nextDate);
  static Insertable<RecurringRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<String>? categoryId,
    Expression<String>? incomeTypeId,
    Expression<String>? accountId,
    Expression<String>? frequency,
    Expression<String>? nextDate,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (incomeTypeId != null) 'income_type_id': incomeTypeId,
      if (accountId != null) 'account_id': accountId,
      if (frequency != null) 'frequency': frequency,
      if (nextDate != null) 'next_date': nextDate,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<int>? amount,
    Value<String?>? categoryId,
    Value<String?>? incomeTypeId,
    Value<String>? accountId,
    Value<String>? frequency,
    Value<String>? nextDate,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return RecurringRulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      incomeTypeId: incomeTypeId ?? this.incomeTypeId,
      accountId: accountId ?? this.accountId,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (incomeTypeId.present) {
      map['income_type_id'] = Variable<String>(incomeTypeId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (nextDate.present) {
      map['next_date'] = Variable<String>(nextDate.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringRulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('incomeTypeId: $incomeTypeId, ')
          ..write('accountId: $accountId, ')
          ..write('frequency: $frequency, ')
          ..write('nextDate: $nextDate, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfigItemsTable extends ConfigItems
    with TableInfo<$ConfigItemsTable, ConfigItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listKeyMeta = const VerificationMeta(
    'listKey',
  );
  @override
  late final GeneratedColumn<String> listKey = GeneratedColumn<String>(
    'list_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listKey,
    name,
    description,
    active,
    isDefault,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'config_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_key')) {
      context.handle(
        _listKeyMeta,
        listKey.isAcceptableOrUnknown(data['list_key']!, _listKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_listKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfigItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ConfigItemsTable createAlias(String alias) {
    return $ConfigItemsTable(attachedDatabase, alias);
  }
}

class ConfigItemRow extends DataClass implements Insertable<ConfigItemRow> {
  final String id;
  final String listKey;
  final String name;
  final String description;
  final bool active;
  final bool isDefault;
  final int sortOrder;
  const ConfigItemRow({
    required this.id,
    required this.listKey,
    required this.name,
    required this.description,
    required this.active,
    required this.isDefault,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_key'] = Variable<String>(listKey);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['active'] = Variable<bool>(active);
    map['is_default'] = Variable<bool>(isDefault);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ConfigItemsCompanion toCompanion(bool nullToAbsent) {
    return ConfigItemsCompanion(
      id: Value(id),
      listKey: Value(listKey),
      name: Value(name),
      description: Value(description),
      active: Value(active),
      isDefault: Value(isDefault),
      sortOrder: Value(sortOrder),
    );
  }

  factory ConfigItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigItemRow(
      id: serializer.fromJson<String>(json['id']),
      listKey: serializer.fromJson<String>(json['listKey']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      active: serializer.fromJson<bool>(json['active']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listKey': serializer.toJson<String>(listKey),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'active': serializer.toJson<bool>(active),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ConfigItemRow copyWith({
    String? id,
    String? listKey,
    String? name,
    String? description,
    bool? active,
    bool? isDefault,
    int? sortOrder,
  }) => ConfigItemRow(
    id: id ?? this.id,
    listKey: listKey ?? this.listKey,
    name: name ?? this.name,
    description: description ?? this.description,
    active: active ?? this.active,
    isDefault: isDefault ?? this.isDefault,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ConfigItemRow copyWithCompanion(ConfigItemsCompanion data) {
    return ConfigItemRow(
      id: data.id.present ? data.id.value : this.id,
      listKey: data.listKey.present ? data.listKey.value : this.listKey,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      active: data.active.present ? data.active.value : this.active,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigItemRow(')
          ..write('id: $id, ')
          ..write('listKey: $listKey, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('active: $active, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, listKey, name, description, active, isDefault, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigItemRow &&
          other.id == this.id &&
          other.listKey == this.listKey &&
          other.name == this.name &&
          other.description == this.description &&
          other.active == this.active &&
          other.isDefault == this.isDefault &&
          other.sortOrder == this.sortOrder);
}

class ConfigItemsCompanion extends UpdateCompanion<ConfigItemRow> {
  final Value<String> id;
  final Value<String> listKey;
  final Value<String> name;
  final Value<String> description;
  final Value<bool> active;
  final Value<bool> isDefault;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ConfigItemsCompanion({
    this.id = const Value.absent(),
    this.listKey = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.active = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfigItemsCompanion.insert({
    required String id,
    required String listKey,
    required String name,
    this.description = const Value.absent(),
    this.active = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listKey = Value(listKey),
       name = Value(name);
  static Insertable<ConfigItemRow> custom({
    Expression<String>? id,
    Expression<String>? listKey,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? active,
    Expression<bool>? isDefault,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listKey != null) 'list_key': listKey,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (active != null) 'active': active,
      if (isDefault != null) 'is_default': isDefault,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfigItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? listKey,
    Value<String>? name,
    Value<String>? description,
    Value<bool>? active,
    Value<bool>? isDefault,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ConfigItemsCompanion(
      id: id ?? this.id,
      listKey: listKey ?? this.listKey,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listKey.present) {
      map['list_key'] = Variable<String>(listKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigItemsCompanion(')
          ..write('id: $id, ')
          ..write('listKey: $listKey, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('active: $active, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditEntriesTable extends AuditEntries
    with TableInfo<$AuditEntriesTable, AuditRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beforeJsonMeta = const VerificationMeta(
    'beforeJson',
  );
  @override
  late final GeneratedColumn<String> beforeJson = GeneratedColumn<String>(
    'before_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _afterJsonMeta = const VerificationMeta(
    'afterJson',
  );
  @override
  late final GeneratedColumn<String> afterJson = GeneratedColumn<String>(
    'after_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    actor,
    action,
    entity,
    entityId,
    summary,
    beforeJson,
    afterJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    } else if (isInserting) {
      context.missing(_actorMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('before_json')) {
      context.handle(
        _beforeJsonMeta,
        beforeJson.isAcceptableOrUnknown(data['before_json']!, _beforeJsonMeta),
      );
    }
    if (data.containsKey('after_json')) {
      context.handle(
        _afterJsonMeta,
        afterJson.isAcceptableOrUnknown(data['after_json']!, _afterJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      )!,
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      beforeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}before_json'],
      ),
      afterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}after_json'],
      ),
    );
  }

  @override
  $AuditEntriesTable createAlias(String alias) {
    return $AuditEntriesTable(attachedDatabase, alias);
  }
}

class AuditRow extends DataClass implements Insertable<AuditRow> {
  final String id;

  /// ISO date-time, 'YYYY-MM-DDTHH:mm:ss'.
  final String at;
  final String actor;
  final String action;
  final String entity;
  final String? entityId;

  /// What the Audit screen shows, e.g. "Added expense Big Mart · NPR 2,180".
  final String summary;
  final String? beforeJson;
  final String? afterJson;
  const AuditRow({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['at'] = Variable<String>(at);
    map['actor'] = Variable<String>(actor);
    map['action'] = Variable<String>(action);
    map['entity'] = Variable<String>(entity);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || beforeJson != null) {
      map['before_json'] = Variable<String>(beforeJson);
    }
    if (!nullToAbsent || afterJson != null) {
      map['after_json'] = Variable<String>(afterJson);
    }
    return map;
  }

  AuditEntriesCompanion toCompanion(bool nullToAbsent) {
    return AuditEntriesCompanion(
      id: Value(id),
      at: Value(at),
      actor: Value(actor),
      action: Value(action),
      entity: Value(entity),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      summary: Value(summary),
      beforeJson: beforeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(beforeJson),
      afterJson: afterJson == null && nullToAbsent
          ? const Value.absent()
          : Value(afterJson),
    );
  }

  factory AuditRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditRow(
      id: serializer.fromJson<String>(json['id']),
      at: serializer.fromJson<String>(json['at']),
      actor: serializer.fromJson<String>(json['actor']),
      action: serializer.fromJson<String>(json['action']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      summary: serializer.fromJson<String>(json['summary']),
      beforeJson: serializer.fromJson<String?>(json['beforeJson']),
      afterJson: serializer.fromJson<String?>(json['afterJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'at': serializer.toJson<String>(at),
      'actor': serializer.toJson<String>(actor),
      'action': serializer.toJson<String>(action),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String?>(entityId),
      'summary': serializer.toJson<String>(summary),
      'beforeJson': serializer.toJson<String?>(beforeJson),
      'afterJson': serializer.toJson<String?>(afterJson),
    };
  }

  AuditRow copyWith({
    String? id,
    String? at,
    String? actor,
    String? action,
    String? entity,
    Value<String?> entityId = const Value.absent(),
    String? summary,
    Value<String?> beforeJson = const Value.absent(),
    Value<String?> afterJson = const Value.absent(),
  }) => AuditRow(
    id: id ?? this.id,
    at: at ?? this.at,
    actor: actor ?? this.actor,
    action: action ?? this.action,
    entity: entity ?? this.entity,
    entityId: entityId.present ? entityId.value : this.entityId,
    summary: summary ?? this.summary,
    beforeJson: beforeJson.present ? beforeJson.value : this.beforeJson,
    afterJson: afterJson.present ? afterJson.value : this.afterJson,
  );
  AuditRow copyWithCompanion(AuditEntriesCompanion data) {
    return AuditRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      actor: data.actor.present ? data.actor.value : this.actor,
      action: data.action.present ? data.action.value : this.action,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      summary: data.summary.present ? data.summary.value : this.summary,
      beforeJson: data.beforeJson.present
          ? data.beforeJson.value
          : this.beforeJson,
      afterJson: data.afterJson.present ? data.afterJson.value : this.afterJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('actor: $actor, ')
          ..write('action: $action, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('summary: $summary, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    at,
    actor,
    action,
    entity,
    entityId,
    summary,
    beforeJson,
    afterJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.actor == this.actor &&
          other.action == this.action &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.summary == this.summary &&
          other.beforeJson == this.beforeJson &&
          other.afterJson == this.afterJson);
}

class AuditEntriesCompanion extends UpdateCompanion<AuditRow> {
  final Value<String> id;
  final Value<String> at;
  final Value<String> actor;
  final Value<String> action;
  final Value<String> entity;
  final Value<String?> entityId;
  final Value<String> summary;
  final Value<String?> beforeJson;
  final Value<String?> afterJson;
  final Value<int> rowid;
  const AuditEntriesCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.actor = const Value.absent(),
    this.action = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.summary = const Value.absent(),
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditEntriesCompanion.insert({
    required String id,
    required String at,
    required String actor,
    required String action,
    required String entity,
    this.entityId = const Value.absent(),
    required String summary,
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       at = Value(at),
       actor = Value(actor),
       action = Value(action),
       entity = Value(entity),
       summary = Value(summary);
  static Insertable<AuditRow> custom({
    Expression<String>? id,
    Expression<String>? at,
    Expression<String>? actor,
    Expression<String>? action,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? summary,
    Expression<String>? beforeJson,
    Expression<String>? afterJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (actor != null) 'actor': actor,
      if (action != null) 'action': action,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (summary != null) 'summary': summary,
      if (beforeJson != null) 'before_json': beforeJson,
      if (afterJson != null) 'after_json': afterJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? at,
    Value<String>? actor,
    Value<String>? action,
    Value<String>? entity,
    Value<String?>? entityId,
    Value<String>? summary,
    Value<String?>? beforeJson,
    Value<String?>? afterJson,
    Value<int>? rowid,
  }) {
    return AuditEntriesCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      actor: actor ?? this.actor,
      action: action ?? this.action,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      summary: summary ?? this.summary,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (beforeJson.present) {
      map['before_json'] = Variable<String>(beforeJson.value);
    }
    if (afterJson.present) {
      map['after_json'] = Variable<String>(afterJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditEntriesCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('actor: $actor, ')
          ..write('action: $action, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('summary: $summary, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaRow copyWith({String? key, String? value}) =>
      MetaRow(key: key ?? this.key, value: value ?? this.value);
  MetaRow copyWithCompanion(AppMetaCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $LoansTable loans = $LoansTable(this);
  late final $IncomeTypesTable incomeTypes = $IncomeTypesTable(this);
  late final $ExpenseCategoriesTable expenseCategories =
      $ExpenseCategoriesTable(this);
  late final $LoanTypesTable loanTypes = $LoanTypesTable(this);
  late final $RecurringRulesTable recurringRules = $RecurringRulesTable(this);
  late final $ConfigItemsTable configItems = $ConfigItemsTable(this);
  late final $AuditEntriesTable auditEntries = $AuditEntriesTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    transactions,
    loans,
    incomeTypes,
    expenseCategories,
    loanTypes,
    recurringRules,
    configItems,
    auditEntries,
    appMeta,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String name,
  required String shortName,
  Value<String?> institution,
  Value<String?> accountTypeId,
  required String accountGroup,
  required String kind,
  Value<String?> maskedNumber,
  Value<String?> smsSender,
  Value<bool> autoUpdateFromSms,
  required int openingBalance,
  required int balance,
  Value<int?> creditLimit,
  Value<String?> statementDueDate,
  Value<String?> note,
  Value<bool> archived,
  Value<String?> lastReconciled,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> shortName,
  Value<String?> institution,
  Value<String?> accountTypeId,
  Value<String> accountGroup,
  Value<String> kind,
  Value<String?> maskedNumber,
  Value<String?> smsSender,
  Value<bool> autoUpdateFromSms,
  Value<int> openingBalance,
  Value<int> balance,
  Value<int?> creditLimit,
  Value<String?> statementDueDate,
  Value<String?> note,
  Value<bool> archived,
  Value<String?> lastReconciled,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountTypeId => $composableBuilder(
    column: $table.accountTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountGroup => $composableBuilder(
    column: $table.accountGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maskedNumber => $composableBuilder(
    column: $table.maskedNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get smsSender => $composableBuilder(
    column: $table.smsSender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoUpdateFromSms => $composableBuilder(
    column: $table.autoUpdateFromSms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statementDueDate => $composableBuilder(
    column: $table.statementDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReconciled => $composableBuilder(
    column: $table.lastReconciled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountTypeId => $composableBuilder(
    column: $table.accountTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountGroup => $composableBuilder(
    column: $table.accountGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maskedNumber => $composableBuilder(
    column: $table.maskedNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get smsSender => $composableBuilder(
    column: $table.smsSender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoUpdateFromSms => $composableBuilder(
    column: $table.autoUpdateFromSms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statementDueDate => $composableBuilder(
    column: $table.statementDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReconciled => $composableBuilder(
    column: $table.lastReconciled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  GeneratedColumn<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountTypeId => $composableBuilder(
    column: $table.accountTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountGroup => $composableBuilder(
    column: $table.accountGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get maskedNumber => $composableBuilder(
    column: $table.maskedNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get smsSender =>
      $composableBuilder(column: $table.smsSender, builder: (column) => column);

  GeneratedColumn<bool> get autoUpdateFromSms => $composableBuilder(
    column: $table.autoUpdateFromSms,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statementDueDate => $composableBuilder(
    column: $table.statementDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get lastReconciled => $composableBuilder(
    column: $table.lastReconciled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (
            AccountRow,
            BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>,
          ),
          AccountRow,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> shortName = const Value.absent(),
                Value<String?> institution = const Value.absent(),
                Value<String?> accountTypeId = const Value.absent(),
                Value<String> accountGroup = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> maskedNumber = const Value.absent(),
                Value<String?> smsSender = const Value.absent(),
                Value<bool> autoUpdateFromSms = const Value.absent(),
                Value<int> openingBalance = const Value.absent(),
                Value<int> balance = const Value.absent(),
                Value<int?> creditLimit = const Value.absent(),
                Value<String?> statementDueDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> lastReconciled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                shortName: shortName,
                institution: institution,
                accountTypeId: accountTypeId,
                accountGroup: accountGroup,
                kind: kind,
                maskedNumber: maskedNumber,
                smsSender: smsSender,
                autoUpdateFromSms: autoUpdateFromSms,
                openingBalance: openingBalance,
                balance: balance,
                creditLimit: creditLimit,
                statementDueDate: statementDueDate,
                note: note,
                archived: archived,
                lastReconciled: lastReconciled,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String shortName,
                Value<String?> institution = const Value.absent(),
                Value<String?> accountTypeId = const Value.absent(),
                required String accountGroup,
                required String kind,
                Value<String?> maskedNumber = const Value.absent(),
                Value<String?> smsSender = const Value.absent(),
                Value<bool> autoUpdateFromSms = const Value.absent(),
                required int openingBalance,
                required int balance,
                Value<int?> creditLimit = const Value.absent(),
                Value<String?> statementDueDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> lastReconciled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                shortName: shortName,
                institution: institution,
                accountTypeId: accountTypeId,
                accountGroup: accountGroup,
                kind: kind,
                maskedNumber: maskedNumber,
                smsSender: smsSender,
                autoUpdateFromSms: autoUpdateFromSms,
                openingBalance: openingBalance,
                balance: balance,
                creditLimit: creditLimit,
                statementDueDate: statementDueDate,
                note: note,
                archived: archived,
                lastReconciled: lastReconciled,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, AccountRow>(table),
                  BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, BaseReferences<_$AppDatabase, $AccountsTable, AccountRow>),
      AccountRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String date,
      required String time,
      required String title,
      required String type,
      Value<String?> direction,
      required String accountId,
      Value<String?> counterAccountId,
      Value<String?> categoryId,
      Value<String?> incomeTypeId,
      Value<String?> loanId,
      required int amount,
      Value<int?> principal,
      Value<int?> interest,
      required String status,
      required String source,
      Value<String?> smsId,
      Value<String?> note,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String> time,
      Value<String> title,
      Value<String> type,
      Value<String?> direction,
      Value<String> accountId,
      Value<String?> counterAccountId,
      Value<String?> categoryId,
      Value<String?> incomeTypeId,
      Value<String?> loanId,
      Value<int> amount,
      Value<int?> principal,
      Value<int?> interest,
      Value<String> status,
      Value<String> source,
      Value<String?> smsId,
      Value<String?> note,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TxnRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _counterAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__counter_account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get counterAccountId {
    final $_column = $_itemColumn<String>('counter_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get incomeTypeId => $composableBuilder(
    column: $table.incomeTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loanId => $composableBuilder(
    column: $table.loanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get principal => $composableBuilder(
    column: $table.principal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interest => $composableBuilder(
    column: $table.interest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get smsId => $composableBuilder(
    column: $table.smsId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get counterAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get incomeTypeId => $composableBuilder(
    column: $table.incomeTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loanId => $composableBuilder(
    column: $table.loanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get principal => $composableBuilder(
    column: $table.principal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interest => $composableBuilder(
    column: $table.interest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get smsId => $composableBuilder(
    column: $table.smsId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get counterAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get incomeTypeId => $composableBuilder(
    column: $table.incomeTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loanId =>
      $composableBuilder(column: $table.loanId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get principal =>
      $composableBuilder(column: $table.principal, builder: (column) => column);

  GeneratedColumn<int> get interest =>
      $composableBuilder(column: $table.interest, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get smsId =>
      $composableBuilder(column: $table.smsId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get counterAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TxnRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TxnRow, $$TransactionsTableReferences),
          TxnRow,
          PrefetchHooks Function({bool accountId, bool counterAccountId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> time = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> direction = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> counterAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> incomeTypeId = const Value.absent(),
                Value<String?> loanId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int?> principal = const Value.absent(),
                Value<int?> interest = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> smsId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                date: date,
                time: time,
                title: title,
                type: type,
                direction: direction,
                accountId: accountId,
                counterAccountId: counterAccountId,
                categoryId: categoryId,
                incomeTypeId: incomeTypeId,
                loanId: loanId,
                amount: amount,
                principal: principal,
                interest: interest,
                status: status,
                source: source,
                smsId: smsId,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String time,
                required String title,
                required String type,
                Value<String?> direction = const Value.absent(),
                required String accountId,
                Value<String?> counterAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> incomeTypeId = const Value.absent(),
                Value<String?> loanId = const Value.absent(),
                required int amount,
                Value<int?> principal = const Value.absent(),
                Value<int?> interest = const Value.absent(),
                required String status,
                required String source,
                Value<String?> smsId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                date: date,
                time: time,
                title: title,
                type: type,
                direction: direction,
                accountId: accountId,
                counterAccountId: counterAccountId,
                categoryId: categoryId,
                incomeTypeId: incomeTypeId,
                loanId: loanId,
                amount: amount,
                principal: principal,
                interest: interest,
                status: status,
                source: source,
                smsId: smsId,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TxnRow>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({accountId = false, counterAccountId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$TransactionsTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (counterAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.counterAccountId,
                            referencedTable: $$TransactionsTableReferences
                                ._counterAccountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._counterAccountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TxnRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TxnRow, $$TransactionsTableReferences),
      TxnRow,
      PrefetchHooks Function({bool accountId, bool counterAccountId})
    >;
typedef $$LoansTableCreateCompanionBuilder = LoansCompanion Function({
  required String id,
  required String loanTypeId,
  required String name,
  required String lender,
  required int principal,
  required int outstanding,
  Value<double?> ratePct,
  required String method,
  required int installment,
  required String frequency,
  Value<String?> startDate,
  Value<String?> maturityDate,
  Value<String?> nextDueDate,
  Value<String?> repaymentAccountId,
  Value<String?> feesAndPrepayment,
  Value<bool> closed,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$LoansTableUpdateCompanionBuilder = LoansCompanion Function({
  Value<String> id,
  Value<String> loanTypeId,
  Value<String> name,
  Value<String> lender,
  Value<int> principal,
  Value<int> outstanding,
  Value<double?> ratePct,
  Value<String> method,
  Value<int> installment,
  Value<String> frequency,
  Value<String?> startDate,
  Value<String?> maturityDate,
  Value<String?> nextDueDate,
  Value<String?> repaymentAccountId,
  Value<String?> feesAndPrepayment,
  Value<bool> closed,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$LoansTableFilterComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loanTypeId => $composableBuilder(
    column: $table.loanTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lender => $composableBuilder(
    column: $table.lender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get principal => $composableBuilder(
    column: $table.principal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outstanding => $composableBuilder(
    column: $table.outstanding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ratePct => $composableBuilder(
    column: $table.ratePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installment => $composableBuilder(
    column: $table.installment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maturityDate => $composableBuilder(
    column: $table.maturityDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repaymentAccountId => $composableBuilder(
    column: $table.repaymentAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feesAndPrepayment => $composableBuilder(
    column: $table.feesAndPrepayment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LoansTableOrderingComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loanTypeId => $composableBuilder(
    column: $table.loanTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lender => $composableBuilder(
    column: $table.lender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get principal => $composableBuilder(
    column: $table.principal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outstanding => $composableBuilder(
    column: $table.outstanding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ratePct => $composableBuilder(
    column: $table.ratePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installment => $composableBuilder(
    column: $table.installment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maturityDate => $composableBuilder(
    column: $table.maturityDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repaymentAccountId => $composableBuilder(
    column: $table.repaymentAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feesAndPrepayment => $composableBuilder(
    column: $table.feesAndPrepayment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get loanTypeId => $composableBuilder(
    column: $table.loanTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get lender =>
      $composableBuilder(column: $table.lender, builder: (column) => column);

  GeneratedColumn<int> get principal =>
      $composableBuilder(column: $table.principal, builder: (column) => column);

  GeneratedColumn<int> get outstanding => $composableBuilder(
    column: $table.outstanding,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ratePct =>
      $composableBuilder(column: $table.ratePct, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get installment => $composableBuilder(
    column: $table.installment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get maturityDate => $composableBuilder(
    column: $table.maturityDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repaymentAccountId => $composableBuilder(
    column: $table.repaymentAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feesAndPrepayment => $composableBuilder(
    column: $table.feesAndPrepayment,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get closed =>
      $composableBuilder(column: $table.closed, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$LoansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoansTable,
          LoanRow,
          $$LoansTableFilterComposer,
          $$LoansTableOrderingComposer,
          $$LoansTableAnnotationComposer,
          $$LoansTableCreateCompanionBuilder,
          $$LoansTableUpdateCompanionBuilder,
          (LoanRow, BaseReferences<_$AppDatabase, $LoansTable, LoanRow>),
          LoanRow,
          PrefetchHooks Function()
        > {
  $$LoansTableTableManager(_$AppDatabase db, $LoansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> loanTypeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> lender = const Value.absent(),
                Value<int> principal = const Value.absent(),
                Value<int> outstanding = const Value.absent(),
                Value<double?> ratePct = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> installment = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> maturityDate = const Value.absent(),
                Value<String?> nextDueDate = const Value.absent(),
                Value<String?> repaymentAccountId = const Value.absent(),
                Value<String?> feesAndPrepayment = const Value.absent(),
                Value<bool> closed = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoansCompanion(
                id: id,
                loanTypeId: loanTypeId,
                name: name,
                lender: lender,
                principal: principal,
                outstanding: outstanding,
                ratePct: ratePct,
                method: method,
                installment: installment,
                frequency: frequency,
                startDate: startDate,
                maturityDate: maturityDate,
                nextDueDate: nextDueDate,
                repaymentAccountId: repaymentAccountId,
                feesAndPrepayment: feesAndPrepayment,
                closed: closed,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String loanTypeId,
                required String name,
                required String lender,
                required int principal,
                required int outstanding,
                Value<double?> ratePct = const Value.absent(),
                required String method,
                required int installment,
                required String frequency,
                Value<String?> startDate = const Value.absent(),
                Value<String?> maturityDate = const Value.absent(),
                Value<String?> nextDueDate = const Value.absent(),
                Value<String?> repaymentAccountId = const Value.absent(),
                Value<String?> feesAndPrepayment = const Value.absent(),
                Value<bool> closed = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoansCompanion.insert(
                id: id,
                loanTypeId: loanTypeId,
                name: name,
                lender: lender,
                principal: principal,
                outstanding: outstanding,
                ratePct: ratePct,
                method: method,
                installment: installment,
                frequency: frequency,
                startDate: startDate,
                maturityDate: maturityDate,
                nextDueDate: nextDueDate,
                repaymentAccountId: repaymentAccountId,
                feesAndPrepayment: feesAndPrepayment,
                closed: closed,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoansTable, LoanRow>(table),
                  BaseReferences<_$AppDatabase, $LoansTable, LoanRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LoansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoansTable,
      LoanRow,
      $$LoansTableFilterComposer,
      $$LoansTableOrderingComposer,
      $$LoansTableAnnotationComposer,
      $$LoansTableCreateCompanionBuilder,
      $$LoansTableUpdateCompanionBuilder,
      (LoanRow, BaseReferences<_$AppDatabase, $LoansTable, LoanRow>),
      LoanRow,
      PrefetchHooks Function()
    >;
typedef $$IncomeTypesTableCreateCompanionBuilder =
    IncomeTypesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required String icon,
      required int color,
      Value<String?> defaultAccountId,
      required bool recurring,
      Value<int?> expectedAmount,
      required String frequency,
      Value<String?> expectedDay,
      Value<String> applicableDeductionIds,
      Value<bool> active,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$IncomeTypesTableUpdateCompanionBuilder =
    IncomeTypesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String> icon,
      Value<int> color,
      Value<String?> defaultAccountId,
      Value<bool> recurring,
      Value<int?> expectedAmount,
      Value<String> frequency,
      Value<String?> expectedDay,
      Value<String> applicableDeductionIds,
      Value<bool> active,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$IncomeTypesTableFilterComposer
    extends Composer<_$AppDatabase, $IncomeTypesTable> {
  $$IncomeTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultAccountId => $composableBuilder(
    column: $table.defaultAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recurring => $composableBuilder(
    column: $table.recurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedAmount => $composableBuilder(
    column: $table.expectedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedDay => $composableBuilder(
    column: $table.expectedDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get applicableDeductionIds => $composableBuilder(
    column: $table.applicableDeductionIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IncomeTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomeTypesTable> {
  $$IncomeTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultAccountId => $composableBuilder(
    column: $table.defaultAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recurring => $composableBuilder(
    column: $table.recurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedAmount => $composableBuilder(
    column: $table.expectedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedDay => $composableBuilder(
    column: $table.expectedDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applicableDeductionIds => $composableBuilder(
    column: $table.applicableDeductionIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IncomeTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomeTypesTable> {
  $$IncomeTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get defaultAccountId => $composableBuilder(
    column: $table.defaultAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get recurring =>
      $composableBuilder(column: $table.recurring, builder: (column) => column);

  GeneratedColumn<int> get expectedAmount => $composableBuilder(
    column: $table.expectedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get expectedDay => $composableBuilder(
    column: $table.expectedDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get applicableDeductionIds => $composableBuilder(
    column: $table.applicableDeductionIds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$IncomeTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomeTypesTable,
          IncomeTypeRow,
          $$IncomeTypesTableFilterComposer,
          $$IncomeTypesTableOrderingComposer,
          $$IncomeTypesTableAnnotationComposer,
          $$IncomeTypesTableCreateCompanionBuilder,
          $$IncomeTypesTableUpdateCompanionBuilder,
          (
            IncomeTypeRow,
            BaseReferences<_$AppDatabase, $IncomeTypesTable, IncomeTypeRow>,
          ),
          IncomeTypeRow,
          PrefetchHooks Function()
        > {
  $$IncomeTypesTableTableManager(_$AppDatabase db, $IncomeTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomeTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomeTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomeTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String?> defaultAccountId = const Value.absent(),
                Value<bool> recurring = const Value.absent(),
                Value<int?> expectedAmount = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String?> expectedDay = const Value.absent(),
                Value<String> applicableDeductionIds = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomeTypesCompanion(
                id: id,
                name: name,
                description: description,
                icon: icon,
                color: color,
                defaultAccountId: defaultAccountId,
                recurring: recurring,
                expectedAmount: expectedAmount,
                frequency: frequency,
                expectedDay: expectedDay,
                applicableDeductionIds: applicableDeductionIds,
                active: active,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required String icon,
                required int color,
                Value<String?> defaultAccountId = const Value.absent(),
                required bool recurring,
                Value<int?> expectedAmount = const Value.absent(),
                required String frequency,
                Value<String?> expectedDay = const Value.absent(),
                Value<String> applicableDeductionIds = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomeTypesCompanion.insert(
                id: id,
                name: name,
                description: description,
                icon: icon,
                color: color,
                defaultAccountId: defaultAccountId,
                recurring: recurring,
                expectedAmount: expectedAmount,
                frequency: frequency,
                expectedDay: expectedDay,
                applicableDeductionIds: applicableDeductionIds,
                active: active,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IncomeTypesTable, IncomeTypeRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $IncomeTypesTable,
                    IncomeTypeRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IncomeTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomeTypesTable,
      IncomeTypeRow,
      $$IncomeTypesTableFilterComposer,
      $$IncomeTypesTableOrderingComposer,
      $$IncomeTypesTableAnnotationComposer,
      $$IncomeTypesTableCreateCompanionBuilder,
      $$IncomeTypesTableUpdateCompanionBuilder,
      (
        IncomeTypeRow,
        BaseReferences<_$AppDatabase, $IncomeTypesTable, IncomeTypeRow>,
      ),
      IncomeTypeRow,
      PrefetchHooks Function()
    >;
typedef $$ExpenseCategoriesTableCreateCompanionBuilder =
    ExpenseCategoriesCompanion Function({
      required String id,
      required String name,
      required String icon,
      Value<String?> parentId,
      Value<int?> monthlyBudget,
      Value<bool> essential,
      Value<String?> system,
      Value<bool> active,
      Value<bool> custom,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$ExpenseCategoriesTableUpdateCompanionBuilder =
    ExpenseCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> icon,
      Value<String?> parentId,
      Value<int?> monthlyBudget,
      Value<bool> essential,
      Value<String?> system,
      Value<bool> active,
      Value<bool> custom,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$ExpenseCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseCategoriesTable> {
  $$ExpenseCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get essential => $composableBuilder(
    column: $table.essential,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get system => $composableBuilder(
    column: $table.system,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get custom => $composableBuilder(
    column: $table.custom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpenseCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseCategoriesTable> {
  $$ExpenseCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get essential => $composableBuilder(
    column: $table.essential,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get system => $composableBuilder(
    column: $table.system,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get custom => $composableBuilder(
    column: $table.custom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpenseCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseCategoriesTable> {
  $$ExpenseCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get essential =>
      $composableBuilder(column: $table.essential, builder: (column) => column);

  GeneratedColumn<String> get system =>
      $composableBuilder(column: $table.system, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<bool> get custom =>
      $composableBuilder(column: $table.custom, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ExpenseCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseCategoriesTable,
          CategoryRow,
          $$ExpenseCategoriesTableFilterComposer,
          $$ExpenseCategoriesTableOrderingComposer,
          $$ExpenseCategoriesTableAnnotationComposer,
          $$ExpenseCategoriesTableCreateCompanionBuilder,
          $$ExpenseCategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $ExpenseCategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$ExpenseCategoriesTableTableManager(
    _$AppDatabase db,
    $ExpenseCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int?> monthlyBudget = const Value.absent(),
                Value<bool> essential = const Value.absent(),
                Value<String?> system = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<bool> custom = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseCategoriesCompanion(
                id: id,
                name: name,
                icon: icon,
                parentId: parentId,
                monthlyBudget: monthlyBudget,
                essential: essential,
                system: system,
                active: active,
                custom: custom,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String icon,
                Value<String?> parentId = const Value.absent(),
                Value<int?> monthlyBudget = const Value.absent(),
                Value<bool> essential = const Value.absent(),
                Value<String?> system = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<bool> custom = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseCategoriesCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                parentId: parentId,
                monthlyBudget: monthlyBudget,
                essential: essential,
                system: system,
                active: active,
                custom: custom,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpenseCategoriesTable, CategoryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExpenseCategoriesTable,
                    CategoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpenseCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseCategoriesTable,
      CategoryRow,
      $$ExpenseCategoriesTableFilterComposer,
      $$ExpenseCategoriesTableOrderingComposer,
      $$ExpenseCategoriesTableAnnotationComposer,
      $$ExpenseCategoriesTableCreateCompanionBuilder,
      $$ExpenseCategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $ExpenseCategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$LoanTypesTableCreateCompanionBuilder = LoanTypesCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  required String icon,
  required String defaultMethod,
  Value<bool> active,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$LoanTypesTableUpdateCompanionBuilder = LoanTypesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String> icon,
  Value<String> defaultMethod,
  Value<bool> active,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$LoanTypesTableFilterComposer
    extends Composer<_$AppDatabase, $LoanTypesTable> {
  $$LoanTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultMethod => $composableBuilder(
    column: $table.defaultMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LoanTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $LoanTypesTable> {
  $$LoanTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultMethod => $composableBuilder(
    column: $table.defaultMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoanTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoanTypesTable> {
  $$LoanTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get defaultMethod => $composableBuilder(
    column: $table.defaultMethod,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$LoanTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoanTypesTable,
          LoanTypeRow,
          $$LoanTypesTableFilterComposer,
          $$LoanTypesTableOrderingComposer,
          $$LoanTypesTableAnnotationComposer,
          $$LoanTypesTableCreateCompanionBuilder,
          $$LoanTypesTableUpdateCompanionBuilder,
          (
            LoanTypeRow,
            BaseReferences<_$AppDatabase, $LoanTypesTable, LoanTypeRow>,
          ),
          LoanTypeRow,
          PrefetchHooks Function()
        > {
  $$LoanTypesTableTableManager(_$AppDatabase db, $LoanTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoanTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoanTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoanTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> defaultMethod = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoanTypesCompanion(
                id: id,
                name: name,
                description: description,
                icon: icon,
                defaultMethod: defaultMethod,
                active: active,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required String icon,
                required String defaultMethod,
                Value<bool> active = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoanTypesCompanion.insert(
                id: id,
                name: name,
                description: description,
                icon: icon,
                defaultMethod: defaultMethod,
                active: active,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoanTypesTable, LoanTypeRow>(table),
                  BaseReferences<_$AppDatabase, $LoanTypesTable, LoanTypeRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LoanTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoanTypesTable,
      LoanTypeRow,
      $$LoanTypesTableFilterComposer,
      $$LoanTypesTableOrderingComposer,
      $$LoanTypesTableAnnotationComposer,
      $$LoanTypesTableCreateCompanionBuilder,
      $$LoanTypesTableUpdateCompanionBuilder,
      (
        LoanTypeRow,
        BaseReferences<_$AppDatabase, $LoanTypesTable, LoanTypeRow>,
      ),
      LoanTypeRow,
      PrefetchHooks Function()
    >;
typedef $$RecurringRulesTableCreateCompanionBuilder =
    RecurringRulesCompanion Function({
      required String id,
      required String name,
      required String type,
      required int amount,
      Value<String?> categoryId,
      Value<String?> incomeTypeId,
      required String accountId,
      required String frequency,
      required String nextDate,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$RecurringRulesTableUpdateCompanionBuilder =
    RecurringRulesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<int> amount,
      Value<String?> categoryId,
      Value<String?> incomeTypeId,
      Value<String> accountId,
      Value<String> frequency,
      Value<String> nextDate,
      Value<bool> active,
      Value<int> rowid,
    });

class $$RecurringRulesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get incomeTypeId => $composableBuilder(
    column: $table.incomeTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextDate => $composableBuilder(
    column: $table.nextDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecurringRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get incomeTypeId => $composableBuilder(
    column: $table.incomeTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextDate => $composableBuilder(
    column: $table.nextDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get incomeTypeId => $composableBuilder(
    column: $table.incomeTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get nextDate =>
      $composableBuilder(column: $table.nextDate, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$RecurringRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringRulesTable,
          RecurringRow,
          $$RecurringRulesTableFilterComposer,
          $$RecurringRulesTableOrderingComposer,
          $$RecurringRulesTableAnnotationComposer,
          $$RecurringRulesTableCreateCompanionBuilder,
          $$RecurringRulesTableUpdateCompanionBuilder,
          (
            RecurringRow,
            BaseReferences<_$AppDatabase, $RecurringRulesTable, RecurringRow>,
          ),
          RecurringRow,
          PrefetchHooks Function()
        > {
  $$RecurringRulesTableTableManager(
    _$AppDatabase db,
    $RecurringRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> incomeTypeId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> nextDate = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringRulesCompanion(
                id: id,
                name: name,
                type: type,
                amount: amount,
                categoryId: categoryId,
                incomeTypeId: incomeTypeId,
                accountId: accountId,
                frequency: frequency,
                nextDate: nextDate,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required int amount,
                Value<String?> categoryId = const Value.absent(),
                Value<String?> incomeTypeId = const Value.absent(),
                required String accountId,
                required String frequency,
                required String nextDate,
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringRulesCompanion.insert(
                id: id,
                name: name,
                type: type,
                amount: amount,
                categoryId: categoryId,
                incomeTypeId: incomeTypeId,
                accountId: accountId,
                frequency: frequency,
                nextDate: nextDate,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringRulesTable, RecurringRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RecurringRulesTable,
                    RecurringRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecurringRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringRulesTable,
      RecurringRow,
      $$RecurringRulesTableFilterComposer,
      $$RecurringRulesTableOrderingComposer,
      $$RecurringRulesTableAnnotationComposer,
      $$RecurringRulesTableCreateCompanionBuilder,
      $$RecurringRulesTableUpdateCompanionBuilder,
      (
        RecurringRow,
        BaseReferences<_$AppDatabase, $RecurringRulesTable, RecurringRow>,
      ),
      RecurringRow,
      PrefetchHooks Function()
    >;
typedef $$ConfigItemsTableCreateCompanionBuilder =
    ConfigItemsCompanion Function({
      required String id,
      required String listKey,
      required String name,
      Value<String> description,
      Value<bool> active,
      Value<bool> isDefault,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$ConfigItemsTableUpdateCompanionBuilder =
    ConfigItemsCompanion Function({
      Value<String> id,
      Value<String> listKey,
      Value<String> name,
      Value<String> description,
      Value<bool> active,
      Value<bool> isDefault,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$ConfigItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigItemsTable> {
  $$ConfigItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listKey => $composableBuilder(
    column: $table.listKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfigItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigItemsTable> {
  $$ConfigItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listKey => $composableBuilder(
    column: $table.listKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigItemsTable> {
  $$ConfigItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get listKey =>
      $composableBuilder(column: $table.listKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ConfigItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigItemsTable,
          ConfigItemRow,
          $$ConfigItemsTableFilterComposer,
          $$ConfigItemsTableOrderingComposer,
          $$ConfigItemsTableAnnotationComposer,
          $$ConfigItemsTableCreateCompanionBuilder,
          $$ConfigItemsTableUpdateCompanionBuilder,
          (
            ConfigItemRow,
            BaseReferences<_$AppDatabase, $ConfigItemsTable, ConfigItemRow>,
          ),
          ConfigItemRow,
          PrefetchHooks Function()
        > {
  $$ConfigItemsTableTableManager(_$AppDatabase db, $ConfigItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfigItemsCompanion(
                id: id,
                listKey: listKey,
                name: name,
                description: description,
                active: active,
                isDefault: isDefault,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listKey,
                required String name,
                Value<String> description = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfigItemsCompanion.insert(
                id: id,
                listKey: listKey,
                name: name,
                description: description,
                active: active,
                isDefault: isDefault,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConfigItemsTable, ConfigItemRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConfigItemsTable,
                    ConfigItemRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfigItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigItemsTable,
      ConfigItemRow,
      $$ConfigItemsTableFilterComposer,
      $$ConfigItemsTableOrderingComposer,
      $$ConfigItemsTableAnnotationComposer,
      $$ConfigItemsTableCreateCompanionBuilder,
      $$ConfigItemsTableUpdateCompanionBuilder,
      (
        ConfigItemRow,
        BaseReferences<_$AppDatabase, $ConfigItemsTable, ConfigItemRow>,
      ),
      ConfigItemRow,
      PrefetchHooks Function()
    >;
typedef $$AuditEntriesTableCreateCompanionBuilder =
    AuditEntriesCompanion Function({
      required String id,
      required String at,
      required String actor,
      required String action,
      required String entity,
      Value<String?> entityId,
      required String summary,
      Value<String?> beforeJson,
      Value<String?> afterJson,
      Value<int> rowid,
    });
typedef $$AuditEntriesTableUpdateCompanionBuilder =
    AuditEntriesCompanion Function({
      Value<String> id,
      Value<String> at,
      Value<String> actor,
      Value<String> action,
      Value<String> entity,
      Value<String?> entityId,
      Value<String> summary,
      Value<String?> beforeJson,
      Value<String?> afterJson,
      Value<int> rowid,
    });

class $$AuditEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AuditEntriesTable> {
  $$AuditEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditEntriesTable> {
  $$AuditEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditEntriesTable> {
  $$AuditEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get afterJson =>
      $composableBuilder(column: $table.afterJson, builder: (column) => column);
}

class $$AuditEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditEntriesTable,
          AuditRow,
          $$AuditEntriesTableFilterComposer,
          $$AuditEntriesTableOrderingComposer,
          $$AuditEntriesTableAnnotationComposer,
          $$AuditEntriesTableCreateCompanionBuilder,
          $$AuditEntriesTableUpdateCompanionBuilder,
          (
            AuditRow,
            BaseReferences<_$AppDatabase, $AuditEntriesTable, AuditRow>,
          ),
          AuditRow,
          PrefetchHooks Function()
        > {
  $$AuditEntriesTableTableManager(_$AppDatabase db, $AuditEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<String> actor = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String?> beforeJson = const Value.absent(),
                Value<String?> afterJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditEntriesCompanion(
                id: id,
                at: at,
                actor: actor,
                action: action,
                entity: entity,
                entityId: entityId,
                summary: summary,
                beforeJson: beforeJson,
                afterJson: afterJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String at,
                required String actor,
                required String action,
                required String entity,
                Value<String?> entityId = const Value.absent(),
                required String summary,
                Value<String?> beforeJson = const Value.absent(),
                Value<String?> afterJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditEntriesCompanion.insert(
                id: id,
                at: at,
                actor: actor,
                action: action,
                entity: entity,
                entityId: entityId,
                summary: summary,
                beforeJson: beforeJson,
                afterJson: afterJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditEntriesTable, AuditRow>(table),
                  BaseReferences<_$AppDatabase, $AuditEntriesTable, AuditRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditEntriesTable,
      AuditRow,
      $$AuditEntriesTableFilterComposer,
      $$AuditEntriesTableOrderingComposer,
      $$AuditEntriesTableAnnotationComposer,
      $$AuditEntriesTableCreateCompanionBuilder,
      $$AuditEntriesTableUpdateCompanionBuilder,
      (AuditRow, BaseReferences<_$AppDatabase, $AuditEntriesTable, AuditRow>),
      AuditRow,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          MetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (MetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, MetaRow>),
          MetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetaTable, MetaRow>(table),
                  BaseReferences<_$AppDatabase, $AppMetaTable, MetaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      MetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (MetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, MetaRow>),
      MetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db, _db.loans);
  $$IncomeTypesTableTableManager get incomeTypes =>
      $$IncomeTypesTableTableManager(_db, _db.incomeTypes);
  $$ExpenseCategoriesTableTableManager get expenseCategories =>
      $$ExpenseCategoriesTableTableManager(_db, _db.expenseCategories);
  $$LoanTypesTableTableManager get loanTypes =>
      $$LoanTypesTableTableManager(_db, _db.loanTypes);
  $$RecurringRulesTableTableManager get recurringRules =>
      $$RecurringRulesTableTableManager(_db, _db.recurringRules);
  $$ConfigItemsTableTableManager get configItems =>
      $$ConfigItemsTableTableManager(_db, _db.configItems);
  $$AuditEntriesTableTableManager get auditEntries =>
      $$AuditEntriesTableTableManager(_db, _db.auditEntries);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
