# StudyMate AI — Mobile Application (Flutter Material 3)

Ứng dụng Hỗ Trợ Học Tập Thông Minh & Rèn Luyện Kỷ Luật Tích Hợp Trí Tuệ Nhân Tạo.

## 📱 Phân Hệ Đã Phát Triển & Hoàn Thiện (Đào Thị Yến — K65KTPM)

### 1. Phân hệ Hệ thống & Xác thực (Auth System — Sprint 1 / Issue #1)
- **Màn hình Splash (`views/auth/splash_screen.dart`):** Logo hoạt họa StudyMate AI với hiệu ứng scale, pulse và glow gradient Indigo-Purple, tự động chuyển cảnh mượt mà.
- **Màn hình Onboarding (`views/auth/onboarding_screen.dart`):** `PageView` 3 bước vuốt ngang giới thiệu 3 tính năng cốt lõi:
  1. *Luyện phát âm AI* (NLTK CMUDict/IPA đối chiếu âm vị).
  2. *Đồng hồ Pomodoro* (Rèn luyện kỷ luật, chuỗi Streak 🔥).
  3. *Thẻ Flashcards SM-2* (Lặp lại ngắt quãng, thẻ lật 3D).
- **Form Đăng nhập & Đăng ký (`views/auth/login_screen.dart`, `register_screen.dart`):** Form chuẩn Material 3, kiểm tra hợp lệ toàn diện (Email định dạng chuẩn, Mật khẩu >= 6 ký tự, khớp xác nhận mật khẩu), chống tràn viền (No RenderFlex overflow).
- **Đa chủ đề (`theme/app_theme.dart`, `providers/theme_provider.dart`):** Chuyển đổi mượt mà giữa Light Theme và Dark Theme với nút bấm hoạt họa `ThemeToggleButton`.

### 2. Phân hệ Trang chủ & Kỷ luật (Dashboard & Discipline — Sprint 2 / Issue #2)
- **Thẻ Chuỗi kỷ luật (`views/dashboard/widgets/streak_card.dart`):** Biểu tượng ngọn lửa hoạt họa (`Streak Flame 🔥`), hiển thị số ngày streak hiện tại và kỉ lục chuỗi ngày học.
- **Vòng tròn mục tiêu ngày (`views/dashboard/widgets/daily_goal_progress_ring.dart`):** Vòng tròn tiến độ hoạt họa `TweenAnimationBuilder` hiển thị số phút học hôm nay (ví dụ: hoàn thành 25/30 phút, 83%).
- **Bản đồ nhiệt độ học tập 30 ngày (`views/dashboard/widgets/monthly_heatmap_grid.dart`):** Thiết kế 30 ô vuông theo phong cách GitHub Contribution với 5 cấp độ màu xanh lá tăng dần theo mức độ học tập, hỗ trợ chạm xem chi tiết từng ngày.
- **Dải chọn ngày cuộn ngang (`views/dashboard/widgets/date_selector_strip.dart`):** Duyệt 7 ngày trong tuần, chấm trạng thái hoàn thành và nút quay về "Hôm nay".
- **Quản lý dữ liệu thời gian thực (`providers/discipline_provider.dart`):** Tự động tăng điểm Streak và cập nhật Heatmap khi người dùng hoàn thành phiên học.

### 3. Phân hệ Đồng hồ tập trung Pomodoro (Focus Pomodoro — Sprint 3 / Issue #3)
- **Vòng tròn đếm ngược hoạt họa (`views/pomodoro/widgets/circular_timer_widget.dart`):** Hiển thị số phút/giây `mm:ss`, tự động đổi màu theo chế độ (Tập trung: Đỏ cam, Nghỉ ngắn: Xanh ngọc, Nghỉ dài: Xanh dương).
- **Cụm điều khiển linh hoạt (`views/pomodoro/widgets/timer_controls.dart`):** Bắt đầu (Start), Tạm dừng (Pause), Đặt lại (Reset), Bỏ qua (Skip).
- **Tùy chỉnh thời gian Settings (`views/pomodoro/widgets/pomodoro_settings_sheet.dart`):** Thanh trượt tùy biến thời gian 25 phút tập trung, 5 phút nghỉ ngắn, 15 phút nghỉ dài, bật/tắt âm thanh chuông.
- **Chế độ khóa xao nhãng (`views/pomodoro/widgets/distraction_lock_view.dart`):** Giữ màn hình luôn sáng (Wakelock), nền tối sâu chống mỏi mắt, hiển thị câu danh ngôn truyền cảm hứng học tập và chống vô tình chạm thoát phiên học.
- **Chuông báo & SQLite (`services/pomodoro_database_helper.dart`, `providers/pomodoro_provider.dart`):** Tự động phát âm thanh chuông báo khi về `00:00` và tự động lưu phiên học vào cơ sở dữ liệu SQLite.

---

## 🚀 Hướng Dẫn Chạy Ứng Dụng

```bash
# 1. Di chuyển vào thư mục dự án
cd nhom19-65ktpm/src/mobile

# 2. Cài đặt các gói thư viện
flutter pub get

# 3. Chạy ứng dụng trên máy ảo hoặc thiết bị
flutter run

# 4. Chạy trên trình duyệt Web (nhẹ và nhanh nhất)
flutter run -d chrome

# 5. Chạy bộ kiểm thử tự động
flutter test
```
