/**
 * HaptiTalk 공통 분석 로직
 * 실시간 분석과 최종 분석에서 동일한 계산 로직 사용
 */

class AnalyticsCore {
  /**
   * 시나리오별 실시간 지표 계산
   */
  static calculateRealtimeMetrics(speechData, scenario) {
    switch (scenario?.toLowerCase()) {
      case 'presentation':
        return this.calculatePresentationMetrics(speechData);
      case 'interview':
        return this.calculateInterviewMetrics(speechData);
      case 'dating':
      default:
        return this.calculateDatingMetrics(speechData);
    }
  }

  /**
   * 발표 시나리오 지표 계산
   */
  static calculatePresentationMetrics(speechData) {
    const confidence = this.calculateSpeakingConfidence(speechData);
    const persuasion = this.calculatePersuasion(speechData);
    const clarity = this.calculateClarity(speechData);
    
    return {
      confidence: Math.round(confidence),
      persuasion: Math.round(persuasion),
      clarity: Math.round(clarity),
      speakingSpeed: speechData.evaluation_wpm || 0
    };
  }

  /**
   * 면접 시나리오 지표 계산
   */
  static calculateInterviewMetrics(speechData) {
    const confidence = this.calculateSpeakingConfidence(speechData);
    const stability = this.calculateStability(speechData);
    const clarity = this.calculateClarity(speechData);
    
    return {
      confidence: Math.round(confidence),
      stability: Math.round(stability),
      clarity: Math.round(clarity),
      speakingSpeed: speechData.evaluation_wpm || 0
    };
  }

  /**
   * 소개팅 시나리오 지표 계산
   */
  static calculateDatingMetrics(speechData) {
    const likeability = this.calculateLikeability(speechData);
    const interest = this.calculateInterest(speechData);
    const emotion = this.calculateEmotion(speechData);
    
    return {
      likeability: Math.round(likeability),
      interest: Math.round(interest),
      emotion: emotion,
      speakingSpeed: speechData.evaluation_wpm || 0
    };
  }

  /**
   * 말하기 자신감 계산 (발표/면접용)
   */
  static calculateSpeakingConfidence(speechData) {
    // 발화 밀도와 말하기 속도를 기반으로 자신감 계산
    const speechDensity = speechData.speech_density || 0.5;
    const speechRate = speechData.evaluation_wpm || 120;
    const tonality = speechData.tonality || 0.7;
    
    // 기본 자신감 계산 (발화 밀도 기반)
    let baseConfidence;
    if (speechDensity <= 0.0) {
      baseConfidence = 10.0;
    } else if (speechDensity <= 0.3) {
      baseConfidence = 10.0 + (speechDensity / 0.3) * 30.0; // 10-40
    } else if (speechDensity <= 0.5) {
      baseConfidence = 40.0 + ((speechDensity - 0.3) / 0.2) * 20.0; // 40-60
    } else if (speechDensity <= 0.7) {
      baseConfidence = 60.0 + ((speechDensity - 0.5) / 0.2) * 15.0; // 60-75
    } else if (speechDensity <= 0.9) {
      baseConfidence = 75.0 + ((speechDensity - 0.7) / 0.2) * 10.0; // 75-85
    } else {
      baseConfidence = 85.0 + ((speechDensity - 0.9) / 0.1) * 10.0; // 85-95
    }
    
    // 말하기 속도 보정 (적절한 속도일 때 자신감 상승)
    if (speechRate >= 120 && speechRate <= 160) {
      baseConfidence *= 1.1; // 적절한 속도일 때 10% 보너스
    } else if (speechRate > 180) {
      baseConfidence *= 0.9; // 너무 빠르면 10% 감소
    } else if (speechRate < 100) {
      baseConfidence *= 0.95; // 너무 느리면 5% 감소
    }
    
    // 톤 품질 보정
    baseConfidence *= (0.7 + tonality * 0.3);
    
    return Math.max(15, Math.min(95, baseConfidence));
  }

