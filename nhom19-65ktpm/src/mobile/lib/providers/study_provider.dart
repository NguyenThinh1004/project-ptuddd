import 'package:flutter/foundation.dart';
import '../models/learning_models.dart';
import '../services/ai_audio_service.dart';

class StudyProvider extends ChangeNotifier {
  final AiAudioService _service;
  StudyProvider(this._service);

  final List<StudySubject> subjects = [
    StudySubject(
      id: 'sub_1',
      name: 'Tiếng Anh Giao Tiếp & Phát Âm',
      materials: ['Slide Phonetics IPA.pdf', 'Danh sách từ vựng thường sai âm'],
      notes: ['Chú ý âm /θ/ và /ð/', 'Nhấn trọng âm câu'],
    ),
    StudySubject(
      id: 'sub_2',
      name: 'Phát Triển Ứng Dụng Di Động',
      materials: ['Tài liệu Flutter Material 3', 'REST API Spec'],
      notes: ['Tách riêng Service và Provider', 'Kiểm tra responsive'],
    ),
  ];

  final List<FlashcardItem> flashcards = [
    FlashcardItem(
      id: 'fc_1',
      subjectId: 'sub_1',
      front: 'Thorough',
      back: 'Kỹ lưỡng, thấu đáo',
      ipa: '/ˈθʌr.ə/',
    ),
    FlashcardItem(
      id: 'fc_2',
      subjectId: 'sub_1',
      front: 'Schedule',
      back: 'Lịch trình, kế hoạch',
      ipa: '/ˈʃed.juːl/ hoặc /ˈskedʒ.uːl/',
    ),
  ];

  final List<QuizQuestion> quizQuestions = [
    QuizQuestion(
      id: 'q_1',
      question: 'Màu nào hiển thị từ phát âm chuẩn trên màn hình Luyện phát âm AI?',
      options: ['Xanh lá', 'Đỏ', 'Xám', 'Tím'],
      correctIndex: 0,
    ),
    QuizQuestion(
      id: 'q_2',
      question: 'Hiệu ứng thẻ ghi nhớ cần hỗ trợ thao tác nào?',
      options: ['Lật 3D 2 mặt & chọn Dễ/Vừa/Khó', 'Chỉ đọc văn bản', 'Xóa thẻ sau 1 lần', 'Không cần lưu'],
      correctIndex: 0,
    ),
  ];

  int currentCardIndex = 0;
  bool isFlipped = false;
  bool isGeneratingCards = false;

  FlashcardItem? get currentCard =>
      flashcards.isEmpty ? null : flashcards[currentCardIndex % flashcards.length];

  void toggleFlip() {
    isFlipped = !isFlipped;
    notifyListeners();
  }

  void rateCard(RecallRating rating) {
    final card = currentCard;
    if (card != null) {
      if (rating == RecallRating.easy) card.easeLevel += 2;
      if (rating == RecallRating.medium) card.easeLevel += 1;
      if (rating == RecallRating.hard) card.easeLevel = 1;
    }
    isFlipped = false;
    if (flashcards.isNotEmpty) {
      currentCardIndex = (currentCardIndex + 1) % flashcards.length;
    }
    notifyListeners();
  }

  Future<void> generateAiCards(String promptText, String subjectId) async {
    isGeneratingCards = true;
    notifyListeners();
    final generated = await _service.generateFlashcardsFromText(promptText, subjectId);
    flashcards.addAll(generated);
    isGeneratingCards = false;
    notifyListeners();
  }

  void addSubject(String name) {
    if (name.trim().isEmpty) return;
    subjects.add(
      StudySubject(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
      ),
    );
    notifyListeners();
  }

  void addNoteToSubject(String subjectId, String note) {
    if (note.trim().isEmpty) return;
    final idx = subjects.indexWhere((s) => s.id == subjectId);
    if (idx != -1) {
      final updatedNotes = [...subjects[idx].notes, note.trim()];
      subjects[idx] = StudySubject(
        id: subjects[idx].id,
        name: subjects[idx].name,
        materials: subjects[idx].materials,
        notes: updatedNotes,
      );
      notifyListeners();
    }
  }
}
