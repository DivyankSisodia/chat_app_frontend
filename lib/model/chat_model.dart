class Message {
  final String? id;
  final String sender_id;
  final String receiver_id;
  final String message;

  Message({
    this.id,
    required this.sender_id,
    required this.receiver_id,
    required this.message
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
        id: json['id'],
        sender_id: json['sender_id'],
        receiver_id: json['receiver_id'],
        message: json['message']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': sender_id,
      'receiver_id': receiver_id,
      'message': message
    };
  }
}