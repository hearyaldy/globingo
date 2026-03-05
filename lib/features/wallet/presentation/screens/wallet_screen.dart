import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../mode_switch/presentation/providers/mode_provider.dart';
import '../../data/models/wallet_models.dart';
import '../../data/repositories/wallet_repository.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final WalletRepository _walletRepository = WalletRepository();
  final TextEditingController _withdrawAmountController =
      TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _withdrawAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view wallet.'));
    }

    final isMobile = Responsive.isMobile(context);
    final mode = ref.watch(modeProvider);
    final isTeachingMode = mode == AppMode.teaching;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _walletRepository.watchWalletSummary(user.uid),
      builder: (context, summarySnapshot) {
        if (summarySnapshot.hasError) {
          return _WalletLoadError(
            title: 'Failed to load wallet summary.',
            error: summarySnapshot.error,
            uid: user.uid,
          );
        }
        if (!summarySnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = _walletRepository.mapWalletSummary(
          summarySnapshot.data!,
        );

        return SingleChildScrollView(
          padding: Responsive.screenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTeachingMode ? 'Teaching Wallet' : 'Learning Wallet',
                style: AppTypography.h1,
              ),
              const SizedBox(height: 8),
              Text(
                isTeachingMode
                    ? 'Track your earnings, pending releases, and payout requests.'
                    : 'Track your credits, refunds, and learning-side transactions.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _buildSummaryCards(summary, isMobile, isTeachingMode),
              const SizedBox(height: 20),
              _buildWithdrawCard(summary, isTeachingMode),
              const SizedBox(height: 20),
              _buildTransactionsSection(summary.uid),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(
    WalletSummary summary,
    bool isMobile,
    bool isTeachingMode,
  ) {
    final cards = [
      _BalanceCard(
        label: isTeachingMode ? 'Available Payout' : 'Available Credits',
        value: summary.availableBalance,
        color: AppColors.success,
        currency: summary.currency,
      ),
      _BalanceCard(
        label: isTeachingMode ? 'Pending Release' : 'Pending Credits',
        value: summary.pendingBalance,
        color: AppColors.warning,
        currency: summary.currency,
      ),
      _BalanceCard(
        label: 'Volunteer',
        value: summary.volunteerBalance,
        color: AppColors.info,
        currency: summary.currency,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildWithdrawCard(WalletSummary summary, bool isTeachingMode) {
    final kycReady = summary.kycStatus == WalletKycStatus.verified;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTeachingMode ? 'Withdraw' : 'Payouts',
            style: AppTypography.h4,
          ),
          const SizedBox(height: 6),
          if (!isTeachingMode)
            Text(
              'Withdrawal requests are available in Teaching mode. Switch mode to request payouts.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Text(
              'KYC: ${_formatKyc(summary.kycStatus)} • Minimum: ${summary.withdrawalThreshold.toStringAsFixed(0)} ${summary.currency}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _withdrawAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'Enter amount (${summary.currency})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitWithdrawal(summary),
                  icon: const Icon(Icons.request_page_outlined),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Request Withdrawal',
                  ),
                ),
                if (!kycReady)
                  Text(
                    'KYC must be verified before requesting withdrawal.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(String uid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transactions', style: AppTypography.h4),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _walletRepository.watchWalletTransactions(uid),
            builder: (context, txSnapshot) {
              if (txSnapshot.hasError) {
                return _WalletLoadError(
                  title: 'Failed to load transactions.',
                  error: txSnapshot.error,
                  uid: uid,
                );
              }
              if (!txSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final records = txSnapshot.data!.docs
                  .map(_walletRepository.mapWalletTransaction)
                  .toList();
              records.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (records.isEmpty) {
                return Text(
                  'No transactions yet.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              }

              return Column(
                children: [
                  for (int i = 0; i < records.length; i++) ...[
                    _TransactionTile(record: records[i]),
                    if (i < records.length - 1)
                      const Divider(color: AppColors.borderLight, height: 20),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitWithdrawal(WalletSummary summary) async {
    final raw = _withdrawAmountController.text.trim();
    final amount = double.tryParse(raw);

    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid amount.', isError: true);
      return;
    }

    if (summary.kycStatus != WalletKycStatus.verified) {
      _showMessage('KYC must be verified.', isError: true);
      return;
    }

    if (amount < summary.withdrawalThreshold) {
      _showMessage(
        'Amount must be at least ${summary.withdrawalThreshold.toStringAsFixed(0)} ${summary.currency}.',
        isError: true,
      );
      return;
    }

    if (amount > summary.availableBalance) {
      _showMessage('Amount exceeds available balance.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _walletRepository.requestWithdrawal(
        uid: summary.uid,
        amount: amount,
      );
      _withdrawAmountController.clear();
      _showMessage('Withdrawal request submitted.');
    } catch (_) {
      _showMessage('Failed to submit withdrawal request.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatKyc(WalletKycStatus status) {
    switch (status) {
      case WalletKycStatus.none:
        return 'none';
      case WalletKycStatus.pending:
        return 'pending';
      case WalletKycStatus.verified:
        return 'verified';
      case WalletKycStatus.rejected:
        return 'rejected';
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String currency;

  const _BalanceCard({
    required this.label,
    required this.value,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(2)} $currency',
            style: AppTypography.h3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransactionRecord record;

  const _TransactionTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isDebit =
        record.type == 'withdrawal' ||
        record.type == 'penalty' ||
        record.type == 'payment_out';
    final amountColor = isDebit ? AppColors.error : AppColors.success;
    final sign = isDebit ? '-' : '+';

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDebit ? Icons.remove_circle_outline : Icons.add_circle_outline,
            color: amountColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.type.replaceAll('_', ' '),
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                'Status: ${record.status.name} • Bucket: ${record.bucket.name}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          '$sign${record.amount.toStringAsFixed(2)} ${record.currency}',
          style: AppTypography.labelLarge.copyWith(color: amountColor),
        ),
      ],
    );
  }
}

class _WalletLoadError extends StatelessWidget {
  final String title;
  final Object? error;
  final String uid;

  const _WalletLoadError({
    required this.title,
    required this.error,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    String details = 'Unknown error';

    if (error is FirebaseException) {
      final firebaseError = error as FirebaseException;
      details = 'code=${firebaseError.code}, message=${firebaseError.message}';
    } else if (error != null) {
      details = error.toString();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h4.copyWith(color: AppColors.error)),
          const SizedBox(height: 8),
          Text(
            'UID: $uid',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            details,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
