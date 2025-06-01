// lib/models/note.dart
class Note {
  final String id;
  final String userId;
  final String title;
  final String extractedText;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.extractedText,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create a Note object from a JSON map (e.g., from Supabase)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      extractedText: map['extracted_text'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Method to convert a Note object to a JSON map (e.g., for Supabase insert/update)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'extracted_text': extractedText,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(), // Supabase expects ISO 8601 string
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}