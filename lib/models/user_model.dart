class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String profileImage;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "fullName": fullName,
      "email": email,
      "phone": phone,
      "profileImage": profileImage,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"] ?? "",
      fullName: map["fullName"] ?? "",
      email: map["email"] ?? "",
      phone: map["phone"] ?? "",
      profileImage: map["profileImage"] ?? "",
    );
  }
}