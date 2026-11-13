import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/receipt.dart';
import '../services/n8n_service.dart';
import '../theme/app_theme.dart';
import 'review_screen.dart';

/// Capture Screen: allows taking a receipt photo or picking from gallery,
/// validates the image, and sends it to the n8n Gemini workflow for analysis (Step 2).
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final N8nService _n8nService = N8nService();

  File? _selectedImage;
  bool _isAnalyzing = false;

  /// Maximum allowed file size for Workflow A (5 MB)
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  /// Selects an image using camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    if (_isAnalyzing) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90, // Optimize quality while staying well below 5 MB
      );

      // User cancelled picker
      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      // Validate file extension (JPEG and PNG only)
      final pathLower = pickedFile.path.toLowerCase();
      final isJpeg = pathLower.endsWith('.jpg') || pathLower.endsWith('.jpeg');
      final isPng = pathLower.endsWith('.png');

      if (!isJpeg && !isPng) {
        _showErrorSnackBar(
          'Unsupported format. Please select a JPG or PNG image.',
        );
        return;
      }

      // Validate file size
      final fileSize = await file.length();
      if (fileSize > _maxFileSizeBytes) {
        _showErrorSnackBar('Image is too large. Maximum file size is 5 MB.');
        return;
      }

      setState(() {
        _selectedImage = file;
      });
    } catch (e) {
      _showErrorSnackBar('Could not select image. Please try again.');
    }
  }

  /// Clears the currently selected receipt image
  void _clearImage() {
    if (_isAnalyzing) return;
    setState(() {
      _selectedImage = null;
    });
  }

  /// Calls n8n Workflow A to analyze the receipt with Gemini
  Future<void> _analyzeReceipt() async {
    if (_selectedImage == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final Receipt extractedReceipt = await _n8nService.analyze(
        _selectedImage!,
      );

      if (!mounted) return;

      // Navigate to Review Screen with the extracted receipt data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewScreen(receipt: extractedReceipt),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Display friendly error message without exposing technical secrets
      String message =
          'Failed to analyze receipt. Please check your connection and try again.';
      if (e is ReceiptException) {
        message = e.message;
      }

      _showErrorSnackBar(message);
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  /// Displays styled error feedback
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Helper to format file size for display
  String _getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('ExpenseSnap'),
          ],
        ),
        actions: [
          if (_selectedImage != null && !_isAnalyzing)
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Reset image',
              onPressed: _clearImage,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'EXPENSE EXTRACTION',
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
                'Scan a receipt',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Take a photo or choose an existing receipt to automatically extract merchant, date, amount, and category.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Upload / Preview area
              _buildUploadPreviewArea(),

              const SizedBox(height: 20),

              // Image Source Action Buttons (Camera / Gallery)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 20),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Primary "Analyze Receipt" button
              ElevatedButton(
                onPressed: (_isAnalyzing || _selectedImage == null)
                    ? null
                    : _analyzeReceipt,
                child: _isAnalyzing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Analyzing receipt with Gemini...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 8),
                          Text('Analyze Receipt'),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Trust / Security footer
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Directly processed via your secure n8n backend.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the receipt image preview or the empty upload box
  Widget _buildUploadPreviewArea() {
    if (_selectedImage != null) {
      // Selected image preview state
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  if (!_isAnalyzing)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                          tooltip: 'Remove photo',
                          onPressed: _clearImage,
                        ),
                      ),
                    ),
                  if (_isAnalyzing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Reading receipt details...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: FutureBuilder<int>(
                future: _selectedImage!.length(),
                builder: (context, snapshot) {
                  final sizeText = snapshot.hasData
                      ? _getFileSizeString(snapshot.data!)
                      : 'Checking size...';
                  final fileName = _selectedImage!.path
                      .split(RegExp(r'[/\\]'))
                      .last;

                  return Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        sizeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // Empty state container
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No receipt selected yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Take a photo with your camera or select an image from your device gallery.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
                SizedBox(width: 6),
                Text(
                  'JPG or PNG · Max 5 MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
