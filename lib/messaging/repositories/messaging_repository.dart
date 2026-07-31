import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Messaging repository — ready to be wired up with Firebase Firestore.
class MessagingRepository {
  final List<MessageRequest> _requests = [];
  final List<Message> _messages = [];

  Future<List<MessageRequest>> getRequestsForUser(String userId) async {
    return _requests.where((r) => r.toUserId == userId).toList();
  }

  Future<List<MessageRequest>> getSentRequests(String userId) async {
    return _requests.where((r) => r.fromUserId == userId).toList();
  }

  Future<List<MessageRequest>> getPendingRequests(String userId) async {
    return _requests.where((r) => r.toUserId == userId && !r.accepted).toList();
  }

  Future<List<MessageRequest>> getConversations(String userId) async {
    return _requests.where((r) => (r.toUserId == userId || r.fromUserId == userId) && r.accepted).toList();
  }

  Future<MessageRequest> sendRequest(MessageRequest request) async {
    _requests.add(request);
    return request;
  }

  Future<MessageRequest> acceptRequest(String requestId) async {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final updated = _requests[idx].copyWith(accepted: true);
      _requests[idx] = updated;
      return updated;
    }
    throw MessagingException('Message request not found.');
  }

  Future<void> declineRequest(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
  }

  Future<List<Message>> getConversationMessages(String conversationId) async {
    return _messages.where((m) => m.conversationId == conversationId).toList();
  }

  Future<Message> sendMessage(Message message) async {
    _messages.add(message);
    return message;
  }

  Future<void> markAsRead(String conversationId, String userId) async {}
}

class MessagingException implements Exception {
  final String message;
  MessagingException(this.message);

  @override
  String toString() => message;
}
