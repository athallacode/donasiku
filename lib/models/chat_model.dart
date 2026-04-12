import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}

class ChatRoom {
  final String id; // donationId used as chatRoomId
  final String donationId;
  final String donationName;
  final String donorId;
  final String donorName;
  final String receiverId;
  final String receiverName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.donationId,
    required this.donationName,
    required this.donorId,
    required this.donorName,
    required this.receiverId,
    required this.receiverName,
    this.lastMessage = '',
    DateTime? lastMessageTime,
    this.unreadCount = 0,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donationId': donationId,
      'donationName': donationName,
      'donorId': donorId,
      'donorName': donorName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      donationId: map['donationId'] ?? '',
      donationName: map['donationName'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] is Timestamp
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
    );
  }
}
