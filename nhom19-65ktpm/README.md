## Hướng Dẫn

### Cài đặt môi trường máy tính
Cài đặt **Git**, **Flutter SDK 3.x**, **Android Studio**, **Python**

### Cấu hình định danh Git cá nhân
Mở Terminal và chạy (đảm bảo email trùng với tài khoản GitHub):
```bash
git config --global user.name "Họ và Tên Của Bạn"
git config --global user.email "email_cua_ban@example.com"
```

### Clone dự án về máy
Kho Fork chính thức của nhóm 19 đặt tại: `https://github.com/NguyenThinh1004/project-ptuddd.git`

Chạy các lệnh sau:
```bash
# Clone kho của nhóm
git clone https://github.com/NguyenThinh1004/project-ptuddd.git
cd project-ptuddd

# Chuyển sang nhánh chính thức của nhóm 19
git checkout nhom19-65ktpm

# Kéo mã nguồn mới nhất về
git pull origin nhom19-65ktpm
```

### Tạo nhánh làm việc cá nhân (Feature Branch)
**Tuyệt đối không commit trực tiếp trên nhánh `nhom19-65ktpm` hay `main`**. Mỗi thành viên khi làm tính năng mới sẽ tạo một nhánh riêng:
```bash
# Cú pháp: git checkout -b feature/nhom19/<ten-ban>-<tinh-nang>
# Ví dụ:
git checkout -b feature/nhom19/yen-design-figma
git checkout -b feature/nhom19/hung-ui-pomodoro
git checkout -b feature/nhom19/trung-sqlite-db
```

---

## Quy Chuẩn Git & Kỷ Luật Mã Nguồn (BẮT BUỘC)

Thầy giảng viên đã bật chế độ bảo vệ nhánh và có hệ thống kiểm tra tự động. Mọi thành viên **phải tuân thủ 100% các quy định sau**:

### ⚠️ 5 Điều Cấm Kỵ & Quy Tắc Sống Còn:
1. **CHỈ thao tác bên trong thư mục `nhom19-65ktpm/`**:
   - Nghiêm cấm tạo, sửa đổi hoặc xóa bất kỳ file nào nằm ngoài thư mục này (không sửa file ở root, không đụng vào thư mục của nhóm khác).
2. **TUYỆT ĐỐI KHÔNG dùng lệnh `git add .` ở thư mục gốc**:
   - Lệnh này sẽ vô tình stage toàn bộ file rác hoặc file nhóm khác, dẫn đến bị trừ điểm toàn nhóm.
   - Luôn chỉ định đích danh:
     ```bash
     git add nhom19-65ktpm/
     ```
3. **KHÔNG commit tệp rác, tệp build và bảo mật**:
   - ❌ `build/`, `.dart_tool/`, `.gradle/`, `Pods/`
   - ❌ File nhị phân: `*.apk`, `*.aab`, `*.ipa`
   - ❌ File tạm IDE: `.vscode/`, `.idea/`, `.DS_Store`
   - ❌ File môi trường: `.env`, `.venv/` (Python virtualenv)
4. **Quy chuẩn thông điệp commit (Commit Message)**:
   - Cú pháp: `<loại-thay-đổi>(nhom19-65ktpm): <mô tả ngắn bằng tiếng Việt không dấu>`
   - Các loại hợp lệ:
     - `feat`: Thêm tính năng mới, màn hình mới.
     - `fix`: Sửa lỗi logic, sửa bug giao diện.
     - `docs`: Cập nhật tài liệu, danh sách nhóm, báo cáo.
     - `refactor`: Tối ưu hóa, dọn dẹp mã nguồn.
   - *Ví dụ chuẩn:*
     ```bash
     git commit -m "feat(nhom19-65ktpm): hoan thien man hinh dong ho pomodoro"
     git commit -m "docs(nhom19-65ktpm): cap nhat tai lieu dac ta yeu cau srs"
     ```
5. **Quy trình đẩy code & xét duyệt (Pull Request nội bộ)**:
   - Đẩy code lên nhánh cá nhân trên GitHub:
     ```bash
     git push origin feature/nhom19/<ten-ban>-<tinh-nang>
     ```
   - Lên GitHub tạo Pull Request gộp vào nhánh `nhom19-65ktpm`.
   - Trưởng nhóm (Thịnh) sẽ review code, kiểm tra xung đột và merge vào nhánh chính của nhóm.

