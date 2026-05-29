import 'package:finledger/features/invoices/screens/create_invoice_screen.dart';
import 'package:finledger/features/invoices/services/pdf_service.dart';
import 'package:finledger/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text(
            'Invoices',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Paid'),
            ],
          ),
        ),
        // Here is the magic! We wrap the TabBarView in a StreamBuilder
        body: StreamBuilder<List<InvoiceModel>>(
          stream: InvoiceService().getInvoicesStream(),
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Error State
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // 3. Data State
            final invoices = snapshot.data ?? [];

            return TabBarView(
              children: [
                _buildInvoiceList(invoices, 'All'),
                _buildInvoiceList(invoices, 'Pending'),
                _buildInvoiceList(invoices, 'Paid'),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateInvoiceScreen(),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // Notice we now pass the list of invoices and a filter string!
  Widget _buildInvoiceList(List<InvoiceModel> allInvoices, String filter) {
    // We filter the master list locally using Dart's .where() method
    final filteredInvoices = allInvoices.where((inv) {
      if (filter == 'All') return true;
      return inv.status == filter;
    }).toList();

    // 4. Empty State
    if (filteredInvoices.isEmpty) {
      return Center(
        child: Text(
          'No $filter invoices found.',
          style: const TextStyle(
            color: Color.fromRGBO(100, 116, 139, 1),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredInvoices.length,
      itemBuilder: (context, index) {
        final invoice = filteredInvoices[index];

        // NEW: Dismissible adds native swipe-to-delete!
        return Dismissible(
          // Every Dismissible needs a unique key so Flutter knows exactly which item to animate
          key: Key(invoice.id),

          // Only allow swiping from right to left
          direction: DismissDirection.endToStart,

          // The red background that reveals itself as you swipe
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),

          // What happens when the swipe completes? Delete from Firebase!
          onDismissed: (direction) {
            InvoiceService().deleteInvoice(invoice.id);

            // Show a quick undo/confirmation message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${invoice.clientName} invoice deleted')),
            );
          },

          // The actual card sitting on top
          child: _InvoiceCard(invoice: invoice),
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final isPaid = invoice.status == 'Paid';
    final dateStr =
        '${invoice.dueDate.month}/${invoice.dueDate.day}/${invoice.dueDate.year}';
    final remainingBalance = invoice.amount - invoice.amountPaid;

    // NEW: DEADLINE TRACKING!
    // Strip the exact time off 'now' so we only compare the calendar days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      invoice.dueDate.year,
      invoice.dueDate.month,
      invoice.dueDate.day,
    );

    // It is overdue if it is NOT paid, and the due date is strictly BEFORE today
    final isOverdue = !isPaid && due.isBefore(today);

    // Dynamic text based on partial payments
    String amountDisplay;
    if (isPaid) {
      amountDisplay = '₹${invoice.amount.toStringAsFixed(2)}';
    } else if (invoice.amountPaid > 0) {
      amountDisplay = '₹${remainingBalance.toStringAsFixed(2)} left';
    } else {
      amountDisplay = '₹${invoice.amount.toStringAsFixed(2)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          invoice.clientName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        // NEW UI: Show a tiny progress indicator if partially paid!
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOverdue ? 'Overdue: $dateStr' : 'Due: $dateStr',
              // Turns the text bold red if overdue!
              style: TextStyle(
                color: isOverdue ? AppColors.error : AppColors.textSecondary,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (invoice.amountPaid > 0 && !isPaid) ...[
              const SizedBox(height: 4),
              Text(
                'Paid: ₹${invoice.amountPaid.toStringAsFixed(2)} of ₹${invoice.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invoice.status,
                    style: TextStyle(
                      color: isPaid ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _EditInvoiceForm(invoice: invoice),
                    );
                  },
                ),
                // THE EXISTING PDF BUTTON
                IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: () async {
                    await PdfService.generateAndPrintInvoice(invoice);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE FORM TO EDIT AN EXISTING INVOICE
// ============================================================================
class _EditInvoiceForm extends StatefulWidget {
  final InvoiceModel invoice;
  const _EditInvoiceForm({required this.invoice});

  @override
  State<_EditInvoiceForm> createState() => _EditInvoiceFormState();
}

class _EditInvoiceFormState extends State<_EditInvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // PRE-FILL THE DATA!
    _amountController = TextEditingController(
      text: widget.invoice.amount.toString(),
    );
    _selectedDate = widget.invoice.dueDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _updateInvoice() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Create an updated version of the model, keeping the SAME ID and amounts paid!
        final updatedInvoice = InvoiceModel(
          id: widget
              .invoice
              .id, // CRITICAL: Keeping the same ID tells Firestore to OVERWRITE
          clientName: widget.invoice.clientName,
          amount: double.parse(_amountController.text.trim()),
          amountPaid: widget.invoice.amountPaid,
          status: widget
              .invoice
              .status, // Status remains the same (payments dictate status)
          dueDate: _selectedDate,
        );

        // We can reuse our createInvoice function because Firestore .set() acts as an upsert!
        await InvoiceService().createInvoice(updatedInvoice);

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: bottomPadding + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Invoice for ${widget.invoice.clientName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Total Amount (₹)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              const Text(
                'Due Date',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Update Invoice',
                isLoading: _isLoading,
                onPressed: _updateInvoice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
