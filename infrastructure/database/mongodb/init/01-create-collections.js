// 데이터베이스 접근
var dbName = _getEnv('MONGO_INITDB_DATABASE');
db = db.getSiblingDB(dbName);

// 인증 설정
db.auth(
  _getEnv('MONGO_INITDB_ROOT_USERNAME'),
  _getEnv('MONGO_INITDB_ROOT_PASSWORD')
);

// 컬렉션 생성
db.createCollection("sessionAnalytics");
db.createCollection("hapticFeedbacks");
db.createCollection("speechFeatures");
db.createCollection("userModels");
db.createCollection("sessionSegments");

// 컬렉션 설명 추가
db.sessionAnalytics.stats();
db.sessionAnalytics.drop();
db.createCollection("sessionAnalytics", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["sessionId", "userId", "sessionType", "createdAt"],
      properties: {
        sessionId: {
          bsonType: "string",
          description: "PostgreSQL의 users.sessions.id 참조"
        },
        userId: {
          bsonType: "string",
          description: "사용자 ID (PostgreSQL auth.users.id 참조)"
        },
        sessionType: {
          bsonType: "string",
          enum: ["dating", "interview", "business", "coaching", "presentation"],
          description: "세션 유형"
        },
        createdAt: {
          bsonType: "date",
          description: "레코드 생성 시간"
        }
      }
    }
  }
});

db.hapticFeedbacks.stats();
db.hapticFeedbacks.drop();
db.createCollection("hapticFeedbacks", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["sessionId", "userId", "timestamp", "feedbackType"],
      properties: {
        sessionId: {
          bsonType: "string",
          description: "세션 ID"
        },
        userId: {
          bsonType: "string",
          description: "사용자 ID"
        },
        timestamp: {
          bsonType: "date",
          description: "피드백 발생 시간"
        },
        feedbackType: {
          bsonType: "string",
          description: "피드백 유형"
        }
      }
    }
  }
});

db.speechFeatures.stats();
db.speechFeatures.drop();
db.createCollection("speechFeatures", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["sessionId", "userId", "segment", "timestamp"],
      properties: {
        sessionId: {
          bsonType: "string",
          description: "세션 ID"
        },
        userId: {
          bsonType: "string",
          description: "사용자 ID"
        },
        segment: {
          bsonType: "object",
          description: "오디오 세그먼트 정보"
        },
        timestamp: {
          bsonType: "date",
          description: "데이터 생성 시간"
        }
      }
    }
  }
});

db.userModels.stats();
db.userModels.drop();
db.createCollection("userModels", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "created_at", "updated_at"],
      properties: {
        userId: {
          bsonType: "string",
          description: "사용자 ID"
        },
        created_at: {
          bsonType: "date",
          description: "생성 시간"
        },
        updated_at: {
          bsonType: "date",
          description: "수정 시간"
        }
      }
    }
  }
});

db.sessionSegments.stats();
db.sessionSegments.drop();
db.createCollection("sessionSegments", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["sessionId", "userId", "segmentIndex", "timestamp"],
      properties: {
        sessionId: {
          bsonType: "string",
          description: "세션 ID (PostgreSQL sessions.id 참조)"
        },
        userId: {
          bsonType: "string",
          description: "사용자 ID (PostgreSQL auth.users.id 참조)"
        },
        segmentIndex: {
          bsonType: "int",
          description: "세그먼트 순서 (0, 1, 2, ... 30초 단위)"
        },
        timestamp: {
          bsonType: "date",
          description: "세그먼트 생성 시간"
        },
        transcription: {
          bsonType: "string",
          description: "해당 세그먼트의 음성 인식 텍스트"
        },
        analysis: {
          bsonType: "object",
          description: "실시간 분석 결과",
          properties: {
            emotionState: {
              bsonType: "string",
              description: "감정 상태"
            },
            speakingSpeed: {
              bsonType: "int",
              description: "말하기 속도"
            },
            likability: {
              bsonType: "int",
              description: "호감도 점수"
            },
            interest: {
              bsonType: "int",
              description: "관심도 점수"
            },
            confidence: {
              bsonType: "double",
              description: "분석 신뢰도"
            },
            volume: {
              bsonType: "double",
              description: "음성 볼륨"
            },
            pitch: {
              bsonType: "double",
              description: "음성 피치"
            }
          }
        },
        hapticFeedbacks: {
          bsonType: "array",
          description: "해당 세그먼트에서 발생한 햅틱 피드백들",
          items: {
            bsonType: "object",
            properties: {
              type: { bsonType: "string" },
              pattern: { bsonType: "string" },
              timestamp: { bsonType: "date" },
              message: { bsonType: "string" }
            }
          }
        },
        suggestedTopics: {
          bsonType: "array",
          description: "추천 대화 주제",
          items: { bsonType: "string" }
        }
      }
    }
  }
});

print("MongoDB collections created successfully");