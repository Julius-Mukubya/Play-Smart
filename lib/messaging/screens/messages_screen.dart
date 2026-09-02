import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/messaging/providers/messaging_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:play_smart/core/theme/app_theme.dart';
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

  String _requestFilter = 'All';

  Widget _buildRequestsTab(BuildContext context, ThemeData theme, MessagingState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    final currentUserId = _getCurrentUserId();
    final allRequests = state.allRequests.isNotEmpty ? state.allRequests : state.pendingRequests;

    final filtered = allRequests.where((r) {
      if (_requestFilter == 'Pending') return r.isPending;
      if (_requestFilter == 'Accepted') return r.isAccepted;
      if (_requestFilter == 'Declined') return r.isRejected;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter pills for requests
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Accepted', 'Declined'].map((filterLabel) {
                final active = _requestFilter == filterLabel;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _requestFilter = filterLabel),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accentPrimary
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? AppColors.accentPrimary
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        filterLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          color: active ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          _requestFilter == 'All'
                              ? 'No requests found'
                              : 'No $_requestFilter.toLowerCase() requests',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Requests between you and other athletes/recruiters will appear here.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final request = filtered[i];
                    final isIncoming = request.toUserId == currentUserId;
                    final otherName = isIncoming ? request.fromUserName : 'User (${request.toUserId})';
                    final otherPhoto = isIncoming ? request.fromUserPhotoUrl : request.toUserPhotoUrl;

                    Color badgeColor;
                    String badgeText;
                    if (request.isAccepted) {
                      badgeColor = AppColors.stateSuccess;
                      badgeText = 'Accepted';
                    } else if (request.isRejected) {
                      badgeColor = AppColors.stateError;
                      badgeText = 'Declined';
                    } else {
                      badgeColor = AppColors.badgeSelf;
                      badgeText = 'Pending';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  backgroundImage: (otherPhoto != null && otherPhoto.isNotEmpty)
                                      ? CachedNetworkImageProvider(otherPhoto)
                                      : null,
                                  child: (otherPhoto == null || otherPhoto.isEmpty)
                                      ? Text(
                                          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        otherName,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        isIncoming ? 'Sent you a connection request' : 'You sent a connection request',
                                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (request.message.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(request.message, style: theme.textTheme.bodyMedium),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (request.isPending && isIncoming)
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
                              )
                            else if (request.isAccepted)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _openConversation(context, request.id, otherName, otherPhotoUrl: otherPhoto),
                                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                    label: const Text('Open Chat'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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

    final currentUserId = _getCurrentUserId();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.conversations.length,
      itemBuilder: (ctx, i) {
        final conv = state.conversations[i];
        final otherName = _getOtherParticipantName(conv);
        final otherPhoto = conv.fromUserId == currentUserId ? conv.toUserPhotoUrl : conv.fromUserPhotoUrl;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: (otherPhoto != null && otherPhoto.isNotEmpty)
                  ? CachedNetworkImageProvider(otherPhoto)
                  : null,
              child: (otherPhoto == null || otherPhoto.isEmpty)
                  ? Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              conv.message.isNotEmpty ? conv.message : 'Open conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openConversation(context, conv.id, otherName, otherPhotoUrl: otherPhoto),
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

  void _openConversation(BuildContext context, String conversationId, String otherName, {String? otherPhotoUrl}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ConversationScreen(
          conversationId: conversationId,
          otherName: otherName,
          otherPhotoUrl: otherPhotoUrl,
        ),
      ),
    );
  }
}

/// Conversation screen — shows messages in a thread.
class _ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherName;
  final String? otherPhotoUrl;

  const _ConversationScreen({
    required this.conversationId,
    required this.otherName,
    this.otherPhotoUrl,
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: (widget.otherPhotoUrl != null && widget.otherPhotoUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(widget.otherPhotoUrl!)
                  : null,
              child: (widget.otherPhotoUrl == null || widget.otherPhotoUrl!.isEmpty)
                  ? Text(
                      widget.otherName.isNotEmpty ? widget.otherName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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