---

## 4. Phân Công Nhiệm Vụ Chi Tiết Từng Thành Viên

### 👤 1. Nguyễn Văn Thịnh — Trưởng Nhóm / System Architect & Fullstack AI Lead
* **Trách nhiệm chính:**
  - Quản trị kho lưu trữ GitHub, duy trì nhánh `nhom19-65ktpm`, review Pull Request của thành viên và nộp PR cuối kỳ lên kho của Giảng viên.
  - Thiết kế kiến trúc tổng thể Client - Server, định nghĩa chuẩn RESTful API cho toàn hệ thống.
  - Phát triển Backend AI (FastAPI):
    - Kế thừa & nâng cấp module xử lý âm vị ngôn ngữ NLTK CMUDict/IPA chấm điểm phát âm tiếng Anh.
    - Xây dựng module kết nối LLM (Gemini API / OpenAI API) để tóm tắt tài liệu học và tự động sinh bộ câu hỏi Flashcards/Quiz.
  - Hỗ trợ thành viên kết nối API, cấu hình server và xử lý các lỗi kỹ thuật phức tạp.

### 👤 2. Đào Thị Yến — Frontend Developer (Flutter Core UI & Discipline System)
* **Trách nhiệm chính:**
  - Thiết kế và lập trình giao diện người dùng **Flutter Material 3** (hỗ trợ thích ứng cả Light Theme và Dark Theme).
  - **Lập trình phân hệ Hệ thống & Xác thực:** Màn hình Splash, Onboarding giới thiệu app, Đăng nhập / Đăng ký và Quản lý trang cá nhân.
  - **Lập trình phân hệ Trang chủ & Kỷ luật (Dashboard & Discipline):**
    - Màn hình Dashboard trung tâm: Chuỗi ngày kỷ luật (**Streak 🔥**), Vòng tròn mục tiêu ngày (**Daily Goal Progress Ring**).
    - Biểu đồ thời gian học 7 ngày và **Bản đồ nhiệt độ học tập 30 ngày (Monthly Heatmap Grid)**.
  - **Lập trình phân hệ Đồng hồ tập trung (Focus Pomodoro Timer):**
    - Widget vòng tròn đếm ngược thời gian hoạt họa mượt mà (Animated Circular Countdown).
    - Chế độ khóa xao nhãng khi đang trong phiên học tập trung.
  - Quản lý trạng thái giao diện bằng Provider: `ThemeProvider`, `PomodoroProvider`, `DisciplineProvider`.

### 👤 3. Nguyễn Năng Vũ Hùng — Frontend Developer (Flutter AI Speech & Smart Learning)
* **Trách nhiệm chính:**
  - Lập trình giao diện và tích hợp nghiệp vụ chuyên sâu cho phân hệ Trí tuệ Nhân tạo và Học tập thông minh.
  - **Lập trình phân hệ AI Luyện phát âm (Speech Assessment):**
    - Giao diện thu âm giọng nói với hiệu ứng sóng âm (Audio Waveform Visualizer).
    - Hiển thị kết quả chấm điểm phát âm đối chiếu âm vị, tự động đổi màu từng từ: Xanh lá (chuẩn), Cam (gần đúng), Đỏ (sai âm).
  - **Lập trình phân hệ Học tập & Ôn tập thông minh:**
    - Widget thẻ ghi nhớ **Flashcards lật 3D 2 mặt** với các nút chọn mức độ nhớ (Dễ / Vừa / Khó).
    - Màn hình làm bài kiểm tra trắc nghiệm Quiz tự động sinh từ tài liệu.
    - Màn hình Quản lý môn học/học phần, danh sách tài liệu và ghi chú học tập.
  - **Tích hợp Plugin Thiết bị & Audio:** `speech_to_text` (nhận diện giọng nói), `flutter_tts` (phát âm bản xứ), `record`, `just_audio`.
  - Kết nối tầng API Client (`http`/`dio`) với Backend AI của Thịnh và quản lý trạng thái (`SpeechProvider`, `StudyProvider`).

