class SessionLogMessage {
  const SessionLogMessage({
    required this.sender,
    required this.content,
    this.timestamp,
    this.isSystem = false,
  });

  final String sender;
  final String content;
  final DateTime? timestamp;
  final bool isSystem;

  SessionLogMessage copyWith({
    String? sender,
    String? content,
    DateTime? timestamp,
    bool? isSystem,
  }) {
    return SessionLogMessage(
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  Map<String, Object?> toJson() => {
        'sender': sender,
        'content': content,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
        'isSystem': isSystem,
      };
}
