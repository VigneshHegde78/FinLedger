class CustomerModel {
  final String id;
  final String name;
  final String email;
  final String phone;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CustomerModel(
      id: documentId,
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? 'No email',
      phone: map['phone'] ?? 'No phone',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'phone': phone};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    // We tell Dart that two CustomerModels are equal if their IDs match!
    return other is CustomerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
