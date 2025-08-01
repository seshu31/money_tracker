class Expense {
  final String id;
  final String title;
  final String description;
  final String type;
  final double amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
} 