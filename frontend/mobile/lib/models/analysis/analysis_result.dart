class AnalysisResult {
  final String sessionId;
  final String transcription;
  final EmotionData emotionData;
  final SpeakingMetrics speakingMetrics;
  final List<String> suggestedTopics;
  final List<String> feedback;
  final DateTime timestamp;

  AnalysisResult({
    required this.sessionId,
    required this.transcription,
    required this.emotionData,
    required this.speakingMetrics,
    required this.suggestedTopics,
    required this.feedback,
    required this.timestamp,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      sessionId: json['sessionId'],
      transcription: json['transcription'],
      emotionData: EmotionData.fromJson(json['emotionData']),
      speakingMetrics: SpeakingMetrics.fromJson(json['speakingMetrics']),
      suggestedTopics: List<String>.from(json['suggestedTopics']),
      feedback: List<String>.from(json['feedback']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'transcription': transcription,
      'emotionData': emotionData.toJson(),
      'speakingMetrics': speakingMetrics.toJson(),
      'suggestedTopics': suggestedTopics,
      'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class EmotionData {
  final String emotionState;
  final int likability;
  final int interest;
  final Map<String, double> emotionBreakdown;

  EmotionData({
    required this.emotionState,
    required this.likability,
    required this.interest,
    required this.emotionBreakdown,
  });

  factory EmotionData.fromJson(Map<String, dynamic> json) {
    return EmotionData(
      emotionState: json['emotionState'],
      likability: json['likability'],
      interest: json['interest'],
      emotionBreakdown: Map<String, double>.from(json['emotionBreakdown']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotionState': emotionState,
      'likability': likability,
      'interest': interest,
      'emotionBreakdown': emotionBreakdown,
    };
  }
}

class SpeakingMetrics {
  final int speakingSpeed;
  final int confidence;
  final int clarity;
  final int fillerWordCount;
  final Map<String, int> wordFrequency;

  SpeakingMetrics({
    required this.speakingSpeed,
    required this.confidence,
    required this.clarity,
    required this.fillerWordCount,
    required this.wordFrequency,
  });

  factory SpeakingMetrics.fromJson(Map<String, dynamic> json) {
    return SpeakingMetrics(
      speakingSpeed: json['speakingSpeed'],
      confidence: json['confidence'],
      clarity: json['clarity'],
      fillerWordCount: json['fillerWordCount'],
      wordFrequency: Map<String, int>.from(json['wordFrequency']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speakingSpeed': speakingSpeed,
      'confidence': confidence,
      'clarity': clarity,
      'fillerWordCount': fillerWordCount,
      'wordFrequency': wordFrequency,
    };
  }
}
