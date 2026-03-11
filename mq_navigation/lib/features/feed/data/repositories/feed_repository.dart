import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/features/feed/domain/entities/feed_item.dart';

class FeedQuery {
  const FeedQuery({
    this.searchTerm = '',
    this.selectedTypes = const <FeedItemType>{
      FeedItemType.event,
      FeedItemType.announcement,
      FeedItemType.featured,
    },
    this.dateRange,
  });

  final String searchTerm;
  final Set<FeedItemType> selectedTypes;
  final DateTimeRange? dateRange;

  FeedQuery copyWith({
    String? searchTerm,
    Set<FeedItemType>? selectedTypes,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
  }) {
    return FeedQuery(
      searchTerm: searchTerm ?? this.searchTerm,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      dateRange: clearDateRange ? null : dateRange ?? this.dateRange,
    );
  }
}

class FeedPageResult {
  const FeedPageResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<FeedItem> items;
  final bool hasMore;
  final DateTime? nextCursor;
}

abstract interface class FeedRepository {
  Future<FeedPageResult> fetchFeed({
    required FeedQuery query,
    DateTime? cursor,
    int pageSize,
  });
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return SupabaseFeedRepository(Supabase.instance.client);
});

class SupabaseFeedRepository implements FeedRepository {
  const SupabaseFeedRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<FeedPageResult> fetchFeed({
    required FeedQuery query,
    DateTime? cursor,
    int pageSize = 20,
  }) async {
    var request = _client.from('public_events').select();

    if (cursor != null) {
      request = request.gt('start_at', cursor.toIso8601String());
    }

    final range = query.dateRange;
    if (range != null) {
      request = request
          .gte('start_at', range.start.toIso8601String())
          .lte('start_at', range.end.toIso8601String());
    } else {
      request = request.gte(
        'start_at',
        DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
      );
    }

    final searchTerm = query.searchTerm.trim();
    if (searchTerm.isNotEmpty) {
      final escaped = searchTerm.replaceAll(',', ' ');
      request = request.or(
        'title.ilike.%$escaped%,description.ilike.%$escaped%',
      );
    }

    final response = await request.order('start_at').limit(pageSize * 3);

    final allItems =
        (response as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(FeedItem.fromJson)
            .where((item) => !item.isDeleted)
            .where((item) => query.selectedTypes.contains(item.type))
            .toList()
          ..sort((left, right) => left.startAt.compareTo(right.startAt));

    final items = allItems.take(pageSize).toList();
    return FeedPageResult(
      items: items,
      hasMore: allItems.length > pageSize,
      nextCursor: items.isEmpty ? cursor : items.last.startAt,
    );
  }
}
