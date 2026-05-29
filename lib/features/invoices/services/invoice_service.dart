import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to dynamically get the current user's specific invoice collection
  CollectionReference get _userInvoices {
    final userId = _auth.currentUser!.uid;
    return _db.collection('users').doc(userId).collection('invoices');
  }

  // 1. CREATE: Push a new invoice to Firestore
  Future<void> createInvoice(InvoiceModel invoice) async {
    // We use .doc(invoice.id).set() instead of .add() so we can control the ID manually
    await _userInvoices.doc(invoice.id).set(invoice.toMap());
  }

  // 2. READ: Get a real-time stream of the user's invoices
  Stream<List<InvoiceModel>> getInvoicesStream() {
    return _userInvoices
        .orderBy('dueDate', descending: true) // Show newest due dates first
        .snapshots() // This is the magic real-time pipe!
        .map((snapshot) {
          // Convert the raw Firestore documents into our Dart Models
          return snapshot.docs.map((doc) {
            return InvoiceModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // 3. DELETE: Remove an invoice by its ID
  Future<void> deleteInvoice(String invoiceId) async {
    await _userInvoices.doc(invoiceId).delete();
  }
}
