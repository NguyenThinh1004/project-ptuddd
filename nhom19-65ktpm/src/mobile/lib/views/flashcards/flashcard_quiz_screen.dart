import 'package:flutter/material.dart';

import '../../services/flashcard_repository.dart';

class FlashcardQuizScreen extends StatefulWidget {
  const FlashcardQuizScreen({
    super.key,
    required this.category,
    required this.repository,
  });

  final FlashcardCategory category;
  final FlashcardRepository repository;

  @override
  State<FlashcardQuizScreen> createState() => _FlashcardQuizScreenState();
}

class _FlashcardQuizScreenState extends State<FlashcardQuizScreen> {
  List<FlashcardQuizQuestion> _questions = const [];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _selectedIndex = null;
      _currentIndex = 0;
      _score = 0;
    });
    try {
      final cards = await widget.repository.getCards(widget.category.id);
      final questions = buildFlashcardQuiz(cards);
      if (mounted) {
        setState(() {
          _questions = questions;
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

  void _selectAnswer(int index) {
    if (_selectedIndex != null) return;
    setState(() {
      _selectedIndex = index;
      if (index == _questions[_currentIndex].correctIndex) {
        _score++;
      }
    });
  }

  void _continue() {
    if (_selectedIndex == null) return;
    if (_currentIndex == _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
      });
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz · ${widget.category.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildLoadError(theme)
                : _questions.isEmpty
                    ? _buildNotEnoughCards(theme)
                    : _currentIndex >= _questions.length
                        ? _buildResults(theme)
                        : _buildQuestion(theme),
      ),
    );
  }

  Widget _buildQuestion(ThemeData theme) {
    final question = _questions[_currentIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Câu ${_currentIndex + 1} / ${_questions.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Điểm: $_score',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Text(
            'Chọn đáp án đúng',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.prompt,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final isCorrect = index == question.correctIndex;
                final isSelected = index == _selectedIndex;
                final showFeedback = _selectedIndex != null;
                final color = showFeedback && isCorrect
                    ? const Color(0xFF059669)
                    : showFeedback && isSelected
                        ? theme.colorScheme.error
                        : theme.colorScheme.outlineVariant;
                return OutlinedButton(
                  onPressed: _selectedIndex == null
                      ? () => _selectAnswer(index)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    alignment: Alignment.centerLeft,
                    side: BorderSide(
                      color: showFeedback && (isCorrect || isSelected)
                          ? color
                          : theme.colorScheme.outlineVariant,
                      width: showFeedback && (isCorrect || isSelected)
                          ? 1.6
                          : 1,
                    ),
                    backgroundColor: showFeedback && (isCorrect || isSelected)
                        ? color.withValues(alpha: 0.08)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: showFeedback && (isCorrect || isSelected)
                            ? Icon(
                                isCorrect
                                    ? Icons.check_rounded
                                    : Icons.close_rounded,
                                size: 18,
                                color: color,
                              )
                            : Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.options[index],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_selectedIndex != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_selectedIndex == question.correctIndex
                        ? const Color(0xFF059669)
                        : theme.colorScheme.error)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _selectedIndex == question.correctIndex
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: _selectedIndex == question.correctIndex
                        ? const Color(0xFF059669)
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedIndex == question.correctIndex
                          ? 'Chính xác! ${question.explanation}'
                          : 'Chưa đúng. Đáp án: '
                              '${question.options[question.correctIndex]}\n'
                              '${question.explanation}',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _continue,
              icon: Icon(
                _currentIndex == _questions.length - 1
                    ? Icons.flag_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                _currentIndex == _questions.length - 1
                    ? 'Xem kết quả'
                    : 'Câu tiếp theo',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final percentage = (_score / _questions.length * 100).round();
    final message = percentage >= 80
        ? 'Làm tốt lắm! Bạn đã nắm rất chắc bộ thẻ.'
        : percentage >= 50
            ? 'Khá tốt! Ôn lại các thẻ sai để ghi nhớ lâu hơn.'
            : 'Hãy ôn flashcard thêm một lượt rồi thử lại nhé.';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= 80
                  ? Icons.emoji_events_rounded
                  : Icons.fact_check_rounded,
              size: 68,
              color: percentage >= 80
                  ? const Color(0xFFF59E0B)
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Hoàn thành Quiz!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_score / ${_questions.length} câu đúng · $percentage%',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadQuiz,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Làm lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotEnoughCards(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa đủ đáp án cho Quiz',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cần ít nhất 4 thẻ có định nghĩa khác nhau để tạo câu hỏi 4 lựa chọn.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.style_rounded),
              label: const Text('Quay lại quản lý thẻ'),
            ),
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
            Text('Không thể tải câu hỏi: $_loadError'),
            TextButton(
              onPressed: _loadQuiz,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
