import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../utils/app_error_handler.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final bool isReadOnly;

  const ChatScreen({
    super.key,
    required this.chatRoom,
    this.isReadOnly = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  File? _selectedImageFile;
  bool _isSending = false;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    final hasImage = _selectedImageBytes != null;
    if (text.isEmpty && !hasImage) return;

    final user = _authService.currentUser;
    if (user == null) return;

    final userName = await _authService.getUserName(user.uid);
    
    setState(() {
      _isSending = true;
    });

    try {
      String? imageUrl;
      if (hasImage) {
        imageUrl = await _chatService.uploadChatImage(_selectedImageBytes!);
      }

      _messageController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageFile = null;
      });

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        senderId: user.uid,
        senderName: userName,
        text: text,
        imageUrl: imageUrl,
      );

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 50,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showError(context, e);
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Kirim Gambar / Foto', style: AppTheme.headingSmall),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.photo_library_outlined,
                        label: 'Galeri',
                        color: AppTheme.primaryBlue,
                        onTap: () {
                          _pickImage(ImageSource.gallery);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'Kamera',
                        color: AppTheme.emeraldGreen,
                        onTap: () {
                          _pickImage(ImageSource.camera);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTheme.labelBold.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatImage(String imageUrl, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        return Container(
          width: width,
          height: height,
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: _buildChatImage(
                imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final bool isDonor = widget.chatRoom.donorId == user?.uid;
    final String otherName =
        isDonor ? widget.chatRoom.receiverName : widget.chatRoom.donorName;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderGrey, height: 1),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryBlue.withAlpha(20),
              child: Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                style: AppTheme.labelBold.copyWith(
                  color: AppTheme.primaryBlue,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: AppTheme.labelBold.copyWith(fontSize: 15),
                  ),
                  Text(
                    widget.chatRoom.donationName,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Donation context banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.paleBlue,
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Percakapan terkait donasi "${widget.chatRoom.donationName}"',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryBlue,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (widget.isReadOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.amber.withAlpha(18),
              child: Text(
                'Mode preview aktif. Anda dapat membaca percakapan, tetapi belum dapat mengirim pesan.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Messages
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryBlue),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.waving_hand_rounded,
                            size: 48, color: AppTheme.amber),
                        const SizedBox(height: 16),
                        Text('Mulai percakapan!',
                            style: AppTheme.headingSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Kirim pesan pertama Anda',
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll on new messages
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == user?.uid;
                    final showDate = index == 0 ||
                        !_isSameDay(messages[index - 1].timestamp,
                            message.timestamp);

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundGrey,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderGrey),
                              ),
                              child: Text(
                                _formatDate(message.timestamp),
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                            ),
                          ),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Image Preview (if selected)
          if (_selectedImageFile != null && !widget.isReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.white,
                border: const Border(
                  top: BorderSide(color: AppTheme.borderGrey),
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImageFile!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImageFile = null;
                              _selectedImageBytes = null;
                            });
                          },
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: const Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gambar siap dikirim...',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
                    ),
                  ),
                ],
              ),
            ),

          // Sending progress bar
          if (_isSending)
            const LinearProgressIndicator(
              color: AppTheme.primaryBlue,
              backgroundColor: AppTheme.paleBlue,
            ),

          // Input Bar
          if (!widget.isReadOnly)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.white,
                border: const Border(
                  top: BorderSide(color: AppTheme.borderGrey),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                      onPressed: _isSending ? null : _showImagePicker,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGrey,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          enabled: !_isSending,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 4,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            hintStyle: AppTheme.bodyMedium,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _isSending ? Colors.grey : AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 6,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryBlue : AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: AppTheme.borderGrey.withAlpha(150)),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              GestureDetector(
                onTap: () => _showFullScreenImage(context, message.imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildChatImage(
                    message.imageUrl!,
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
              if (message.text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: AppTheme.bodyMedium.copyWith(
                  color: isMe ? Colors.white : AppTheme.textDark,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                color: isMe ? Colors.white70 : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Hari ini';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Kemarin';
    }
    return DateFormat('dd MMMM yyyy').format(date);
  }
}
