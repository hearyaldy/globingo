import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/language_chip.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Personal Info
  final _nameController = TextEditingController(text: '小明');
  final _emailController = TextEditingController(text: 'xiaoming@example.com');
  final _bioController = TextEditingController(text: '熱愛教學，喜歡幫助別人學習中文！');

  // Language Preferences
  String _interfaceLanguage = '繁體中文';
  String _nativeLanguage = '中文';
  final List<String> _learningLanguages = ['English', 'Japanese'];

  // Teacher Profile
  bool _openForTeaching = true;
  final List<String> _teachingLanguages = ['Chinese'];
  final _hourlyRateController = TextEditingController(text: '25');
  final _teachingBioController = TextEditingController(
    text: '熱愛教學，喜歡幫助別人學習中文！',
  );

  // Notifications
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _bookingReminders = true;
  bool _newReviewNotifications = true;
  bool _marketingMessages = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSettings();
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _teachingBioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please log in to view settings.'));
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: Responsive.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.accountSettings, style: AppTypography.h1),
          const SizedBox(height: 24),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: isMobile,
              indicator: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: 8),
                      Text(AppStrings.personalInfo),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.language, size: 18),
                      const SizedBox(width: 8),
                      Text(AppStrings.languagePreferences),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(AppStrings.teacherProfile),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(AppStrings.notifications),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (isMobile)
            _buildActiveTabContent()
          else
            SizedBox(
              height: 600,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalInfoTab(isMobile),
                  _buildLanguagePreferencesTab(),
                  _buildTeacherProfileTab(isMobile),
                  _buildNotificationsTab(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildPersonalInfoTab(true);
      case 1:
        return _buildLanguagePreferencesTab();
      case 2:
        return _buildTeacherProfileTab(true);
      case 3:
      default:
        return _buildNotificationsTab();
    }
  }

  Widget _buildPersonalInfoTab(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.personalInfo, style: AppTypography.h4),
          const SizedBox(height: 4),
          Text(
            AppStrings.updatePersonalInfo,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Avatar
          Row(
            children: [
              AvatarWidget(
                name: _nameController.text.trim().isEmpty
                    ? 'User'
                    : _nameController.text.trim(),
                size: 80,
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                child: Text(
                  AppStrings.changeAvatar,
                  style: AppTypography.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Name and Email
          if (isMobile)
            Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.name, style: AppTypography.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.email, style: AppTypography.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.name, style: AppTypography.labelLarge),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.email, style: AppTypography.labelLarge),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Bio
          Text(AppStrings.bio, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isSaving ? null : _savePersonalInfo,
            child: Text(AppStrings.save, style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePreferencesTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.languagePreferences, style: AppTypography.h4),
          const SizedBox(height: 4),
          Text(
            'Set your language preferences',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Interface Language
          Text(AppStrings.interfaceLanguage, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _interfaceLanguage,
                isExpanded: true,
                items: ['繁體中文', 'English', '日本語']
                    .map(
                      (lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang, style: AppTypography.bodyMedium),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _interfaceLanguage = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Native Language
          Text(AppStrings.nativeLanguage, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _nativeLanguage,
                isExpanded: true,
                items: ['中文', 'English', '日本語', '한국어']
                    .map(
                      (lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang, style: AppTypography.bodyMedium),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _nativeLanguage = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Learning Languages
          Text(AppStrings.learningLanguages, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._learningLanguages.map(
                (lang) => LanguageChip(
                  language: lang,
                  isPrimary: true,
                  onDelete: () {
                    setState(() => _learningLanguages.remove(lang));
                  },
                ),
              ),
              AddLanguageChip(
                onTap: () => _showAddLanguageDialog(
                  title: 'Add learning language',
                  onAdd: (lang) {
                    if (!_learningLanguages.contains(lang)) {
                      setState(() => _learningLanguages.add(lang));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveLanguagePreferences,
            child: Text(AppStrings.save, style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherProfileTab(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.teacherProfile, style: AppTypography.h4),
          const SizedBox(height: 4),
          Text(
            'Set up your teaching profile',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Open for Teaching Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.openForTeaching,
                        style: AppTypography.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.allowBookings,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _openForTeaching,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) =>
                      setState(() => _openForTeaching = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Teaching Languages
          Text(AppStrings.teachingLanguages, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._teachingLanguages.map(
                (lang) => LanguageChip(
                  language: lang,
                  isPrimary: true,
                  onDelete: () {
                    setState(() => _teachingLanguages.remove(lang));
                  },
                ),
              ),
              AddLanguageChip(
                onTap: () => _showAddLanguageDialog(
                  title: 'Add teaching language',
                  onAdd: (lang) {
                    if (!_teachingLanguages.contains(lang)) {
                      setState(() => _teachingLanguages.add(lang));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Hourly Rate
          Text(AppStrings.hourlyRate, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            width: isMobile ? double.infinity : 200,
            child: TextField(
              controller: _hourlyRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Teaching Bio
          Text(AppStrings.teachingBio, style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _teachingBioController,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isSaving ? null : _saveTeacherProfile,
            child: Text(AppStrings.save, style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.notifications, style: AppTypography.h4),
          const SizedBox(height: 4),
          Text(
            'Manage your notification preferences',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          _NotificationToggle(
            title: AppStrings.emailNotifications,
            value: _emailNotifications,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),
          _NotificationToggle(
            title: AppStrings.pushNotifications,
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          _NotificationToggle(
            title: AppStrings.bookingReminders,
            value: _bookingReminders,
            onChanged: (v) => setState(() => _bookingReminders = v),
          ),
          _NotificationToggle(
            title: AppStrings.newReviewNotifications,
            value: _newReviewNotifications,
            onChanged: (v) => setState(() => _newReviewNotifications = v),
          ),
          _NotificationToggle(
            title: AppStrings.marketingMessages,
            value: _marketingMessages,
            onChanged: (v) => setState(() => _marketingMessages = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveNotifications,
            child: Text(AppStrings.save, style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddLanguageDialog({
    required String title,
    required ValueChanged<String> onAdd,
  }) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Language',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final lang = controller.text.trim();
              if (lang.isEmpty) return;
              onAdd(lang);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return <String>[];
    return value
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userFuture = firestore.collection('users').doc(user.uid).get();
      final teacherFuture = firestore
          .collection('teachers')
          .doc(user.uid)
          .get();
      final results = await Future.wait<DocumentSnapshot<Map<String, dynamic>>>(
        [userFuture, teacherFuture],
      );
      final userData = results[0].data() ?? const <String, dynamic>{};
      final teacherData = results[1].data() ?? const <String, dynamic>{};

      _nameController.text =
          (userData['displayName'] as String?)?.trim().isNotEmpty == true
          ? (userData['displayName'] as String).trim()
          : (user.displayName ?? '');
      _emailController.text =
          (userData['email'] as String?)?.trim().isNotEmpty == true
          ? (userData['email'] as String).trim()
          : (user.email ?? '');
      _bioController.text = (userData['bio'] as String?) ?? _bioController.text;

      final interfaceLanguage = userData['interfaceLanguage'] as String?;
      final nativeLanguage = userData['nativeLanguage'] as String?;
      final learningLanguages = _asStringList(userData['learningLanguages']);
      final notifications =
          userData['notifications'] as Map<String, dynamic>? ??
          const <String, dynamic>{};

      _interfaceLanguage = interfaceLanguage ?? _interfaceLanguage;
      _nativeLanguage = nativeLanguage ?? _nativeLanguage;
      if (learningLanguages.isNotEmpty) {
        _learningLanguages
          ..clear()
          ..addAll(learningLanguages);
      }

      _emailNotifications =
          notifications['emailNotifications'] as bool? ?? _emailNotifications;
      _pushNotifications =
          notifications['pushNotifications'] as bool? ?? _pushNotifications;
      _bookingReminders =
          notifications['bookingReminders'] as bool? ?? _bookingReminders;
      _newReviewNotifications =
          notifications['newReviewNotifications'] as bool? ??
          _newReviewNotifications;
      _marketingMessages =
          notifications['marketingMessages'] as bool? ?? _marketingMessages;

      _openForTeaching =
          (teacherData['isActive'] as bool?) ??
          (userData['teachingModeEnabled'] as bool?) ??
          _openForTeaching;
      _teachingBioController.text =
          (teacherData['bio'] as String?) ?? _teachingBioController.text;
      _hourlyRateController.text =
          ((teacherData['hourlyRate'] as num?)?.toDouble() ?? 25).toString();

      final teachingLanguages = _asStringList(teacherData['teachingLanguages']);
      if (teachingLanguages.isNotEmpty) {
        _teachingLanguages
          ..clear()
          ..addAll(teachingLanguages);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load settings.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _savePersonalInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      final displayName = _nameController.text.trim();
      final bio = _bioController.text.trim();
      await _saveUserData({
        'displayName': displayName,
        'email': _emailController.text.trim(),
        'bio': bio,
      });
      await user.updateDisplayName(displayName);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save profile.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveLanguagePreferences() async {
    setState(() => _isSaving = true);
    try {
      await _saveUserData({
        'interfaceLanguage': _interfaceLanguage,
        'nativeLanguage': _nativeLanguage,
        'learningLanguages': _learningLanguages,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Language settings saved.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save language settings.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveTeacherProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hourlyRate = double.tryParse(_hourlyRateController.text.trim());
    if (hourlyRate == null || hourlyRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid hourly rate.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final teacherRef = firestore.collection('teachers').doc(user.uid);

      await _saveUserData({'teachingModeEnabled': true});

      await teacherRef.set({
        'uid': user.uid,
        'name': _nameController.text.trim().isEmpty
            ? (user.displayName ?? 'Teacher')
            : _nameController.text.trim(),
        'bio': _teachingBioController.text.trim(),
        'teachingLanguages': _teachingLanguages,
        'hourlyRate': hourlyRate,
        'isActive': _openForTeaching,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!_openForTeaching) {
        await _saveUserData({'teachingModeEnabled': false});
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Teacher profile saved.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save teacher profile.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveNotifications() async {
    setState(() => _isSaving = true);
    try {
      await _saveUserData({
        'notifications': {
          'emailNotifications': _emailNotifications,
          'pushNotifications': _pushNotifications,
          'bookingReminders': _bookingReminders,
          'newReviewNotifications': _newReviewNotifications,
          'marketingMessages': _marketingMessages,
        },
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save notifications.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _NotificationToggle extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.bodyMedium),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
