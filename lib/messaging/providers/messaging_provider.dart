import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/messaging/repositories/messaging_repository.dart';
import 'package:play_smart/messaging/services/messaging_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';

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
  @override
  MessagingState build() {
    return MessagingState();
  }

  MessagingRepository get _repository => ref.read(messagingRepositoryProvider);
  MessagingService get _service => ref.read(messagingServiceProvider);

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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Send a message request to an athlete.
  Future<String?> sendRequest(String recipientId, String message) async {
    final sender = _currentUser;
    final userId = _currentUserId;
    if (sender == null || userId == null) return 'Not authenticated';

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final request = MessageRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        fromUserId: userId,
        fromUserName: sender.name,
        toUserId: recipientId,
        message: message,
        accepted: false,
        requiresMonitoring: false,
        createdAt: DateTime.now(),
      );

      final result = await _repository.sendRequest(request);
      await _service.onMessageRequestSent(result);
      await loadMessages();
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return e.toString();
    }
  }

  /// Accept a message request.
  Future<void> acceptRequest(String requestId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.acceptRequest(requestId);
      await _service.onMessageRequestAccepted(result);
      await loadMessages();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Decline a message request.
  Future<void> declineRequest(String requestId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.declineRequest(requestId);
      await loadMessages();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load messages in a conversation.
  Future<void> loadConversationMessages(String conversationId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final messages = await _repository.getConversationMessages(conversationId);
      state = state.copyWith(currentMessages: messages);
      await _repository.markAsRead(conversationId, userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Send a message in a conversation.
  Future<void> sendMessage(String conversationId, String text) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final msg = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: userId,
      text: text,
      read: false,
      sentAt: DateTime.now(),
    );

    try {
      final sent = await _repository.sendMessage(msg);
      state = state.copyWith(
        currentMessages: [...state.currentMessages, sent],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Messaging state notifier provider.
final messagingProvider = NotifierProvider<MessagingNotifier, MessagingState>(
  MessagingNotifier.new,
);