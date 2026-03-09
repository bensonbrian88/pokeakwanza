class PaymentMethod {
  final int id;
  final String type;
  final String details; // could be last4 or description

  PaymentMethod({
    required this.id,
    required this.type,
    required this.details,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      type: json['type']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'details': details,
    };
  }
}
