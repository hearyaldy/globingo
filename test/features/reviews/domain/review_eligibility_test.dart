import 'package:flutter_test/flutter_test.dart';
import 'package:globingo/features/reviews/domain/review_eligibility.dart';

void main() {
  group('canSubmitReviewForBookingStatus', () {
    test('allows completed bookings', () {
      expect(canSubmitReviewForBookingStatus('completed'), isTrue);
    });

    test('blocks non-completed bookings', () {
      expect(canSubmitReviewForBookingStatus('pending'), isFalse);
      expect(canSubmitReviewForBookingStatus('accepted'), isFalse);
      expect(canSubmitReviewForBookingStatus('in_progress'), isFalse);
      expect(canSubmitReviewForBookingStatus('cancelled'), isFalse);
      expect(canSubmitReviewForBookingStatus('rejected'), isFalse);
    });
  });
}
