class UserModel {
  int? id;
  final String name;
  String? phone;
  String? email;
  String? password;

  UserModel({
    this.id,
    required this.name,
     this.phone,
     this.email,
     this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
    };
  }
}