class Session {
  final String id;
  final String title;
  final String tag;
  final String duration;
  final String engagement;
  final String sentiment;
  final double progressPercentage;
  final DateTime date;

  Session({
    required this.id,
    required this.title,
    required this.tag,
    required this.duration,
    required this.engagement,
    required this.sentiment,
    required this.progressPercentage,
    required this.date,
  });
}
