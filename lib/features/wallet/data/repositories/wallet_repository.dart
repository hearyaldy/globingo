import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wallet_models.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;

  WalletRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchWalletSummary(
    String uid,
  ) {
    return _firestore.collection('wallets').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchWalletTransactions(
    String uid,
  ) {
    return _firestore
        .collection('wallet_transactions')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  Future<void> requestWithdrawal({
    required String uid,
    required double amount,
  }) {
    // Backend policy engine validates KYC + threshold + balance.
    return _firestore.collection('wallet_withdrawal_requests').add({
      'uid': uid,
      'amount': amount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  WalletSummary mapWalletSummary(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return WalletSummary(
      uid: (data['uid'] as String?) ?? snapshot.id,
      pendingBalance: (data['pendingBalance'] as num?)?.toDouble() ?? 0,
      availableBalance: (data['availableBalance'] as num?)?.toDouble() ?? 0,
      volunteerBalance: (data['volunteerBalance'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] as String?) ?? 'USD',
      kycStatus: _mapKycStatus(data['kycStatus'] as String?),
      withdrawalThreshold:
          (data['withdrawalThreshold'] as num?)?.toDouble() ?? 500,
    );
  }

  WalletKycStatus _mapKycStatus(String? value) {
    switch (value) {
      case 'pending':
        return WalletKycStatus.pending;
      case 'verified':
        return WalletKycStatus.verified;
      case 'rejected':
        return WalletKycStatus.rejected;
      case 'none':
      default:
        return WalletKycStatus.none;
    }
  }

  WalletTransactionRecord mapWalletTransaction(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return WalletTransactionRecord(
      id: snapshot.id,
      uid: (data['uid'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'unknown',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] as String?) ?? 'USD',
      bucket: _mapBucket(data['bucket'] as String?),
      withdrawable: (data['withdrawable'] as bool?) ?? false,
      status: _mapTransactionStatus(data['status'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  WalletBucket _mapBucket(String? value) {
    switch (value) {
      case 'available':
        return WalletBucket.available;
      case 'volunteer':
        return WalletBucket.volunteer;
      case 'pending':
      default:
        return WalletBucket.pending;
    }
  }

  WalletTransactionStatus _mapTransactionStatus(String? value) {
    switch (value) {
      case 'applied':
        return WalletTransactionStatus.applied;
      case 'reversed':
        return WalletTransactionStatus.reversed;
      case 'failed':
        return WalletTransactionStatus.failed;
      case 'pending':
      default:
        return WalletTransactionStatus.pending;
    }
  }
}
