import 'package:flutter/material.dart';
import 'package:hopenglish/src/libs/logger.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/pages/word_learning_page.dart';
import 'package:hopenglish/src/pages/word_library_page.dart';
import 'package:hopenglish/src/services/app_settings_service.dart';
import 'package:hopenglish/src/services/category_service.dart';
import 'package:hopenglish/src/services/lesson_session_service.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/widgets/category_card.dart';
import 'package:hopenglish/src/widgets/lesson_settings_sheet.dart';

final _logger = Logger.getLogger();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<Category>> _categoriesFuture;
  int _lessonSize = AppSettingsService.defaultLessonWordCount;
  String? _loadingCategoryId;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryService.loadCategories();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final value = await AppSettingsService.instance.getLessonWordCount();
    if (mounted) setState(() => _lessonSize = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppTheme.spacingLarge),
                Expanded(child: _buildCategoryGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text('HopEnglish', style: AppTheme.headlineMedium),
        ),
        _headerButton(
          icon: Icons.auto_stories_rounded,
          tooltip: 'Word Library',
          onTap: _openLibrary,
        ),
        const SizedBox(width: 10),
        _headerButton(
          icon: Icons.settings_rounded,
          tooltip: '课程设置',
          onTap: _openSettings,
        ),
      ],
    );
  }

  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          _logger.error('加载分类失败', error: snapshot.error);
          return const Center(child: Text('Please try again'));
        }
        final categories = snapshot.data ?? [];
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.spacingMedium,
            mainAxisSpacing: AppTheme.spacingMedium,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: CategoryCard(
                    category: category,
                    onTap: _loadingCategoryId == null
                        ? () => _startLesson(category)
                        : null,
                  ),
                ),
                if (_loadingCategoryId == category.id)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startLesson(Category category) async {
    setState(() => _loadingCategoryId = category.id);
    try {
      final plan = await LessonSessionService.instance.buildLesson(
        category: category,
        lessonSize: _lessonSize,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WordLearningPage(
            plan: plan,
            lessonSize: _lessonSize,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingCategoryId = null);
    }
  }

  Future<void> _openLibrary() async {
    final categories = await _categoriesFuture;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WordLibraryPage(categories: categories),
      ),
    );
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LessonSettingsSheet(
        selectedCount: _lessonSize,
        onChanged: (value) {
          setState(() => _lessonSize = value);
        },
      ),
    );
  }
}
