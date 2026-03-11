import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.studentId,
    this.faculty,
    this.course,
    this.year,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? studentId;
  final String? faculty;
  final String? course;
  final String? year;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isComplete =>
      _hasValue(fullName) && _hasValue(studentId) && _hasValue(course);

  String get displayName {
    if (_hasValue(fullName)) {
      return fullName!.trim();
    }
    return email;
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? studentId,
    String? faculty,
    String? course,
    String? year,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearAvatarUrl = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
      studentId: studentId ?? this.studentId,
      faculty: faculty ?? this.faculty,
      course: course ?? this.course,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      fullName: _stringOrNull(json['full_name']),
      avatarUrl: _stringOrNull(json['avatar_url']),
      studentId: _stringOrNull(json['student_id']),
      faculty: _stringOrNull(json['faculty']),
      course: _stringOrNull(json['course']),
      year: _stringOrNull(json['year']),
      createdAt: _dateTimeOrNull(json['created_at']),
      updatedAt: _dateTimeOrNull(json['updated_at']),
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'full_name': _nullIfBlank(fullName),
      'avatar_url': _nullIfBlank(avatarUrl),
      'student_id': _nullIfBlank(studentId),
      'faculty': _nullIfBlank(faculty),
      'course': _nullIfBlank(course),
      'year': _nullIfBlank(year),
    };
  }
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

String? _nullIfBlank(String? value) => _stringOrNull(value);

DateTime? _dateTimeOrNull(Object? value) {
  final text = _stringOrNull(value);
  if (text == null) {
    return null;
  }
  return DateTime.tryParse(text);
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
