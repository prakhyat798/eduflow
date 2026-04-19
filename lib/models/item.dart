class Item {
  String title;
  bool completed;

  Item({
    required this.title,
    this.completed = false,
  });

  // ✅ Alias so home_screen.dart works without changes
  bool get isDone => completed;
  set isDone(bool value) => completed = value;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'completed': completed,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      title: json['title'],
      completed: json['completed'] ?? false,
    );
  }
}