### 👤 4. Lê Đức Trung — Database Specialist, QA / Tester & Technical Writer
* **Trách nhiệm chính:**
  - **Quản lý dữ liệu cục bộ (Offline-First Database):**
    - Thiết kế và triển khai cơ sở dữ liệu **SQLite** (`sqflite`) trên thiết bị.
    - Tạo các bảng lưu trữ: Môn học (`subjects`), Thẻ nhớ (`flashcards`), Nhật ký học tập (`study_logs`), Cấu hình Pomodoro (`settings`).
    - Viết thuật toán tính chu kỳ lặp lại ngắt quãng **Spaced Repetition (Leitner / SM-2)** cập nhật trạng thái thẻ nhớ cục bộ mà không cần Internet.
  - **Kiểm thử chất lượng phần mềm (QA / Testing):**
    - Xây dựng tài liệu kịch bản kiểm thử (Test Cases) chi tiết cho từng màn hình và luồng chức năng.
    - Thực hiện kiểm thử chức năng (Functional Testing), kiểm thử giao diện trên nhiều kích thước màn hình Android.
    - Bắt lỗi, tạo Issue trên GitHub và phối hợp với Hùng/Thịnh để khắc phục bug.
  - **Biên soạn Báo cáo Đồ án:**
    - Hoàn thiện tệp `danhsachnhom.md`.
    - Chủ trì viết toàn văn **Báo cáo Đồ án tốt nghiệp / Cuối kỳ** theo đúng quy chuẩn học thuật của nhà trường (lưu tại `nhom19-65ktpm/docs/baocao_doan.pdf`).
    - Chuẩn bị Slide thuyết trình (PowerPoint/Canva) cho buổi bảo vệ đồ án.

---

## 5. Cấu Trúc Thư Mục & Vị Trí Làm Việc

Mọi tệp tin của nhóm phải nằm chính xác trong cây thư mục sau:

```text
project-ptuddd/
├── .gitignore
├── README.md (File gốc của thầy - KHÔNG CHỈNH SỬA)
└── nhom19-65ktpm/
    ├── README.md              # Sổ tay hướng dẫn công việc nội bộ này
    ├── danhsachnhom.md        # Bảng danh sách thành viên & phân công (BẮT BUỘC)
    ├── docs/                  # Thư mục chứa tài liệu, thiết kế, báo cáo
    │   ├── de_cuong_do_an.md  # Đề cương chi tiết đồ án
    │   ├── figma_design_link.md # Link figma, tài liệu UX
    │   ├── test_cases.xlsx    # Bảng kịch bản test
    │   └── baocao_doan.pdf    # Báo cáo đồ án hoàn chỉnh
    └── src/                   # Toàn bộ mã nguồn dự án
        ├── mobile/            # Source code Flutter (lib/, android/, ios/, pubspec.yaml)
        └── backend/           # Source code Python FastAPI AI
```

---

## 6. Kế Hoạch Thực Hiện & Mốc Tiến Độ (Milestones)

Dự án kéo dài trong **6 Sprint (12 Tuần)**:

| Mốc / Sprint | Thời Gian | Mục Tiêu Chính | Phụ Trách Chính |
| :---: | :---: | :--- | :--- |
| **Sprint 1** | Tuần 1 – 2 | Chốt đề cương, dựng khung dự án Flutter Material 3, khởi tạo cấu trúc SQLite DB & API Specs. | Thịnh, Yến, Hùng, Trung |
| **Sprint 2** | Tuần 3 – 4 | Lập trình UI Auth & Dashboard (Yến); Nâng cấp API phát âm NLTK CMUDict (Thịnh); Lập trình thuật toán SM-2 (Trung). | Yến, Thịnh, Trung |
| **Sprint 3** | Tuần 5 – 6 | Lập trình Widget Pomodoro Timer (Yến); Lập trình UI Luyện phát âm AI & Audio (Hùng); Xây dựng API sinh Flashcards LLM (Thịnh). | Yến, Hùng, Thịnh |
| **Sprint 4** | Tuần 7 – 8 | Lập trình UI Flashcard lật 3D & Môn học (Hùng); Hoàn thiện Heatmap & Streak (Yến); Nạp SQLite & Test Cases (Trung). | Hùng, Yến, Trung |
| **Sprint 5** | Tuần 9 – 10 | Ghép nối toàn diện Client - Server, kiểm thử tổng thể (QA), bắt lỗi, tối ưu độ trễ AI, đóng gói APK. | Cả nhóm |
| **Sprint 6** | Tuần 11 – 12 | Viết hoàn chỉnh Báo cáo đồ án (`baocao_doan.pdf`), làm slide thuyết trình, quay video demo và nộp bài PR. | Trung, Thịnh, Yến, Hùng |

