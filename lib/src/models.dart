
// ignore_for_file: unused_import

class GroceryItem {
  GroceryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.date,
    this.imagePath,
  });

  final String id;
  final String userId;
  final String name;
  final double quantity;
  final String unit;
  final double price;
  final DateTime date;
  final String? imagePath;

  double get total => price * quantity;

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return GroceryItem(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
      price: (json['price'] as num).toDouble(),
      date: parsedDate,
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
    };
  }
}