  /**
   * 설득력 계산 (발표용)
   */
  static calculatePersuasion(speechData) {
    const tonality = speechData.tonality || 0.7;
    const clarity = speechData.clarity || 0.7;
    const speechPattern = speechData.speech_pattern || 'normal';
    
    // 기본 설득력 (톤 + 명확성)
    let basePersuasion = (tonality * 50 + clarity * 50);
    
    // 말하기 패턴에 따른 조정
    const patternBonus = {
      'continuous': 10,
      'steady': 8,
      'normal': 0,
      'variable': -3,
      'staccato': -5,
      'sparse': -8
    };
    
    basePersuasion += (patternBonus[speechPattern] || 0);
    
    return Math.max(20, Math.min(90, basePersuasion));
  }

  /**
   * 명확성 계산
   */
  static calculateClarity(speechData) {
    const clarity = speechData.clarity || 0.7;
    const speechRate = speechData.evaluation_wpm || 120;
    
    let clarityScore = clarity * 100;
    
    // 말하기 속도에 따른 명확성 조정
    if (speechRate > 160) {
      clarityScore *= 0.9; // 빠르면 명확성 감소
    } else if (speechRate < 100) {
      clarityScore *= 0.95; // 너무 느려도 약간 감소
    }
    
    return Math.max(20, Math.min(95, clarityScore));
  }

  /**
   * 안정감 계산 (면접용)
   */
  static calculateStability(speechData) {
    const tonality = speechData.tonality || 0.7;
    const speechPattern = speechData.speech_pattern || 'normal';
    const speechRate = speechData.evaluation_wpm || 120;
    
    let stabilityScore = tonality * 100;
    
    // 말하기 패턴에 따른 안정감 조정
    const patternStability = {
      'steady': 15,
      'normal': 5,
      'continuous': 0,
      'variable': -10,
      'staccato': -15,
      'sparse': -20
    };
    
    stabilityScore += (patternStability[speechPattern] || 0);
    
    // 적절한 속도일 때 안정감 증가
    if (speechRate >= 110 && speechRate <= 150) {
      stabilityScore += 5;
    }
    
    return Math.max(25, Math.min(90, stabilityScore));
  }

  /**
   * 호감도 계산 (소개팅용)
   */
  static calculateLikeability(speechData) {
    const speechDensity = speechData.speech_density || 0.5;
    const emotionScore = speechData.emotion_score || 0.6;
    
    // 발화 밀도 기반 호감도
    let baseLikeability;
    if (speechDensity <= 0.0) {
      baseLikeability = 10.0;
    } else if (speechDensity <= 0.3) {
      baseLikeability = 10.0 + (speechDensity / 0.3) * 30.0;
    } else if (speechDensity <= 0.5) {
      baseLikeability = 40.0 + ((speechDensity - 0.3) / 0.2) * 20.0;
    } else if (speechDensity <= 0.7) {
      baseLikeability = 60.0 + ((speechDensity - 0.5) / 0.2) * 15.0;
    } else {
      baseLikeability = 75.0 + ((speechDensity - 0.7) / 0.3) * 15.0;
    }
    
    // 감정 점수 반영
    baseLikeability *= (0.6 + emotionScore * 0.4);
    
    return Math.max(15, Math.min(95, baseLikeability));
  }

  /**
   * 관심도 계산 (소개팅용)
   */
  static calculateInterest(speechData) {
    const speechPattern = speechData.speech_pattern || 'normal';
    const tonality = speechData.tonality || 0.7;
    
    // 말하기 패턴 기반 관심도
    const patternInterest = {
      'continuous': 85,
      'steady': 80,
      'variable': 75,
      'normal': 70,
      'staccato': 55,
      'sparse': 40,
      'very_sparse': 25
    };
    
    let baseInterest = patternInterest[speechPattern] || 50;
    
    // 톤 품질 반영
    baseInterest *= (0.7 + tonality * 0.3);
    
    return Math.max(20, Math.min(90, baseInterest));
  }