---

## 7. Quy Định Họp & Báo Cáo Tiến Độ

1. **Họp định kỳ (Weekly Sync):** Tối Chủ nhật hằng tuần lúc 20:30 (Online qua Google Meet / Discord).
   - Mỗi thành viên trình bày: Đã làm được gì tuần qua? Đang vướng mắc gì (Blocker)? Kế hoạch tuần tới là gì?
2. **Kênh trao đổi hàng ngày:** Nhóm Zalo / Discord Nhóm 19.
   - Khi gặp lỗi kỹ thuật hoặc vướng mắc về UI/API, nhắn tin ngay lên nhóm để Trưởng nhóm và các bạn hỗ trợ, không được giấu lỗi làm chậm tiến độ chung.
3. **Quy định kỷ luật & Đánh giá đóng góp:**
   - Đánh giá tỷ lệ đóng góp (%) cuối kỳ sẽ căn cứ minh bạch dựa trên:
     - Số lượng commit, Issue và Pull Request thực tế trên GitHub.
     - Mức độ hoàn thành các đầu việc được giao đúng hạn.
     - Tinh thần chủ động, review và phản hồi PR của đồng đội.

---

## 8. Hướng Dẫn Sử Dụng GitHub Projects, Issues & Quy Trình Review PR Chéo

### 8.1. Mô Hình Bảng Quản Lý Tiến Độ (GitHub Project Board)
Nhóm sử dụng mô hình **Kanban Board** với 4 cột trạng thái:
1. **📋 Todo (Cần làm):** Chứa toàn bộ các task/issue đã được phân công nhưng chưa bắt đầu làm.
2. **⏳ In Progress (Đang làm):** Thẻ nhiệm vụ đang được thành viên xử lý. Mỗi người tại một thời điểm chỉ nên có 1-2 task ở cột này.
3. **👀 In Review (Chờ duyệt PR):** Mã nguồn đã viết xong, đã tạo Pull Request và đang chờ các thành viên khác vào kiểm tra (review).
4. **✅ Done (Hoàn thành):** Pull Request đã được kiểm duyệt và merge thành công vào nhánh `nhom19-65ktpm`, Issue tự động đóng.

### 8.2. Quy Trình Tạo & Nhận Issue Chuẩn
Mỗi đầu việc (dù nhỏ hay lớn) đều phải có một Issue đại diện trên GitHub:
1. **Tiêu đề Issue:** `[<Tên Phân Hệ>] <Hành động cụ thể>`
   - *Ví dụ:* `[Frontend] Lập trình giao diện Dashboard, Streak ngọn lửa và Heatmap 30 ngày (Yến)`
   - *Ví dụ:* `[Frontend] Lập trình Widget Đồng hồ Focus Pomodoro và khóa xao nhãng (Yến)`
   - *Ví dụ:* `[Frontend] Lập trình giao diện Luyện phát âm AI và visualizer sóng âm (Hùng)`
   - *Ví dụ:* `[Frontend] Xây dựng màn hình Flashcard lật 3D hai mặt (Hùng)`
   - *Ví dụ:* `[Database] Xây dựng SQLite Helper và Schema bảng flashcards (Trung)`
   - *Ví dụ:* `[Backend] Nâng cấp API bóc tách âm vị NLTK CMUDict (Thịnh)`
2. **Nội dung mô tả (Body):**
   - **Mục tiêu:** Task này giải quyết chức năng gì?
   - **Checklist hoàn thành (Definition of Done):**
     - [ ] Vẽ xong giao diện Light/Dark Mode
     - [ ] Xuất file assets SVG/PNG
     - [ ] Kiểm tra hiển thị responsive
