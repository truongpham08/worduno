# Báo cáo kiểm thử Worduno

**Ngày chạy:** 09/07/2026  
**Lệnh:** `flutter test --concurrency=1`  
**Tài liệu tham chiếu:** `docs/specs.md` (ưu tiên 1)  
**Lưu ý:** Thư mục `docs/lexia-preview/` không tồn tại trong repo tại thời điểm kiểm thử.

---

## 1. Tổng quan

| Chỉ số | Giá trị |
|--------|---------|
| Tổng số test case | **87** |
| Pass | **87** |
| Fail | **0** |

**Kết luận ngắn:** Toàn bộ suite pass. Các luồng widget trước đây chưa cover (Exam session/result/review, Coach phase machine, history delete, deep link, Create Exam, TTS feedback) đã được bổ sung.

---

## 2. Cấu trúc bộ test

```
test/
├── helpers/
│   ├── fakes.dart              # Fake/stub: Vocabulary, Exam, Coach, Learn, Dashboard, TTS
│   ├── test_database.dart      # Khởi tạo sqflite FFI + DB tạm
│   ├── test_app_setup.dart     # Setup DI test (fake TTS)
│   └── widget_harness.dart     # Provider wrapper cho widget test
├── app/
│   ├── navigation_notifier_test.dart
│   └── route_parser_test.dart  # Deep link parser
├── core/utils/search_utils_test.dart
├── core/utils/sort_utils_test.dart
├── features/exam/exam_flow_test.dart
├── features/learning/learning_home_coach_test.dart
├── shared/word_state/word_state_store_test.dart
└── widget/
    ├── app_flow_widget_test.dart
    ├── exam_pages_widget_test.dart   # Exam session/result/history/detail
    ├── coach_pages_widget_test.dart  # Coach session phases + history delete
    ├── level_list_widget_test.dart   # Create Exam entry point
    └── tts_widget_test.dart          # speakTermWithFeedback
```

Các file test có sẵn được mở rộng: `learn_session_test.dart`, `exam_grader_test.dart`, `widget_test.dart`, `dashboard_local_data_source_test.dart`.

---

## 3. Bảng luồng nghiệp vụ × kết quả

### 3.1. Navigation (spec §2)

| # | Luồng | Loại | Case | Kết quả | Ghi chú |
|---|-------|------|------|---------|---------|
| N1 | Mở app → tab Home mặc định | Widget | Normal | ✅ Pass | `widget_test.dart`, `app_flow_widget_test.dart` |
| N2 | Chuyển tab Dashboard / History / AI | Widget | Normal | ✅ Pass | Bottom nav hoạt động |
| N3 | Home stack: Level → Unit | Widget | Normal | ✅ Pass | Poll UI tối đa ~10s |
| N4 | Push/pop home route | Unit | Normal | ✅ Pass | `navigation_notifier_test.dart` |
| N5 | Mở/xóa exam detail trên tab History | Unit + Widget | Normal | ✅ Pass | Unit: notifier; Widget: `exam_pages_widget_test.dart` |
| N6 | Reset home về root | Unit | Normal | ✅ Pass | |
| N7 | Deep link `/dashboard` | Unit | Normal | ✅ Pass | `route_parser_test.dart` |
| N8 | Deep link `/exam-history` | Unit | Normal | ✅ Pass | `route_parser_test.dart` |
| N9 | Deep link `/coach-history` | Unit | Normal | ✅ Pass | `route_parser_test.dart` |

### 3.2. Home – Level / Unit / Term (spec §3–5, §10–11)

| # | Luồng | Loại | Case | Kết quả | Ghi chú |
|---|-------|------|------|---------|---------|
| H1 | Load danh sách term | Unit | Normal | ✅ Pass | `TermListViewModel` |
| H2 | Đếm số từ Know theo unit | Unit | Normal | ✅ Pass | BR-07 |
| H3 | Toggle star trên term list | Unit | Normal | ✅ Pass | BR-06 |
| H4 | API lỗi khi load terms | Unit | Abnormal | ✅ Pass | Hiển thị `errorMessage` |
| H5 | Search không phân biệt hoa thường | Unit | Normal | ✅ Pass | `SearchUtils` |
| H6 | Sort Original / A-Z / Z-A | Unit | Normal | ✅ Pass | `SortUtils` |
| H7 | Hiển thị term trên UI | Widget | Normal | ✅ Pass | Provider binding |
| H8 | Nút **Create Exam** từ Level List | Widget | Normal | ✅ Pass | `level_list_widget_test.dart` → mở `/exam/config` |

