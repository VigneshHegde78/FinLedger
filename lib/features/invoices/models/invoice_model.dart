import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String id;
  final String clientName;
  final double amount; // The total bill
  final double amountPaid; // NEW: How much has been paid so far
  final String status;
  final DateTime dueDate;

  InvoiceModel({
    required this.id,
    required this.clientName,
    required this.amount,
    this.amountPaid = 0.0, // NEW: Defaults to 0 when creating a new invoice
    required this.status,
    required this.dueDate,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return InvoiceModel(
      id: documentId,
      clientName: map['clientName'] ?? 'Unknown Client',
      amount: (map['amount'] ?? 0).toDouble(),
      // NEW: Safely pull amountPaid from Firebase, defaulting to 0 if it doesn't exist yet
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      status: map['status'] ?? 'Pending',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'amount': amount,
      'amountPaid': amountPaid, // NEW: Save it to Firebase
      'status': status,
      'dueDate': Timestamp.fromDate(dueDate),
    };
  }
}
