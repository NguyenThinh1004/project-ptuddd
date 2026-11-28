import 'package:flutter/material.dart';

import '../../services/flashcard_repository.dart';
import 'flashcard_quiz_screen.dart';
import 'flashcard_review_screen.dart';

class FlashcardDeckScreen extends StatefulWidget {
  const FlashcardDeckScreen({
    super.key,
    required this.category,
    required this.repository,
  });

  final FlashcardCategory category;
  final FlashcardRepository repository;

  @override
  State<FlashcardDeckScreen> createState() => _FlashcardDeckScreenState();
}

class _FlashcardDeckScreenState extends State<FlashcardDeckScreen> {
  List<StudyFlashcard> _cards = const [];
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final cards = await widget.repository.getCards(widget.category.id);
      if (mounted) {
        setState(() {
          _cards = cards;
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

  Future<void> _showCardDialog({StudyFlashcard? card}) async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => _FlashcardFormDialog(card: card),
    );
    if (values == null) return;

    try {
      if (card == null) {
        await widget.repository.createCard(
          subjectId: widget.category.id,
          front: values[0],
          back: values[1],
          ipa: values[2],
          example: values[3],
        );
      } else {
        await widget.repository.updateCard(
          cardId: card.id,
          front: values[0],
          back: values[1],
          ipa: values[2],
          example: values[3],
        );
      }
      await _loadCards();
    } catch (error) {
      _showError('Không thể lưu flashcard: $error');
    }
  }

  Future<void> _deleteCard(StudyFlashcard card) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa flashcard?'),
        content: Text('Bạn có chắc muốn xóa “${card.front}”?'),
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
      await widget.repository.deleteCard(card.id);
      await _loadCards();
    } catch (error) {
      _showError('Không thể xóa flashcard: $error');
    }
  }

  Future<void> _openReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlashcardReviewScreen(
          category: widget.category,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted) await _loadCards();
  }

  Future<void> _openQuiz() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlashcardQuizScreen(
          category: widget.category,
          repository: widget.repository,
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
    final uniqueAnswers = _cards
        .map((card) => card.back.trim().toLowerCase())
        .where((answer) => answer.isNotEmpty)
        .toSet()
        .length;
    final canTakeQuiz = uniqueAnswers >= 4;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Ôn tập thẻ đến hạn',
            onPressed: _cards.isEmpty ? null : _openReview,
            icon: const Icon(Icons.style_rounded),
          ),
          IconButton(
            tooltip: 'Làm quiz',
            onPressed: canTakeQuiz ? _openQuiz : null,
            icon: const Icon(Icons.quiz_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildLoadError(theme)
              : _cards.isEmpty
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: _loadCards,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: _cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildFlashcard(_cards[index], theme),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCardDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm thẻ'),
      ),
    );
  }

  Widget _buildFlashcard(StudyFlashcard card, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.front,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(card.back),
                  if (card.ipa?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      card.ipa!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                  if (card.example?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      card.example!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') {
                  _showCardDialog(card: card);
                } else if (action == 'delete') {
                  _deleteCard(card);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                PopupMenuItem(value: 'delete', child: Text('Xóa thẻ')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.style_outlined,
              size: 52,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Bộ thẻ đang trống',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Thêm thẻ đầu tiên cho môn học này.'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Không thể tải bộ thẻ: $_loadError'),
            TextButton(
              onPressed: _loadCards,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardFormDialog extends StatefulWidget {
  const _FlashcardFormDialog({required this.card});

  final StudyFlashcard? card;

  @override
  State<_FlashcardFormDialog> createState() => _FlashcardFormDialogState();
}

class _FlashcardFormDialogState extends State<_FlashcardFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  late final TextEditingController _ipaController;
  late final TextEditingController _exampleController;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card?.front ?? '');
    _backController = TextEditingController(text: widget.card?.back ?? '');
    _ipaController = TextEditingController(text: widget.card?.ipa ?? '');
    _exampleController =
        TextEditingController(text: widget.card?.example ?? '');
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _ipaController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Trường này không được để trống.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.card == null ? 'Thêm flashcard' : 'Chỉnh sửa flashcard',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _frontController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mặt trước: từ / khái niệm',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _backController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mặt sau: định nghĩa',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ipaController,
                decoration: const InputDecoration(
                  labelText: 'Phiên âm IPA (tùy chọn)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _exampleController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ví dụ minh họa (tùy chọn)',
                ),
              ),
            ],
          ),
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
              Navigator.pop(context, [
                _frontController.text.trim(),
                _backController.text.trim(),
                _ipaController.text.trim(),
                _exampleController.text.trim(),
              ]);
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
