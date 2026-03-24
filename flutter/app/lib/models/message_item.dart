class MessageItem {
  final int messageId;
  final int senderUserId;
  final String content;
  final String sentAt;

  MessageItem({
    required this.messageId,
    required this.senderUserId,
    required this.content,
    required this.sentAt,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json){
    return MessageItem(
      messageId: json['message_id'],
      senderUserId: json['sender_user_id'],
      content: json['content'] ?? '',
      sentAt: json['sent_at'] ?? '',
    );
  }

}