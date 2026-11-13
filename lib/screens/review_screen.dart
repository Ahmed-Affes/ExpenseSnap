import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../services/n8n_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';

/// Screen for reviewing, editing, and saving extracted receipt details (Step 3).
///
/// Pre-fills fields with data extracted by Gemini (Workflow A) and submits
/// approved receipt data to Google Sheets via n8n (Workflow B).
class ReviewScreen extends StatefulWidget {
  final Receipt? receipt;

  const ReviewScreen({super.key, this.receipt});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final N8nService _n8nService = N8nService();

  late TextEditingController _merchantController;
  late TextEditingController _dateController;
  late TextEditingController _amountController;
  late TextEditingController _currencyController;
  late ReceiptCategory _selectedCategory;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.receipt;

    _merchantController = TextEditingController(text: r?.merchant ?? '');

    // Format initial date to YYYY-MM-DD (defaults to today if empty)
    String initialDate = '';
    if (r != null && r.date.trim().isNotEmpty) {
      initialDate = r.date.trim();
    } else {
      final now = DateTime.now();
      initialDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
    _dateController = TextEditingController(text: initialDate);

    _amountController = TextEditingController(
      text: (r != null && r.amount > 0) ? r.amount.toStringAsFixed(2) : '',
    );

    _currencyController = TextEditingController(
      text: (r != null && r.currency.isNotEmpty) ? r.currency : 'TND',
    );

    _selectedCategory = r?.category ?? ReceiptCategory.other;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  /// Opens standard Material date picker for selecting purchase date
  Future<void> _pickDate() async {
    if (_isSaving) return;

    DateTime initialDate = DateTime.now();
    final parsed = DateTime.tryParse(_dateController.text.trim());
    if (parsed != null && !parsed.isAfter(DateTime.now())) {
      initialDate = parsed;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Purchase date cannot be in the future
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _dateController.text = formatted;
      });
    }
  }

  /// Validates the form and sends approved receipt to n8n Workflow B
  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final rawAmount = _amountController.text.trim().replaceAll(',', '.');
      final parsedAmount = double.parse(rawAmount);

      // Build updated Receipt object preserving original confidence and ID
      final updatedReceipt = Receipt(
        id: widget.receipt?.id,
        createdAt: widget.receipt?.createdAt,
        merchant: _merchantController.text.trim(),
        date: _dateController.text.trim(),
        amount: parsedAmount,
        currency: _currencyController.text.trim().toUpperCase(),
        category: _selectedCategory,
        confidence: widget.receipt?.confidence,
      );

      // Call n8n Workflow B (POST /receipts)
      await _n8nService.save(updatedReceipt);

      if (!mounted) return;

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Receipt saved successfully.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to History Screen replacing the Review screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HistoryScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      String message = 'Failed to save receipt. Please try again.';
      if (e is ReceiptException) {
        message = e.message;
      }

      _showErrorSnackBar(message);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Shows floating styled error message
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

  @override
  Widget build(BuildContext context) {
    final confidence = widget.receipt?.confidence;
    final hasLowConfidence = confidence != null && confidence < 0.7;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Receipt')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'AI EXTRACTED DETAILS',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Review receipt',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check the extracted details before saving.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),

                // Confidence Warning Banner (displayed ONLY if confidence < 0.7)
                if (hasLowConfidence)
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Some details may be inaccurate. Please review them carefully.',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Merchant Name
                      const Text(
                        'Merchant Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _merchantController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Monoprix, Shell, Carrefour',
                          prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Merchant name cannot be empty';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Field 2: Purchase Date
                      const Text(
                        'Purchase Date',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: const InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                          ),
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Purchase date is required';
                          }
                          final parsed = DateTime.tryParse(value.trim());
                          if (parsed == null) {
                            return 'Please enter a valid date (YYYY-MM-DD)';
                          }
                          // Verify date is not in the future
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final selectedDay = DateTime(
                            parsed.year,
                            parsed.month,
                            parsed.day,
                          );
                          if (selectedDay.isAfter(today)) {
                            return 'Purchase date cannot be in the future';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Field 3 & 4: Amount & Currency
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _amountController,
                                  enabled: !_isSaving,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: '0.00',
                                    prefixIcon: Icon(
                                      Icons.payments_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter amount';
                                    }
                                    final parsed = double.tryParse(
                                      value.trim().replaceAll(',', '.'),
                                    );
                                    if (parsed == null || parsed <= 0) {
                                      return 'Must be > 0';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Currency
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Currency',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _currencyController,
                                  enabled: !_isSaving,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    hintText: 'TND',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Field 5: Category
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ReceiptCategory>(
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            _selectedCategory.icon,
                            size: 20,
                            color: AppTheme.primary,
                          ),
                        ),
                        items: ReceiptCategory.values.map((category) {
                          return DropdownMenuItem<ReceiptCategory>(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    category.displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _isSaving
                            ? null
                            : (category) {
                                if (category != null) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),

                      // Extraction confidence pill if available
                      if (confidence != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Extraction confidence: ${(confidence * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Receipt Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveReceipt,
                  child: _isSaving
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
                            Text('Saving to Google Sheets...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Save Receipt'),
                          ],
                        ),
                ),

                const SizedBox(height: 12),

                // Discard / Retake Button
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Discard & Retake'),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
