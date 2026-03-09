class HelpCenterInfo {
  final String phone;
  final String whatsapp;
  final String email;
  final String location;

  HelpCenterInfo({
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.location,
  });

  factory HelpCenterInfo.fromJson(Map<String, dynamic> json) {
    return HelpCenterInfo(
      phone: json['phone']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }
}
