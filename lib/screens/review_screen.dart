import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../theme/app_theme.dart';

/// Screen for reviewing and editing extracted receipt details before saving (Step 3).
///
/// In Step 2, this serves as a verified landing destination receiving the [Receipt]
/// parsed by Gemini from Workflow A.
class ReviewScreen extends StatefulWidget {
  final Receipt? receipt;

  const ReviewScreen({super.key, this.receipt});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Receipt')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'STEP 3 PREVIEW',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Extracted Receipt',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Data successfully extracted by Gemini via n8n Workflow A.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              if (receipt != null) ...[
                // Low confidence warning banner (< 0.7)
                if (receipt.confidence != null && receipt.confidence! < 0.7)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.warning,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Low confidence extraction (${(receipt.confidence! * 100).round()}%). Please verify fields carefully in Step 3.',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Card showing extracted fields
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Merchant', receipt.merchant),
                      const Divider(height: 24),
                      _buildReceiptRow('Date', receipt.date),
                      const Divider(height: 24),
                      _buildReceiptRow(
                        'Amount',
                        '${receipt.amount.toStringAsFixed(2)} ${receipt.currency}',
                        isEmphasized: true,
                      ),
                      const Divider(height: 24),
                      _buildReceiptRow(
                        'Category',
                        receipt.category.displayName,
                        icon: receipt.category.icon,
                      ),
                      if (receipt.confidence != null) ...[
                        const Divider(height: 24),
                        _buildReceiptRow(
                          'Confidence',
                          '${(receipt.confidence! * 100).toStringAsFixed(1)}%',
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Empty placeholder if opened directly without a receipt
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No receipt passed yet. Capture and analyze a receipt first.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Educational reminder about Step 3
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Full editable form, input validation, and Workflow B save will be implemented in Step 3.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Back button
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Capture'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isEmphasized = false,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: isEmphasized ? 16 : 14,
                fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w600,
                color: isEmphasized ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