3. **Thuộc tính gán (Metadata):**
   - **Assignees:** Chọn người phụ trách (Yến, Hùng, Trung hoặc Thịnh).
   - **Labels:** Gắn nhãn phù hợp (`feature`, `bug`, `documentation`, `ui/ux`, `backend`).
   - **Projects:** Chọn Project Board của Nhóm 19.

### 8.3. Quy Trình Làm Việc Qua Pull Request & Liên Kết Issue
```text
Issue #1 (Todo) ➔ Kéo sang In Progress ➔ Tạo Branch feature/nhom19/issue-1-... 
➔ Code & Commit ➔ Tạo PR (ghi Closes #1) ➔ Kéo sang In Review 
➔ Review chéo & Approve ➔ Squash and Merge ➔ Tự động chuyển sang Done
```

1. **Nhận việc:** Kéo thẻ Issue từ cột `Todo` sang `In Progress`.
2. **Tạo nhánh theo mã Issue:**
   ```bash
   git checkout nhom19-65ktpm
   git pull origin nhom19-65ktpm
   git checkout -b feature/nhom19/issue-1-figma-pomodoro
   ```
3. **Code & Commit:** Chỉ làm trong thư mục `nhom19-65ktpm/`, commit đúng cú pháp:
   ```bash
   git add nhom19-65ktpm/
   git commit -m "feat(nhom19-65ktpm): thiet ke xong man hinh pomodoro (closes #1)"
   ```
4. **Đẩy nhánh lên GitHub:**
   ```bash
   git push origin feature/nhom19/issue-1-figma-pomodoro
   ```
5. **Mở Pull Request:**
   - **Base branch:** `nhom19-65ktpm` (⚠️ Tuyệt đối KHÔNG chọn `main`).
   - **Compare branch:** `feature/nhom19/issue-1-figma-pomodoro`.
   - **Nội dung PR:** Bắt buộc có dòng từ khóa liên kết: `Closes #1` (để khi merge PR thì Issue #1 tự động đóng).
   - **Reviewers:** Gán ít nhất 1-2 thành viên khác trong nhóm để review chéo.

### 8.4. Quy Chuẩn Review Chéo (Peer Review & Phản Hồi PR)
Mọi Pull Request **bắt buộc phải có ít nhất 1 lượt Review & Approve** từ thành viên khác trước khi được merge vào nhánh nhóm.

#### Checklist dành cho người Review:
1. Mở tab **Files changed** trên giao diện Pull Request:
   - [ ] 100% tệp thay đổi có nằm trọn vẹn trong `nhom19-65ktpm/` không?
   - [ ] Có bị dính tệp rác không (`build/`, `.dart_tool/`, `.env`, file `*.apk`)?
   - [ ] Tên biến, cấu trúc mã nguồn có rõ ràng, sạch đẹp không?
   - [ ] Đã kiểm tra code chạy thử trên máy chưa?
2. **Cách nhận xét (Comment dòng code):**
   - Di chuột vào dòng code cần góp ý, bấm dấu `+` màu xanh.
   - Góp ý mang tính xây dựng, lịch sự.
     - *Ví dụ:* *"Chỗ này nên thêm hàm bắt lỗi try/catch phòng trường hợp mất mạng nhé."*
     - *Ví dụ:* *"Màu nút này ở Dark theme hơi chìm, bạn thử chỉnh sang mã màu `#4E89FF` xem sao."*
3. **Gửi đánh giá (Submit review):**
   - **Approve:** Khi code chuẩn xác, không có lỗi.
   - **Request changes:** Khi phát hiện lỗi hoặc vi phạm quy chuẩn (người tạo PR phải sửa code và commit thêm lên cùng nhánh để cập nhật).
   - **Comment:** Đưa ra câu hỏi hoặc thảo luận mà không chặn merge.

### 8.5. Hợp Nhất Mã Nguồn (Merge Code)
- Khi PR đã đủ điều kiện (đã được Approve và không có conflict):
- Trưởng nhóm (Thịnh) chọn hình thức **Squash and merge** để gộp toàn bộ commit lẻ thành 1 commit duy nhất gọn gàng trên nhánh `nhom19-65ktpm`.
- Bấm **Delete branch** trên GitHub để dọn dẹp các nhánh tính năng đã hoàn thành.

---
