import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Real-time Messaging repository wired up with Cloud Firestore.
class MessagingRepository {
  final FirebaseFirestore _firestore;
  final List<MessageRequest> _requests = [];
  final List<Message> _messages = [];

  MessagingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<MessageRequest>> getRequestsForUser(String userId) async {
    try {
      final snapTo = await _firestore
          .collection('chat_threads')
          .where('toUserId', isEqualTo: userId)
          .get();
      final snapFrom = await _firestore
          .collection('chat_threads')
          .where('fromUserId', isEqualTo: userId)
          .get();

      final docs = [...snapTo.docs, ...snapFrom.docs];
      if (docs.isNotEmpty) {
        final Map<String, MessageRequest> map = {};
        for (final d in docs) {
          map[d.id] = _requestFromDoc(d);
        }
        return map.values.toList();
      }
    } catch (_) {}
    return _requests.where((r) => r.toUserId == userId || r.fromUserId == userId).toList();
  }

  Future<List<MessageRequest>> getSentRequests(String userId) async {
    try {
      final snap = await _firestore
          .collection('chat_threads')
          .where('fromUserId', isEqualTo: userId)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => _requestFromDoc(d)).toList();
      }
    } catch (_) {}
    return _requests.where((r) => r.fromUserId == userId).toList();
  }

  Future<List<MessageRequest>> getPendingRequests(String userId) async {
    try {
      final snap = await _firestore
          .collection('chat_threads')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => _requestFromDoc(d)).toList();
      }
    } catch (_) {}
    return _requests.where((r) => r.toUserId == userId && r.isPending).toList();
  }

  Future<List<MessageRequest>> getAllRequests(String userId) async {
    return getRequestsForUser(userId);
  }

  Future<List<MessageRequest>> getConversations(String userId) async {
    try {
      final snapTo = await _firestore
          .collection('chat_threads')
          .where('toUserId', isEqualTo: userId)
          .where('accepted', isEqualTo: true)
          .get();
      final snapFrom = await _firestore
          .collection('chat_threads')
          .where('fromUserId', isEqualTo: userId)
          .where('accepted', isEqualTo: true)
          .get();

      final docs = [...snapTo.docs, ...snapFrom.docs];
      if (docs.isNotEmpty) {
        final Map<String, MessageRequest> map = {};
        for (final d in docs) {
          map[d.id] = _requestFromDoc(d);
        }
        return map.values.toList();
      }
    } catch (_) {}
    return _requests.where((r) => (r.toUserId == userId || r.fromUserId == userId) && r.accepted).toList();
  }

  Future<MessageRequest> sendRequest(MessageRequest request) async {
    final existingIdx = _requests.indexWhere((r) =>
        r.fromUserId == request.fromUserId &&
        r.toUserId == request.toUserId &&
        !r.accepted);
    if (existingIdx != -1) {
      return _requests[existingIdx];
    }

    _requests.add(request);
    try {
      final existingDocs = await _firestore
          .collection('chat_threads')
          .where('fromUserId', isEqualTo: request.fromUserId)
          .where('toUserId', isEqualTo: request.toUserId)
          .where('accepted', isEqualTo: false)
          .limit(1)
          .get();
      if (existingDocs.docs.isNotEmpty) {
        return request;
      }

      await _firestore.collection('chat_threads').doc(request.id).set({
        'fromUserId': request.fromUserId,
        'fromUserName': request.fromUserName,
        'fromUserPhotoUrl': request.fromUserPhotoUrl,
        'toUserId': request.toUserId,
        'toUserPhotoUrl': request.toUserPhotoUrl,
        'initialMessage': request.message,
        'accepted': request.accepted,
        'status': request.status,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    return request;
  }

  Future<MessageRequest> acceptRequest(String requestId) async {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    MessageRequest? updated;
    if (idx != -1) {
      updated = _requests[idx].copyWith(accepted: true, status: 'accepted');
      _requests[idx] = updated;
    }
    try {
      await _firestore.collection('chat_threads').doc(requestId).update({
        'accepted': true,
        'status': 'accepted',
      });
    } catch (_) {}
    return updated ??
        MessageRequest(
          id: requestId,
          fromUserId: '',
          fromUserName: '',
          toUserId: '',
          message: '',
          accepted: true,
          status: 'accepted',
          createdAt: DateTime.now(),
        );
  }

  Future<void> declineRequest(String requestId) async {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _requests[idx] = _requests[idx].copyWith(accepted: false, status: 'rejected');
    }
    try {
      await _firestore.collection('chat_threads').doc(requestId).update({
        'accepted': false,
        'status': 'rejected',
      });
    } catch (_) {}
  }

  Stream<List<Message>> watchConversationMessages(String conversationId) {
    return _firestore
        .collection('chat_threads')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _messageFromDoc(d, conversationId)).toList());
  }

  Future<List<Message>> getConversationMessages(String conversationId) async {
    try {
      final snap = await _firestore
          .collection('chat_threads')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => _messageFromDoc(d, conversationId)).toList();
      }
    } catch (_) {}
    return _messages.where((m) => m.conversationId == conversationId).toList();
  }

  Future<Message> sendMessage(Message message) async {
    _messages.add(message);
    try {
      await _firestore
          .collection('chat_threads')
          .doc(message.conversationId)
          .collection('messages')
          .doc(message.id)
          .set({
        'senderId': message.senderId,
        'text': message.text,
        'read': message.read,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    return message;
  }

  Future<void> markAsRead(String conversationId, String userId) async {}

  MessageRequest _requestFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final accepted = data['accepted'] as bool? ?? false;
    final status = data['status'] as String? ?? (accepted ? 'accepted' : 'pending');

    return MessageRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserPhotoUrl: data['fromUserPhotoUrl'],
      toUserId: data['toUserId'] ?? '',
      toUserPhotoUrl: data['toUserPhotoUrl'],
      message: data['initialMessage'] ?? '',
      accepted: status == 'accepted',
      status: status,
      createdAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Message _messageFromDoc(DocumentSnapshot doc, String conversationId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Message(
      id: doc.id,
      conversationId: conversationId,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      sentAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
    );
  }
}

class MessagingException implements Exception {
  final String message;
  MessagingException(this.message);

  @override
  String toString() => message;
}
