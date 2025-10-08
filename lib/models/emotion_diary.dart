// Model cho nhật ký cảm xúc
class EmotionDiary {
  final DateTime date;         // Ngày ghi chú
  final int q1;           // Câu hỏi 1: (1-5)
  final int q2;           // Câu hỏi 2: (1-5)
  final int q3;           // Câu hỏi 3: (1-5)
  final String notes;        // Ghi chú thêm (200 ký tự)

  EmotionDiary({
    required this.date,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.notes,
  });

  // Tạo bản sao với các thay đổi
  EmotionDiary copyWith({
    DateTime? date,
    int? q1,
    int? q2,
    int? q3,
    String? notes,
  }) {
    return EmotionDiary(
      date: date ?? this.date,
      q1: q1 ?? this.q1,
      q2: q2 ?? this.q2,
      q3: q3 ?? this.q3,
      notes: notes ?? this.notes,
    );
  }
}