import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_flow_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

/// Subscription UI — business logic lives in [SubscriptionProvider].
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authFlow = context.read<AuthFlowProvider>();
      context.read<SubscriptionProvider>().loadDetails(authFlow);
    });
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    DateTime date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else {
      return '—';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatAmount(dynamic amount, dynamic currency) {
    if (amount == null) return '—';
    final num value = amount is num ? amount : double.tryParse(amount.toString()) ?? 0;
    final code = (currency as String?)?.toUpperCase() ?? 'USD';
    return '\$${value.toStringAsFixed(2)} $code';
  }

  Future<void> _confirmCancel(SubscriptionProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Subscription', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features.',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Subscription', style: GoogleFonts.roboto(color: Color(0xFF8B4513))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel', style: GoogleFonts.roboto(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final authFlow = context.read<AuthFlowProvider>();
    final success = await provider.cancelSubscription(authFlow);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription cancelled successfully', style: GoogleFonts.roboto()),
          backgroundColor: Colors.green,
        ),
      );
      // AuthWrapper switches to LandingPage via cancelSubscription → loadDetails.
      // popUntilRoot only — avoid pop() after lifecycle redirect already cleared the stack.
      context.read<NavigationProvider>().popUntilRoot();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to cancel subscription: ${provider.errorMessage ?? 'Unknown error'}',
            style: GoogleFonts.roboto(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8E8D0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9A826),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Subscription',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B4513)))
          : provider.details == null
              ? _buildEmptyState()
              : _buildSubscriptionContent(provider),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_membership, size: 64, color: Color(0xFF8B4513).withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No subscription found',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have an active subscription plan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionContent(SubscriptionProvider provider) {
    final details = provider.details!;
    final planType = details['planType'] as String?;
    final isActive = provider.isActive;
    final statusLabel = provider.statusLabel;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(provider, statusLabel, isActive),
                const SizedBox(height: 16),
                _buildDetailsCard(
                  title: 'Plan',
                  icon: Icons.workspace_premium,
                  children: [
                    _detailRow('Plan Name', provider.planDisplayName(planType)),
                    _detailRow('Billing', planType == 'yearly' ? 'Yearly' : 'Monthly'),
                    _detailRow('Amount', _formatAmount(details['amount'], details['currency'])),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailsCard(
                  title: 'Billing Period',
                  icon: Icons.calendar_today,
                  children: [
                    _detailRow('Start Date', _formatDate(details['startDate'])),
                    _detailRow('Renewal / Expiry', _formatDate(details['expiryDate'])),
                    _detailRow('Status', statusLabel),
                    if (details['cancelledAt'] != null)
                      _detailRow('Cancelled On', _formatDate(details['cancelledAt'])),
                  ],
                ),
                if (details['paymentIntentId'] != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailsCard(
                    title: 'Payment',
                    icon: Icons.payment,
                    children: [
                      _detailRow(
                        'Payment ID',
                        details['paymentIntentId'].toString(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isActive) _buildCancelButton(provider),
      ],
    );
  }

  Widget _buildStatusCard(SubscriptionProvider provider, String statusText, bool isActive) {
    final Color statusColor = isActive
        ? Colors.green
        : statusText == 'Cancelled'
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9A826), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.subscriptions, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.planDisplayName(provider.details!['planType'] as String?),
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8B4513), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B4513),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(SubscriptionProvider provider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: provider.isCancelling ? null : () => _confirmCancel(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              elevation: 2,
            ),
            child: provider.isCancelling
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Cancel Subscription',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
