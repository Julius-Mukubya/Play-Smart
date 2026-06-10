import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// Messaging repository — handles message requests and conversation threads.
/// Uses mock data; swap with real API calls when backend is connected.
class MessagingRepository {
  final List<MessageRequest> _requests = List.from(MockData.messageRequests);
  final List<Message> _messages = List.from(MockData.messages);

  /// Get all message requests for a user (as recipient).
  List<MessageRequest> getRequestsForUser(String userId) {
    return _requests.where((r) => r.toUserId == userId).toList();
  }

  /// Get all sent message requests from a user.
  List<MessageRequest> getSentRequests(String userId) {
    return _requests.where((r) => r.fromUserId == userId).toList();
  }

  /// Get pending (unaccepted) requests for a user.
  List<MessageRequest> getPendingRequests(String userId) {
    return _requests.where((r) => r.toUserId == userId && !r.accepted).toList();
  }

  /// Get accepted requests (active conversations).
  List<MessageRequest> getConversations(String userId) {
    return _requests.where((r) =>
        (r.toUserId == userId || r.fromUserId == userId) && r.accepted).toList();
  }

  /// Send a message request.
  Future<MessageRequest> sendRequest(MessageRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _requests.add(request);
    return request;
  }

  /// Accept a message request and open a conversation.
  Future<MessageRequest> acceptRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index < 0) throw MessagingException('Message request not found.');
    final request = _requests[index];
    final updated = MessageRequest(
      id: request.id,
      fromUserId: request.fromUserId,
      fromUserName: request.fromUserName,
      toUserId: request.toUserId,
      message: request.message,
      accepted: true,
      createdAt: request.createdAt,
    );
    _requests[index] = updated;
    return updated;
  }

  /// Decline a message request.
  Future<void> declineRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _requests.removeWhere((r) => r.id == requestId);
  }

  /// Get messages in a conversation.
  List<Message> getConversationMessages(String conversationId) {
    return _messages.where((m) => m.conversationId == conversationId).toList();
  }

  /// Send a message in a conversation.
  Future<Message> sendMessage(Message message) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _messages.add(message);
    return message;
  }

  /// Mark all messages in a conversation as read.
  Future<void> markAsRead(String conversationId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].conversationId == conversationId && _messages[i].senderId != userId) {
        _messages[i] = Message(
          id: _messages[i].id,
          conversationId: _messages[i].conversationId,
          senderId: _messages[i].senderId,
          text: _messages[i].text,
          read: true,
          sentAt: _messages[i].sentAt,
        );
      }
    }
  }
}

/// Exception thrown by messaging operations.
class MessagingException implements Exception {
  final String message;
  MessagingException(this.message);

  @override
  String toString() => message;
}