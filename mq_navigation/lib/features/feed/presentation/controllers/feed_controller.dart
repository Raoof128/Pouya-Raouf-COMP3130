import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/feed/data/repositories/feed_repository.dart';
import 'package:mq_navigation/features/feed/domain/entities/feed_item.dart';

@immutable
class FeedState {
  const FeedState({
    required this.items,
    required this.query,
    this.hasMore = true,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<FeedItem> items;
  final FeedQuery query;
  final bool hasMore;
  final DateTime? nextCursor;
  final bool isLoadingMore;

  FeedState copyWith({
    List<FeedItem>? items,
    FeedQuery? query,
    bool? hasMore,
    DateTime? nextCursor,
    bool clearCursor = false,
    bool? isLoadingMore,
  }) {
    return FeedState(
      items: items ?? this.items,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final feedControllerProvider = AsyncNotifierProvider<FeedController, FeedState>(
  FeedController.new,
);

class FeedController extends AsyncNotifier<FeedState> {
  @override
  Future<FeedState> build() async {
    return _load(const FeedQuery());
  }

  Future<void> refresh() async {
    final currentQuery = state.value?.query ?? const FeedQuery();
    state = const AsyncLoading();
    state = AsyncData(await _load(currentQuery));
  }

  Future<void> updateSearchTerm(String value) async {
    final currentQuery = state.value?.query ?? const FeedQuery();
    state = const AsyncLoading();
    state = AsyncData(
      await _load(currentQuery.copyWith(searchTerm: value), resetCursor: true),
    );
  }

  Future<void> toggleType(FeedItemType type) async {
    final currentQuery = state.value?.query ?? const FeedQuery();
    final nextTypes = <FeedItemType>{...currentQuery.selectedTypes};
    if (!nextTypes.add(type)) {
      nextTypes.remove(type);
    }
    if (nextTypes.isEmpty) {
      nextTypes.addAll(FeedItemType.values);
    }

    state = const AsyncLoading();
    state = AsyncData(
      await _load(
        currentQuery.copyWith(selectedTypes: nextTypes),
        resetCursor: true,
      ),
    );
  }

  Future<void> updateDateRange(DateTimeRange? range) async {
    final currentQuery = state.value?.query ?? const FeedQuery();
    state = const AsyncLoading();
    state = AsyncData(
      await _load(
        currentQuery.copyWith(dateRange: range, clearDateRange: range == null),
        resetCursor: true,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = await ref
          .read(feedRepositoryProvider)
          .fetchFeed(
            query: current.query,
            cursor: current.nextCursor,
            pageSize: 20,
          );
      final mergedItems = <FeedItem>[
        ...current.items,
        ...nextPage.items.where(
          (item) => current.items.every((existing) => existing.id != item.id),
        ),
      ];
      state = AsyncData(
        current.copyWith(
          items: mergedItems,
          hasMore: nextPage.hasMore,
          nextCursor: nextPage.nextCursor,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load more feed items', error, stackTrace);
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<FeedState> _load(FeedQuery query, {bool resetCursor = false}) async {
    final page = await ref
        .read(feedRepositoryProvider)
        .fetchFeed(
          query: query,
          cursor: resetCursor ? null : state.value?.nextCursor,
          pageSize: 20,
        );
    return FeedState(
      items: page.items,
      query: query,
      hasMore: page.hasMore,
      nextCursor: page.nextCursor,
    );
  }
}
