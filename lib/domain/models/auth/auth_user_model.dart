import 'package:equatable/equatable.dart';

class AuthUserModel extends Equatable {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String nickname;
  final String position;
  final String locale;
  final String status;
  final String profileImageUrl;

  const AuthUserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.nickname = '',
    this.position = '',
    this.locale = 'en',
    this.status = 'offline',
    this.profileImageUrl = '',
  });

  bool get isAuthenticated => id.isNotEmpty;

  String get displayName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    if (nickname.isNotEmpty) return nickname;
    return username;
  }

  factory AuthUserModel.empty() => const AuthUserModel(
        id: '',
        username: '',
        email: '',
      );

  factory AuthUserModel.fromJson(Map<String, dynamic> json, {String baseUrl = ''}) {
    final userId = json['id'] as String? ?? '';
    return AuthUserModel(
      id: userId,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      position: json['position'] as String? ?? '',
      locale: json['locale'] as String? ?? 'en',
      status: json['status'] as String? ?? 'offline',
      profileImageUrl: baseUrl.isNotEmpty ? '$baseUrl/api/v4/users/$userId/image' : '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'position': position,
        'locale': locale,
        'status': status,
        'profile_image_url': profileImageUrl,
      };

  AuthUserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? nickname,
    String? position,
    String? locale,
    String? status,
    String? profileImageUrl,
  }) {
    return AuthUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickname: nickname ?? this.nickname,
      position: position ?? this.position,
      locale: locale ?? this.locale,
      status: status ?? this.status,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id, username, email, firstName, lastName,
        nickname, position, locale, status, profileImageUrl,
      ];
}
