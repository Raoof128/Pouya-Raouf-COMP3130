import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/core/utils/validators.dart';
import 'package:mq_navigation/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';
import 'package:mq_navigation/shared/widgets/mq_input.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final calendarState = ref.watch(calendarControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendar),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(calendarControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh calendar',
          ),
        ],
      ),
      body: calendarState.when(
        data: (state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(MqSpacing.space4),
                child: _CalendarHeader(state: state),
              ),
              _FilterBar(state: state),
              const SizedBox(height: MqSpacing.space2),
              Expanded(
                child: switch (state.viewMode) {
                  CalendarViewMode.agenda => _AgendaView(state: state),
                  CalendarViewMode.day => _DayView(state: state),
                  CalendarViewMode.week => _WeekView(state: state),
                },
              ),
            ],
          );
        },
        error: (error, stackTrace) => const Center(
          child: Padding(
            padding: EdgeInsets.all(MqSpacing.space4),
            child: Text('Unable to load your calendar right now.'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: calendarState.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _showQuickAddPicker(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Quick add'),
            )
          : null,
    );
  }

  Future<void> _showQuickAddPicker(BuildContext context, WidgetRef ref) async {
    final selectedType = await showModalBottomSheet<AcademicItemType>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('Deadline'),
                onTap: () =>
                    Navigator.of(context).pop(AcademicItemType.deadline),
              ),
              ListTile(
                leading: const Icon(Icons.quiz_outlined),
                title: const Text('Exam'),
                onTap: () => Navigator.of(context).pop(AcademicItemType.exam),
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Event'),
                onTap: () => Navigator.of(context).pop(AcademicItemType.event),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('To-do'),
                onTap: () => Navigator.of(context).pop(AcademicItemType.todo),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || selectedType == null) {
      return;
    }

    switch (selectedType) {
      case AcademicItemType.deadline:
      case AcademicItemType.exam:
        await _editDeadline(context, ref, type: selectedType);
      case AcademicItemType.event:
        await _editEvent(context, ref);
      case AcademicItemType.todo:
        await _editTodo(context, ref);
    }
  }

  static Future<void> _editDeadline(
    BuildContext context,
    WidgetRef ref, {
    DeadlineItem? existing,
    AcademicItemType type = AcademicItemType.deadline,
  }) async {
    final calendarState = ref.read(calendarControllerProvider).value;
    final seedUnit = calendarState?.units.isNotEmpty == true
        ? calendarState!.units.first
        : null;
    final result = await showModalBottomSheet<_EditorResult<DeadlineItem>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _DeadlineEditorSheet(
          item:
              existing ??
              DeadlineItem(
                unitId: seedUnit?.id,
                unitCode: seedUnit?.code ?? 'GEN',
                title: '',
                dueDate: DateTime.now().add(const Duration(days: 1)),
                type: type,
              ),
          units: calendarState?.units ?? const [],
        );
      },
    );

    if (!context.mounted || result == null) {
      return;
    }

    final controller = ref.read(calendarControllerProvider.notifier);
    final message = result.deleteRequested
        ? await controller.deleteDeadline(existing!.id!)
        : await controller.saveDeadline(result.value!);
    if (message != null && context.mounted) {
      context.showSnackBar(message, isError: true);
    }
  }

  static Future<void> _editEvent(
    BuildContext context,
    WidgetRef ref, {
    AcademicEvent? existing,
  }) async {
    final result = await showModalBottomSheet<_EditorResult<AcademicEvent>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _EventEditorSheet(
          item:
              existing ??
              AcademicEvent(
                title: '',
                startAt: DateTime.now().add(const Duration(hours: 1)),
                endAt: DateTime.now().add(const Duration(hours: 2)),
              ),
        );
      },
    );

    if (!context.mounted || result == null) {
      return;
    }

    final controller = ref.read(calendarControllerProvider.notifier);
    final message = result.deleteRequested
        ? await controller.deleteEvent(existing!.id!)
        : await controller.saveEvent(result.value!);
    if (message != null && context.mounted) {
      context.showSnackBar(message, isError: true);
    }
  }

  static Future<void> _editTodo(
    BuildContext context,
    WidgetRef ref, {
    TodoItem? existing,
  }) async {
    final result = await showModalBottomSheet<_EditorResult<TodoItem>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _TodoEditorSheet(
          item:
              existing ??
              TodoItem(
                title: '',
                dueDate: DateTime.now().add(const Duration(days: 1)),
              ),
        );
      },
    );

    if (!context.mounted || result == null) {
      return;
    }

    final controller = ref.read(calendarControllerProvider.notifier);
    final message = result.deleteRequested
        ? await controller.deleteTodo(existing!.id!)
        : await controller.saveTodo(result.value!);
    if (message != null && context.mounted) {
      context.showSnackBar(message, isError: true);
    }
  }
}

