# **SOFTWARE REQUIREMENT SPECIFICATION**

# **1\. Overview**

## **1.1 Purpose**

Ứng dụng hỗ trợ học từ vựng bộ sách Destination thông qua flashcard, chế độ học tương tác, bài kiểm tra và AI Coach.

Ứng dụng chỉ là client Flutter. Dữ liệu từ vựng được lấy từ backend API đã tồn tại.

## **1.2 Scope**

Level:

* B1  
* B2  
* C1\&C2

Chức năng chính:

* Xem danh sách level, unit, term  
* Học bằng flashcard  
* Đánh dấu sao  
* Theo dõi tiến độ học  
* Tạo bài kiểm tra  
* AI Coach  
* Xem lịch sử bài kiểm tra  
* Xem lịch sử AI feedback  
* Dashboard thống kê

## **1.3 Business Rules**

BR-01

Ứng dụng không kiểm tra dữ liệu trả về từ API.

BR-02

Ứng dụng không xử lý term trùng lặp.

BR-03

Ứng dụng không xử lý definition sai format.

BR-04

Mọi trạng thái học tập được lưu cục bộ.

BR-05

Không yêu cầu đăng nhập.

BR-06

Star, Know và Learning được quản lý độc lập theo từng Unit.

BR-07

Progress được tính dựa trên số từ có trạng thái Know.

---

# **2\. Navigation Structure**

Bottom Navigation gồm:

* Home  
* Dashboard  
* Exam History  
* Coach History

Các màn hình:

Home  
→ Level List  
→ Unit List  
→ Term List  
→ Learn  
→ Exam  
→ Coach

Dashboard

Exam History  
→ Exam Detail

Coach History  
→ Coach Detail

---

# **3\. Home**

## **3.1 Level List**

Hiển thị:

* B1  
* B2  
* C1\&C2

Mỗi level hiển thị:

* Progress %  
* Số từ đã Know  
* Tổng số từ

Có nút:

Create Exam

## **3.2 Create Exam**

Cho phép chọn:

Level

Dropdown:

* B1  
* B2  
* C1\&C2

Unit

Dropdown:

* All  
* Unit cụ thể

Star only

Switch:

* OFF  
* ON

Question count

Dropdown:

* 10  
* 20  
* 50  
* 100

Question types

Checkbox:

* Term → Definition  
* Definition → Term  
* Cloze AI  
* Matching  
* English → Vietnamese  
* English → English  
* Sentence Writing AI

---

# **4\. Unit List**

Hiển thị:

* Danh sách unit  
* Progress %

Mỗi item gồm:

* Unit name  
* Progress bar  
* Learned words / Total words

Chức năng:

Search

Sort:

* Original order  
* A-Z  
* Z-A

---

# **5\. Term List**

Header:

* Learn  
* Exam  
* Coach

Search supported.

Sort:

* Original order  
* A-Z  
* Z-A

Filter:

* All  
* Starred  
* Learning  
* Known

## **Mode 1**

Quizlet style.

Hiển thị:

* Term  
* Definition  
* Speaker button  
* Star button  
* Know button  
* Learning button

Hiển thị theo dạng danh sách.

## **Mode 2**

Danh sách flashcard.

Card chỉ hiển thị một mặt:

* Term hoặc Definition

User chọn mặt mặc định.

Bấm card:

Card đó tự lật.

Mỗi card có:

* Speaker button  
* Star button  
* Know button  
* Learning button

---

# **6\. Learn Module**

Full screen.

Hiển thị từng card.

Thành phần:

* Term  
* Definition  
* Speaker button  
* Star button

Gesture:

Swipe left

→ Know

Swipe right

→ Learning

Undo

→ Quay lại card trước.

Shuffle

→ Xáo trộn thứ tự card.

Session Rule

Các từ được đánh dấu Learning sẽ xuất hiện lại sau khi hoàn thành vòng đầu.

Session chỉ kết thúc khi tất cả card đều ở trạng thái Know.

---

# **7\. Exam Module**

## **7.1 Configuration**

Cho phép:

Question count:

* 10  
* 20  
* 50  
* 100

Star only:

* OFF  
* ON

Question type toggles:

* Term → Definition  
* Definition → Term  
* Cloze AI  
* Matching  
* English → Vietnamese  
* English → English  
* Sentence Writing AI

Không có timer.

## **7.2 Question Types**

### **Multiple Choice**

Term

→ 4 definitions

### **Multiple Choice**

Definition

→ 4 terms

### **Cloze AI**

AI sinh câu đục lỗ.

4 đáp án.

### **Matching**

5 terms

5 definitions

Ghép cặp.

### **English → Vietnamese**

Tự luận.

AI chỉ được gọi khi không khớp synonym đã lưu.

### **English → English**

Tự luận.

Phải khớp đáp án.

### **Sentence Writing**

Tuỳ chọn bật trước khi tạo bài.

User đặt câu tiếng Anh.

AI trả về:

* Score  
* Grammar  
* Vocabulary  
* Naturalness  
* Suggestion

## **7.3 Result**

Hiển thị:

Correct answers

Wrong answers

Percentage

Buttons:

Review Answers

## **7.4 History**

Lưu:

* Date  
* Unit  
* Score  
* Question list  
* User answers  
* Correct answers

Cho phép xoá.

---

# **8\. AI Coach**

Chọn số lượng:

* 5 words  
* 10 words  
* 20 words

Random từ trong Unit.

Flow:

Word 1

↓

User nhập câu

↓

AI đánh giá

↓

Word 2

...

Feedback gồm:

Grammar

Vocabulary

Naturalness

Suggestion

Không chấm điểm.

Lưu lịch sử.

Cho phép xoá.

---

# **9\. Dashboard**

Hiển thị:

Overall progress

Learned words

Learning words

Starred words

Level progress:

* B1  
* B2  
* C1\&C2

Exam count

Average exam score

Strongest units

Weakest units

Recent exams

Recent AI Coach feedback

Không có streak.

Không có heatmap.

---

# **10\. Search Rules**

Áp dụng cho:

* Level List  
* Unit List  
* Term List

Search realtime.

Không phân biệt chữ hoa và chữ thường.

---

# **11\. Sorting Rules**

Sort:

Original order

A-Z

Z-A

Áp dụng cho mọi danh sách.

---

# **12\. Audio**

Sử dụng flutter\_tts.

Chỉ đọc term.

---

# **13\. Local Data**

UserWordState

* unitId  
* termId  
* isStarred  
* status

Status:

* New  
* Learning  
* Know

ExamHistory

* id  
* date  
* unitId  
* score

QuestionHistory

* examId  
* type  
* question  
* userAnswer  
* correctAnswer

CoachHistory

* id  
* date  
* word  
* userSentence  
* grammarFeedback  
* vocabularyFeedback  
* naturalnessFeedback  
* suggestionFeedback

---

# **14\. Non-functional Requirements**

Flutter mobile application.

Offline local progress.

Responsive UI.

Support Android.

Simple architecture.

No authentication.

No synchronization.

No data validation.

