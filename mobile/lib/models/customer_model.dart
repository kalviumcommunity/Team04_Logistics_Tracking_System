class CustomerModel {
  final String id;
  final String fullName;
  final String? email;
  final String phone;
  final String address;
  final String city;

  CustomerModel({
    required this.id,
    required this.fullName,
    this.email,
    required this.phone,
    required this.address,
    required this.city,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final phoneVal = (json['phone'] ??
            json['phoneNumber'] ??
            json['customerPhone'] ??
            json['recipientPhone'] ??
            json['contactNumber'] ??
            json['contact'])
        ?.toString()
        .trim();

    final nameVal = (json['fullName'] ??
            json['name'] ??
            json['customerName'] ??
            json['recipientName'])
        ?.toString()
        .trim();

    final addressVal = (json['address'] ??
            json['deliveryAddress'] ??
            json['destinationAddress'])
        ?.toString()
        .trim();

    final emailVal = (json['email'] ??
            json['customerEmail'] ??
            json['recipientEmail'])
        ?.toString()
        .trim();

    final cityVal =
        (json['city'] ?? json['destinationCity'])?.toString().trim();

    return CustomerModel(
      id: json['id']?.toString() ?? '',
      fullName: nameVal?.isNotEmpty == true ? nameVal! : '',
      email: emailVal?.isNotEmpty == true ? emailVal : null,
      phone: phoneVal?.isNotEmpty == true ? phoneVal! : '',
      address: addressVal?.isNotEmpty == true ? addressVal! : '',
      city: cityVal?.isNotEmpty == true ? cityVal! : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
    };
  }
}
