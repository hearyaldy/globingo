import assert from 'node:assert/strict';
import fs from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'globingo-4362f';
const rules = fs.readFileSync('firestore.rules', 'utf8');

const testEnv = await initializeTestEnvironment({
  projectId,
  firestore: { rules },
});

async function seedBaseDocs() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'users/teacher1'), {
      teachingModeEnabled: true,
      role: 'both',
    });
    await setDoc(doc(db, 'users/learner1'), {
      teachingModeEnabled: false,
      role: 'student',
    });
    await setDoc(doc(db, 'users/other1'), {
      teachingModeEnabled: false,
      role: 'student',
    });

    await setDoc(doc(db, 'teachers/teacher1'), {
      uid: 'teacher1',
      displayName: 'Teacher One',
      active: true,
    });

    await setDoc(doc(db, 'bookings/booking-completed'), {
      slotId: 'booking-completed',
      learnerId: 'learner1',
      teacherId: 'teacher1',
      teacherDocId: 'teacher1',
      status: 'completed',
      createdAt: new Date('2026-03-05T00:00:00.000Z'),
      updatedAt: new Date('2026-03-05T00:00:00.000Z'),
    });

    await setDoc(doc(db, 'bookings/booking-pending'), {
      slotId: 'booking-pending',
      learnerId: 'learner1',
      teacherId: 'teacher1',
      teacherDocId: 'teacher1',
      status: 'pending',
      createdAt: new Date('2026-03-05T00:00:00.000Z'),
      updatedAt: new Date('2026-03-05T00:00:00.000Z'),
    });

    await setDoc(doc(db, 'bookings/booking-in-progress'), {
      slotId: 'booking-in-progress',
      learnerId: 'learner1',
      teacherId: 'teacher1',
      teacherDocId: 'teacher1',
      status: 'in_progress',
      createdAt: new Date('2026-03-05T00:00:00.000Z'),
      updatedAt: new Date('2026-03-05T00:00:00.000Z'),
    });

    await setDoc(doc(db, 'bookings/booking-accepted'), {
      slotId: 'booking-accepted',
      learnerId: 'learner1',
      teacherId: 'teacher1',
      teacherDocId: 'teacher1',
      status: 'accepted',
      createdAt: new Date('2026-03-05T00:00:00.000Z'),
      updatedAt: new Date('2026-03-05T00:00:00.000Z'),
    });

    await setDoc(doc(db, 'wallets/learner1'), {
      uid: 'learner1',
      pendingBalance: 20,
      availableBalance: 100,
      volunteerBalance: 0,
      currency: 'USD',
      kycStatus: 'none',
      withdrawalThreshold: 500,
      updatedAt: new Date('2026-03-05T00:00:00.000Z'),
    });

    await setDoc(doc(db, 'wallets/other1'), {
      uid: 'other1',
      pendingBalance: 0,
      availableBalance: 900,
      volunteerBalance: 0,
      currency: 'USD',
      kycStatus: 'verified',
      withdrawalThreshold: 500,
      updatedAt: new Date('2026-03-05T00:00:00.000Z'),
    });

    await setDoc(doc(db, 'wallet_transactions/tx-1'), {
      txId: 'tx-1',
      uid: 'learner1',
      type: 'lesson_earning',
      amount: 50,
      currency: 'USD',
      bucket: 'pending',
      withdrawable: true,
      status: 'pending',
      createdAt: new Date('2026-03-05T00:00:00.000Z'),
    });

    await setDoc(doc(db, 'service_learning_hours/record-1'), {
      recordId: 'record-1',
      teacherId: 'teacher1',
      lessonId: 'group-1',
      hours: 1.5,
      language: 'English',
      ratingSnapshot: 4.8,
      createdAt: new Date('2026-03-05T00:00:00.000Z'),
    });

    await setDoc(doc(db, 'certificates/cert-1'), {
      certificateId: 'cert-1',
      uid: 'teacher1',
      totalHours: 10,
      languages: ['English'],
      averageRating: 4.7,
      fileUrl: 'https://example.com/cert-1.pdf',
      issuedAt: new Date('2026-03-05T00:00:00.000Z'),
      metadata: {},
    });
  });
}

