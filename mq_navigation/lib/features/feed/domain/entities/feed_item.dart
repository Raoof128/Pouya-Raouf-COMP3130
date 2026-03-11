import 'package:flutter/foundation.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';

enum FeedItemType { event, announcement, featured }

@immutable
class FeedItem {
  const FeedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startAt,
    required this.category,
    required this.priority,
    this.building,
    this.room,
    this.endAt,
    this.imageUrl,
    this.isFeatured = false,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String? building;
  final String? room;
  final DateTime startAt;
  final DateTime? endAt;
  final String category;
  final String? imageUrl;
  final bool isFeatured;
  final int priority;
  final DateTime? deletedAt;

  FeedItemType get type {
    if (isFeatured) {
      return FeedItemType.featured;
    }
    if (category.toLowerCase() == 'announcement') {
      return FeedItemType.announcement;
    }
    return FeedItemType.event;
  }

  bool get isDeleted => deletedAt != null;

  String get subtitle {
    if (building != null && building!.isNotEmpty) {
      return '$location · $building';
    }
    return location;
  }

  AcademicEvent toAcademicEvent() {
    return AcademicEvent(
      sourcePublicEventId: id,
      title: title,
      description: description,
      location: location,
      building: building,
      room: room,
      startAt: startAt,
      endAt: endAt,
      category: category,
      imageUrl: imageUrl,
      notificationEnabled: true,
    );
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      building: json['building'] as String?,
      room: json['room'] as String?,
      startAt:
          DateTime.tryParse(json['start_at'] as String? ?? '') ??
          DateTime.now(),
      endAt: DateTime.tryParse(json['end_at'] as String? ?? ''),
      category: (json['category'] as String?) ?? 'general',
      imageUrl: json['image_url'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      deletedAt: DateTime.tryParse(json['deleted_at'] as String? ?? ''),
    );
  }
}
