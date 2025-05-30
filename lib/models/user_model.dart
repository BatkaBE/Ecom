import 'package:cloud_firestore/cloud_firestore.dart';

class NameModel {
  final String firstname;
  final String lastname;

  NameModel({required this.firstname, required this.lastname});

  factory NameModel.fromMap(Map<String, dynamic> map) {
    return NameModel(
      firstname: map['firstname'] ?? '',
      lastname: map['lastname'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'firstname': firstname, 'lastname': lastname};
  }
}

class Address {
  final String city;
  final String street;
  // Add other fields like zipcode, geolocation if needed

  Address({required this.city, required this.street});

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(city: map['city'] ?? '', street: map['street'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'city': city, 'street': street};
  }
}

class UserModel {
  final String id; // Firebase UID
  final String email;
  final String? username; // Can be same as email or different
  final NameModel name;
  final String phone;
  final Address address;
  final String? avatarUrl; // Firebase Auth might provide this

  UserModel({
    required this.id,
    required this.email,
    this.username,
    required this.name,
    required this.phone,
    required this.address,
    this.avatarUrl,
  });

  // Factory constructor to create a UserModel from a Firestore document
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null)
      throw FirebaseException(
        plugin: 'Firestore',
        message: 'User data is null',
      );

    return UserModel(
      id: snapshot.id,
      email: data['email'] ?? '',
      username: data['username'],
      name: NameModel.fromMap(data['name'] ?? {}),
      phone: data['phone'] ?? '',
      address: Address.fromMap(data['address'] ?? {}),
      avatarUrl: data['avatarUrl'],
    );
  }

  // Method to convert UserModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'name': name.toMap(),
      'phone': phone,
      'address': address.toMap(),
      'avatarUrl': avatarUrl,
      // 'id' is the document ID, so not stored inside the document fields
    };
  }

  // Helper to create an empty/default user model
  factory UserModel.empty(String uid, String email, {String? displayName}) {
    // Try to parse displayName into first and last names
    String firstName = '';
    String lastName = '';
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      firstName = parts.isNotEmpty ? parts[0] : '';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return UserModel(
      id: uid,
      email: email,
      username: email.split('@')[0], // Default username from email
      name: NameModel(
        firstname: firstName,
        lastname: lastName,
      ), // Default empty name
      phone: '', // Default empty phone
      address: Address(city: '', street: ''), // Default empty address
      avatarUrl: null,
    );
  }
}
