import '../../finance/money.dart';
import 'client.dart';

// Response schemas sent to Gemini (structured output) and the strict Dart
// parsers that check every answer before the UI shows it (spec §9.3: a
// malformed answer is an error, never half-shown).

typedef JsonMap = Map<String, Object?>;

T _req<T>(JsonMap j, String k) {
  final v = j[k];
  if (v is T) return v;
  throw AiError(AiErrorCode.badResponse);
}

List<JsonMap> _list(JsonMap j, String k, {bool optional = false}) {
  final v = j[k];
  if (v == null && optional) return const [];
  if (v is! List) throw AiError(AiErrorCode.badResponse);
  return [for (final e in v) if (e is Map) e.cast<String, Object?>() else throw AiError(AiErrorCode.badResponse)];
}

const _deepLinks = ['planner', 'budgets', 'goals', 'inbox', 'salary', 'none'];
const _severities = ['good', 'info', 'warning', 'critical'];

/// Spec §9.4 analysis schema.
const Map<String, Object?> analysisSchema = {
  'type': 'OBJECT',
  'properties': {
    'healthScore': {'type': 'INTEGER', 'minimum': 0, 'maximum': 100},
    'headline': {'type': 'STRING'},
    'findings': {
      'type': 'ARRAY',
      'maxItems': 5,
      'items': {
        'type': 'OBJECT',
        'properties': {
          'title': {'type': 'STRING'},
          'detail': {'type': 'STRING'},
          'severity': {'type': 'STRING', 'enum': _severities},
        },
        'required': ['title', 'detail', 'severity'],
      },
    },
    'actions': {
      'type': 'ARRAY',
      'maxItems': 3,
      'items': {
        'type': 'OBJECT',
        'properties': {
          'title': {'type': 'STRING'},
          'why': {'type': 'STRING'},
          'estimatedMonthlyImpactNpr': {'type': 'NUMBER'},
          'deepLink': {'type': 'STRING', 'enum': _deepLinks},
        },
        'required': ['title', 'why', 'deepLink'],
      },
    },
    'risks': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
  },
  'required': ['healthScore', 'headline', 'findings', 'actions'],
};

class AiFinding {
  const AiFinding(this.title, this.detail, this.severity);
  final String title;
  final String detail;

  /// good | info | warning | critical
  final String severity;
}

class AiAction {
  const AiAction(this.title, this.why, this.deepLink, this.monthlyImpact);
  final String title;
  final String why;

  /// planner | budgets | goals | inbox | salary | none
  final String deepLink;
  final num? monthlyImpact;
}

class AiAnalysis {
  const AiAnalysis({
    required this.healthScore,
    required this.headline,
    required this.findings,
    required this.actions,
    required this.risks,
    this.generatedAt,
  });

  final int healthScore;
  final String headline;
  final List<AiFinding> findings;
  final List<AiAction> actions;
  final List<String> risks;

  /// 'YYYY-MM-DDTHH:mm:ss' when the analysis was made (cache).
  final String? generatedAt;

  static AiAnalysis fromJson(JsonMap j) {
    final score = _req<num>(j, 'healthScore');
    if (score < 0 || score > 100) throw AiError(AiErrorCode.badResponse);
    return AiAnalysis(
      healthScore: score.round(),
      headline: _req<String>(j, 'headline'),
      findings: [
        for (final f in _list(j, 'findings').take(5))
          AiFinding(
            _req<String>(f, 'title'),
            _req<String>(f, 'detail'),
            _severities.contains(f['severity']) ? f['severity']! as String : 'info',
          ),
      ],
      actions: [
        for (final a in _list(j, 'actions').take(3))
          AiAction(
            _req<String>(a, 'title'),
            _req<String>(a, 'why'),
            _deepLinks.contains(a['deepLink']) ? a['deepLink']! as String : 'none',
            a['estimatedMonthlyImpactNpr'] is num ? a['estimatedMonthlyImpactNpr']! as num : null,
          ),
      ],
      risks: [for (final r in (j['risks'] as List? ?? const [])) if (r is String) r],
      generatedAt: j['generatedAt'] as String?,
    );
  }

