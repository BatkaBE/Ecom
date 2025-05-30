// lib/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id; // Firestore document ID
  final String productId;
  final String userId; // Firebase Auth User UID
  final String username; // User's display name
  final String? userAvatarUrl; // User's avatar URL (optional)
  final String content;
  final Timestamp timestamp;

  CommentModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.content,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for CommentModel ${doc.id}');
    }
    return CommentModel(
      id: doc.id,
      productId: data['productId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? 'Anonymous',
      userAvatarUrl: data['userAvatarUrl'] as String?,
      content: data['content'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
