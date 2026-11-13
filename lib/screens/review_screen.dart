import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../theme/app_theme.dart';

/// Screen for reviewing and editing extracted receipt details before saving (Step 3).
class ReviewScreen extends StatefulWidget {
  final Receipt? receipt;

  const ReviewScreen({super.key, this.receipt});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Receipt')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.edit_note_outlined,
                  size: 40,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Review & Validate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ready for Step 3 implementation.\nEdit merchant, date, amount, currency, and category with live validation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Review Screen will be implemented in Step 3',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Review Form (Step 3)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
