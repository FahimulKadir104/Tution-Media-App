import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../providers/refresh_provider.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  RefreshProvider? _refreshProvider;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    
    // Start polling for new messages every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(silent: true);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshProvider = context.read<RefreshProvider>();
      _refreshProvider!.addListener(_loadMessages);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _refreshProvider?.removeListener(_loadMessages);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    try {
      final messagesData = await ApiService.getMessages(
        auth.token!,
        widget.conversation.id,
      );

      // Mark messages as read
      await ApiService.markMessagesAsRead(
        auth.token!,
        widget.conversation.id,
      );

      if (!mounted) return;

      final newMessages = messagesData
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList();
      
      // Only update UI if messages changed or first load
      if (!silent || _messages.length != newMessages.length) {
        setState(() {
          final wasAtBottom = _isAtBottom();
          _messages = newMessages;
          _isLoading = false;
          
          // Auto-scroll to bottom only if user was already at bottom
          if (wasAtBottom || !silent) {
            _scrollToBottom();
          }
        });
      } else if (_isLoading) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return (maxScroll - currentScroll) < 100; // Within 100 pixels of bottom
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !mounted) return;

    final auth = context.read<AuthProvider>();
    _messageController.clear();

    try {
      await ApiService.sendMessage(
        auth.token!,
        widget.conversation.id,
        text,
      );

      if (mounted) {
        _loadMessages();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.onPrimaryContainer.withOpacity(0.1),
              child: Text(
                ((widget.conversation.otherUserName ??
                            widget.conversation.otherUserEmail)?[0] ??
                        '?')
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.otherUserName ??
                        widget.conversation.otherUserEmail ??
                        'Chat',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.conversation.postSubject ?? 'Tuition Discussion',
                    style: TextStyle(fontSize: 11, color: colorScheme.onPrimaryContainer.withOpacity(0.7)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: kIsWeb ? 800 : double.infinity),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: _messages.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                                children: [
                                  _buildEmptyState(colorScheme),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isMe =
                                      message.senderId == auth.user!.id;
                                  return _buildMessageBubble(
                                    message,
                                    isMe,
                                    colorScheme,
                                  );
                                },
                              ),
                      ),
              ),
              _buildInputArea(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 48, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No messages yet',
              style: TextStyle(color: colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Message message, bool isMe, ColorScheme colorScheme) {
    final showTime = _shouldShowTime(message);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                FutureBuilder<String?>(
                  future: ApiService.getProfilePicture(message.senderId),
                  builder: (context, snapshot) {
                    final profilePictureUrl = snapshot.data;
                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                          ? NetworkImage(profilePictureUrl)
                          : null,
                      child: profilePictureUrl == null || profilePictureUrl.isEmpty
                          ? Text(
                              (message.senderName ?? message.senderEmail ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                FutureBuilder<String?>(
                  future: ApiService.getProfilePicture(message.senderId),
                  builder: (context, snapshot) {
                    final profilePictureUrl = snapshot.data;
                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                          ? NetworkImage(profilePictureUrl)
                          : null,
                      child: profilePictureUrl == null || profilePictureUrl.isEmpty
                          ? Text(
                              (message.senderName ?? message.senderEmail ?? 'Y')[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ],
            ],
          ),
          if (showTime) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : 40,
                right: isMe ? 40 : 0,
              ),
              child: Text(
                _formatMessageTime(message.sentAt),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.outline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowTime(Message message) {
    final index = _messages.indexOf(message);
    if (index == _messages.length - 1) return true;
    
    try {
      final currentTime = DateTime.parse(message.sentAt);
      final nextTime = DateTime.parse(_messages[index + 1].sentAt);
      return nextTime.difference(currentTime).inMinutes > 5;
    } catch (_) {
      return false;
    }
  }

  String _formatMessageTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      } else if (diff.inDays == 1) {
        return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, "0")}';
      } else {
        return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, "0")}';
      }
    } catch (_) {
      return '';
    }
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: Icon(Icons.send_rounded, color: colorScheme.onPrimary),
              iconSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}
