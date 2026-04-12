import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final ChatService chatService = ChatService();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          // ── Clean Header ──
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesan',
                        style: AppTheme.headingLarge.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Komunikasi dengan donatur atau penerima',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: Container(height: 1, color: AppTheme.borderGrey)),

          // ── Chat List ──
          StreamBuilder<List<ChatRoom>>(
            stream: chatService.getChatRooms(user?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                  ),
                );
              }

              final chatRooms = snapshot.data ?? [];

              if (chatRooms.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 48, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text('Belum ada pesan', style: AppTheme.headingSmall),
                        const SizedBox(height: 8),
                        Text(
                          'Pesan akan muncul saat Anda\nterhubung melalui donasi',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final room = chatRooms[index];
                      return _buildChatRoomTile(context, room, user?.uid ?? '');
                    },
                    childCount: chatRooms.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomTile(
      BuildContext context, ChatRoom room, String currentUserId) {
    final bool isDonor = room.donorId == currentUserId;
    final String otherName = isDonor ? room.receiverName : room.donorName;
    final String initials =
        otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: room),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.softCard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryBlue.withAlpha(20),
                child: Text(
                  initials,
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.primaryBlue,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: AppTheme.labelBold.copyWith(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(room.lastMessageTime),
                          style: AppTheme.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.donationName,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.lastMessage.isNotEmpty
                          ? room.lastMessage
                          : 'Belum ada pesan',
                      style: AppTheme.bodySmall.copyWith(
                        color: room.lastMessage.isNotEmpty
                            ? AppTheme.textGrey
                            : AppTheme.textLight,
                        fontStyle: room.lastMessage.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    if (time.year == 2000) return ''; // Default past time handling
    
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0 && now.day == time.day) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != time.day)) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }
}
