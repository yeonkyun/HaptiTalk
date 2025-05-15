import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/session/session_model.dart';
import '../../models/analysis/analysis_result.dart';
import '../../providers/session_provider.dart';
import '../../providers/analysis_provider.dart';
import '../../constants/colors.dart';
import '../../widgets/common/buttons/primary_button.dart';
import '../../widgets/session/session_header.dart';
import '../../widgets/session/session_detail_tab_timeline.dart';
import '../../widgets/session/session_detail_tab_emotion.dart';
import '../../widgets/session/session_detail_tab_speaking.dart';
import '../../widgets/session/session_detail_tab_topics.dart';

class SessionDetailsScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailsScreen({Key? key, required this.sessionId})
      : super(key: key);

  @override
  _SessionDetailsScreenState createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<AnalysisResult> _analysisFuture;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _analysisFuture = _loadAnalysisData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<AnalysisResult> _loadAnalysisData() async {
    final analysisProvider =
        Provider.of<AnalysisProvider>(context, listen: false);
    return analysisProvider.getAnalysisResult(widget.sessionId);
  }

  void _toggleAudioPlayback() {
    setState(() {
      _isAudioPlaying = !_isAudioPlaying;
    });
    // 실제 구현에서는 오디오 재생/정지 로직 추가
  }

  void _shareSession() {
    // 세션 공유 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('세션 공유 기능이 추가될 예정입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          '세션 상세',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black87),
            onPressed: _shareSession,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<AnalysisResult>(
        future: _analysisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('분석 데이터를 불러오는데 실패했습니다.'),
                  SizedBox(height: 16),
                  PrimaryButton(
                    text: '다시 시도',
                    onPressed: () {
                      setState(() {
                        _analysisFuture = _loadAnalysisData();
                      });
                    },
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: Text('데이터가 없습니다.'));
          }

          final analysisResult = snapshot.data!;

          return Column(
            children: [
              // 세션 기본 정보 헤더
              SessionHeader(
                title: analysisResult.title,
                date: analysisResult.getFormattedDate(),
                duration: analysisResult.getFormattedDuration(),
                category: analysisResult.category,
                isAudioPlaying: _isAudioPlaying,
                onPlayAudio: _toggleAudioPlayback,
              ),

              // 탭 바 (피그마 디자인에 맞게 수정)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF0F0F0)),
                    bottom: BorderSide(color: Color(0xFFF0F0F0)),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Color(0xFF757575),
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: '타임라인'),
                    Tab(text: '감정/호감도'),
                    Tab(text: '말하기 패턴'),
                    Tab(text: '대화 주제'),
                  ],
                ),
              ),

              // 탭 내용
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: TabBarView(
                    controller: _tabController,
                    physics: BouncingScrollPhysics(),
                    children: [
                      // 타임라인 탭
                      SessionDetailTabTimeline(analysisResult: analysisResult),

                      // 감정/호감도 탭
                      SessionDetailTabEmotion(analysisResult: analysisResult),

                      // 말하기 패턴 탭
                      SessionDetailTabSpeaking(analysisResult: analysisResult),

                      // 대화 주제 탭
                      SessionDetailTabTopics(analysisResult: analysisResult),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
