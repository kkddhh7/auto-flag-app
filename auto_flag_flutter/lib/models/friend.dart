class Friend {
  final String id;
  final String introduction;

  Friend({required this.id, required this.introduction});

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      introduction: json['introduction'] as String,
    );
  }
}