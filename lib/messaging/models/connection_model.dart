import 'package:cloud_firestore/cloud_firestore.dart';

enum ConnectionStatus { pending, accepted, rejected }

/// Model for a friend / connection request between users.
class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final ConnectionStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendRequest(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ConnectionStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
