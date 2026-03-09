class PhoneCode {
  final String code;
  final String country;

  PhoneCode({required this.code, required this.country});

  factory PhoneCode.fromJson(Map<String, dynamic> json) {
    return PhoneCode(
      code: json['code']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'country': country,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneCode &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          country == other.country;

  @override
  int get hashCode => code.hashCode ^ country.hashCode;
}
