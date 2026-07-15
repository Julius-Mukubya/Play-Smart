import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/messaging/repositories/messaging_repository.dart';
import 'package:play_smart/messaging/services/messaging_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangeEvent, PostgresChangeFilter, PostgresChangeFilterType, RealtimeChannel;

/// Messaging repository provider.
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository();
});

/// Messaging service provider.
final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService();
});

/// Messaging state.
class MessagingState {
  final List<MessageRequest> pendingRequests;
  final List<MessageRequest> conversations;
  final List<Message> currentMessages;
  final bool isLoading;
  final String? error;

  const MessagingState({
    this.pendingRequests = const [],
    this.conversations = const [],
    this.currentMessages = const [],
    this.isLoading = false,
    this.error,
  });

  MessagingState copyWith({
    List<MessageRequest>? pendingRequests,
    List<MessageRequest>? conversations,
    List<Message>? currentMessages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MessagingState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      conversations: conversations ?? this.conversations,
      currentMessages: currentMessages ?? this.currentMessages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Messaging notifier.
class MessagingNotifier extends Notifier<MessagingState> {
  RealtimeChannel? _requestsChannel;
  RealtimeChannel? _conversationChannel;
  String? _subscribedRequestsUserId;
  String? _subscribedConversationId;

  @override
  MessagingState build() {
    ref.onDispose(() {
      _requestsChannel?.unsubscribe();
      _conversationChannel?.unsubscribe();
    });
    return MessagingState();
  }

  MessagingRepository get _repository => ref.read(messagingRepositoryProvider);
  MessagingService get _service => ref.read(messagingServiceProvider);

  /// Subscribe to live changes on `message_requests` so the pending/
  /// conversations lists stay current across devices (e.g. accepting a
  /// request elsewhere updates this list without a manual refresh).
  /// Safe to call repeatedly — only subscribes once per notifier lifetime.
  void _ensureRequestsSubscription(String userId) {
    if (_subscribedRequestsUserId == userId) return;
    _requestsChannel?.unsubscribe();
    _subscribedRequestsUserId = userId;
    _requestsChannel = supabase
        .channel('message_requests:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_requests',
          callback: (payload) => loadMessages(),
        )
        .subscribe();
  }

  /// Subscribe to new messages in a conversation. Only listens for `insert`
  /// — `update` events (from markAsRead) would otherwise retrigger a reload
  /// that calls markAsRead again, looping.
  void _subscribeToConversation(String conversationId) {
    if (_subscribedConversationId == conversationId) return;
    _conversationChannel?.unsubscribe();
    _subscribedConversationId = conversationId;
    _conversationChannel = supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => loadConversationMessages(conversationId),
        )
        .subscribe();
  }

  String? get _currentUserId {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) return auth.user.id;
    return null;
  }

  User? get _currentUser {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) return auth.user;
    return null;
  }

  /// Load all messaging data for current user.
  Future<void> loadMessages() async {
    final userId = _currentUserId;
    if (userId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pending = await _repository.getPendingRequests(userId);
      final conversations = await _repository.getConversations(userId);
      state = state.copyWith(
        pendingRequests: pending,
        conversations: conversations,
        isLoading: false,
      );
      _ensureRequestsSubscription(userId);
    } catch (e, st) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Send a message request to an athlete.
  Future<String?> sendRequest(String recipientId, String message) async {
    final sender = _currentUser;
    final userId = _currentUserId;
    if (sender == null || userId == null) return 'Not authenticated.';

    // Look up recipient user
    final recipient = await ref.read(authRepositoryProvider).getUserById(recipientId);
    if (recipient == null) return 'Recipient not found.';

    // Check if allowed
    final error = _service.getSendRequestError(sender, recipient);
    if (error != null) return error;

    try {
      final now = DateTime.now();
      await _repository.sendRequest(MessageRequest(
        id: 'mr-${now.millisecondsSinceEpoch}',
        fromUserId: userId,
        fromUserName: sender.name,
        toUserId: recipientId,
        message: message,
      ));
      await loadMessages();
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  /// Accept a message request.
  Future<void> acceptRequest(String requestId) async {
    try {
      await _repository.acceptRequest(requestId);
      await loadMessages();
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Decline a message request.
  Future<void> declineRequest(String requestId) async {
    try {
      await _repository.declineRequest(requestId);
      await loadMessages();
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load messages for a specific conversation.
  Future<void> loadConversationMessages(String conversationId) async {
    state = state.copyWith(isLoading: true);
    try {
      final messages = await _repository.getConversationMessages(conversationId);
      state = state.copyWith(currentMessages: messages, isLoading: false);
      _subscribeToConversation(conversationId);
      // Mark as read
      final userId = _currentUserId;
      if (userId != null) {
        await _repository.markAsRead(conversationId, userId);
      }
    } catch (e, st) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Send a message in a conversation.
  Future<void> sendMessage(String conversationId, String text) async {
    final userId = _currentUserId;
    if (userId == null) return;
    try {
      final now = DateTime.now();
      await _repository.sendMessage(Message(
        id: 'msg-${now.millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: userId,
        text: text,
      ));
      await loadConversationMessages(conversationId);
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Messaging state provider.
final messagingProvider = NotifierProvider<MessagingNotifier, MessagingState>(
  MessagingNotifier.new,
);