class _CalendarHeader extends ConsumerWidget {
  const _CalendarHeader({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(calendarControllerProvider.notifier);
    final weekLabel =
        '${DateFormat('d MMM').format(state.weekStart)} - ${DateFormat('d MMM').format(state.weekEnd)}';

    return MqCard(
      child: Padding(
        padding: const EdgeInsets.all(MqSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => controller.setFocusedDate(
                    state.focusedDate.subtract(const Duration(days: 7)),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        weekLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: MqSpacing.space1),
                      Text(
                        'Level ${state.gamification.level} • ${state.gamification.xp} XP',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.setFocusedDate(
                    state.focusedDate.add(const Duration(days: 7)),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: MqSpacing.space4),
            SegmentedButton<CalendarViewMode>(
              segments: const [
                ButtonSegment(
                  value: CalendarViewMode.agenda,
                  icon: Icon(Icons.view_agenda_outlined),
                  label: Text('Agenda'),
                ),
                ButtonSegment(
                  value: CalendarViewMode.day,
                  icon: Icon(Icons.view_day_outlined),
                  label: Text('Day'),
                ),
                ButtonSegment(
                  value: CalendarViewMode.week,
                  icon: Icon(Icons.calendar_view_week_outlined),
                  label: Text('Week'),
                ),
              ],
              selected: {state.viewMode},
              onSelectionChanged: (selection) {
                controller.setViewMode(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(calendarControllerProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: MqSpacing.space4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Show completed'),
            selected: state.includeCompletedItems,
            onSelected: controller.toggleIncludeCompletedItems,
          ),
          const SizedBox(width: MqSpacing.space2),
          ...state.units.map(
            (unit) => Padding(
              padding: const EdgeInsets.only(right: MqSpacing.space2),
              child: FilterChip(
                label: Text(unit.code),
                selected: state.selectedUnitIds.contains(unit.id),
                onSelected: (_) => controller.toggleUnit(unit.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaView extends ConsumerWidget {
  const _AgendaView({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = state.entries;
    if (entries.isEmpty) {
      return const _EmptyCalendarState(message: 'No calendar items this week.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(MqSpacing.space4),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _CalendarEntryCard(
          entry: entry,
          onTap: () => _handleEntryTap(context, ref, state, entry),
        );
      },
    );
  }
}

class _DayView extends ConsumerWidget {
  const _DayView({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = state.focusedDayEntries;
    if (entries.isEmpty) {
      return const _EmptyCalendarState(
        message: 'Nothing scheduled for this day.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(MqSpacing.space4),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _CalendarEntryCard(
          entry: entry,
          onTap: () => _handleEntryTap(context, ref, state, entry),
        );
      },
    );
  }
}

class _WeekView extends ConsumerWidget {
  const _WeekView({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = List<DateTime>.generate(
      7,
      (index) => state.weekStart.add(Duration(days: index)),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(MqSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: days.map((day) {
          final entries = state.entriesForDay(day);
          return SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.only(right: MqSpacing.space3),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE d').format(day),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: MqSpacing.space2),
                  if (entries.isEmpty)
                    const MqCard(
                      child: Padding(
                        padding: EdgeInsets.all(MqSpacing.space3),
                        child: Text('No items'),
                      ),
                    ),
                  ...entries.map(
                    (entry) => _CompactEntryCard(
                      entry: entry,
                      onTap: () => _handleEntryTap(context, ref, state, entry),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Future<void> _handleEntryTap(
  BuildContext context,
  WidgetRef ref,
  CalendarState state,
  CalendarEntry entry,
) async {
  switch (entry.type) {
    case AcademicItemType.deadline:
    case AcademicItemType.exam:
      final item = state.deadlines.firstWhere(
        (candidate) => candidate.id == entry.id,
      );
      await CalendarPage._editDeadline(
        context,
        ref,
        existing: item,
        type: item.type,
      );
    case AcademicItemType.event:
      final item = state.events.firstWhere(
        (candidate) => candidate.id == entry.id,
      );
      await CalendarPage._editEvent(context, ref, existing: item);
    case AcademicItemType.todo:
      final item = state.todos.firstWhere(
        (candidate) => candidate.id == entry.id,
      );
      await CalendarPage._editTodo(context, ref, existing: item);
  }
}

class _CalendarEntryCard extends StatelessWidget {
  const _CalendarEntryCard({required this.entry, required this.onTap});

  final CalendarEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('EEE d MMM, h:mm a').format(entry.startAt);
    final end = entry.endAt == null
        ? null
        : DateFormat('h:mm a').format(entry.endAt!);

    return MqCard(
      onTap: onTap,
      child: ListTile(
        leading: Icon(_iconForType(entry.type)),
        title: Text(entry.title),
        subtitle: Text(
          end == null
              ? '$start${entry.subtitle == null ? '' : ' • ${entry.subtitle}'}'
              : '$start - $end${entry.subtitle == null ? '' : ' • ${entry.subtitle}'}',
        ),
        trailing: entry.trailingLabel == null
            ? null
            : Text(
                entry.trailingLabel!,
                style: Theme.of(context).textTheme.labelMedium,
              ),
      ),
    );
  }
}

class _CompactEntryCard extends StatelessWidget {
  const _CompactEntryCard({required this.entry, required this.onTap});

  final CalendarEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MqCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(MqSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('h:mm a').format(entry.startAt),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: MqSpacing.space1),
            Text(entry.title, style: Theme.of(context).textTheme.titleSmall),
            if (entry.subtitle != null) ...[
              const SizedBox(height: MqSpacing.space1),
              Text(
                entry.subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCalendarState extends StatelessWidget {
  const _EmptyCalendarState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MqSpacing.space4),
        child: Text(message),
      ),
    );
  }
}

class _EditorResult<T> {
  const _EditorResult.save(this.value) : deleteRequested = false;
  const _EditorResult.delete() : value = null, deleteRequested = true;

  final T? value;
  final bool deleteRequested;
}

class _DeadlineEditorSheet extends StatefulWidget {
  const _DeadlineEditorSheet({required this.item, required this.units});

  final DeadlineItem item;
  final List<UnitSummary> units;

  @override
  State<_DeadlineEditorSheet> createState() => _DeadlineEditorSheetState();
}

class _DeadlineEditorSheetState extends State<_DeadlineEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _unitCodeController;
  late DateTime _dueDate;
  late String _priority;
  late bool _completed;
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(
      text: widget.item.description ?? '',
    );
    _unitCodeController = TextEditingController(text: widget.item.unitCode);
    _dueDate = widget.item.dueDate;
    _priority = widget.item.priority;
    _completed = widget.item.completed;
    _selectedUnitId = widget.item.unitId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _unitCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.item.isExam ? 'Edit exam' : 'Edit deadline';

    return _EditorScaffold(
      title: widget.item.id == null
          ? (widget.item.isExam ? 'New exam' : 'New deadline')
          : title,
      deleteEnabled: widget.item.id != null,
      onDelete: () => Navigator.of(context).pop(const _EditorResult.delete()),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MqInput(
              label: 'Title',
              controller: _titleController,
              prefixIcon: Icons.title_outlined,
              validator: (value) =>
                  Validators.required(value, fieldName: 'Title'),
            ),
            const SizedBox(height: MqSpacing.space4),
            if (widget.units.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: _selectedUnitId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No linked unit'),
                  ),
                  ...widget.units.map(
                    (unit) => DropdownMenuItem<String?>(
                      value: unit.id,
                      child: Text('${unit.code} • ${unit.name}'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUnitId = value;
                    final linkedUnit = widget.units.where(
                      (unit) => unit.id == value,
                    );
                    if (linkedUnit.isNotEmpty) {
                      _unitCodeController.text = linkedUnit.first.code;
                    }
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Linked unit',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
              ),
              const SizedBox(height: MqSpacing.space4),
            ],
            MqInput(
              label: 'Unit code',
              controller: _unitCodeController,
              prefixIcon: Icons.confirmation_number_outlined,
              validator: (value) =>
                  Validators.required(value, fieldName: 'Unit code'),
            ),
            const SizedBox(height: MqSpacing.space4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Due date'),
              subtitle: Text(DateFormat('EEE d MMM, h:mm a').format(_dueDate)),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: MqSpacing.space4),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _priority = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Priority',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: MqSpacing.space4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Completed'),
              value: _completed,
              onChanged: (value) {
                setState(() {
                  _completed = value;
                });
              },
            ),
            const SizedBox(height: MqSpacing.space4),
            MqInput(
              label: 'Description',
              controller: _descriptionController,
              prefixIcon: Icons.notes_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: MqSpacing.space6),
            MqButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await _pickDateTime(context, _dueDate);
    if (picked == null) {
      return;
    }
    setState(() {
      _dueDate = picked;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _EditorResult.save(
        widget.item.copyWith(
          unitId: _selectedUnitId,
          unitCode: _unitCodeController.text.trim().toUpperCase(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate,
          priority: _priority,
          completed: _completed,
        ),
      ),
    );
  }
}

class _EventEditorSheet extends StatefulWidget {
  const _EventEditorSheet({required this.item});

  final AcademicEvent item;

  @override
  State<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<_EventEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late DateTime _startAt;
  late DateTime _endAt;
  late String _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(
      text: widget.item.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.item.location ?? '',
    );
    _startAt = widget.item.startAt;
    _endAt =
        widget.item.endAt ?? widget.item.startAt.add(const Duration(hours: 1));
    _category = widget.item.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: widget.item.id == null ? 'New event' : 'Edit event',
      deleteEnabled: widget.item.id != null,
      onDelete: () => Navigator.of(context).pop(const _EditorResult.delete()),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MqInput(
              label: 'Title',
              controller: _titleController,
              prefixIcon: Icons.title_outlined,
              validator: (value) =>
                  Validators.required(value, fieldName: 'Title'),
            ),
            const SizedBox(height: MqSpacing.space4),
            MqInput(
              label: 'Location',
              controller: _locationController,
              prefixIcon: Icons.location_on_outlined,
              validator: (value) =>
                  Validators.required(value, fieldName: 'Location'),
            ),
            const SizedBox(height: MqSpacing.space4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Starts'),
              subtitle: Text(DateFormat('EEE d MMM, h:mm a').format(_startAt)),
              onTap: _pickStart,
            ),
            const SizedBox(height: MqSpacing.space2),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stop_circle_outlined),
              title: const Text('Ends'),
              subtitle: Text(DateFormat('EEE d MMM, h:mm a').format(_endAt)),
              onTap: _pickEnd,
            ),
            const SizedBox(height: MqSpacing.space4),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                DropdownMenuItem(value: 'general', child: Text('General')),
                DropdownMenuItem(value: 'study', child: Text('Study')),
                DropdownMenuItem(value: 'campus', child: Text('Campus')),
                DropdownMenuItem(value: 'social', child: Text('Social')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _category = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: MqSpacing.space4),
            MqInput(
              label: 'Description',
              controller: _descriptionController,
              prefixIcon: Icons.notes_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: MqSpacing.space6),
            MqButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(context, _startAt);
    if (picked == null) {
      return;
    }
    setState(() {
      _startAt = picked;
      if (_endAt.isBefore(_startAt)) {
        _endAt = _startAt.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(context, _endAt);
    if (picked == null) {
      return;
    }
    setState(() {
      _endAt = picked;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _EditorResult.save(
        widget.item.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          startAt: _startAt,
          endAt: _endAt,
          category: _category,
        ),
      ),
    );
  }
}

class _TodoEditorSheet extends StatefulWidget {
  const _TodoEditorSheet({required this.item});

  final TodoItem item;

  @override
  State<_TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<_TodoEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime? _dueDate;
  late String _priority;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(
      text: widget.item.description ?? '',
    );
    _dueDate = widget.item.dueDate;
    _priority = widget.item.priority;
    _completed = widget.item.completed;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: widget.item.id == null ? 'New to-do' : 'Edit to-do',
      deleteEnabled: widget.item.id != null,
      onDelete: () => Navigator.of(context).pop(const _EditorResult.delete()),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MqInput(
              label: 'Title',
              controller: _titleController,
              prefixIcon: Icons.check_circle_outline,
              validator: (value) =>
                  Validators.required(value, fieldName: 'Title'),
            ),
            const SizedBox(height: MqSpacing.space4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Due date'),
              subtitle: Text(
                _dueDate == null
                    ? 'No due date'
                    : DateFormat('EEE d MMM, h:mm a').format(_dueDate!),
              ),
              trailing: _dueDate == null
                  ? null
                  : IconButton(
                      onPressed: () {
                        setState(() {
                          _dueDate = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: MqSpacing.space4),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _priority = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Priority',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: MqSpacing.space4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Completed'),
              value: _completed,
              onChanged: (value) {
                setState(() {
                  _completed = value;
                });
              },
            ),
            const SizedBox(height: MqSpacing.space4),
            MqInput(
              label: 'Description',
              controller: _descriptionController,
              prefixIcon: Icons.notes_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: MqSpacing.space6),
            MqButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await _pickDateTime(context, _dueDate ?? DateTime.now());
    if (picked == null) {
      return;
    }
    setState(() {
      _dueDate = picked;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _EditorResult.save(
        widget.item.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate,
          priority: _priority,
          completed: _completed,
          completedAt: _completed ? DateTime.now() : null,
        ),
      ),
    );
  }
}

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({
    required this.title,
    required this.child,
    required this.deleteEnabled,
    required this.onDelete,
  });

  final String title;
  final Widget child;
  final bool deleteEnabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MqSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (deleteEnabled)
                    TextButton(
                      onPressed: onDelete,
                      child: const Text('Delete'),
                    ),
                ],
              ),
              const SizedBox(height: MqSpacing.space4),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> _pickDateTime(
  BuildContext context,
  DateTime initialValue,
) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: initialValue,
    firstDate: DateTime(initialValue.year - 1),
    lastDate: DateTime(initialValue.year + 3),
  );
  if (pickedDate == null || !context.mounted) {
    return null;
  }

  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialValue),
  );
  if (pickedTime == null) {
    return null;
  }

  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}

IconData _iconForType(AcademicItemType type) {
  return switch (type) {
    AcademicItemType.deadline => Icons.assignment_outlined,
    AcademicItemType.exam => Icons.quiz_outlined,
    AcademicItemType.event => Icons.event_outlined,
    AcademicItemType.todo => Icons.check_circle_outline,
  };
}