  JsonMap toJson() => {
        'healthScore': healthScore,
        'headline': headline,
        'findings': [for (final f in findings) {'title': f.title, 'detail': f.detail, 'severity': f.severity}],
        'actions': [
          for (final a in actions)
            {'title': a.title, 'why': a.why, 'deepLink': a.deepLink, 'estimatedMonthlyImpactNpr': a.monthlyImpact},
        ],
        'risks': risks,
        'generatedAt': generatedAt,
      };
}

const Map<String, Object?> chatSchema = {
  'type': 'OBJECT',
  'properties': {
    'answer': {'type': 'STRING'},
    'usedData': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
    'deepLink': {'type': 'STRING', 'enum': _deepLinks},
  },
  'required': ['answer', 'usedData'],
};

class ChatAnswer {
  const ChatAnswer(this.answer, this.usedData, this.deepLink);
  final String answer;

  /// Which parts of the summary the answer used, e.g. ['loans', 'budgets'].
  final List<String> usedData;
  final String deepLink;

  static ChatAnswer fromJson(JsonMap j) => ChatAnswer(
        _req<String>(j, 'answer'),
        [for (final u in (j['usedData'] as List? ?? const [])) if (u is String) u],
        _deepLinks.contains(j['deepLink']) ? j['deepLink']! as String : 'none',
      );
}

const Map<String, Object?> explainSchema = {
  'type': 'OBJECT',
  'properties': {
    'explanation': {'type': 'STRING'},
    'tradeoffs': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
    'sustainableExtraNpr': {'type': 'NUMBER'},
  },
  'required': ['explanation', 'tradeoffs'],
};

class PlanExplanation {
  const PlanExplanation(this.explanation, this.tradeoffs, this.sustainableExtra);
  final String explanation;
  final List<String> tradeoffs;
  final Paisa? sustainableExtra;

  static PlanExplanation fromJson(JsonMap j) => PlanExplanation(
        _req<String>(j, 'explanation'),
        [for (final t in (j['tradeoffs'] as List? ?? const [])) if (t is String) t],
        j['sustainableExtraNpr'] is num ? fromRupees(j['sustainableExtraNpr']! as num) : null,
      );
}

const Map<String, Object?> budgetSchema = {
  'type': 'OBJECT',
  'properties': {
    'suggestions': {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'categoryId': {'type': 'STRING'},
          'limitNpr': {'type': 'NUMBER'},
          'reason': {'type': 'STRING'},
        },
        'required': ['categoryId', 'limitNpr', 'reason'],
      },
    },
  },
  'required': ['suggestions'],
};

class BudgetSuggestion {
  const BudgetSuggestion(this.categoryId, this.limit, this.reason);
  final String categoryId;
  final Paisa limit;
  final String reason;
}

class BudgetSuggestions {
  const BudgetSuggestions(this.items);
  final List<BudgetSuggestion> items;

  static BudgetSuggestions fromJson(JsonMap j) => BudgetSuggestions([
        for (final s in _list(j, 'suggestions'))
          if (_req<num>(s, 'limitNpr') > 0)
            BudgetSuggestion(_req<String>(s, 'categoryId'), fromRupees(_req<num>(s, 'limitNpr')), _req<String>(s, 'reason')),
      ]);
}

const Map<String, Object?> salaryCheckSchema = {
  'type': 'OBJECT',
  'properties': {
    'summary': {'type': 'STRING'},
    'flags': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
  },
  'required': ['summary', 'flags'],
};

class SalaryCheck {
  const SalaryCheck(this.summary, this.flags);
  final String summary;
  final List<String> flags;

  static SalaryCheck fromJson(JsonMap j) => SalaryCheck(
        _req<String>(j, 'summary'),
        [for (final f in (j['flags'] as List? ?? const [])) if (f is String) f],
      );
}

const _smsTypes = [
  'expense', 'income', 'transfer', 'loan_repayment', 'cc_payment', 'cash_withdrawal', 'refund', 'reversal', 'loan_disbursement',
];

/// Spec §9.4 low-confidence SMS help.
const Map<String, Object?> smsHelpSchema = {
  'type': 'OBJECT',
  'properties': {
    'type': {'type': 'STRING', 'enum': _smsTypes},
    'categoryId': {'type': 'STRING'},
    'incomeTypeId': {'type': 'STRING'},
    'counterAccountId': {'type': 'STRING'},
    'confidence': {'type': 'STRING', 'enum': ['high', 'medium', 'low']},
    'reason': {'type': 'STRING'},
  },
  'required': ['type', 'confidence', 'reason'],
};

