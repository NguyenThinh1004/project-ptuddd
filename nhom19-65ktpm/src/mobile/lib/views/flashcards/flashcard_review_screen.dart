import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/flashcard_repository.dart';
import '../../services/sm2_service.dart';

class FlashcardReviewScreen extends StatefulWidget {
  const FlashcardReviewScreen({
    super.key,
    required this.category,
    required this.repository,
  });

  final FlashcardCategory category;
  final FlashcardRepository repository;

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  List<StudyFlashcard> _cards = const [];
  int _currentIndex = 0;
  Object? _loadError;
  bool _isLoading = true;
  bool _isSavingReview = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _loadDueCards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadDueCards() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final cards = await widget.repository.getDueCards(widget.category.id);
      if (mounted) {
        setState(() {
          _cards = cards;
          _currentIndex = 0;
          _isLoading = false;
        });
        _flipController.value = 0;
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

  void _toggleFlip() {
    if (_isSavingReview) return;
    if (_flipController.isAnimating) return;
    if (_flipController.value < 0.5) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -120) {
      _moveCard(1);
    } else if (velocity > 120) {
      _moveCard(-1);
    }
  }

  void _moveCard(int offset) {
    if (_cards.isEmpty || _isSavingReview) return;
    final nextIndex = _currentIndex + offset;
    if (nextIndex < 0 || nextIndex >= _cards.length) return;
    setState(() {
      _currentIndex = nextIndex;
    });
    _flipController.value = 0;
  }

  Future<void> _rateCard(ReviewRating rating) async {
    if (_cards.isEmpty || _flipController.value < 0.5 || _isSavingReview) {
      return;
    }
    final card = _cards[_currentIndex];
    setState(() {
      _isSavingReview = true;
    });

    try {
      final result = await widget.repository.reviewCard(
        card: card,
        quality: Sm2Service.qualityFromRating(rating),
      );
      if (!mounted) return;
      setState(() {
        _cards = [..._cards]..removeAt(_currentIndex);
        if (_currentIndex >= _cards.length && _currentIndex > 0) {
          _currentIndex--;
        }
        _isSavingReview = false;
      });
      _flipController.value = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu lịch ôn tiếp theo sau ${result.nextInterval} ngày.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSavingReview = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu đánh giá: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ôn tập · ${widget.category.name}',
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
                : _cards.isEmpty
                    ? _buildCompleteState(theme)
                    : _buildReviewContent(theme),
      ),
    );
  }

  Widget _buildReviewContent(ThemeData theme) {
    final card = _cards[_currentIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Thẻ ${_currentIndex + 1} / ${_cards.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Vuốt để chuyển thẻ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _cards.length,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: _handleSwipe,
              onTap: _toggleFlip,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, animation) {
                  final position = Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: position, child: child),
                  );
                },
                child: _buildFlipCard(card, theme, key: ValueKey(card.id)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _flipController,
            builder: (context, _) => Column(
              children: [
                Text(
                  _flipController.value >= 0.5
                      ? 'Bạn nhớ thẻ này đến mức nào?'
                      : 'Chạm vào thẻ để lật và xem đáp án',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ratingButton(
                        label: 'Khó',
                        subtitle: 'Ôn lại ngày mai',
                        icon: Icons.replay_rounded,
                        color: const Color(0xFFDC2626),
                        rating: ReviewRating.hard,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ratingButton(
                        label: 'Vừa',
                        subtitle: 'Ôn lại sớm',
                        icon: Icons.check_rounded,
                        color: const Color(0xFFD97706),
                        rating: ReviewRating.medium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ratingButton(
                        label: 'Dễ',
                        subtitle: 'Giãn chu kỳ',
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF059669),
                        rating: ReviewRating.easy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipCard(
    StudyFlashcard card,
    ThemeData theme, {
    required Key key,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedBuilder(
      key: key,
      animation: _flipController,
      builder: (context, _) {
        final angle = _flipController.value * math.pi;
        final showFront = angle <= math.pi / 2;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: showFront
              ? _buildCardFace(
                  theme: theme,
                  isDark: isDark,
                  label: 'MẶT TRƯỚC',
                  content: card.front,
                  accent: theme.colorScheme.primary,
                  footer: 'Từ vựng · Khái niệm · Câu hỏi',
                )
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: _buildCardBack(card, theme, isDark),
                ),
        );
      },
    );
  }

  Widget _buildCardBack(
    StudyFlashcard card,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF1E293B), Color(0xFF25334A)]
              : const [Color(0xFFEEF2FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MẶT SAU',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            card.back,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          if (card.ipa?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              card.ipa!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontFamily: 'serif',
              ),
            ),
          ],
          if (card.example?.isNotEmpty == true) ...[
            const SizedBox(height: 18),
            Text(
              'Ví dụ',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              card.example!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardFace({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required String content,
    required Color accent,
    required String footer,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF1E293B), Color(0xFF263750)]
              : const [Colors.white, Color(0xFFF1F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, color: accent, size: 28),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Flexible(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            footer,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required ReviewRating rating,
  }) {
    final canRate = _flipController.value >= 0.5 && !_isSavingReview;
    return OutlinedButton(
      onPressed: canRate ? () => _rateCard(rating) : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.task_alt_rounded,
              size: 64,
              color: Color(0xFF10B981),
            ),
            const SizedBox(height: 14),
            Text(
              'Bạn đã ôn hết thẻ đến hạn!',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các đánh giá đã được lưu và chu kỳ ôn tập tiếp theo đã cập nhật.',
              textAlign: TextAlign.center,
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
            Text('Không thể tải thẻ ôn tập: $_loadError'),
            TextButton(
              onPressed: _loadDueCards,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
