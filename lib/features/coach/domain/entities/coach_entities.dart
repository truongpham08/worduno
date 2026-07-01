import 'dart:convert';

import '../../../../shared/vocabulary/domain/entities/term.dart';
import 'coach_star_filter.dart';

class CoachSessionConfig {
  const CoachSessionConfig({
    required this.levelCodes,
    required this.unitKeys,
    required this.starFilter,
    required this.wordCount,
    this.fixedLevelCode,
    this.fixedUnitName,
    this.fixedUnitId,
  });

  final List<String> levelCodes;
  final List<String> unitKeys;
  final CoachStarFilter starFilter;
  final int wordCount;
  final String? fixedLevelCode;
  final String? fixedUnitName;
  final String? fixedUnitId;

  bool get isUnitScoped =>
      fixedLevelCode != null && fixedUnitName != null;
}

class CoachWord {
  const CoachWord({
    required this.levelCode,
    required this.unitName,
    required this.unitId,
    required this.term,
  });

  final String levelCode;
  final String unitName;
  final String unitId;
  final Term term;
}

class CoachExplainExample {
  const CoachExplainExample({
    required this.sentence,
    required this.note,
  });

  factory CoachExplainExample.fromJson(Map<String, dynamic> json) {
    return CoachExplainExample(
      sentence: json['sentence'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }

  final String sentence;
  final String note;
}

class CoachExplainResult {
  const CoachExplainResult({
    required this.usage,
    required this.contexts,
    required this.examples,
  });

  factory CoachExplainResult.fromJson(Map<String, dynamic> json) {
    return CoachExplainResult(
      usage: json['usage'] as String? ?? '',
      contexts: (json['contexts'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      examples: (json['examples'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CoachExplainExample.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'usage': usage,
        'contexts': contexts,
        'examples': examples
            .map((e) => {'sentence': e.sentence, 'note': e.note})
            .toList(),
      };

  final String usage;
  final List<String> contexts;
  final List<CoachExplainExample> examples;
}

class CoachEvaluateResult {
  const CoachEvaluateResult({
    required this.grammar,
    required this.vocabulary,
    required this.naturalness,
    required this.suggestions,
    required this.rawJson,
  });

  factory CoachEvaluateResult.fromJson(Map<String, dynamic> json) {
    final suggestions = (json['suggestion'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);

    return CoachEvaluateResult(
      grammar: json['grammar'] as String? ?? '',
      vocabulary: json['vocabulary'] as String? ?? '',
      naturalness: json['naturalness'] as String? ?? '',
      suggestions: suggestions,
      rawJson: json,
    );
  }

  final String grammar;
  final String vocabulary;
  final String naturalness;
  final List<String> suggestions;
  final Map<String, dynamic> rawJson;
}

/// In-memory coach run only — not persisted.
class CoachSession {
  const CoachSession({
    required this.words,
    required this.config,
  });

  final List<CoachWord> words;
  final CoachSessionConfig config;
}

/// One coached term identity: unique by (unit_id, term_id).
class CoachHistoryTerm {
  const CoachHistoryTerm({
    required this.unitId,
    required this.termId,
    required this.levelCode,
    required this.unitName,
    required this.definition,
    required this.lastCoachedAt,
    required this.feedbackCount,
  });

  final String unitId;
  final String termId;
  final String levelCode;
  final String unitName;
  final String definition;
  final DateTime lastCoachedAt;
  final int feedbackCount;

  String get word => termId;
}

class CoachHistoryTermDetail {
  const CoachHistoryTermDetail({
    required this.unitId,
    required this.termId,
    required this.levelCode,
    required this.unitName,
    required this.definition,
    this.explanation,
  });

  final String unitId;
  final String termId;
  final String levelCode;
  final String unitName;
  final String definition;
  final CoachExplainResult? explanation;

  String get word => termId;
}

class CoachFeedbackEntry {
  const CoachFeedbackEntry({
    required this.id,
    required this.date,
    required this.unitId,
    required this.termId,
    required this.levelCode,
    required this.unitName,
    required this.definition,
    required this.userSentence,
    required this.responseJson,
  });

  final String id;
  final DateTime date;
  final String unitId;
  final String termId;
  final String levelCode;
  final String unitName;
  final String definition;
  final String userSentence;
  final String responseJson;

  String get word => termId;

  CoachEvaluateResult? get evaluateResult {
    try {
      final decoded = jsonDecode(responseJson) as Map<String, dynamic>;
      return CoachEvaluateResult.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