### 3.3. Learn Module (spec §6)

| # | Luồng | Loại | Case | Kết quả | Ghi chú |
|---|-------|------|------|---------|---------|
| L1 | Queue bắt đầu với từ chưa Know | Unit | Normal | ✅ Pass | `learn_session_test.dart` |
| L2 | Từ đã Know bị loại khỏi queue | Unit | Normal | ✅ Pass | |
| L3 | Learning → xuất hiện lại sau vòng 1 | Unit | Normal | ✅ Pass | Session rule |
| L4 | Session chỉ kết thúc khi tất cả Know | Unit | Normal | ✅ Pass | |
| L5 | Undo hoàn tác trạng thái | Unit | Normal | ✅ Pass | |
| L6 | Shuffle xóa undo stack | Unit | Normal | ✅ Pass | |
| L7 | markKnow / undo qua ViewModel | Unit | Normal | ✅ Pass | |
| L8 | Load session lỗi | Unit | Abnormal | ✅ Pass | |
| L9 | Resolve unitId từ tên unit | Unit | Normal | ✅ Pass | `LearnRepositoryImpl` |
| L10 | UI hiển thị "Session Complete" | Widget | Normal | ✅ Pass | |

### 3.4. Exam Module (spec §7)

| # | Luồng | Loại | Case | Kết quả | Ghi chú |
|---|-------|------|------|---------|---------|
| E1 | Chấm Multiple Choice (Term↔Def) | Unit | Normal | ✅ Pass | `exam_grader_test.dart` |
| E2 | Chấm EN→EN không phân biệt hoa thường | Unit | Normal | ✅ Pass | |
| E3 | Chấm EN→VI theo synonym | Unit | Normal | ✅ Pass | |
| E4 | Chấm Matching JSON đúng/sai | Unit | Normal/Abnormal | ✅ Pass | JSON invalid → sai |
| E5 | Sentence Writing: câu rỗng | Unit | Abnormal | ✅ Pass | |
| E6 | Sentence Writing: AI lỗi → fallback chứa từ | Unit | Abnormal | ✅ Pass | |
| E7 | Sentence Writing: điểm AI < 7 → fail | Unit | Abnormal | ✅ Pass | |
| E8 | Generator: không có loại câu hỏi | Unit | Abnormal | ✅ Pass | `StateError` |
| E9 | Generator: không đủ từ trong pool | Unit | Abnormal | ✅ Pass | |
| E10 | Generator: tạo đủ số câu | Unit | Normal | ✅ Pass | |
| E11 | Cloze AI fallback khi API lỗi | Unit | Abnormal | ✅ Pass | |
| E12 | starOnly chỉ lấy từ đã star | Unit | Normal | ✅ Pass | `ExamServiceImpl` |
| E13 | submitExam không có paper | Unit | Abnormal | ✅ Pass | `StateError` |
| E14 | submitExam lưu lịch sử | Unit | Normal | ✅ Pass | SQLite |
| E15 | Config: không tắt hết loại câu hỏi | Unit | Abnormal | ✅ Pass | `ExamConfigViewModel` |
| E16 | Config: starOnly + questionCount | Unit | Normal | ✅ Pass | |
| E17 | ExamConfig canStart sau initialize | Unit | Normal | ✅ Pass | |
| E18 | **ExamSessionPage** hiển thị câu hỏi + Submit | Widget | Normal | ✅ Pass | `exam_pages_widget_test.dart` |
| E19 | Submit exam → navigate result | Widget | Normal | ✅ Pass | |
| E20 | **ExamResultPage** Review Answers / Back to summary | Widget | Normal | ✅ Pass | |
| E21 | **ExamHistoryPage** liệt kê lịch sử | Widget | Normal | ✅ Pass | |
| E22 | **ExamDetailPage** xóa exam (dialog) | Widget | Normal | ✅ Pass | |

### 3.5. AI Coach (spec §8)

| # | Luồng | Loại | Case | Kết quả | Ghi chú |
|---|-------|------|------|---------|---------|
| C1 | buildSession đúng wordCount (5/10/20) | Unit | Normal | ✅ Pass | |
| C2 | Pool rỗng sau filter star | Unit | Abnormal | ✅ Pass | `StateError` |
| C3 | getExplanation cache local | Unit | Normal | ✅ Pass | BR-04 |
| C4 | saveCoachFeedback + ensurePersisted | Unit | Normal | ✅ Pass | qua `WordStateStore` |
| C5 | **Coach session** explain → write → feedback | Widget | Normal | ✅ Pass | `coach_pages_widget_test.dart` |
| C6 | **CoachHistoryPage** xóa feedback theo term | Widget | Normal | ✅ Pass | Dialog confirm |

