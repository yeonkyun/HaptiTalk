// 데이터베이스 접근
var dbName = _getEnv('MONGO_INITDB_DATABASE');
db = db.getSiblingDB(dbName);

// 인증 설정
db.auth(
  _getEnv('MONGO_INITDB_ROOT_USERNAME'),
  _getEnv('MONGO_INITDB_ROOT_PASSWORD')
);

// sessionAnalytics 컬렉션 인덱스
db.sessionAnalytics.createIndex(
  { userId: 1, sessionType: 1, createdAt: -1 },
  { name: "idx_user_type_date" }
);
db.sessionAnalytics.createIndex(
  { sessionId: 1 },
  { name: "idx_session_id", unique: true }
);

// hapticFeedbacks 컬렉션 인덱스
db.hapticFeedbacks.createIndex(
  { sessionId: 1, timestamp: 1 },
  { name: "idx_session_time" }
);
db.hapticFeedbacks.createIndex(
  { userId: 1, feedbackType: 1 },
  { name: "idx_user_feedback_type" }
);

// speechFeatures 컬렉션 인덱스
db.speechFeatures.createIndex(
  { sessionId: 1, "segment.start": 1 },
  { name: "idx_session_segment" }
);
db.speechFeatures.createIndex(
  { userId: 1, timestamp: 1 },
  { name: "idx_user_timestamp" }
);

// userModels 컬렉션 인덱스
db.userModels.createIndex(
  { userId: 1 },
  { name: "idx_user_id", unique: true }
);

print("MongoDB indexes created successfully");