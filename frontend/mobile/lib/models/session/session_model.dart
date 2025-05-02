import '../analysis/analysis_result.dart';

enum SessionMode {
  dating,
  interview,
  business,
  coaching,
}

enum AnalysisLevel {
  basic,
  standard,
  premium,
}

enum RecordingRetention {
  none,
  sevenDays,
  thirtyDays,
}

class SessionModel {
  final String id;
  final String? name;
  final SessionMode mode;
  final AnalysisLevel analysisLevel;
  final RecordingRetention recordingRetention;
  final DateTime createdAt;
  final DateTime? endedAt;
  final Duration duration;
  final bool isSmartWatchConnected;
  final String? recordingPath;
  final String? transcription;
  final List<SessionTag>? tags;
  final AnalysisResult? analysisResult;

  SessionModel({
    required this.id,
    this.name,
    required this.mode,
    required this.analysisLevel,
    required this.recordingRetention,
    required this.createdAt,
    this.endedAt,
    required this.duration,
    required this.isSmartWatchConnected,
    this.recordingPath,
    this.transcription,
    this.tags,
    this.analysisResult,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'],
      name: json['name'],
      mode: SessionMode.values.byName(json['mode']),
      analysisLevel: AnalysisLevel.values.byName(json['analysisLevel']),
      recordingRetention:
          RecordingRetention.values.byName(json['recordingRetention']),
      createdAt: DateTime.parse(json['createdAt']),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      duration: Duration(seconds: json['durationSeconds']),
      isSmartWatchConnected: json['isSmartWatchConnected'],
      recordingPath: json['recordingPath'],
      transcription: json['transcription'],
      tags: json['tags'] != null
          ? (json['tags'] as List)
              .map((tag) => SessionTag.fromJson(tag))
              .toList()
          : null,
      analysisResult: json['analysisResult'] != null
          ? AnalysisResult.fromJson(json['analysisResult'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mode': mode.name,
      'analysisLevel': analysisLevel.name,
      'recordingRetention': recordingRetention.name,
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'isSmartWatchConnected': isSmartWatchConnected,
      'recordingPath': recordingPath,
      'transcription': transcription,
      'tags': tags?.map((tag) => tag.toJson()).toList(),
      'analysisResult': analysisResult?.toJson(),
    };
  }

  SessionModel copyWith({
    String? id,
    String? name,
    SessionMode? mode,
    AnalysisLevel? analysisLevel,
    RecordingRetention? recordingRetention,
    DateTime? createdAt,
    DateTime? endedAt,
    Duration? duration,
    bool? isSmartWatchConnected,
    String? recordingPath,
    String? transcription,
    List<SessionTag>? tags,
    AnalysisResult? analysisResult,
  }) {
    return SessionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      analysisLevel: analysisLevel ?? this.analysisLevel,
      recordingRetention: recordingRetention ?? this.recordingRetention,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      isSmartWatchConnected:
          isSmartWatchConnected ?? this.isSmartWatchConnected,
      recordingPath: recordingPath ?? this.recordingPath,
      transcription: transcription ?? this.transcription,
      tags: tags ?? this.tags,
      analysisResult: analysisResult ?? this.analysisResult,
    );
  }
}

class SessionTag {
  final String id;
  final String name;
  final String? color;

  SessionTag({
    required this.id,
    required this.name,
    this.color,
  });

  factory SessionTag.fromJson(Map<String, dynamic> json) {
    return SessionTag(
      id: json['id'],
      name: json['name'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}