class SmsAiSuggestion {
  const SmsAiSuggestion({required this.type, this.categoryId, this.incomeTypeId, this.counterAccountId, required this.confidence, required this.reason});

  /// A wire type, e.g. 'expense'.
  final String type;
  final String? categoryId;
  final String? incomeTypeId;
  final String? counterAccountId;
  final String confidence;
  final String reason;

  static SmsAiSuggestion fromJson(JsonMap j) {
    final type = _req<String>(j, 'type');
    if (!_smsTypes.contains(type)) throw AiError(AiErrorCode.badResponse);
    String? opt(String k) => j[k] is String && (j[k]! as String).isNotEmpty ? j[k]! as String : null;
    return SmsAiSuggestion(
      type: type,
      categoryId: opt('categoryId'),
      incomeTypeId: opt('incomeTypeId'),
      counterAccountId: opt('counterAccountId'),
      confidence: ['high', 'medium', 'low'].contains(j['confidence']) ? j['confidence']! as String : 'low',
      reason: _req<String>(j, 'reason'),
    );
  }
}

const Map<String, Object?> lessonSchema = {
  'type': 'OBJECT',
  'properties': {
    'title': {'type': 'STRING'},
    'body': {'type': 'STRING'},
    'takeaway': {'type': 'STRING'},
  },
  'required': ['title', 'body', 'takeaway'],
};

/// Today's lesson, written by the AI from the user's own numbers.
class AiLesson {
  const AiLesson({required this.title, required this.body, required this.takeaway, this.date});
  final String title;
  final String body;
  final String takeaway;

  /// The day it was written (cached per day).
  final String? date;

  static AiLesson fromJson(JsonMap j) => AiLesson(
        title: _req<String>(j, 'title'),
        body: _req<String>(j, 'body'),
        takeaway: _req<String>(j, 'takeaway'),
        date: j['date'] as String?,
      );

  JsonMap toJson() => {'title': title, 'body': body, 'takeaway': takeaway, 'date': date};
}

/// What a reality check is about.
enum RealityTopic {
  afford('afford'),
  habits('habits'),
  goals('goals'),
  review('review'),
  budget('budget');

  const RealityTopic(this.wire);
  final String wire;
}

const _verdicts = ['yes', 'wait', 'no', 'good', 'watch', 'bad'];

const Map<String, Object?> realitySchema = {
  'type': 'OBJECT',
  'properties': {
    'verdict': {'type': 'STRING', 'enum': _verdicts},
    'headline': {'type': 'STRING'},
    'points': {'type': 'ARRAY', 'maxItems': 5, 'items': {'type': 'STRING'}},
    'actions': {'type': 'ARRAY', 'maxItems': 3, 'items': {'type': 'STRING'}},
  },
  'required': ['verdict', 'headline', 'points', 'actions'],
};

/// An honest answer from the AI, built on facts Paisa computed.
class RealityAnswer {
  const RealityAnswer({required this.verdict, required this.headline, required this.points, required this.actions, this.at});

  /// yes | wait | no (purchases) or good | watch | bad (everything else).
  final String verdict;
  final String headline;
  final List<String> points;
  final List<String> actions;

  /// When it was written (cached answers).
  final String? at;

  static RealityAnswer fromJson(JsonMap j) {
    final verdict = _req<String>(j, 'verdict');
    if (!_verdicts.contains(verdict)) throw AiError(AiErrorCode.badResponse);
    List<String> strings(String k) {
      final v = j[k];
      if (v is! List) throw AiError(AiErrorCode.badResponse);
      return [for (final e in v) if (e is String && e.trim().isNotEmpty) e];
    }

    return RealityAnswer(verdict: verdict, headline: _req<String>(j, 'headline'), points: strings('points'), actions: strings('actions'), at: j['at'] as String?);
  }

  JsonMap toJson() => {'verdict': verdict, 'headline': headline, 'points': points, 'actions': actions, 'at': at};
}
