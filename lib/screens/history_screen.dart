import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../services/n8n_service.dart';
import '../theme/app_theme.dart';
import 'capture_screen.dart';

/// Screen for displaying monthly expense history, totals, and month filtering (Step 4).
///
/// Fetches saved receipt data from Google Sheets via n8n Workflow C (GET /receipts?month=YYYY-MM).
class HistoryScreen extends StatefulWidget {
  final N8nService? service;
  final VoidCallback? onNavigateToCapture;

  const HistoryScreen({super.key, this.service, this.onNavigateToCapture});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final N8nService _n8nService;

  /// Default selected month is the current month according to device date
  late DateTime _selectedMonth;

  ReceiptList? _receiptList;
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _n8nService = widget.service ?? N8nService();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _fetchHistory();
  }

  /// Formats the selected month as YYYY-MM query parameter (e.g. 2026-11)
  String get _monthParam {
    final year = _selectedMonth.year.toString().padLeft(4, '0');
    final month = _selectedMonth.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  /// Formats the selected month for human display (e.g. "November 2026")
  String get _monthDisplayName {
    return '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  /// Changes the active month by [delta] (-1 for previous, +1 for next)
  void _changeMonth(int delta) {
    if (_isLoading) return;
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _fetchHistory();
  }

  /// Calls n8n Workflow C to retrieve receipts for the current [_monthParam]
  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _n8nService.list(month: _monthParam);
      if (!mounted) return;

      setState(() {
        _receiptList = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      String message = 'Unable to load expenses. Please check your connection.';
      if (e is ReceiptException) {
        message = e.message;
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  /// Navigates to the Capture Screen to scan a new receipt
  void _navigateToCapture() {
    if (widget.onNavigateToCapture != null) {
      widget.onNavigateToCapture!();
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh expenses',
            onPressed: _isLoading ? null : _fetchHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _fetchHistory,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  child: const Text(
                    'MONTHLY OVERVIEW',
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
                  'Expense history',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track and review your monthly expenses and receipts.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),

                // Month Navigator
                _buildMonthSelector(),

                const SizedBox(height: 16),

                // Monthly Total Spending Summary Card
                _buildMonthlySummaryCard(),

                const SizedBox(height: 24),

                // Section title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (_receiptList != null && _receiptList!.items.isNotEmpty)
                      Text(
                        '${_receiptList!.items.length} total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Expense List, Loading, Empty or Error state
                _buildListContent(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Month selector with previous/next arrows and readable month/year
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: _isLoading ? null : () => _changeMonth(-1),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _monthDisplayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: _isLoading ? null : () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  /// Monthly spending summary card displaying the total from n8n API
  Widget _buildMonthlySummaryCard() {
    final totalAmount = _receiptList?.total ?? 0.0;
    final formattedTotal = '${totalAmount.toStringAsFixed(3)} TND';
    final itemsCount = _receiptList?.items.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL MONTHLY SPENDING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedTotal,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            itemsCount == 1 ? '1 saved receipt' : '$itemsCount saved receipts',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main content area (loading, error, empty, or list)
  Widget _buildListContent() {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: const Column(
          children: [
            CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 2.5,
            ),
            SizedBox(height: 16),
            Text(
              'Loading expenses...',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppTheme.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load expenses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchHistory,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
            ),
          ],
        ),
      );
    }

    final items = _receiptList?.items ?? [];

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 30,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No expenses this month',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your saved receipts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _navigateToCapture,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Scan a Receipt'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 42)),
            ),
          ],
        ),
      );
    }

    // Receipts list container
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final receipt = items[index];
          return _buildTransactionTile(receipt);
        },
      ),
    );
  }

  /// Transaction row widget displaying merchant, category icon, date, and amount
  Widget _buildTransactionTile(Receipt receipt) {
    final formattedAmount =
        '${receipt.amount.toStringAsFixed(3)} ${receipt.currency}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Category icon badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              receipt.category.icon,
              size: 20,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),

          // Merchant and date / category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.merchant,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      receipt.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '·',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        receipt.category.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Formatted financial amount
          Text(
            formattedAmount,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
