import 'package:cloud_firestore/cloud_firestore.dart';

class GroupLessonRepository {
  final FirebaseFirestore _firestore;

  GroupLessonRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchScheduledLessons() {
    return _firestore
        .collection('group_lessons')
        .where('status', isEqualTo: 'scheduled')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTeacherLessons(
    String teacherId,
  ) {
    return _firestore
        .collection('group_lessons')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots();
  }

  Future<void> createLesson({
    required String teacherId,
    required String teacherDocId,
    required String title,
    String? description,
    required String language,
    String? level,
    required int capacity,
    required double pricePerSeat,
    required DateTime scheduledAt,
    required int durationMinutes,
  }) {
    final lessonRef = _firestore.collection('group_lessons').doc();
    return lessonRef.set({
      'lessonId': lessonRef.id,
      'teacherId': teacherId,
      'teacherDocId': teacherDocId,
      'title': title,
      'description': (description ?? '').trim(),
      'language': language,
      'level': (level ?? '').trim(),
      'capacity': capacity,
      'enrolledCount': 0,
      'pricePerSeat': pricePerSeat,
      'status': 'scheduled',
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'durationMinutes': durationMinutes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLesson({
    required String lessonId,
    required String title,
    String? description,
    required String language,
    String? level,
    required int capacity,
    required double pricePerSeat,
    required DateTime scheduledAt,
    required int durationMinutes,
  }) {
    return _firestore.collection('group_lessons').doc(lessonId).update({
      'title': title,
      'description': (description ?? '').trim(),
      'language': language,
      'level': (level ?? '').trim(),
      'capacity': capacity,
      'pricePerSeat': pricePerSeat,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'durationMinutes': durationMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelLesson({required String lessonId}) {
    return _firestore.collection('group_lessons').doc(lessonId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> enroll({required String lessonId, required String learnerId}) {
    final enrollmentId = '${lessonId}_$learnerId';
    return _firestore.collection('group_enrollments').doc(enrollmentId).set({
      'lessonId': lessonId,
      'learnerId': learnerId,
      'status': 'enrolled',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
