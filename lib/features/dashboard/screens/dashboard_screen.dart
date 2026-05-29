import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Our new charting library!
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/services/invoice_service.dart';
import '../../invoices/screens/create_invoice_screen.dart';
import '../../customers/screens/customers_screen.dart';
import '../../payments/screens/payments_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Overview',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // We replace the single logout button with a sleek dropdown menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().signOut();
              } else if (value == 'delete') {
                _showDeleteAccountDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 8),
                    Text('Log Out'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: AppColors.error,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Delete Account',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        // We wrap the body in a StreamBuilder listening to the SAME invoice stream
        child: StreamBuilder<List<InvoiceModel>>(
          stream: InvoiceService().getInvoicesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final invoices = snapshot.data ?? [];

            // 1. Calculate the Derived State (Accurate Math!)
            double totalOutstanding = 0;
            double totalPaid = 0;

            for (var invoice in invoices) {
              if (invoice.status == 'Paid') {
                // If the status is officially Paid, the entire amount counts as paid!
                totalPaid += invoice.amount;
              } else {
                // If it is Pending, we split it based on partial payments
                totalPaid += invoice.amountPaid;
                totalOutstanding += (invoice.amount - invoice.amountPaid);
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(totalOutstanding),
                  const SizedBox(height: 24),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),

                  const Text(
                    'Revenue Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  invoices.isEmpty
                      ? const Text(
                          'Create an invoice to see your analytics.',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      : _buildAnalyticsChart(totalOutstanding, totalPaid),

                  const SizedBox(height: 32), // Add some spacing
                  // NEW: Inject the pending list right at the bottom!
                  _buildPendingActionList(invoices),

                  const SizedBox(
                    height: 40,
                  ), // Bottom padding so it doesn't hug the nav bar
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // We now pass the dynamic total into the summary card
  Widget _buildSummaryCard(double totalOutstanding) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Outstanding',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalOutstanding.toStringAsFixed(2)}', // Dynamic data formatting
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionCard(
          icon: Icons.add,
          title: 'New Invoice',
          onTap: () {
            // Pushes the full screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateInvoiceScreen(),
              ),
            );
          },
        ),
        _ActionCard(
          icon: Icons.person_add,
          title: 'Add Client',
          onTap: () {
            // Opens the public bottom sheet from the Customers file!
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddCustomerForm(),
            );
          },
        ),
        _ActionCard(
          icon: Icons.payment,
          title: 'Record Pay',
          onTap: () {
            // Opens the public bottom sheet from the Payments file!
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const RecordPaymentForm(),
            );
          },
        ),
      ],
    );
  }

  // ============================================================================
  // 1. THE DONUT CHART & LEGEND
  // ============================================================================
  Widget _buildAnalyticsChart(double pending, double paid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Left Side: The Donut Chart
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 140, // Slightly smaller to fit nicely
              child: PieChart(
                PieChartData(
                  sectionsSpace:
                      0, // Removes the gap between slices for a clean look
                  centerSpaceRadius:
                      40, // This hollows out the middle to make it a DONUT!
                  sections: [
                    PieChartSectionData(
                      color: Colors.orange,
                      value: pending,
                      title: '', // We hide the titles inside the chart now
                      radius: 25,
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: paid,
                      title: '',
                      radius: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Right Side: The Legend
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendIndicator(
                  color: Colors.green,
                  title: 'Paid',
                  amount: paid,
                ),
                const SizedBox(height: 16),
                _buildLegendIndicator(
                  color: Colors.orange,
                  title: 'Pending',
                  amount: pending,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator({
    required Color color,
    required String title,
    required double amount,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // 2. THE NEW PENDING CUSTOMERS LIST
  // ============================================================================
  Widget _buildPendingActionList(List<InvoiceModel> allInvoices) {
    final pendingInvoices = allInvoices
        .where((inv) => inv.status == 'Pending')
        .toList();

    if (pendingInvoices.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort them so the most overdue/oldest ones appear at the top!
    pendingInvoices.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Action Required',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          // We use a Column mapping instead of ListView.builder because it's already inside a SingleChildScrollView
          child: Column(
            children: pendingInvoices.asMap().entries.map((entry) {
              final index = entry.key;
              final invoice = entry.value;
              final remaining = invoice.amount - invoice.amountPaid;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      invoice.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Due: ${invoice.dueDate.month}/${invoice.dueDate.day}/${invoice.dueDate.year}',
                    ),
                    trailing: Text(
                      '₹${remaining.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Add a divider between items, but not after the very last item
                  if (index != pendingInvoices.length - 1)
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Colors.grey.shade200,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isDeleting = false; // Local state for the dialog's loading spinner

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Delete Account?',
                style: TextStyle(color: AppColors.error),
              ),
              content: const Text(
                'This action is permanent and cannot be undone. All of your invoices, customers, and payment data will be permanently erased.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await AuthService().deleteAccount();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext); // Close the dialog
                              // Our AuthGate in main.dart will automatically see the user is gone
                              // and instantly snap them back to the Login Screen!
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(
                                dialogContext,
                              ); // Close the dialog first
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Delete Permanently',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
