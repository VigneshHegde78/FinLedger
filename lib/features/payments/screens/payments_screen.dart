import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/services/invoice_service.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Payment Ledger',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Listening to our real-time payment stream
      body: StreamBuilder<List<PaymentModel>>(
        stream: PaymentService().getPaymentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return const Center(
              child: Text(
                'No payments recorded yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final dateStr =
                  '${payment.date.month}/${payment.date.day}/${payment.date.year}';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white),
                ),
                title: Text(
                  payment.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text('ID: ${payment.invoiceId}\nDate: $dateStr'),
                isThreeLine: true,
                trailing: Text(
                  '+\$${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordPaymentModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_card, color: Colors.white),
      ),
    );
  }

  void _showRecordPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecordPaymentForm(),
    );
  }
}

class RecordPaymentForm extends StatefulWidget {
  const RecordPaymentForm();

  @override
  State<RecordPaymentForm> createState() => _RecordPaymentFormState();
}

class _RecordPaymentFormState extends State<RecordPaymentForm> {
  final _formKey = GlobalKey<FormState>();

  // We deleted the Invoice ID and Client Name controllers!
  InvoiceModel? _selectedInvoice;
  final _amountController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final newPayment = PaymentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          invoiceId: _selectedInvoice!.id,
          clientName:
              _selectedInvoice!.clientName, // Automatically grab the name!
          amount: double.parse(_amountController.text.trim()),
          date: DateTime.now(),
        );

        // This triggers our beautiful Batch Write!
        await PaymentService().recordPayment(
          payment: newPayment,
          invoiceTotalAmount: _selectedInvoice!.amount,
          currentAmountPaid: _selectedInvoice!.amountPaid,
        );

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
              const Text(
                'Record Payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Select Pending Invoice',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // NEW CODE: StreamBuilder to fetch ONLY Pending Invoices!
              StreamBuilder<List<InvoiceModel>>(
                stream: InvoiceService().getInvoicesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // We filter the stream locally to only show invoices that actually need paying!
                  final pendingInvoices = (snapshot.data ?? [])
                      .where((inv) => inv.status == 'Pending')
                      .toList();

                  if (pendingInvoices.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'All caught up! You have no pending invoices to pay.',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return DropdownButtonFormField<InvoiceModel>(
                    value: _selectedInvoice,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    hint: const Text('Choose an invoice...'),
                    items: pendingInvoices.map((invoice) {
                      // NEW: Calculate remaining balance for the dropdown text
                      final remaining = invoice.amount - invoice.amountPaid;
                      return DropdownMenuItem(
                        value: invoice,
                        child: Text(
                          '${invoice.clientName} - \$${remaining.toStringAsFixed(2)} remaining',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedInvoice = val;
                        // NEW: Auto-fill the text field with ONLY the remaining balance
                        if (val != null) {
                          final remaining = val.amount - val.amountPaid;
                          _amountController.text = remaining.toStringAsFixed(2);
                        }
                      });
                    },
                    validator: (val) =>
                        val == null ? 'Please select an invoice' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Amount Paid (\$)',
                hint: '0.00',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  final parsed = double.tryParse(val);
                  if (parsed == null) return 'Invalid amount';

                  // NEW: Prevent overpayment!
                  if (_selectedInvoice != null) {
                    final remaining =
                        _selectedInvoice!.amount - _selectedInvoice!.amountPaid;
                    if (parsed > remaining) {
                      return 'Cannot pay more than \$${remaining.toStringAsFixed(2)}';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Process Payment',
                isLoading: _isLoading,
                onPressed: _savePayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
