import 'package:hapti_talk/models/session.dart';
import 'package:hapti_talk/models/tip.dart';

// 최근 세션 목업 데이터
List<Session> mockSessions = [
  Session(
    id: '1',
    title: '팀 프로젝트 미팅',
    tag: '비즈니스',
    duration: '45:12',
    engagement: '82%',
    sentiment: '75%',
    progressPercentage: 0.7,
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Session(
    id: '2',
    title: '첫번째 소개팅',
    tag: '소개팅',
    duration: '1:32:05',
    engagement: '91%',
    sentiment: '88%',
    progressPercentage: 0.9,
    date: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Session(
    id: '3',
    title: '취업 면접 준비',
    tag: '면접',
    duration: '58:30',
    engagement: '87%',
    sentiment: '79%',
    progressPercentage: 0.8,
    date: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Session(
    id: '4',
    title: '리더십 코칭 세션',
    tag: '코칭',
    duration: '1:15:45',
    engagement: '95%',
    sentiment: '92%',
    progressPercentage: 0.95,
    date: DateTime.now().subtract(const Duration(days: 7)),
  ),
];

// 오늘의 팁 목업 데이터
List<Tip> mockTips = [
  Tip(
    id: '1',
    title: '경청 기술 향상하기',
    content:
        "상대방의 이야기에 '맞아요', '그렇군요'와 같은 짧은 반응을 추가하면 경청하고 있다는 신호를 효과적으로 전달할 수 있습니다.",
    iconName: 'lightbulb_outline',
  ),
  Tip(
    id: '2',
    title: '질문 기술 개선하기',
    content: "열린 질문(어떻게, 왜 등으로 시작하는 질문)을 사용하면 상대방이 더 풍부한 답변을 할 수 있게 됩니다.",
    iconName: 'help_outline',
  ),
  Tip(
    id: '3',
    title: '비언어적 신호 활용하기',
    content: "고개를 끄덕이거나 눈 맞춤을 유지하는 것은 상대방이 대화에 더 집중하도록 돕습니다.",
    iconName: 'visibility',
  ),
];

// 햅틱 패턴 연습 데이터
Map<String, String> mockHapticPractice = {
  'title': '햅틱 패턴 연습',
  'description': '다양한 햅틱 피드백을 연습해보세요',
};

// Premium 정보 데이터
Map<String, String> mockPremiumInfo = {
  'title': 'HaptiTalk Premium',
  'description': '더 많은 분석과 심층 인사이트를\n경험해보세요',
};
