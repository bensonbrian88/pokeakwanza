class Order {
  final int id;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<dynamic> items;
  final String deliveryStatus;
  final String trackingNumber;
  final String courierName;
  final String estimatedDelivery;

  Order({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
    this.deliveryStatus = '',
    this.trackingNumber = '',
    this.courierName = '',
    this.estimatedDelivery = '',
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      status: json['status'],
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      items: json['items'] ?? [],
      deliveryStatus:
          (json['delivery_status'] ?? json['status'] ?? '').toString(),
      trackingNumber: (json['tracking_number'] ?? '').toString(),
      courierName: (json['courier_name'] ?? '').toString(),
      estimatedDelivery: (json['estimated_delivery'] ?? '').toString(),
    );
  }
}
