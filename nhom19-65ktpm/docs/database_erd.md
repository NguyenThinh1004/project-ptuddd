
# StudyMate AI - SQLite Database ERD

## 1. So do quan he du lieu

```mermaid
erDiagram
    subjects ||--o{ flashcards : contains

    subjects {
        INTEGER id PK
        TEXT name
        TEXT color
        TEXT icon
    }

    flashcards {
        INTEGER id PK
        INTEGER subject_id FK
        TEXT front_text
        TEXT back_text
        INTEGER repetition_level
        INTEGER repetitions
        REAL ease_factor
        INTEGER interval
        TEXT next_review_date
    }

    pomodoro_sessions {
        INTEGER id PK
        TEXT start_time
        INTEGER duration
        INTEGER is_completed
    }

    daily_habits {
        INTEGER id PK
        TEXT study_date
        INTEGER study_minutes
        INTEGER is_goal_completed
        INTEGER streak_count
    }
```

## 2. Mo ta

- subjects: Luu danh sach mon hoc.
- flashcards: Luu the ghi nho va thong tin on tap SM-2.
- pomodoro_sessions: Luu lich su cac phien hoc.
- daily_habits: Theo doi thoi quen hoc tap.

## 3. Quan he

subjects (1) -- (N) flashcards

Moi flashcard thuoc ve mot mon hoc.
Khi xoa mon hoc, cac flashcard lien quan
se duoc xoa theo (ON DELETE CASCADE).

## 4. Database

- Database: studymate.db
- Version: 2
- Framework: Flutter
- Storage: SQLite (sqflite)
