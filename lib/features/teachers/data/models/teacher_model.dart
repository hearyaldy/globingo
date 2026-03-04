import '../../../../core/widgets/skill_radar_chart.dart';

class Teacher {
  final String id;
  final String uid;
  final String name;
  final String? avatarUrl;
  final String bio;
  final List<String> teachingLanguages;
  final List<String> speakingLanguages;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final int lessonCount;
  final int studentCount;
  final SkillRating skillRating;
  final List<String> availableDays;
  final List<Review> reviews;

  const Teacher({
    required this.id,
    required this.uid,
    required this.name,
    this.avatarUrl,
    required this.bio,
    required this.teachingLanguages,
    required this.speakingLanguages,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.lessonCount,
    required this.studentCount,
    required this.skillRating,
    required this.availableDays,
    this.reviews = const [],
  });

  int get price30Min => (hourlyRate * 0.5).round();
  int get price60Min => hourlyRate.round();
  int get price90Min => (hourlyRate * 1.5).round();

  factory Teacher.fromFirestore(String id, Map<String, dynamic> data) {
    final skill = (data['skillRating'] as Map<String, dynamic>?) ?? const {};

    return Teacher(
      id: id,
      uid: (data['uid'] as String?) ?? id,
      name: (data['name'] as String?) ?? 'Teacher',
      avatarUrl: data['avatarUrl'] as String?,
      bio: (data['bio'] as String?) ?? '',
      teachingLanguages: _toStringList(data['teachingLanguages']),
      speakingLanguages: _toStringList(data['speakingLanguages']),
      hourlyRate: _toDouble(data['hourlyRate']),
      rating: _toDouble(data['rating'] ?? data['averageRating']),
      reviewCount: _toInt(data['reviewCount']),
      lessonCount: _toInt(data['lessonCount']),
      studentCount: _toInt(data['studentCount']),
      skillRating: SkillRating(
        clearExplanation: _toDouble(
          skill['clearExplanation'] ?? data['clearExplanation'],
        ),
        patient: _toDouble(skill['patient'] ?? data['patient']),
        wellPrepared: _toDouble(skill['wellPrepared'] ?? data['wellPrepared']),
        helpful: _toDouble(skill['helpful'] ?? data['helpful']),
        fun: _toDouble(skill['fun'] ?? data['fun']),
      ),
      availableDays: _toStringList(data['availableDays']),
    );
  }

  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class Review {
  final String id;
  final String studentName;
  final String? studentAvatarUrl;
  final DateTime date;
  final double rating;
  final String? comment;
  final SkillRating skillRating;

  const Review({
    required this.id,
    required this.studentName,
    this.studentAvatarUrl,
    required this.date,
    required this.rating,
    this.comment,
    required this.skillRating,
  });
}

// Mock Data
class MockTeachers {
  static final List<Teacher> teachers = [
    Teacher(
      id: '1',
      uid: '1',
      name: 'Sarah Johnson',
      bio:
          "Hi! I'm Sarah, a native English speaker from California. I love helping students build confidence in speaking English through fun and engaging conversations.",
      teachingLanguages: ['English'],
      speakingLanguages: ['English', 'Spanish'],
      hourlyRate: 28,
      rating: 4.8,
      reviewCount: 7,
      lessonCount: 342,
      studentCount: 89,
      skillRating: const SkillRating(
        clearExplanation: 4.8,
        patient: 4.9,
        wellPrepared: 4.7,
        helpful: 4.8,
        fun: 4.6,
      ),
      availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      reviews: [
        Review(
          id: 'r1',
          studentName: 'Anonymous',
          date: DateTime(2025, 11, 26),
          rating: 3.8,
          comment: 'Decent experience, will try again.',
          skillRating: const SkillRating(
            clearExplanation: 4.0,
            patient: 4.5,
            wellPrepared: 3.5,
            helpful: 4.0,
            fun: 3.5,
          ),
        ),
      ],
    ),
    Teacher(
      id: '2',
      uid: '2',
      name: '田中 優子',
      bio: 'こんにちは！日本語を楽しく学びましょう。アニメやマンガを使った授業も大歓迎です。日本の文化や日常会話を教えることが得意です。',
      teachingLanguages: ['Japanese'],
      speakingLanguages: ['Japanese', 'English'],
      hourlyRate: 32,
      rating: 4.9,
      reviewCount: 10,
      lessonCount: 567,
      studentCount: 13,
      skillRating: const SkillRating(
        clearExplanation: 4.9,
        patient: 5.0,
        wellPrepared: 4.8,
        helpful: 4.9,
        fun: 4.8,
      ),
      availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    ),
    Teacher(
      id: '3',
      uid: '3',
      name: 'Isabella Romano',
      bio:
          "Ciao! Sono Isabella da Roma. L'italiano è la lingua dell'amore, dell'arte e del buon cibo. Impariamo insieme in modo divertente!",
      teachingLanguages: ['Italian'],
      speakingLanguages: ['Italian', 'English', 'Spanish'],
      hourlyRate: 26,
      rating: 4.8,
      reviewCount: 4,
      lessonCount: 234,
      studentCount: 56,
      skillRating: const SkillRating(
        clearExplanation: 4.7,
        patient: 4.9,
        wellPrepared: 4.8,
        helpful: 4.6,
        fun: 4.9,
      ),
      availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      reviews: [
        Review(
          id: 'r2',
          studentName: 'Anonymous',
          date: DateTime(2025, 11, 26),
          rating: 3.8,
          comment: 'Decent experience, will try again.',
          skillRating: const SkillRating(
            clearExplanation: 4.0,
            patient: 4.5,
            wellPrepared: 3.5,
            helpful: 4.0,
            fun: 3.5,
          ),
        ),
      ],
    ),
    Teacher(
      id: '4',
      uid: '4',
      name: '김민준',
      bio:
          '안녕하세요! 저는 서울 출신의 한국어 선생님입니다. K-pop과 K-drama를 좋아하신다면 함께 재미있게 한국어를 배워봐요!',
      teachingLanguages: ['Korean'],
      speakingLanguages: ['Korean', 'English'],
      hourlyRate: 30,
      rating: 4.7,
      reviewCount: 8,
      lessonCount: 198,
      studentCount: 42,
      skillRating: const SkillRating(
        clearExplanation: 4.6,
        patient: 4.8,
        wellPrepared: 4.7,
        helpful: 4.7,
        fun: 4.5,
      ),
      availableDays: ['Tue', 'Wed', 'Thu', 'Sat', 'Sun'],
    ),
    Teacher(
      id: '5',
      uid: '5',
      name: '王小華',
      bio: '大家好！我是小華，來自台灣。我喜歡用輕鬆有趣的方式教中文，讓你在學習中感受到中文的美。',
      teachingLanguages: ['Chinese'],
      speakingLanguages: ['Chinese', 'English'],
      hourlyRate: 22,
      rating: 4.6,
      reviewCount: 5,
      lessonCount: 156,
      studentCount: 38,
      skillRating: const SkillRating(
        clearExplanation: 4.5,
        patient: 4.7,
        wellPrepared: 4.6,
        helpful: 4.5,
        fun: 4.4,
      ),
      availableDays: ['Mon', 'Wed', 'Fri', 'Sat'],
    ),
  ];

  static Teacher? getTeacherById(String id) {
    try {
      return teachers.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
