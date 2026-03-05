import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<bool> hasReviewForBooking({
    required String bookingId,
    required String reviewerId,
  }) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .where('reviewerId', isEqualTo: reviewerId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> createReview({
    required String bookingId,
    required String reviewerId,
    required String reviewerName,
    required String teacherId,
    required String teacherName,
    required double clearExplanation,
    required double patient,
    required double wellPrepared,
    required double helpful,
    required double fun,
    required double overall,
  }) {
    return _firestore.collection('reviews').add({
      'bookingId': bookingId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'clearExplanation': clearExplanation,
      'patient': patient,
      'wellPrepared': wellPrepared,
      'helpful': helpful,
      'fun': fun,
      'overall': overall,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReviewsByReviewer(
    String reviewerId,
  ) {
    return _firestore
        .collection('reviews')
        .where('reviewerId', isEqualTo: reviewerId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReviewsByTeacher(
    String teacherId,
  ) {
    return _firestore
        .collection('reviews')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReviewsByTeacherRefs({
    required String teacherUid,
    required String teacherDocId,
  }) {
    final refs = <String>{teacherUid.trim(), teacherDocId.trim()}
      ..removeWhere((value) => value.isEmpty);

    if (refs.length == 1) {
      return _firestore
          .collection('reviews')
          .where('teacherId', isEqualTo: refs.first)
          .snapshots();
    }

    return _firestore
        .collection('reviews')
        .where('teacherId', whereIn: refs.toList())
        .snapshots();
  }
}
