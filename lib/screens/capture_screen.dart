import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Screen for capturing or picking a receipt photo to analyze (Step 2).
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Receipt')),
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
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Receipt Capture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ready for Step 2 implementation.\nTake a photo or choose an image to analyze with Gemini.',
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
                        'Capture Screen will be implemented in Step 2',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Capture Flow (Step 2)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