async function run() {
  await seedBaseDocs();

  // users/{uid}: owner can write own doc; non-owner cannot.
  {
    const ownerDb = testEnv.authenticatedContext('learner1').firestore();
    const otherDb = testEnv.authenticatedContext('other1').firestore();

    await assertSucceeds(
      setDoc(doc(ownerDb, 'users/learner1'), {
        displayName: 'Learner One',
      }),
    );

    await assertFails(
      setDoc(doc(otherDb, 'users/learner1'), {
        hacked: true,
      }),
    );
  }

  // lesson_offers: only teacher with teachingModeEnabled can create with matching teacherId.
  {
    const teacherDb = testEnv.authenticatedContext('teacher1').firestore();
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();

    await assertSucceeds(
      setDoc(doc(teacherDb, 'lesson_offers/offer1'), {
        teacherId: 'teacher1',
        title: 'Conversation Practice',
        durationMinutes: 60,
        price: 26,
      }),
    );

    await assertFails(
      setDoc(doc(learnerDb, 'lesson_offers/offer2'), {
        teacherId: 'learner1',
        title: 'Should Fail',
        durationMinutes: 30,
        price: 13,
      }),
    );
  }

  // bookings read: participants can read, unrelated user cannot.
  {
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();
    const teacherDb = testEnv.authenticatedContext('teacher1').firestore();
    const otherDb = testEnv.authenticatedContext('other1').firestore();

    await assertSucceeds(getDoc(doc(learnerDb, 'bookings/booking-completed')));
    await assertSucceeds(getDoc(doc(teacherDb, 'bookings/booking-completed')));
    await assertFails(getDoc(doc(otherDb, 'bookings/booking-completed')));
  }

  // reviews create: only for completed booking and matching learner/teacher/booking linkage.
  {
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();

    await assertSucceeds(
      setDoc(doc(learnerDb, 'reviews/review-completed'), {
        reviewerId: 'learner1',
        teacherId: 'teacher1',
        bookingId: 'booking-completed',
        clearExplanation: 5,
        patient: 5,
        wellPrepared: 5,
        helpful: 5,
        fun: 5,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    await assertFails(
      setDoc(doc(learnerDb, 'reviews/review-pending'), {
        reviewerId: 'learner1',
        teacherId: 'teacher1',
        bookingId: 'booking-pending',
        clearExplanation: 4,
        patient: 4,
        wellPrepared: 4,
        helpful: 4,
        fun: 4,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  }

  // bookings no_show: only teacher can mark no_show from in_progress with actor.
  {
    const teacherDb = testEnv.authenticatedContext('teacher1').firestore();
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();

    await assertFails(
      updateDoc(doc(learnerDb, 'bookings/booking-in-progress'), {
        status: 'no_show',
        noShowActor: 'teacher',
        updatedAt: serverTimestamp(),
      }),
    );

    await assertSucceeds(
      updateDoc(doc(teacherDb, 'bookings/booking-in-progress'), {
        status: 'no_show',
        noShowActor: 'learner',
        updatedAt: serverTimestamp(),
      }),
    );
  }

  // bookings cancel: teacher can cancel accepted with reason; learner cannot cancel accepted.
  {
    const teacherDb = testEnv.authenticatedContext('teacher1').firestore();
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();

    await assertSucceeds(
      updateDoc(doc(teacherDb, 'bookings/booking-accepted'), {
        status: 'cancelled',
        cancelledBy: 'teacher',
        cancellationReason: 'Teacher unavailable',
        updatedAt: serverTimestamp(),
      }),
    );

    await assertFails(
      updateDoc(doc(learnerDb, 'bookings/booking-accepted'), {
        status: 'cancelled',
        cancelledBy: 'learner',
        cancellationReason: 'Need to reschedule',
        updatedAt: serverTimestamp(),
      }),
    );
  }

  // admin claim can bypass ownership constraints.
  {
    const adminDb = testEnv
      .authenticatedContext('adminUser', { admin: true })
      .firestore();

    await assertSucceeds(
      setDoc(doc(adminDb, 'users/learner1'), {
        displayName: 'Admin updated profile',
      }),
    );

    await assertSucceeds(getDoc(doc(adminDb, 'bookings/booking-completed')));
  }

  // wallets: owner can read but cannot write; admin can write.
  {
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();
    const adminDb = testEnv
      .authenticatedContext('adminUser', { admin: true })
      .firestore();

    await assertSucceeds(getDoc(doc(learnerDb, 'wallets/learner1')));

    await assertFails(
      setDoc(doc(learnerDb, 'wallets/learner1'), {
        uid: 'learner1',
        pendingBalance: 0,
        availableBalance: 9999,
      }),
    );

    await assertSucceeds(
      setDoc(doc(adminDb, 'wallets/learner1'), {
        uid: 'learner1',
        pendingBalance: 0,
        availableBalance: 120,
        volunteerBalance: 0,
        currency: 'USD',
        kycStatus: 'verified',
        withdrawalThreshold: 500,
        updatedAt: serverTimestamp(),
      }),
    );
  }

  // wallet transactions: owner can read own transactions; only admin can create.
  {
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();
    const otherDb = testEnv.authenticatedContext('other1').firestore();
    const adminDb = testEnv
      .authenticatedContext('adminUser', { admin: true })
      .firestore();

    await assertSucceeds(getDoc(doc(learnerDb, 'wallet_transactions/tx-1')));
    await assertFails(getDoc(doc(otherDb, 'wallet_transactions/tx-1')));

    await assertFails(
      setDoc(doc(learnerDb, 'wallet_transactions/tx-2'), {
        txId: 'tx-2',
        uid: 'learner1',
        type: 'adjustment',
        amount: 1000,
        currency: 'USD',
        bucket: 'available',
        withdrawable: true,
        status: 'applied',
        createdAt: serverTimestamp(),
      }),
    );

    await assertSucceeds(
      setDoc(doc(adminDb, 'wallet_transactions/tx-2'), {
        txId: 'tx-2',
        uid: 'learner1',
        type: 'adjustment',
        amount: 1,
        currency: 'USD',
        bucket: 'available',
        withdrawable: false,
        status: 'applied',
        createdAt: serverTimestamp(),
      }),
    );
  }

  // group lessons + enrollments: teacher can create, learner can enroll, learner cannot self-mark attendance.
  {
    const teacherDb = testEnv.authenticatedContext('teacher1').firestore();
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();
    const otherDb = testEnv.authenticatedContext('other1').firestore();

    await assertSucceeds(
      setDoc(doc(teacherDb, 'group_lessons/group-1'), {
        lessonId: 'group-1',
        teacherId: 'teacher1',
        teacherDocId: 'teacher1',
        title: 'Group Conversation',
        description: 'Practice speaking',
        language: 'English',
        level: 'A2',
        capacity: 8,
        pricePerSeat: 12,
        status: 'scheduled',
        scheduledAt: new Date('2026-03-10T01:00:00.000Z'),
        durationMinutes: 60,
        enrolledCount: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    await assertFails(
      setDoc(doc(learnerDb, 'group_lessons/group-2'), {
        lessonId: 'group-2',
        teacherId: 'learner1',
        teacherDocId: 'teacher1',
        title: 'Invalid',
        description: 'Invalid',
        language: 'English',
        level: 'A1',
        capacity: 4,
        pricePerSeat: 10,
        status: 'scheduled',
        scheduledAt: new Date('2026-03-10T01:00:00.000Z'),
        durationMinutes: 45,
        enrolledCount: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    await assertSucceeds(
      setDoc(doc(learnerDb, 'group_enrollments/group-1_learner1'), {
        enrollmentId: 'group-1_learner1',
        lessonId: 'group-1',
        learnerId: 'learner1',
        status: 'enrolled',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    await assertFails(
      setDoc(doc(otherDb, 'group_enrollments/group-1_learner1'), {
        enrollmentId: 'group-1_learner1',
        lessonId: 'group-1',
        learnerId: 'learner1',
        status: 'enrolled',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    await assertFails(
      updateDoc(doc(learnerDb, 'group_enrollments/group-1_learner1'), {
        status: 'attended',
        updatedAt: serverTimestamp(),
      }),
    );

    await assertSucceeds(
      updateDoc(doc(teacherDb, 'group_enrollments/group-1_learner1'), {
        status: 'attended',
        updatedAt: serverTimestamp(),
      }),
    );
  }

  // service learning docs: only admin writes certificates/hours; owners can read.
  {
    const teacherDb = testEnv.authenticatedContext('teacher1').firestore();
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();
    const adminDb = testEnv
      .authenticatedContext('adminUser', { admin: true })
      .firestore();

    await assertSucceeds(getDoc(doc(teacherDb, 'service_learning_hours/record-1')));
    await assertFails(getDoc(doc(learnerDb, 'service_learning_hours/record-1')));
    await assertSucceeds(getDoc(doc(teacherDb, 'certificates/cert-1')));

    await assertFails(
      setDoc(doc(teacherDb, 'certificates/cert-2'), {
        certificateId: 'cert-2',
        uid: 'teacher1',
      }),
    );

    await assertSucceeds(
      setDoc(doc(adminDb, 'certificates/cert-2'), {
        certificateId: 'cert-2',
        uid: 'teacher1',
        totalHours: 12,
        languages: ['English'],
        averageRating: 4.9,
        fileUrl: 'https://example.com/cert-2.pdf',
        issuedAt: serverTimestamp(),
        metadata: {},
      }),
    );
  }

  // wallet withdrawal requests: enforce KYC and threshold gating.
  {
    const learnerDb = testEnv.authenticatedContext('learner1').firestore();
    const otherDb = testEnv.authenticatedContext('other1').firestore();
    const adminDb = testEnv
      .authenticatedContext('adminUser', { admin: true })
      .firestore();

    // Fails: learner1 has kycStatus=none.
    await assertFails(
      setDoc(doc(learnerDb, 'wallet_withdrawal_requests/req-learner-1'), {
        uid: 'learner1',
        amount: 50,
        status: 'pending',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    // Fails: other1 is verified but amount below threshold (500).
    await assertFails(
      setDoc(doc(otherDb, 'wallet_withdrawal_requests/req-other-low'), {
        uid: 'other1',
        amount: 400,
        status: 'pending',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    // Succeeds: other1 is verified and amount is in allowed range.
    await assertSucceeds(
      setDoc(doc(otherDb, 'wallet_withdrawal_requests/req-other-ok'), {
        uid: 'other1',
        amount: 600,
        status: 'pending',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    // Owner can read own request, unrelated user cannot.
    await assertSucceeds(
      getDoc(doc(otherDb, 'wallet_withdrawal_requests/req-other-ok')),
    );
    await assertFails(
      getDoc(doc(learnerDb, 'wallet_withdrawal_requests/req-other-ok')),
    );

    // Admin can mutate request status.
    await assertSucceeds(
      updateDoc(doc(adminDb, 'wallet_withdrawal_requests/req-other-ok'), {
        status: 'approved',
        updatedAt: serverTimestamp(),
      }),
    );
  }

  await testEnv.cleanup();

  assert.ok(true);
  console.log('All Firestore rules tests passed.');
}

try {
  await run();
} catch (error) {
  await testEnv.cleanup();
  console.error(error);
  process.exit(1);
}