### 3.6. Dashboard (spec §9)

| # | Luồng | Loại | Case | Kết quả | Ghi chú |
|---|-------|------|------|---------|---------|
| D1 | Tổng hợp progress theo level/unit | Unit | Normal | ✅ Pass | |
| D2 | Coach history rows từ SQLite | Unit | Normal | ✅ Pass | |
| D3 | Hiển thị Dashboard trên UI | Widget | Normal | ✅ Pass | Tab Stats |

### 3.7. Local Data / Word State (spec §13, BR-04–07)

| # | Luồng | Loại | Case | Kết quả | Ghi chú |
|---|-------|------|------|---------|---------|
| W1 | Persist status sau reopen DB | Unit | Normal | ✅ Pass | |
| W2 | Star và status độc lập | Unit | Normal | ✅ Pass | BR-06 |
| W3 | Store notify listeners | Unit | Normal | ✅ Pass | |
| W4 | Rollback khi persist fail | Unit | Abnormal | ✅ Pass | Optimistic update |
| W5 | saveExplanation cache coach | Unit | Normal | ✅ Pass | |
| W6 | ensurePersisted cho FK coach | Unit | Normal | ✅ Pass | |
| W7 | Vocabulary disk cache | Unit | Normal | ✅ Pass | |
| W8 | clearCache refetch remote | Unit | Normal | ✅ Pass | |

### 3.8. TTS (spec §12)

| # | Luồng | Loại | Case | Kết quả | Ghi chú |
|---|-------|------|------|---------|---------|
| T1 | TTS thành công → không hiện snackbar | Widget | Normal | ✅ Pass | `FakeTtsService` |
| T2 | TTS thất bại → snackbar lỗi | Widget | Abnormal | ✅ Pass | `tts_widget_test.dart` |

### 3.9. Network / Error handling

| # | Luồng | Loại | Case | Kết quả | Ghi chú |
|---|-------|------|------|---------|---------|
| X1 | Dio 429 hiển thị detail | Unit | Abnormal | ✅ Pass | |
| X2 | Timeout không bị che bởi message chung | Unit | Abnormal | ✅ Pass | |

---

## 4. Ghi chú môi trường (Windows)

### 4.1. Crash Flutter tool (`sqlite3.dll` errno 183)

- **Triệu chứng:** `PathExistsException: Cannot copy file to ... sqlite3.dll`
- **Nguyên nhân:** Process `dart` / `flutter_tester` từ lần chạy trước vẫn giữ lock file native asset.
- **Cách chạy lại:**
  1. Đóng mọi `dart.exe`, `flutter_tester.exe` trong Task Manager
  2. Xóa `build/native_assets/`
  3. Chạy `flutter test --concurrency=1`

### 4.2. Database locked warning

Một số widget test (app shell) có thể log `database has been locked` nhưng vẫn pass. Chạy `--concurrency=1` giảm xung đột SQLite trên Windows.

---

## 5. Phạm vi còn có thể mở rộng (tùy chọn)

| Luồng spec | Ghi chú |
|------------|---------|
| ExamConfigPage full widget flow (Start Exam → session) | Đã có unit test ViewModel; widget test cần mock vocabulary + exam service đầy đủ |
| TermList / LearnSession widget binding | Tránh duplicate `AppDatabase` trong get_it để không timeout |
| TTS phát âm thật trên device | Cần integration test / device test với `flutter_tts` |
| Coach session multi-word + skip/back | Phase machine cơ bản đã cover; edge case navigation chưa widget test |

---

## 6. Hướng dẫn chạy test

```powershell
cd d:\Documents\Programming\Flutter\worduno
flutter test --concurrency=1
```

Chạy theo nhóm:

```powershell
flutter test test/features/exam/
flutter test test/features/learning/
flutter test test/widget/
flutter test test/app/route_parser_test.dart
```

---

## 7. Kết luận

Bộ test hiện tại **bao phủ các business rule chính** trong specs và **các luồng UI quan trọng** trước đây thiếu widget test. Tổng cộng **87/87 pass** với `flutter test --concurrency=1`.
