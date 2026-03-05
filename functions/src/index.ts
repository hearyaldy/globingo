import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';

if (getApps().length === 0) {
  initializeApp();
}

type WalletTransaction = {
  uid?: string;
  amount?: number;
  status?: string;
  bucket?: string;
  availableAt?: Timestamp;
  withdrawable?: boolean;
  type?: string;
};

type WalletDoc = {
  uid: string;
  pendingBalance: number;
  availableBalance: number;
  volunteerBalance: number;
  currency: string;
  kycStatus: string;
  withdrawalThreshold: number;
  updatedAt: FirebaseFirestore.FieldValue;
};

type BookingDoc = {
  learnerId?: string;
  teacherId?: string;
  status?: string;
  noShowActor?: string;
  paymentRoute?: string;
  lessonFee?: number;
  totalAmount?: number;
  paymentMethod?: string;
};

const QUALITY_WINDOW_SIZE = 20;
const QUALITY_WARNING_THRESHOLD = 4.2;
const QUALITY_FREEZE_THRESHOLD = 3.6;
const QUALITY_UNFREEZE_THRESHOLD = 4.3;

function toFiniteNumber(value: unknown): number | null {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return null;
  }
  return value;
}

function reviewScore(review: Record<string, unknown>): number | null {
  const overall = toFiniteNumber(review.overall);
  if (overall != null) {
    return overall;
  }

  const parts = [
    toFiniteNumber(review.clearExplanation),
    toFiniteNumber(review.patient),
    toFiniteNumber(review.wellPrepared),
    toFiniteNumber(review.helpful),
    toFiniteNumber(review.fun),
  ].filter((n): n is number => n != null);

  if (parts.length === 0) {
    return null;
  }

  const total = parts.reduce((sum, n) => sum + n, 0);
  return total / parts.length;
}

function resolveEarningAmount(booking: BookingDoc): number {
  if (typeof booking.lessonFee === 'number' && booking.lessonFee > 0) {
    return booking.lessonFee;
  }
  if (typeof booking.totalAmount === 'number' && booking.totalAmount > 0) {
    return booking.totalAmount;
  }
  return 0;
}

function isVolunteerCredit(booking: BookingDoc): boolean {
  if (typeof booking.paymentMethod !== 'string') {
    return false;
  }

  const normalized = booking.paymentMethod.trim().toLowerCase();
  return normalized === 'service_learning' || normalized === 'volunteer';
}

type SettlementRoute = 'teacher_direct' | 'organization_escrow';

function resolveSettlementRoute(booking: BookingDoc): SettlementRoute {
  // Centralized settlement policy: all booking funds must go through organization escrow.
  // Any client-provided route is ignored for enforcement consistency.
  return 'organization_escrow';
}

