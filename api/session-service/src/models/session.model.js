const {DataTypes} = require('sequelize');
const {sequelize} = require('../config/database');
const {v4: uuidv4} = require('uuid');

// 세션 타입 정의
const SESSION_TYPES = {
    DATING: 'dating',
    INTERVIEW: 'interview',
    BUSINESS: 'business',
    PRESENTATION: 'presentation',
};

// 세션 상태 정의
const SESSION_STATUS = {
    CREATED: 'created',
    ACTIVE: 'active',
    PAUSED: 'paused',
    ENDED: 'ended',
};

// 세션 모델 정의
const Session = sequelize.define('session', {
    id: {
        type: DataTypes.UUID,
        primaryKey: true,
        defaultValue: () => uuidv4(),
        allowNull: false,
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
        comment: '세션을 생성한 사용자 ID',
    },
    title: {
        type: DataTypes.STRING(100),
        allowNull: false,
        comment: '세션 제목',
    },
    type: {
        type: DataTypes.ENUM(Object.values(SESSION_TYPES)),
        allowNull: false,
        comment: '세션 유형 (dating, interview, business, presentation)',
    },
    status: {
        type: DataTypes.ENUM(Object.values(SESSION_STATUS)),
        allowNull: false,
        defaultValue: SESSION_STATUS.CREATED,
        comment: '세션 상태 (created, active, paused, ended)',
    },
    start_time: {
        type: DataTypes.DATE,
        allowNull: true,
        comment: '세션 시작 시간',
    },
    end_time: {
        type: DataTypes.DATE,
        allowNull: true,
        comment: '세션 종료 시간',
    },
    duration: {
        type: DataTypes.INTEGER,
        allowNull: true,
        comment: '세션 지속 시간 (초)',
    },
    settings: {
        type: DataTypes.JSONB,
        allowNull: false,
        defaultValue: {},
        comment: '세션 설정 (JSON)',
    },
    metadata: {
        type: DataTypes.JSONB,
        allowNull: false,
        defaultValue: {},
        comment: '세션 메타데이터 (JSON)',
    },
    summary: {
        type: DataTypes.JSONB,
        allowNull: true,
        comment: '세션 요약 데이터 (JSON)',
    }
}, {
    schema: 'session',
    tableName: 'sessions',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            name: 'sessions_user_id_idx',
            fields: ['user_id']
        },
        {
            name: 'sessions_type_idx',
            fields: ['type']
        },
        {
            name: 'sessions_status_idx',
            fields: ['status']
        }
    ]
});

// 세션 타입별 기본 설정 정의
const getDefaultSettings = (type) => {
    const baseSettings = {
        feedback: {
            enabled: true,
            haptic: true,
            visual: true,
            audio: false,
        },
        analysis: {
            enabled: true,
            sentiment: true,
            keywords: true,
            speaking_rate: true,
        },
        privacy: {
            store_audio: false,
            store_text: true,
            data_retention_days: 30,
        }
    };

    switch (type) {
        case SESSION_TYPES.DATING:
            return {
                ...baseSettings,
                dating_specific: {
                    interest_tracking: true,
                    topic_suggestions: true,
                    silence_alerts: true,
                }
            };

        case SESSION_TYPES.INTERVIEW:
            return {
                ...baseSettings,
                interview_specific: {
                    confidence_tracking: true,
                    question_detection: true,
                    answer_quality: true,
                }
            };

        case SESSION_TYPES.BUSINESS:
            return {
                ...baseSettings,
                business_specific: {
                    meeting_contribution: true,
                    key_points_tracking: true,
                    agreement_detection: true,
                }
            };

        case SESSION_TYPES.PRESENTATION:
            return {
                ...baseSettings,
                presentation_specific: {
                    timer: {
                        enabled: true,
                        duration_minutes: 10,
                        alerts: {
                            halfway: true,
                            five_minutes: true,
                            two_minutes: true,
                            thirty_seconds: true,
                        }
                    },
                    speaking_rate: {
                        enabled: true,
                        target_min_wpm: 120,
                        target_max_wpm: 160,
                        alert_threshold: 20, // 목표 속도에서 벗어난 정도 (%)
                    },
                    filler_words: {
                        enabled: true,
                        words: ['음', '그', '어', '저', '뭐', '아', '그니까', '그러니까'],
                        alert_frequency: 3, // 특정 횟수 이상 반복 시 알림
                    }
                }
            };

        default:
            return baseSettings;
    }
};

module.exports = {
    Session,
    SESSION_TYPES,
    SESSION_STATUS,
    getDefaultSettings
};