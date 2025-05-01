class Session {
  final String id;
  final String title;
  final String date;
  final String duration;
  final String type;
  final Map<String, int> metrics;
  final double progress;

  Session({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.type,
    required this.metrics,
    required this.progress,
  });
}