// P2-005: wallet transition engine (pending -> available).
export const walletPendingReleaseCron = onSchedule('every 1 hours', async () => {
  const db = getFirestore();
  const now = Timestamp.now();
  const eligibleSnapshot = await db
    .collection('wallet_transactions')
    .where('status', '==', 'pending')
    .where('bucket', '==', 'pending')
    .where('availableAt', '<=', now)
    .limit(200)
    .get();

  if (eligibleSnapshot.empty) {
    logger.info('walletPendingReleaseCron: no eligible pending transactions');
    return;
  }

  let releasedCount = 0;
  for (const txDoc of eligibleSnapshot.docs) {
    const txRef = txDoc.ref;
    await db.runTransaction(async (trx) => {
      const freshTxSnap = await trx.get(txRef);
      if (!freshTxSnap.exists) {
        return;
      }

      const tx = freshTxSnap.data() as WalletTransaction;
      if (
        tx.status !== 'pending'
        || tx.bucket !== 'pending'
        || !(tx.availableAt instanceof Timestamp)
        || tx.availableAt.toMillis() > now.toMillis()
      ) {
        return;
      }

      if (typeof tx.uid !== 'string' || tx.uid.length === 0) {
        logger.warn('walletPendingReleaseCron: skipping transaction with invalid uid', {
          txId: txRef.id,
        });
        return;
      }

      if (typeof tx.amount !== 'number' || tx.amount <= 0) {
        logger.warn('walletPendingReleaseCron: skipping transaction with invalid amount', {
          txId: txRef.id,
          amount: tx.amount,
        });
        return;
      }

      const walletRef = db.doc(`wallets/${tx.uid}`);
      const walletSnap = await trx.get(walletRef);

      const basePending = walletSnap.exists
        ? (walletSnap.get('pendingBalance') as number | undefined) ?? 0
        : 0;
      const baseAvailable = walletSnap.exists
        ? (walletSnap.get('availableBalance') as number | undefined) ?? 0
        : 0;
      const baseVolunteer = walletSnap.exists
        ? (walletSnap.get('volunteerBalance') as number | undefined) ?? 0
        : 0;
      const currency = walletSnap.exists
        ? (walletSnap.get('currency') as string | undefined) ?? 'USD'
        : 'USD';
      const kycStatus = walletSnap.exists
        ? (walletSnap.get('kycStatus') as string | undefined) ?? 'none'
        : 'none';
      const withdrawalThreshold = walletSnap.exists
        ? (walletSnap.get('withdrawalThreshold') as number | undefined) ?? 500
        : 500;

      const targetBucket = tx.withdrawable === false ? 'volunteer' : 'available';

      const nextPending = Math.max(0, basePending - tx.amount);
      const nextAvailable = targetBucket === 'available' ? baseAvailable + tx.amount : baseAvailable;
      const nextVolunteer = targetBucket === 'volunteer' ? baseVolunteer + tx.amount : baseVolunteer;

      const walletData: WalletDoc = {
        uid: tx.uid,
        pendingBalance: nextPending,
        availableBalance: nextAvailable,
        volunteerBalance: nextVolunteer,
        currency,
        kycStatus,
        withdrawalThreshold,
        updatedAt: FieldValue.serverTimestamp(),
      };

      trx.set(walletRef, walletData, { merge: true });
      trx.update(txRef, {
        status: 'applied',
        bucket: targetBucket,
        metadata: {
          releaseProcessedAt: FieldValue.serverTimestamp(),
        },
      });

      releasedCount += 1;
    });
  }

  logger.info('walletPendingReleaseCron: processed pending releases', {
    processed: releasedCount,
    scanned: eligibleSnapshot.size,
  });
});

