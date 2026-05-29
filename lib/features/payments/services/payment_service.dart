import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // 1. CREATE PAYMENT & UPDATE INVOICE AT THE SAME TIME
  Future<void> recordPayment({
    required PaymentModel payment,
    required double invoiceTotalAmount,
    required double currentAmountPaid,
  }) async {
    final batch = _db.batch();

    final paymentRef = _db
        .collection('users')
        .doc(_userId)
        .collection('payments')
        .doc(payment.id);
    final invoiceRef = _db
        .collection('users')
        .doc(_userId)
        .collection('invoices')
        .doc(payment.invoiceId);

    // Queue Operation 1: Save the payment history
    batch.set(paymentRef, payment.toMap());

    // NEW MATH LOGIC
    final newTotalPaid = currentAmountPaid + payment.amount;

    // Floating point math in Dart can sometimes result in 99.999999, so we round it slightly for safety,
    // or just check if it's greater than or equal to the total.
    final isFullyPaid = newTotalPaid >= invoiceTotalAmount;

    // Queue Operation 2: Update the invoice with the new math!
    batch.update(invoiceRef, {
      'amountPaid': newTotalPaid,
      'status': isFullyPaid ? 'Paid' : 'Pending',
    });

    await batch.commit();
  }

  // 2. READ: Get a stream of the ledger
  Stream<List<PaymentModel>> getPaymentsStream() {
    return _db
        .collection('users')
        .doc(_userId)
        .collection('payments')
        .orderBy('date', descending: true) // Newest payments at the top
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PaymentModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
