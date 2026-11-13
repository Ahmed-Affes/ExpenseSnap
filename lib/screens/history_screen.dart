import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Screen for displaying monthly expense history and totals (Step 4).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense History')),
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
                  Icons.history_outlined,
                  size: 40,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Expense History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ready for Step 4 implementation.\nBrowse monthly expenses, filter by month, and track your total spending.',
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
                        'History Screen will be implemented in Step 4',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('History List (Step 4)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
