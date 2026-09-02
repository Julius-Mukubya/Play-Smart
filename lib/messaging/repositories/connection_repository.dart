import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/messaging/models/connection_model.dart';

class ConnectionRepository {
  final FirebaseFirestore _firestore;
  final Map<String, FriendRequest> _ephemeralRequests = {};

  ConnectionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<FriendRequest> sendRequest(String senderId, String receiverId) async {
    final docRef = _firestore.collection('friend_requests').doc();
    final request = FriendRequest(
      id: docRef.id,
      senderId: senderId,
      receiverId: receiverId,
      status: ConnectionStatus.pending,
      createdAt: DateTime.now(),
    );

    _ephemeralRequests['${senderId}_$receiverId'] = request;

    try {
      await docRef.set(request.toFirestore());
    } catch (_) {
      // Ephemeral fallback
    }

    return request;
  }

  Future<void> respondToRequest(String requestId, ConnectionStatus status) async {
    try {
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ephemeral fallback
    }
  }

  Future<FriendRequest?> getRequestStatus(String currentUserId, String targetUserId) async {
    try {
      final snap = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: targetUserId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return FriendRequest.fromFirestore(snap.docs.first);
      }

      final reverseSnap = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: targetUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (reverseSnap.docs.isNotEmpty) {
        return FriendRequest.fromFirestore(reverseSnap.docs.first);
      }
    } catch (_) {
      // Ephemeral fallback
    }

    return _ephemeralRequests['${currentUserId}_$targetUserId'] ??
        _ephemeralRequests['${targetUserId}_$currentUserId'];
  }

  Future<int> getFriendsCount(String userId) async {
    final Set<String> friendIds = {};
    try {
      final snapSent = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: ConnectionStatus.accepted.name)
          .get();
      for (final d in snapSent.docs) {
        final data = d.data();
        if (data['receiverId'] != null) friendIds.add(data['receiverId'] as String);
      }

      final snapRecv = await _firestore
          .collection('friend_requests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: ConnectionStatus.accepted.name)
          .get();
      for (final d in snapRecv.docs) {
        final data = d.data();
        if (data['senderId'] != null) friendIds.add(data['senderId'] as String);
      }
    } catch (_) {}

    try {
      final snapThreads = await _firestore
          .collection('chat_threads')
          .where('accepted', isEqualTo: true)
          .get();
      for (final d in snapThreads.docs) {
        final data = d.data();
        if (data['fromUserId'] == userId && data['toUserId'] != null) {
          friendIds.add(data['toUserId'] as String);
        } else if (data['toUserId'] == userId && data['fromUserId'] != null) {
          friendIds.add(data['fromUserId'] as String);
        }
      }
    } catch (_) {}

    for (final req in _ephemeralRequests.values) {
      if (req.status == ConnectionStatus.accepted) {
        if (req.senderId == userId) friendIds.add(req.receiverId);
        if (req.receiverId == userId) friendIds.add(req.senderId);
      }
    }

    return friendIds.length;
  }
}

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return ConnectionRepository();
});