// P2-005/P2-006: handle settlement hold on accept and earning release on completion.
export const bookingStatusPolicyHook = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;

  if (!before || !after || before.status === after.status) {
    return;
  }

  if (
    typeof after.teacherId !== 'string'
    || after.teacherId.length === 0
    || typeof after.learnerId !== 'string'
    || after.learnerId.length === 0
  ) {
    logger.warn('bookingStatusPolicyHook: booking missing teacherId/learnerId', {
      bookingId: event.params.bookingId,
    });
    return;
  }

  const bookingId = event.params.bookingId;
  const amount = resolveEarningAmount(after);
  if (amount <= 0) {
    logger.warn('bookingStatusPolicyHook: booking has no positive settlement amount', {
      bookingId,
      lessonFee: after.lessonFee,
      totalAmount: after.totalAmount,
    });
    return;
  }

  const teacherId = after.teacherId;
  const learnerId = after.learnerId;
  const settlementRoute = resolveSettlementRoute(after);
  const db = getFirestore();
  const bookingRef = db.doc(`bookings/${bookingId}`);

  if (after.status === 'accepted') {
    const learnerWalletRef = db.doc(`wallets/${learnerId}`);
    const settlementRef = db.doc(`booking_settlements/${bookingId}`);
    const paymentOutTxRef = db.doc(`wallet_transactions/payment_out_${bookingId}`);
    const routeFundRef = settlementRoute === 'teacher_direct'
      ? db.doc(`teacher_escrow/${teacherId}`)
      : db.doc('organization_funds/main');

    await db.runTransaction(async (trx) => {
      const existingPaymentOutTx = await trx.get(paymentOutTxRef);
      if (existingPaymentOutTx.exists) {
        return;
      }

      const learnerWalletSnap = await trx.get(learnerWalletRef);
      const learnerAvailable = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('availableBalance') as number | undefined) ?? 0
        : 0;
      const learnerPending = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('pendingBalance') as number | undefined) ?? 0
        : 0;
      const learnerVolunteer = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('volunteerBalance') as number | undefined) ?? 0
        : 0;
      const learnerCurrency = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('currency') as string | undefined) ?? 'USD'
        : 'USD';
      const learnerKyc = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('kycStatus') as string | undefined) ?? 'none'
        : 'none';
      const learnerThreshold = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('withdrawalThreshold') as number | undefined) ?? 500
        : 500;

      if (learnerAvailable < amount) {
        trx.set(
          settlementRef,
          {
            bookingId,
            learnerId,
            teacherId,
            amount,
            currency: learnerCurrency,
            route: settlementRoute,
            status: 'failed',
            reason: 'insufficient_learner_balance',
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        trx.set(
          bookingRef,
          {
            status: 'cancelled',
            cancellationReason: 'payment_failed',
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        return;
      }

      const routeFundSnap = await trx.get(routeFundRef);
      const routeEscrowBalance = routeFundSnap.exists
        ? (routeFundSnap.get('escrowBalance') as number | undefined) ?? 0
        : 0;

      trx.set(
        learnerWalletRef,
        {
          uid: learnerId,
          pendingBalance: learnerPending,
          availableBalance: Math.max(0, learnerAvailable - amount),
          volunteerBalance: learnerVolunteer,
          currency: learnerCurrency,
          kycStatus: learnerKyc,
          withdrawalThreshold: learnerThreshold,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      trx.create(paymentOutTxRef, {
        txId: `payment_out_${bookingId}`,
        uid: learnerId,
        type: 'payment_out',
        sourceBookingId: bookingId,
        amount,
        currency: learnerCurrency,
        bucket: 'available',
        withdrawable: false,
        status: 'applied',
        metadata: {
          settlementRoute,
        },
        createdAt: FieldValue.serverTimestamp(),
      });

      trx.set(
        routeFundRef,
        {
          ownerId: settlementRoute === 'teacher_direct' ? teacherId : 'organization',
          escrowBalance: routeEscrowBalance + amount,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      trx.set(
        settlementRef,
        {
          bookingId,
          learnerId,
          teacherId,
          amount,
          currency: learnerCurrency,
          route: settlementRoute,
          status: 'held',
          heldAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    logger.info('bookingStatusPolicyHook: settlement hold processed', {
      bookingId,
      learnerId,
      teacherId,
      amount,
      settlementRoute,
    });
    return;
  }

  if (after.status !== 'completed') {
    return;
  }

  const earningTxRef = db.doc(`wallet_transactions/earning_${bookingId}`);
  const teacherWalletRef = db.doc(`wallets/${teacherId}`);
  const settlementRef = db.doc(`booking_settlements/${bookingId}`);
  const now = Timestamp.now();
  const availableAt = Timestamp.fromMillis(
    now.toMillis() + (7 * 24 * 60 * 60 * 1000),
  );
  let payoutCreated = false;
  let payoutSkippedReason = 'unknown';
  let payoutRouteUsed: SettlementRoute = settlementRoute;

  await db.runTransaction(async (trx) => {
    const existingEarningTx = await trx.get(earningTxRef);
    if (existingEarningTx.exists) {
      payoutSkippedReason = 'earning_already_exists';
      return;
    }

    const teacherWalletSnap = await trx.get(teacherWalletRef);
    const basePending = teacherWalletSnap.exists
      ? (teacherWalletSnap.get('pendingBalance') as number | undefined) ?? 0
      : 0;
    const baseAvailable = teacherWalletSnap.exists
      ? (teacherWalletSnap.get('availableBalance') as number | undefined) ?? 0
      : 0;
    const baseVolunteer = teacherWalletSnap.exists
      ? (teacherWalletSnap.get('volunteerBalance') as number | undefined) ?? 0
      : 0;
    const currency = teacherWalletSnap.exists
      ? (teacherWalletSnap.get('currency') as string | undefined) ?? 'USD'
      : 'USD';
    const kycStatus = teacherWalletSnap.exists
      ? (teacherWalletSnap.get('kycStatus') as string | undefined) ?? 'none'
      : 'none';
    const withdrawalThreshold = teacherWalletSnap.exists
      ? (teacherWalletSnap.get('withdrawalThreshold') as number | undefined) ?? 500
      : 500;

    const settlementSnap = await trx.get(settlementRef);
    let releaseAmount = amount;
    if (!settlementSnap.exists) {
      payoutSkippedReason = 'missing_settlement_hold';
      trx.set(
        settlementRef,
        {
          bookingId,
          learnerId,
          teacherId,
          amount,
          route: settlementRoute,
          status: 'failed',
          reason: 'missing_settlement_hold',
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      trx.set(
        bookingRef,
        {
          status: 'cancelled',
          cancellationReason: 'payment_failed',
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }

    releaseAmount = (settlementSnap.get('amount') as number | undefined) ?? amount;
    const settlementStoredRoute = (settlementSnap.get('route') as string | undefined) ?? null;
    const effectiveRoute: SettlementRoute = settlementStoredRoute === 'teacher_direct'
      ? 'teacher_direct'
      : 'organization_escrow';
    const routeFundRef = effectiveRoute === 'teacher_direct'
      ? db.doc(`teacher_escrow/${teacherId}`)
      : db.doc('organization_funds/main');
    payoutRouteUsed = effectiveRoute;
    const settlementStatus = (settlementSnap.get('status') as string | undefined) ?? 'held';

    if (settlementStatus === 'failed') {
      payoutSkippedReason = 'settlement_failed';
      return;
    }

    if (settlementStatus !== 'held' && settlementStatus !== 'released') {
      payoutSkippedReason = 'invalid_settlement_status';
      trx.set(
        settlementRef,
        {
          status: 'failed',
          reason: 'invalid_settlement_status',
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }

    if (settlementStatus === 'held') {
      const routeFundSnap = await trx.get(routeFundRef);
      const currentEscrow = routeFundSnap.exists
        ? (routeFundSnap.get('escrowBalance') as number | undefined) ?? 0
        : 0;

      if (currentEscrow < releaseAmount) {
        payoutSkippedReason = 'insufficient_escrow_balance';
        trx.set(
          settlementRef,
          {
            status: 'failed',
            reason: 'insufficient_escrow_balance',
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        trx.set(
          bookingRef,
          {
            status: 'cancelled',
            cancellationReason: 'payment_failed',
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        return;
      }

      trx.set(
        routeFundRef,
        {
          escrowBalance: currentEscrow - releaseAmount,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      trx.set(
        settlementRef,
        {
          status: 'released',
          releasedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    trx.create(earningTxRef, {
      txId: `earning_${bookingId}`,
      uid: teacherId,
      type: isVolunteerCredit(after) ? 'volunteer_earning' : 'lesson_earning',
      sourceBookingId: bookingId,
      amount: releaseAmount,
      currency,
      bucket: 'pending',
      withdrawable: !isVolunteerCredit(after),
      status: 'pending',
      availableAt,
      metadata: {
        bookedStatusFrom: before.status ?? null,
        bookedStatusTo: after.status ?? null,
        paymentMethod: after.paymentMethod ?? null,
        settlementRoute: effectiveRoute,
      },
      createdAt: FieldValue.serverTimestamp(),
    });

    trx.set(
      teacherWalletRef,
      {
        uid: teacherId,
        pendingBalance: basePending + releaseAmount,
        availableBalance: baseAvailable,
        volunteerBalance: baseVolunteer,
        currency,
        kycStatus,
        withdrawalThreshold,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    payoutCreated = true;
    payoutSkippedReason = '';
  });

  if (payoutCreated) {
    logger.info('bookingStatusPolicyHook: settlement released to teacher pending', {
      bookingId,
      teacherId,
      amount,
      settlementRoute: payoutRouteUsed,
    });
  } else {
    logger.warn('bookingStatusPolicyHook: skipped teacher payout', {
      bookingId,
      teacherId,
      reason: payoutSkippedReason,
    });
  }
});

// P2-006: process withdrawal requests into ledger entries and wallet deductions.
export const walletWithdrawalRequestHook = onDocumentCreated(
  'wallet_withdrawal_requests/{requestId}',
  async (event) => {
    const requestId = event.params.requestId;
    const db = getFirestore();
    const requestRef = db.doc(`wallet_withdrawal_requests/${requestId}`);

    await db.runTransaction(async (trx) => {
      const requestSnap = await trx.get(requestRef);
      if (!requestSnap.exists) {
        return;
      }

      const requestData = requestSnap.data() as {
        uid?: string;
        amount?: number;
        status?: string;
      };

      if (requestData.status !== 'pending') {
        return;
      }

      if (typeof requestData.uid !== 'string' || requestData.uid.length === 0) {
        trx.update(requestRef, {
          status: 'rejected',
          reason: 'invalid_uid',
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      if (typeof requestData.amount !== 'number' || requestData.amount <= 0) {
        trx.update(requestRef, {
          status: 'rejected',
          reason: 'invalid_amount',
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      const uid = requestData.uid;
      const amount = requestData.amount;
      const walletRef = db.doc(`wallets/${uid}`);
      const walletSnap = await trx.get(walletRef);

      if (!walletSnap.exists) {
        trx.update(requestRef, {
          status: 'rejected',
          reason: 'wallet_not_found',
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      const availableBalance = (walletSnap.get('availableBalance') as number | undefined) ?? 0;
      const pendingBalance = (walletSnap.get('pendingBalance') as number | undefined) ?? 0;
      const volunteerBalance = (walletSnap.get('volunteerBalance') as number | undefined) ?? 0;
      const currency = (walletSnap.get('currency') as string | undefined) ?? 'USD';
      const kycStatus = (walletSnap.get('kycStatus') as string | undefined) ?? 'none';
      const withdrawalThreshold = (walletSnap.get('withdrawalThreshold') as number | undefined) ?? 500;

      if (kycStatus !== 'verified') {
        trx.update(requestRef, {
          status: 'rejected',
          reason: 'kyc_not_verified',
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      if (amount < withdrawalThreshold) {
        trx.update(requestRef, {
          status: 'rejected',
          reason: 'below_threshold',
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      if (amount > availableBalance) {
        trx.update(requestRef, {
          status: 'rejected',
          reason: 'insufficient_available_balance',
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      const txId = `withdrawal_${requestId}`;
      const txRef = db.doc(`wallet_transactions/${txId}`);
      const txSnap = await trx.get(txRef);

      if (!txSnap.exists) {
        trx.create(txRef, {
          txId,
          uid,
          type: 'withdrawal',
          amount,
          currency,
          bucket: 'available',
          withdrawable: false,
          status: 'applied',
          metadata: {
            sourceRequestId: requestId,
          },
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      trx.set(
        walletRef,
        {
          uid,
          pendingBalance,
          availableBalance: Math.max(0, availableBalance - amount),
          volunteerBalance,
          currency,
          kycStatus,
          withdrawalThreshold,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      trx.update(requestRef, {
        status: 'processed',
        processedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    logger.info('walletWithdrawalRequestHook: request processed', { requestId });
  },
);

// P2-007: no-show event trail (future-compatible with explicit no_show status).
export const bookingNoShowPolicyHook = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const before = event.data?.before.data() as BookingDoc | undefined;
  const after = event.data?.after.data() as BookingDoc | undefined;

  if (!before || !after || before.status === after.status) {
    return;
  }

  if (after.status !== 'no_show') {
    return;
  }

  if (
    typeof after.teacherId !== 'string'
    || after.teacherId.length === 0
    || typeof after.learnerId !== 'string'
    || after.learnerId.length === 0
  ) {
    logger.warn('bookingNoShowPolicyHook: missing teacher/learner ids', {
      bookingId: event.params.bookingId,
    });
    return;
  }

  const bookingId = event.params.bookingId;
  const eventId = `booking_no_show_${bookingId}`;
  const noShowActor = after.noShowActor === 'teacher' || after.noShowActor === 'learner'
    ? after.noShowActor
    : 'system';
  const policyAmount = resolveEarningAmount(after);
  const db = getFirestore();
  const noShowRef = db.doc(`no_show_events/${eventId}`);
  const qualityEventRef = db.doc(`teacher_quality_events/no_show_warning_${bookingId}`);

  await db.runTransaction(async (trx) => {
    const existing = await trx.get(noShowRef);
    if (existing.exists) {
      return;
    }

    let penaltyApplied = false;
    let penaltyAmount = 0;

    if (noShowActor === 'teacher' && policyAmount > 0) {
      const learnerWalletRef = db.doc(`wallets/${after.learnerId}`);
      const teacherWalletRef = db.doc(`wallets/${after.teacherId}`);
      const refundTxRef = db.doc(`wallet_transactions/refund_no_show_${bookingId}`);
      const penaltyTxRef = db.doc(`wallet_transactions/penalty_no_show_${bookingId}`);

      const learnerWalletSnap = await trx.get(learnerWalletRef);
      const teacherWalletSnap = await trx.get(teacherWalletRef);

      const learnerAvailable = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('availableBalance') as number | undefined) ?? 0
        : 0;
      const learnerPending = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('pendingBalance') as number | undefined) ?? 0
        : 0;
      const learnerVolunteer = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('volunteerBalance') as number | undefined) ?? 0
        : 0;
      const learnerCurrency = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('currency') as string | undefined) ?? 'USD'
        : 'USD';
      const learnerKyc = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('kycStatus') as string | undefined) ?? 'none'
        : 'none';
      const learnerThreshold = learnerWalletSnap.exists
        ? (learnerWalletSnap.get('withdrawalThreshold') as number | undefined) ?? 500
        : 500;

      const teacherAvailable = teacherWalletSnap.exists
        ? (teacherWalletSnap.get('availableBalance') as number | undefined) ?? 0
        : 0;
      const teacherPending = teacherWalletSnap.exists
        ? (teacherWalletSnap.get('pendingBalance') as number | undefined) ?? 0
        : 0;
      const teacherVolunteer = teacherWalletSnap.exists
        ? (teacherWalletSnap.get('volunteerBalance') as number | undefined) ?? 0
        : 0;
      const teacherCurrency = teacherWalletSnap.exists
        ? (teacherWalletSnap.get('currency') as string | undefined) ?? 'USD'
        : 'USD';
      const teacherKyc = teacherWalletSnap.exists
        ? (teacherWalletSnap.get('kycStatus') as string | undefined) ?? 'none'
        : 'none';
      const teacherThreshold = teacherWalletSnap.exists
        ? (teacherWalletSnap.get('withdrawalThreshold') as number | undefined) ?? 500
        : 500;

      const availableDeduction = Math.min(teacherAvailable, policyAmount);
      const remaining = Math.max(0, policyAmount - availableDeduction);
      const pendingDeduction = Math.min(teacherPending, remaining);
      const totalDeduction = availableDeduction + pendingDeduction;

      trx.set(
        learnerWalletRef,
        {
          uid: after.learnerId,
          pendingBalance: learnerPending,
          availableBalance: learnerAvailable + policyAmount,
          volunteerBalance: learnerVolunteer,
          currency: learnerCurrency,
          kycStatus: learnerKyc,
          withdrawalThreshold: learnerThreshold,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      trx.set(
        teacherWalletRef,
        {
          uid: after.teacherId,
          pendingBalance: Math.max(0, teacherPending - pendingDeduction),
          availableBalance: Math.max(0, teacherAvailable - availableDeduction),
          volunteerBalance: teacherVolunteer,
          currency: teacherCurrency,
          kycStatus: teacherKyc,
          withdrawalThreshold: teacherThreshold,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      trx.create(refundTxRef, {
        txId: `refund_no_show_${bookingId}`,
        uid: after.learnerId,
        type: 'refund',
        sourceBookingId: bookingId,
        amount: policyAmount,
        currency: learnerCurrency,
        bucket: 'available',
        withdrawable: false,
        status: 'applied',
        metadata: {
          reason: 'teacher_no_show',
        },
        createdAt: FieldValue.serverTimestamp(),
      });

      trx.create(penaltyTxRef, {
        txId: `penalty_no_show_${bookingId}`,
        uid: after.teacherId,
        type: 'penalty',
        sourceBookingId: bookingId,
        amount: totalDeduction,
        currency: teacherCurrency,
        bucket: 'available',
        withdrawable: false,
        status: 'applied',
        metadata: {
          reason: 'teacher_no_show',
          intendedPenaltyAmount: policyAmount,
        },
        createdAt: FieldValue.serverTimestamp(),
      });

      penaltyApplied = true;
      penaltyAmount = totalDeduction;

      trx.set(
        qualityEventRef,
        {
          eventId: `no_show_warning_${bookingId}`,
          teacherId: after.teacherId,
          windowSize: 0,
          rollingAverage: 0,
          action: 'warning',
          reason: 'teacher_no_show',
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: false },
      );
    }

    trx.create(noShowRef, {
      eventId,
      bookingId,
      teacherId: after.teacherId,
      learnerId: after.learnerId,
      actor: noShowActor,
      penaltyApplied,
      penaltyAmount,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info('bookingNoShowPolicyHook: no-show event recorded', {
    bookingId,
    eventId,
  });
});

// P2-008: quality protection automation from review stream.
export const reviewQualityPolicyHook = onDocumentCreated('reviews/{reviewId}', async (event) => {
  const review = event.data?.data() as Record<string, unknown> | undefined;
  if (!review) {
    return;
  }

  const teacherId =
    typeof review.teacherId === 'string' && review.teacherId.length > 0
      ? review.teacherId
      : null;

  if (teacherId == null) {
    logger.warn('reviewQualityPolicyHook: review missing teacherId', {
      reviewId: event.params.reviewId,
    });
    return;
  }

  const db = getFirestore();
  const eventId = `quality_${event.params.reviewId}`;
  const qualityEventRef = db.doc(`teacher_quality_events/${eventId}`);
  const userRef = db.doc(`users/${teacherId}`);

  await db.runTransaction(async (trx) => {
    const existingEvent = await trx.get(qualityEventRef);
    if (existingEvent.exists) {
      return;
    }

    const userSnap = await trx.get(userRef);
    const teachingEnabled = userSnap.exists
      ? (userSnap.get('teachingModeEnabled') as boolean | undefined) ?? false
      : false;

    const recentReviewsSnap = await trx.get(
      db
          .collection('reviews')
          .where('teacherId', '==', teacherId)
          .orderBy('createdAt', 'desc')
          .limit(QUALITY_WINDOW_SIZE),
    );

    const scores: number[] = [];
    for (const doc of recentReviewsSnap.docs) {
      const score = reviewScore(doc.data());
      if (score != null) {
        scores.push(score);
      }
    }

    if (scores.length === 0) {
      trx.set(
        qualityEventRef,
        {
          eventId,
          teacherId,
          windowSize: 0,
          rollingAverage: 0,
          action: 'warning',
          reason: 'no_scores_available',
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: false },
      );
      return;
    }

    const total = scores.reduce((sum, value) => sum + value, 0);
    const rollingAverage = total / scores.length;

    let action = 'warning';
    let reason = 'low_quality_warning';
    let nextTeachingModeEnabled: boolean | null = null;

    if (rollingAverage < QUALITY_FREEZE_THRESHOLD) {
      action = 'freeze';
      reason = 'rolling_average_below_freeze_threshold';
      nextTeachingModeEnabled = false;
    } else if (!teachingEnabled && rollingAverage >= QUALITY_UNFREEZE_THRESHOLD) {
      action = 'unfreeze';
      reason = 'rolling_average_recovered';
      nextTeachingModeEnabled = true;
    } else if (rollingAverage < QUALITY_WARNING_THRESHOLD) {
      action = 'warning';
      reason = 'rolling_average_below_warning_threshold';
    } else {
      action = 'warning';
      reason = 'quality_within_threshold';
    }

    trx.set(
      qualityEventRef,
      {
        eventId,
        teacherId,
        windowSize: scores.length,
        rollingAverage,
        action,
        reason,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: false },
    );

    if (nextTeachingModeEnabled != null) {
      trx.set(
        userRef,
        {
          teachingModeEnabled: nextTeachingModeEnabled,
          qualityGuard: {
            status: action,
            rollingAverage,
            updatedAt: FieldValue.serverTimestamp(),
          },
        },
        { merge: true },
      );
    }
  });

  logger.info('reviewQualityPolicyHook: processed quality action', {
    reviewId: event.params.reviewId,
    teacherId,
  });
});
