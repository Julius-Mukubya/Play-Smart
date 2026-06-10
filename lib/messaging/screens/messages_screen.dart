import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/messaging/providers/messaging_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Messages screen — shows message requests and active conversations.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(messagingProvider.notifier).loadMessages());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(messagingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (state.pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.pendingRequests.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Conversations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(context, theme, state),
          _buildConversationsTab(context, theme, state),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(BuildContext context, ThemeData theme, MessagingState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    if (state.pendingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_outline, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('No pending requests', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Message requests from recruiters and clubs will appear here.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.pendingRequests.length,
      itemBuilder: (ctx, i) {
        final request = state.pendingRequests[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        request.fromUserName.isNotEmpty
                            ? request.fromUserName[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.fromUserName, style: theme.textTheme.titleMedium),
                          Text('Wants to connect', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                if (request.message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(request.message, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ref.read(messagingProvider.notifier).declineRequest(request.id);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      child: const Text('Decline'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(messagingProvider.notifier).acceptRequest(request.id);
                      },
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationsTab(BuildContext context, ThemeData theme, MessagingState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    if (state.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('No conversations yet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Accepted message requests will appear here as conversations.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.conversations.length,
      itemBuilder: (ctx, i) {
        final conv = state.conversations[i];
        final otherName = _getOtherParticipantName(conv);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            title: Text(otherName),
            subtitle: Text(
              conv.message.isNotEmpty ? conv.message : 'Open conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openConversation(context, conv.id, otherName),
          ),
        );
      },
    );
  }

  String _getOtherParticipantName(MessageRequest request) {
    final userId = _getCurrentUserId();
    if (request.fromUserId == userId) return request.toUserId;
    return request.fromUserName;
  }

  String? _getCurrentUserId() {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) return auth.user.id;
    return null;
  }

  void _openConversation(BuildContext context, String conversationId, String otherName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ConversationScreen(
          conversationId: conversationId,
          otherName: otherName,
        ),
      ),
    );
  }
}

/// Conversation screen — shows messages in a thread.
class _ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherName;

  const _ConversationScreen({
    required this.conversationId,
    required this.otherName,
  });

  @override
  ConsumerState<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<_ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(messagingProvider.notifier)
        .loadConversationMessages(widget.conversationId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(messagingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.currentMessages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.currentMessages.length,
                        itemBuilder: (ctx, i) {
                          final message = state.currentMessages[i];
                          final isMe = message.senderId == _getCurrentUserId();
                          return _buildMessageBubble(theme, message, isMe);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: theme.colorScheme.primary,
                  onPressed: () {
                    final text = _messageController.text.trim();
                    if (text.isNotEmpty) {
                      ref.read(messagingProvider.notifier)
                          .sendMessage(widget.conversationId, text);
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? _getCurrentUserId() {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) return auth.user.id;
    return null;
  }
}