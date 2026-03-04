import 'package:flutter_test/flutter_test.dart';
import 'package:globingo/features/booking/domain/booking_status_transition.dart';

void main() {
  group('isValidTeacherDecisionStatus', () {
    test('accepts accepted', () {
      expect(isValidTeacherDecisionStatus('accepted'), isTrue);
    });

    test('accepts rejected', () {
      expect(isValidTeacherDecisionStatus('rejected'), isTrue);
    });

    test('rejects non-decision statuses', () {
      expect(isValidTeacherDecisionStatus('pending'), isFalse);
      expect(isValidTeacherDecisionStatus('completed'), isFalse);
      expect(isValidTeacherDecisionStatus('in_progress'), isFalse);
    });
  });
}
