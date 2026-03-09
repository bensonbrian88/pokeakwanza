class ShippingAddress {
  final int id;
  final String name;
  final String address;
  final String city;
  final String? phone;

  ShippingAddress({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.phone,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      if (phone != null) 'phone': phone,
    };
  }
}
