import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/core/utils/validators.dart';
import 'package:mq_navigation/features/profiles/presentation/controllers/profile_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/models/user_profile.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_input.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _facultyController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _facultyController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _seedFields(UserProfile? profile) {
    if (_seeded || profile == null) {
      return;
    }
    _seeded = true;
    _fullNameController.text = profile.fullName ?? '';
    _studentIdController.text = profile.studentId ?? '';
    _facultyController.text = profile.faculty ?? '';
    _courseController.text = profile.course ?? '';
    _yearController.text = profile.year ?? '';
  }

  Future<void> _save(UserProfile? profile) async {
    if (!_formKey.currentState!.validate() || profile == null) {
      return;
    }

    final updatedProfile = profile.copyWith(
      fullName: _fullNameController.text,
      studentId: _studentIdController.text,
      faculty: _facultyController.text,
      course: _courseController.text,
      year: _yearController.text,
    );
    final message = await ref
        .read(profileControllerProvider.notifier)
        .saveProfile(updatedProfile);
    if (!mounted) {
      return;
    }
    if (message != null) {
      context.showSnackBar(message, isError: true);
      return;
    }
    if (widget.isOnboarding) {
      context.goNamed(RouteNames.home);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isOnboarding,
        title: Text(widget.isOnboarding ? 'Complete your profile' : 'Profile'),
      ),
      body: profileState.when(
        data: (profile) {
          _seedFields(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(MqSpacing.space4),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(MqSpacing.space5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            profile?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: MqSpacing.space4),
                          MqInput(
                            label: l10n.fullName,
                            controller: _fullNameController,
                            prefixIcon: Icons.badge_outlined,
                            validator: (value) => Validators.required(
                              value,
                              fieldName: l10n.fullName,
                            ),
                          ),
                          const SizedBox(height: MqSpacing.space4),
                          MqInput(
                            label: l10n.studentId,
                            controller: _studentIdController,
                            prefixIcon: Icons.perm_identity_outlined,
                            validator: (value) => Validators.required(
                              value,
                              fieldName: l10n.studentId,
                            ),
                          ),
                          const SizedBox(height: MqSpacing.space4),
                          MqInput(
                            label: l10n.faculty,
                            controller: _facultyController,
                            prefixIcon: Icons.apartment_outlined,
                          ),
                          const SizedBox(height: MqSpacing.space4),
                          MqInput(
                            label: l10n.course,
                            controller: _courseController,
                            prefixIcon: Icons.menu_book_outlined,
                            validator: (value) => Validators.required(
                              value,
                              fieldName: l10n.course,
                            ),
                          ),
                          const SizedBox(height: MqSpacing.space4),
                          MqInput(
                            label: l10n.year,
                            controller: _yearController,
                            prefixIcon: Icons.school_outlined,
                          ),
                          const SizedBox(height: MqSpacing.space6),
                          MqButton(
                            label: l10n.save,
                            onPressed: () => _save(profile),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        error: (error, stackTrace) => const Center(
          child: Padding(
            padding: EdgeInsets.all(MqSpacing.space4),
            child: Text('Unable to load your profile.'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
