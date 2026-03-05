enum GroupLessonStatus { scheduled, inProgress, completed, cancelled }

enum GroupEnrollmentStatus { enrolled, cancelled, attended, noShow }

class GroupLesson {
  final String id;
  final String teacherId;
  final String title;
  final String language;
  final int capacity;
  final int enrolledCount;
  final double pricePerSeat;
  final GroupLessonStatus status;
  final DateTime scheduledAt;
  final int durationMinutes;

  const GroupLesson({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.language,
    required this.capacity,
    required this.enrolledCount,
    required this.pricePerSeat,
    required this.status,
    required this.scheduledAt,
    required this.durationMinutes,
  });
}

class GroupEnrollment {
  final String id;
  final String lessonId;
  final String learnerId;
  final GroupEnrollmentStatus status;

  const GroupEnrollment({
    required this.id,
    required this.lessonId,
    required this.learnerId,
    required this.status,
  });
}
