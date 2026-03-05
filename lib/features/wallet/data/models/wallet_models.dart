enum WalletKycStatus { none, pending, verified, rejected }

enum WalletBucket { pending, available, volunteer }

enum WalletTransactionStatus { pending, applied, reversed, failed }

class WalletSummary {
  final String uid;
  final double pendingBalance;
  final double availableBalance;
  final double volunteerBalance;
  final String currency;
  final WalletKycStatus kycStatus;
  final double withdrawalThreshold;

  const WalletSummary({
    required this.uid,
    required this.pendingBalance,
    required this.availableBalance,
    required this.volunteerBalance,
    required this.currency,
    required this.kycStatus,
    required this.withdrawalThreshold,
  });
}

class WalletTransactionRecord {
  final String id;
  final String uid;
  final String type;
  final double amount;
  final String currency;
  final WalletBucket bucket;
  final bool withdrawable;
  final WalletTransactionStatus status;
  final DateTime createdAt;

  const WalletTransactionRecord({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.currency,
    required this.bucket,
    required this.withdrawable,
    required this.status,
    required this.createdAt,
  });
}
