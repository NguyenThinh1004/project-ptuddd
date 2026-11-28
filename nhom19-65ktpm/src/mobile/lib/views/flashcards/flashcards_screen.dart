import 'package:flutter/material.dart';

import '../../services/flashcard_repository.dart';
import 'flashcard_deck_screen.dart';
import 'flashcard_quiz_screen.dart';
import 'flashcard_review_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, this.repository});

  final FlashcardRepository? repository;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late final FlashcardRepository _repository;
  List<FlashcardCategory> _categories = const [];
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SqliteFlashcardRepository();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final categories = await _repository.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCategoryDialog({FlashcardCategory? category}) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryFormDialog(category: category),
    );
    if (name == null) return;

    try {
      if (category == null) {
        await _repository.createCategory(name);
      } else {
        await _repository.renameCategory(category.id, name);
      }
      await _loadCategories();
    } catch (error) {
      _showError('Không thể lưu môn học: $error');
    }
  }

  Future<void> _deleteCategory(FlashcardCategory category) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa môn học?'),
        content: Text(
          'Môn học “${category.name}” và toàn bộ ${category.cardCount} thẻ '
          'trong bộ sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await _repository.deleteCategory(category.id);
      await _loadCategories();
    } catch (error) {
      _showError('Không thể xóa môn học: $error');
    }
  }

  Future<void> _openDeck(FlashcardCategory category) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlashcardDeckScreen(
          category: category,
          repository: _repository,
        ),
      ),
    );
    if (mounted) await _loadCategories();
  }

  Future<void> _openReview(FlashcardCategory category) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlashcardReviewScreen(
          category: category,
          repository: _repository,
        ),
      ),
    );
    if (mounted) await _loadCategories();
  }

  Future<void> _openQuiz(FlashcardCategory category) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlashcardQuizScreen(
          category: category,
          repository: _repository,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flashcards 3D & Quiz',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Tạo môn học',
            onPressed: () => _showCategoryDialog(),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Text(
              'Chọn một môn học để quản lý thẻ, ôn tập theo SM-2 hoặc làm quiz.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              _buildLoadError(theme)
            else if (_categories.isEmpty)
              _buildEmptyState(theme)
            else
              for (final category in _categories)
                _buildCategoryCard(category, theme, isDark),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm môn'),
      ),
    );
  }

  Widget _buildCategoryCard(
    FlashcardCategory category,
    ThemeData theme,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${category.cardCount} thẻ trong bộ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Quản lý môn học',
                  onSelected: (action) {
                    if (action == 'rename') {
                      _showCategoryDialog(category: category);
                    } else if (action == 'delete') {
                      _deleteCategory(category);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text('Đổi tên'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Xóa môn học'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openDeck(category),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Quản lý thẻ'),
                ),
                FilledButton.tonalIcon(
                  onPressed: category.cardCount == 0
                      ? null
                      : () => _openReview(category),
                  icon: const Icon(Icons.style_rounded, size: 18),
                  label: const Text('Ôn tập'),
                ),
                FilledButton.icon(
                  onPressed:
                      category.cardCount < 4 ? null : () => _openQuiz(category),
                  icon: const Icon(Icons.quiz_rounded, size: 18),
                  label: const Text('Làm Quiz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(
            Icons.library_add_outlined,
            size: 54,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có môn học nào',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text('Tạo môn học đầu tiên để bắt đầu thêm thẻ.'),
        ],
      ),
    );
  }

  Widget _buildLoadError(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          const Text('Không thể tải danh sách môn học.'),
          TextButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
          Text(
            'Lỗi: $_loadError',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({required this.category});

  final FlashcardCategory? category;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.category == null ? 'Thêm môn học' : 'Đổi tên môn học',
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Tên môn học'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Vui lòng nhập tên môn học.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
