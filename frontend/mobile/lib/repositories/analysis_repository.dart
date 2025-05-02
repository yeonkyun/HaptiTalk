import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../models/analysis/analysis_result.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AnalysisRepository {
  final ApiService _apiService;
  final LocalStorageService _storageService;
  final Random _random = Random();

  AnalysisRepository(this._apiService, this._storageService);

  // 분석 결과 조회
  Future<AnalysisResult> getAnalysisResult(String sessionId) async {
    try {
      // 실제 앱에서는 API를 통해 분석 결과 조회
      // 예시 구현에서는 더미 데이터 사용

      // 감정 데이터 생성
      final emotionData = EmotionData(
        emotionState: _getRandomEmotionState(),
        likability: _random.nextInt(21) + 70, // 70-90 사이 랜덤 값
        interest: _random.nextInt(21) + 70, // 70-90 사이 랜덤 값
        emotionBreakdown: {
          '긍정': 0.7,
          '중립': 0.2,
          '부정': 0.1,
        },
      );

      // 말하기 지표 생성
      final speakingMetrics = SpeakingMetrics(
        speakingSpeed: _random.nextInt(31) + 70, // 70-100 사이 랜덤 값
        confidence: _random.nextInt(31) + 65, // 65-95 사이 랜덤 값
        clarity: _random.nextInt(31) + 65, // 65-95 사이 랜덤 값
        fillerWordCount: _random.nextInt(10), // 0-9 사이 랜덤 값
        wordFrequency: {
          '여행': 4,
          '좋아해요': 2,
          '사진': 3,
          '제주도': 2,
        },
      );

      // 더미 분석 결과 생성
      final result = AnalysisResult(
        sessionId: sessionId,
        transcription:
            '저는 평소에 여행을 좋아해서 시간이 날 때마다 이곳저곳 다니는 편이에요. 사진 찍는 것도 좋아해서 여행지에서 사진을 많이 찍어요. 특히 자연 경관이 아름다운 곳이나 역사적인 장소를 방문하는 걸 좋아합니다. 최근에는 제주도에 다녀왔는데, 정말 예뻤어요. 다음에는 어디로 여행 가보셨나요?',
        emotionData: emotionData,
        speakingMetrics: speakingMetrics,
        suggestedTopics: ['여행 경험', '좋아하는 여행지', '사진 취미', '역사적 장소', '제주도 명소'],
        feedback: [
          '말하기 속도가 빨라지고 있어요. 좀 더 천천히 말해보세요.',
          '질문을 통해 대화를 이어나가는 것이 좋습니다.'
        ],
        timestamp: DateTime.now(),
      );

      // 결과 저장
      await _saveAnalysisResult(result);

      return result;
    } catch (e) {
      throw Exception('분석 결과 조회 실패: $e');
    }
  }

  // 분석 결과 기록 조회
  Future<List<AnalysisResult>> getAnalysisHistory() async {
    try {
      // 로컬 스토리지에서 분석 결과 목록 조회
      final jsonResults = await _storageService.getItem('analysis_results');

      if (jsonResults == null) {
        return [];
      }

      final resultsData = json.decode(jsonResults) as List<dynamic>;
      return resultsData
          .map((resultData) => AnalysisResult.fromJson(resultData))
          .toList();
    } catch (e) {
      throw Exception('분석 기록 조회 실패: $e');
    }
  }

  // 분석 결과 저장 (내부 메서드)
  Future<void> _saveAnalysisResult(AnalysisResult result) async {
    try {
      // 기존 분석 결과 목록 조회
      List<AnalysisResult> results = await getAnalysisHistory();

      // 기존 결과가 있으면 업데이트, 없으면 추가
      final index = results.indexWhere((r) => r.sessionId == result.sessionId);
      if (index >= 0) {
        results[index] = result;
      } else {
        results.add(result);
      }

      // 업데이트된 결과 목록 저장
      await _storageService.setItem(
        'analysis_results',
        json.encode(results.map((r) => r.toJson()).toList()),
      );
    } catch (e) {
      throw Exception('분석 결과 저장 실패: $e');
    }
  }

  // 랜덤 감정 상태 선택
  String _getRandomEmotionState() {
    final states = ['긍정적', '중립적', '열정적', '흥미로움', '활기참'];
    return states[_random.nextInt(states.length)];
  }
}
