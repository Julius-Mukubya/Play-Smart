import 'package:play_smart/messaging/repositories/messaging_repository.dart' show MessagingException;
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// In-memory messaging repository used by unit tests. Not wired into the app
/// — see `MessagingRepository` (Supabase-backed) for the production implementation.
class MockMessagingRepository {
  final List<MessageRequest> _requests = List.from(MockData.messageRequests);
  final List<Message> _messages = List.from(MockData.messages);

  List<MessageRequest> getRequestsForUser(String userId) {
    return _requests.where((r) => r.toUserId == userId).toList();
  }

  List<MessageRequest> getSentRequests(String userId) {
    return _requests.where((r) => r.fromUserId == userId).toList();
  }

  List<MessageRequest> getPendingRequests(String userId) {
    return _requests.where((r) => r.toUserId == userId && !r.accepted).toList();
  }

  List<MessageRequest> getConversations(String userId) {
    return _requests.where((r) =>
        (r.toUserId == userId || r.fromUserId == userId) && r.accepted).toList();
  }

  Future<MessageRequest> sendRequest(MessageRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _requests.add(request);
    return request;
  }

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
      requiresMonitoring: request.requiresMonitoring,
      createdAt: request.createdAt,
    );
    _requests[index] = updated;
    return updated;
  }

  Future<void> declineRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _requests.removeWhere((r) => r.id == requestId);
  }

  List<Message> getConversationMessages(String conversationId) {
    return _messages.where((m) => m.conversationId == conversationId).toList();
  }

  Future<Message> sendMessage(Message message) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _messages.add(message);
    return message;
  }

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
