import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/teacher_model.dart';

class TeacherRepository {
  final FirebaseFirestore _firestore;

  TeacherRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> resolveTeacherDocId(String idOrUid) async {
    final normalized = idOrUid.trim();
    if (normalized.isEmpty) return null;

    final byDocId = await _firestore
        .collection('teachers')
        .doc(normalized)
        .get();
    if (byDocId.exists) {
      return byDocId.id;
    }

    final byUid = await _firestore
        .collection('teachers')
        .where('uid', isEqualTo: normalized)
        .limit(1)
        .get();
    if (byUid.docs.isNotEmpty) {
      return byUid.docs.first.id;
    }

    return null;
  }

  Future<Teacher?> getTeacherByIdOrUid(String idOrUid) async {
    final docId = await resolveTeacherDocId(idOrUid);
    if (docId == null) return null;

    final doc = await _firestore.collection('teachers').doc(docId).get();
    if (!doc.exists) return null;
    return Teacher.fromFirestore(doc.id, doc.data() ?? const {});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchTeacherDoc(String docId) {
    return _firestore.collection('teachers').doc(docId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLessonOffers({
    required String teacherUid,
    required String teacherDocId,
  }) {
    final refs = <String>{teacherUid.trim(), teacherDocId.trim()}
      ..removeWhere((value) => value.isEmpty);

    if (refs.length == 1) {
      return _firestore
          .collection('lesson_offers')
          .where('teacherId', isEqualTo: refs.first)
          .snapshots();
    }

    return _firestore
        .collection('lesson_offers')
        .where('teacherId', whereIn: refs.toList())
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTeachers() {
    return _firestore.collection('teachers').snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getTeacherByUserId(
    String userId,
  ) async {
    final byDocId = await _firestore.collection('teachers').doc(userId).get();
    if (byDocId.exists) {
      return byDocId;
    }

    final byUid = await _firestore
        .collection('teachers')
        .where('uid', isEqualTo: userId)
        .limit(1)
        .get();
    if (byUid.docs.isNotEmpty) {
      return byUid.docs.first;
    }

    return byDocId;
  }

  Future<void> upsertTeacherByUserId(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final teacherDoc = await getTeacherByUserId(userId);
    final targetId = teacherDoc.exists ? teacherDoc.id : userId;
    await _firestore
        .collection('teachers')
        .doc(targetId)
        .set(data, SetOptions(merge: true));
  }

  Future<String> resolveTeacherDocIdByUserId(String userId) async {
    final teacherDoc = await getTeacherByUserId(userId);
    if (teacherDoc.exists) {
      return teacherDoc.id;
    }
    return userId;
  }

  Future<void> upsertLessonOffer({
    required String teacherUid,
    required Map<String, dynamic> data,
    String? offerId,
  }) async {
    final ref = offerId == null
        ? _firestore.collection('lesson_offers').doc()
        : _firestore.collection('lesson_offers').doc(offerId);

    await ref.set({'teacherId': teacherUid, ...data}, SetOptions(merge: true));
  }

  Future<void> setLessonOfferActive({
    required String offerId,
    required bool isActive,
  }) {
    return _firestore.collection('lesson_offers').doc(offerId).set({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteLessonOffer(String offerId) {
    return _firestore.collection('lesson_offers').doc(offerId).delete();
  }
}
