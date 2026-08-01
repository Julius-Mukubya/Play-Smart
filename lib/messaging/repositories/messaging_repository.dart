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
      final snap = await _firestore
          .collection('chat_threads')
          .where('toUserId', isEqualTo: userId)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => _requestFromDoc(d)).toList();
      }
    } catch (_) {}
    return _requests.where((r) => r.toUserId == userId).toList();
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
          .where('accepted', isEqualTo: false)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => _requestFromDoc(d)).toList();
      }
    } catch (_) {}
    return _requests.where((r) => r.toUserId == userId && !r.accepted).toList();
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
        return docs.map((d) => _requestFromDoc(d)).toList();
      }
    } catch (_) {}
    return _requests.where((r) => (r.toUserId == userId || r.fromUserId == userId) && r.accepted).toList();
  }

  Future<MessageRequest> sendRequest(MessageRequest request) async {
    _requests.add(request);
    try {
      await _firestore.collection('chat_threads').doc(request.id).set({
        'fromUserId': request.fromUserId,
        'fromUserName': request.fromUserName,
        'toUserId': request.toUserId,
        'initialMessage': request.message,
        'accepted': request.accepted,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    return request;
  }

  Future<MessageRequest> acceptRequest(String requestId) async {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final updated = _requests[idx].copyWith(accepted: true);
      _requests[idx] = updated;
    }
    try {
      await _firestore.collection('chat_threads').doc(requestId).update({'accepted': true});
    } catch (_) {}
    return MessageRequest(
      id: requestId,
      fromUserId: '',
      fromUserName: '',
      toUserId: '',
      message: '',
      accepted: true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> declineRequest(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
    try {
      await _firestore.collection('chat_threads').doc(requestId).delete();
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
    return MessageRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      toUserId: data['toUserId'] ?? '',
      message: data['initialMessage'] ?? '',
      accepted: data['accepted'] ?? false,
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
