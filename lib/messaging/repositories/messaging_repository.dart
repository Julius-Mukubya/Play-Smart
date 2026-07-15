import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Messaging repository — Supabase-backed message requests + conversation
/// threads. An accepted `message_requests` row doubles as the conversation
/// (its `id` is `messages.conversation_id`) — there is no separate
/// conversations table, matching the app's existing model.
///
/// `messages` insert is guarded server-side by a trigger that raises unless
/// the parent request has `accepted = true` (invariant #1) — a
/// `PostgrestException` from that trigger surfaces here as a
/// `MessagingException`.
class MessagingRepository {
  static const _requestsTable = 'message_requests';
  static const _messagesTable = 'messages';

  Future<List<MessageRequest>> getRequestsForUser(String userId) async {
    final rows = await supabase.from(_requestsTable).select().eq('to_user_id', userId);
    return (rows as List).map((r) => MessageRequest.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<MessageRequest>> getSentRequests(String userId) async {
    final rows = await supabase.from(_requestsTable).select().eq('from_user_id', userId);
    return (rows as List).map((r) => MessageRequest.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<MessageRequest>> getPendingRequests(String userId) async {
    final rows = await supabase
        .from(_requestsTable)
        .select()
        .eq('to_user_id', userId)
        .eq('accepted', false);
    return (rows as List).map((r) => MessageRequest.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<MessageRequest>> getConversations(String userId) async {
    final rows = await supabase
        .from(_requestsTable)
        .select()
        .or('to_user_id.eq.$userId,from_user_id.eq.$userId')
        .eq('accepted', true);
    return (rows as List).map((r) => MessageRequest.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Send a message request. `requires_monitoring` is computed server-side
  /// from both parties' `is_under_18` — the client never sets it directly.
  Future<MessageRequest> sendRequest(MessageRequest request) async {
    try {
      final parties = await supabase
          .from('users')
          .select('id, is_under_18')
          .inFilter('id', [request.fromUserId, request.toUserId]);
      final requiresMonitoring =
          (parties as List).any((u) => u['is_under_18'] == true);

      final row = await supabase.from(_requestsTable).insert({
        'from_user_id': request.fromUserId,
        'from_user_name': request.fromUserName,
        'to_user_id': request.toUserId,
        'message': request.message,
        'requires_monitoring': requiresMonitoring,
      }).select().single();
      return MessageRequest.fromJson(row);
    } catch (e) {
      throw MessagingException(_friendlyMessage(e));
    }
  }

  Future<MessageRequest> acceptRequest(String requestId) async {
    try {
      final row = await supabase
          .from(_requestsTable)
          .update({'accepted': true})
          .eq('id', requestId)
          .select()
          .single();
      return MessageRequest.fromJson(row);
    } catch (e) {
      throw MessagingException('Message request not found.');
    }
  }

  Future<void> declineRequest(String requestId) async {
    await supabase.from(_requestsTable).delete().eq('id', requestId);
  }

  Future<List<Message>> getConversationMessages(String conversationId) async {
    final rows = await supabase
        .from(_messagesTable)
        .select()
        .eq('conversation_id', conversationId)
        .order('sent_at');
    return (rows as List).map((r) => Message.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Send a message. Rejected server-side (invariant #1) unless the parent
  /// `message_requests` row is already accepted.
  Future<Message> sendMessage(Message message) async {
    try {
      final row = await supabase.from(_messagesTable).insert({
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'text': message.text,
      }).select().single();
      return Message.fromJson(row);
    } catch (e) {
      throw MessagingException(
          'Cannot send a message until the athlete accepts the request.');
    }
  }

  Future<void> markAsRead(String conversationId, String userId) async {
    await supabase
        .from(_messagesTable)
        .update({'read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId);
  }

  String _friendlyMessage(Object e) {
    final message = e.toString();
    if (message.contains('allow_message_requests')) {
      return 'This athlete is not accepting message requests right now.';
    }
    return 'Could not send message request. Please try again.';
  }
}

/// Exception thrown by messaging operations.
class MessagingException implements Exception {
  final String message;
  MessagingException(this.message);

  @override
  String toString() => message;
}
