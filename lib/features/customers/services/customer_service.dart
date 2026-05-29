import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dynamically get the current user's customers collection
  CollectionReference get _userCustomers {
    final userId = _auth.currentUser!.uid;
    return _db.collection('users').doc(userId).collection('customers');
  }

  // CREATE
  Future<void> addCustomer(CustomerModel customer) async {
    await _userCustomers.doc(customer.id).set(customer.toMap());
  }

  // READ (Real-time Stream)
  Stream<List<CustomerModel>> getCustomersStream() {
    return _userCustomers
        .orderBy('name') // Sort alphabetically!
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CustomerModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // DELETE CUSTOMER
  Future<void> deleteCustomer(String customerId) async {
    await _userCustomers.doc(customerId).delete();
  }
}