  /**
   * 감정 상태 계산
   */
  static calculateEmotion(speechData) {
    const speedCategory = speechData.speed_category || 'normal';
    
    const emotionMap = {
      'very_slow': '침착함',
      'slow': '안정적',
      'normal': '자연스러움',
      'fast': '활발함',
      'very_fast': '흥미로움'
    };
    
    return emotionMap[speedCategory] || '대기 중';
  }

  /**
   * 햅틱 피드백 조건 체크
   */
  static shouldSendHapticFeedback(currentMetrics, previousMetrics, scenario) {
    if (!previousMetrics) return false;
    
    switch (scenario?.toLowerCase()) {
      case 'presentation':
        return this.checkPresentationHapticConditions(currentMetrics, previousMetrics);
      case 'interview':
        return this.checkInterviewHapticConditions(currentMetrics, previousMetrics);
      case 'dating':
      default:
        return this.checkDatingHapticConditions(currentMetrics, previousMetrics);
    }
  }

  /**
   * 발표 시나리오 햅틱 조건 체크
   */
  static checkPresentationHapticConditions(current, previous) {
    const conditions = [];
    
    // 자신감 급상승
    if (current.confidence - previous.confidence >= 15) {
      conditions.push({
        type: 'confidence_up',
        priority: 'high',
        message: '💪 발표 자신감이 상승했어요!',
        pattern: 'confidence_boost'
      });
    }
    
    // 자신감 급하락
    if (previous.confidence - current.confidence >= 20) {
      conditions.push({
        type: 'confidence_down',
        priority: 'high',
        message: '😮‍💨 심호흡하고 천천히 말해보세요',
        pattern: 'confidence_down'
      });
    }
    
    // 설득력 저조
    if (current.persuasion < 40) {
      conditions.push({
        type: 'persuasion_low',
        priority: 'medium',
        message: '🎯 핵심 포인트를 강조해보세요',
        pattern: 'persuasion_guide'
      });
    }
    
    // 말하기 속도 과속
    if (current.speakingSpeed > 180) {
      conditions.push({
        type: 'speed_fast',
        priority: 'high',
        message: '🚀 조금 천천히 말해보세요',
        pattern: 'speed_control'
      });
    }
    
    return conditions;
  }

  /**
   * 면접 시나리오 햅틱 조건 체크
   */
  static checkInterviewHapticConditions(current, previous) {
    const conditions = [];
    
    // 자신감 상승
    if (current.confidence - previous.confidence >= 15) {
      conditions.push({
        type: 'confidence_up',
        priority: 'high',
        message: '👔 면접 자신감이 좋아요!',
        pattern: 'confidence_boost'
      });
    }
    
    // 안정감 부족
    if (current.stability < 45) {
      conditions.push({
        type: 'stability_low',
        priority: 'medium',
        message: '🧘‍♂️ 더 차분하게 답변해보세요',
        pattern: 'stability_guide'
      });
    }
    
    return conditions;
  }

  /**
   * 소개팅 시나리오 햅틱 조건 체크
   */
  static checkDatingHapticConditions(current, previous) {
    const conditions = [];
    
    // 호감도 상승
    if (current.likeability - previous.likeability >= 15) {
      conditions.push({
        type: 'likeability_up',
        priority: 'high',
        message: '💕 호감도가 상승했어요!',
        pattern: 'likeability_boost'
      });
    }
    
    // 관심도 하락
    if (previous.interest - current.interest >= 20) {
      conditions.push({
        type: 'interest_down',
        priority: 'high',
        message: '⚠️ 주제를 바꿔보세요',
        pattern: 'topic_change'
      });
    }
    
    return conditions;
  }
}

module.exports = AnalyticsCore; 