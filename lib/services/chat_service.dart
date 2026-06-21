import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_error_handler.dart';
import '../models/chat_model.dart';
import 'app_notification_service.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload Chat Image from Bytes with Base64 Fallback
  Future<String> uploadChatImage(Uint8List imageBytes) async {
    try {
      String fileName = const Uuid().v4();
      Reference ref = _storage.ref().child('donations').child('chat_$fileName.jpg');
      
      UploadTask uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      AppErrorHandler.logError('ChatService.uploadChatImage', e);
      // FALLBACK: Convert to Base64 and return as data URI
      String base64String = base64Encode(imageBytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }

  // Get or create chat room for a donation connection
  Future<ChatRoom> getOrCreateChatRoom({
    required String donationId,
    required String donationName,
    required String donorId,
    required String donorName,
    required String receiverId,
    required String receiverName,
  }) async {
    try {
      final roomId = '${donationId}_${donorId}_$receiverId';

      final doc = await _firestore.collection('chatRooms').doc(roomId).get();
      if (doc.exists) {
        return ChatRoom.fromMap(doc.data()!);
      }

      final chatRoom = ChatRoom(
        id: roomId,
        donationId: donationId,
        donationName: donationName,
        donorId: donorId,
        donorName: donorName,
        receiverId: receiverId,
        receiverName: receiverName,
      );

      await _firestore.collection('chatRooms').doc(roomId).set(chatRoom.toMap());
      return chatRoom;
    } catch (e) {
      AppErrorHandler.logError('ChatService.getOrCreateChatRoom', e);
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final message = ChatMessage(
        id: messageId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      // Add message to subcollection
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update chat room metadata
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': imageUrl != null ? '📷 Foto' : text,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      });

      // Send push notification to the recipient
      try {
        final chatRoomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
        if (chatRoomDoc.exists) {
          final donorId = chatRoomDoc.data()?['donorId'] ?? '';
          final receiverId = chatRoomDoc.data()?['receiverId'] ?? '';
          final recipientId = senderId == donorId ? receiverId : donorId;
          
          if (recipientId.isNotEmpty) {
            await AppNotificationService().sendPushNotification(
              receiverUid: recipientId,
              title: senderName,
              body: imageUrl != null ? '📷 Foto' : text,
              payload: '/dashboard',
            );
          }
        }
      } catch (fcmError) {
        debugPrint('Error sending chat push notification: $fcmError');
      }
    } catch (e) {
      AppErrorHandler.logError('ChatService.sendMessage', e);
      rethrow;
    }
  }

  // Stream messages for a chat room
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .toList();
    }).handleError((error) {
      AppErrorHandler.logError('ChatService.getMessagesStream', error);
    });
  }

  // Stream chat rooms for a user (both as donor and receiver)
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    // We need to query both donorId and receiverId
    // Firestore doesn't support OR queries easily, so we merge two streams
    final donorStream = _firestore
        .collection('chatRooms')
        .where('donorId', isEqualTo: userId)
        .snapshots();

    final receiverStream = _firestore
        .collection('chatRooms')
        .where('receiverId', isEqualTo: userId)
        .snapshots();

    return donorStream.asyncExpand((donorSnapshot) {
      return receiverStream.map((receiverSnapshot) {
        final Set<String> seenIds = {};
        final List<ChatRoom> rooms = [];

        for (var doc in donorSnapshot.docs) {
          if (seenIds.add(doc.id)) {
            rooms.add(ChatRoom.fromMap(doc.data()));
          }
        }
        for (var doc in receiverSnapshot.docs) {
          if (seenIds.add(doc.id)) {
            rooms.add(ChatRoom.fromMap(doc.data()));
          }
        }

        rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        return rooms;
      }).handleError((error) {
        AppErrorHandler.logError('ChatService.getChatRoomsStream', error);
      });
    });
  }
}
