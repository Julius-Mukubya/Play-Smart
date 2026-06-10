import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/messaging/repositories/messaging_repository.dart';
import 'package:play_smart/messaging/services/messaging_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

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
      final pending = _repository.getPendingRequests(userId);
      final conversations = _repository.getConversations(userId);
      state = state.copyWith(
        pendingRequests: pending,
        conversations: conversations,
        isLoading: false,
      );
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
    final recipient = MockData.getUserById(recipientId);
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
      final messages = _repository.getConversationMessages(conversationId);
      state = state.copyWith(currentMessages: messages, isLoading: false);
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