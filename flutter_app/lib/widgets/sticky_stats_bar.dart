import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class StickyStatsBar extends StatelessWidget {
  final AppState appState;

  const StickyStatsBar({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;
    final res = appState.result;

    final displayGrandTotal = appState.billingMode == 'actual' && !appState.minBilling
        ? res.grandTotal
        : res.billingGrandTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              label: 'WINDOWS',
              value: '${res.totalWindows}',
              color: AppTheme.accentCyan,
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildStatItem(
              label: 'ACTUAL SQFT',
              value: res.totalSqft.toStringAsFixed(1),
              color: Colors.white,
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildStatItem(
              label: 'BILL SQFT',
              value: res.billingSqft.toStringAsFixed(1),
              color: AppTheme.accentAmber,
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildStatItem(
              label: 'ALU WT (KG)',
              value: res.totalWeight.toStringAsFixed(1),
              color: AppTheme.accentEmerald,
              isDark: isDark,
            ),
            _buildDivider(isDark),
            _buildStatItem(
              label: 'TOTAL',
              value: '₹${displayGrandTotal.toStringAsFixed(0)}',
              color: AppTheme.accentCyan,
              isDark: isDark,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool isBold = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: isDark ? color : (isBold ? AppTheme.primaryBlue : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 22,
      width: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
    );
  }
}
