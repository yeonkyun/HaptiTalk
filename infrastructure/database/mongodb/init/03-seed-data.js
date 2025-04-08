// 데이터베이스 접근
var dbName = _getEnv('MONGO_INITDB_DATABASE');
db = db.getSiblingDB(dbName);

// 인증 설정
db.auth(
  _getEnv('MONGO_INITDB_ROOT_USERNAME'),
  _getEnv('MONGO_INITDB_ROOT_PASSWORD')
);

// 테스트용 userModel 데이터 삽입
db.userModels.insertOne({
  userId: "11111111-1111-1111-1111-111111111111",
  created_at: new Date(),
  updated_at: new Date(),
  baselineProfile: {
    speech: {
      avg_speech_rate: 3.5,
      pitch_range: [100, 180],
      volume_range: [50, 75],
      habitual_phrases: [
        { phrase: "그러니까", frequency: 0.012 },
        { phrase: "음...", frequency: 0.008 }
      ]
    },
    interaction: {
      avg_question_frequency: 0.12,
      avg_response_time: 1.2,
      interruption_tendency: 0.03
    }
  },
  situationalProfiles: {
    dating: {
      comfortable_topics: ["여행", "취미", "음식"],
      communication_strengths: ["질문 기술", "유머"],
      communication_weaknesses: ["긴 침묵", "말 빠르기"]
    }
  }
});

print("MongoDB seed data inserted successfully");