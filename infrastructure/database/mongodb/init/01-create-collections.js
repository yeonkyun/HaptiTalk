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
          enum: ["dating", "interview", "business", "coaching"],
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

print("MongoDB collections created successfully");