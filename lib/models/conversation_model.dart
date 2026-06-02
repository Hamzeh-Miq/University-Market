import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat conversation document in Firestore.
class ConversationModel {
  final String conversationId;
  final List<String> participants;
  final String productId;
  final String productTitle;
  final String lastMessage;
  final DateTime lastMessageTime;

  /// UIDs of users who have soft-deleted this conversation.
  /// The conversation is hidden from these users but still visible to others.
  final List<String> deletedBy;

  ConversationModel({
    required this.conversationId,
    required this.participants,
    required this.productId,
    this.productTitle = '',
    required this.lastMessage,
    required this.lastMessageTime,
    this.deletedBy = const [],
  });

  factory ConversationModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return ConversationModel(
      conversationId: documentId,
      participants: List<String>.from(json['participants'] ?? []),
      productId: json['productId'] ?? '',
      productTitle: json['productTitle'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? (json['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      deletedBy: List<String>.from(json['deletedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'productId': productId,
      'productTitle': productTitle,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'deletedBy': deletedBy,
    };
  }
}

/// Represents a single chat message in a conversation sub-collection.
class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime timestamp;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String documentId) {
    return MessageModel(
      messageId: documentId,
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
