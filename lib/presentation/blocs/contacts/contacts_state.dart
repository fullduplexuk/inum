import 'package:equatable/equatable.dart';

class ContactUser extends Equatable {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String status; // online, away, offline, dnd
  final String profileImageUrl;

  const ContactUser({
    required this.id,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.status = 'offline',
    this.profileImageUrl = '',
  });

  String get displayName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return username;
  }

  factory ContactUser.fromJson(Map<String, dynamic> json, {String baseUrl = ''}) {
    final userId = json['id'] as String? ?? '';
    return ContactUser(
      id: userId,
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      profileImageUrl: baseUrl.isNotEmpty ? '$baseUrl/api/v4/users/$userId/image' : '',
    );
  }

  @override
  List<Object?> get props => [id, username, firstName, lastName, email, status, profileImageUrl];
}

sealed class ContactsState extends Equatable {
  const ContactsState();

  @override
  List<Object?> get props => [];
}

class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

class ContactsLoaded extends ContactsState {
  final List<ContactUser> contacts;
  final List<ContactUser> filteredContacts;
  final String searchQuery;

  const ContactsLoaded({
    required this.contacts,
    required this.filteredContacts,
    this.searchQuery = '',
  });

  ContactsLoaded copyWith({
    List<ContactUser>? contacts,
    List<ContactUser>? filteredContacts,
    String? searchQuery,
  }) {
    return ContactsLoaded(
      contacts: contacts ?? this.contacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [contacts, filteredContacts, searchQuery];
}

class ContactsError extends ContactsState {
  final String message;
  const ContactsError(this.message);

  @override
  List<Object?> get props => [message];
}
