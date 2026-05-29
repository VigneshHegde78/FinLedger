import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String invoiceId;
  final String
  clientName; // Denormalized so we don't have to fetch the invoice just to see the name!
  final double amount;
  final DateTime date;

  PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.clientName,
    required this.amount,
    required this.date,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PaymentModel(
      id: documentId,
      invoiceId: map['invoiceId'] ?? '',
      clientName: map['clientName'] ?? 'Unknown',
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'clientName': clientName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    };
  }
}
