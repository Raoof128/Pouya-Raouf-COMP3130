import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:mq_navigation/features/feed/domain/entities/feed_item.dart';
import 'package:mq_navigation/features/feed/presentation/controllers/feed_controller.dart';
import 'package:mq_navigation/features/feed/presentation/widgets/feed_event_card.dart';
import 'package:mq_navigation/features/feed/presentation/widgets/feed_filter_bar.dart';
import 'package:mq_navigation/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:mq_navigation/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_app_bar.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 240) {
          ref.read(feedControllerProvider.notifier).loadMore();
        }
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedState = ref.watch(feedControllerProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final calendarState = ref.watch(calendarControllerProvider).value;
    final importedEventIds =
        calendarState?.events
            .map((event) => event.sourcePublicEventId)
            .whereType<String>()
            .toSet() ??
        <String>{};

    return Scaffold(
      appBar: MqAppBar(
        title: l10n.eventFeed,
        actions: [
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => context.go('/notifications'),
            icon: NotificationBadge(
              count: unreadCount,
              child: const Icon(Icons.notifications_none_outlined),
            ),
          ),
        ],
      ),
      body: feedState.when(
        data: (state) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(feedControllerProvider.notifier).refresh(),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchEventsPlaceholder,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(feedControllerProvider.notifier)
                                  .updateSearchTerm('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    ref
                        .read(feedControllerProvider.notifier)
                        .updateSearchTerm(value);
                  },
                ),
                const SizedBox(height: 16),
                FeedFilterBar(
                  selectedTypes: state.query.selectedTypes,
                  activeDateRange: state.query.dateRange,
                  onToggleType: (type) => ref
                      .read(feedControllerProvider.notifier)
                      .toggleType(type),
                  onChangeDateRange: () => _selectDateRange(context, state),
                ),
                const SizedBox(height: 16),
                if (state.items.isEmpty)
                  MqCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.noEventsFound,
                          style: context.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.tryDifferentFilters),
                      ],
                    ),
                  ),
                ...state.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FeedEventCard(
                      item: item,
                      isInCalendar: importedEventIds.contains(item.id),
                      onAddToCalendar: () => _addToCalendar(context, item),
                    ),
                  ),
                ),
                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, FeedState state) async {
    final l10n = AppLocalizations.of(context)!;
    if (state.query.dateRange != null) {
      await ref.read(feedControllerProvider.notifier).updateDateRange(null);
      return;
    }

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: l10n.filterEvents,
    );
    if (range != null) {
      await ref.read(feedControllerProvider.notifier).updateDateRange(range);
    }
  }

  Future<void> _addToCalendar(BuildContext context, FeedItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final message = await ref
        .read(calendarControllerProvider.notifier)
        .saveEvent(item.toAcademicEvent());
    if (!context.mounted) {
      return;
    }
    if (message != null) {
      context.showSnackBar(message, isError: true);
      return;
    }
    context.showSnackBar(l10n.eventAddedSuccess);
  }
}
