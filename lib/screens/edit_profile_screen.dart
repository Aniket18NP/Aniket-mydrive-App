import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirestoreService _firestoreService = FirestoreService();

  final StorageService _storageService = StorageService();

  final ImagePicker _picker = ImagePicker();

  bool isLoading = true;
  bool isSaving = false;
  bool uploadingImage = false;

  UserModel? currentUserData;

  File? selectedImage;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You are not logged in."),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final user = await _firestoreService.getUser(firebaseUser.uid);

      if (!mounted) return;

      if (user == null) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User profile not found."),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      currentUserData = user;

      nameController.text = user.fullName;

      phoneController.text = user.phone;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(
      source: source,
      imageQuality: 75,
    );

    if (pickedImage == null) return;

    setState(() {
      selectedImage = File(pickedImage.path);
    });

    await uploadProfileImage();
  }

  Future<void> uploadProfileImage() async {
    if (selectedImage == null) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) return;

    setState(() {
      uploadingImage = true;
    });

    try {
      final imageUrl = await _storageService.uploadProfileImage(
        uid: firebaseUser.uid,
        image: selectedImage!,
      );

      currentUserData = UserModel(
        uid: currentUserData!.uid,
        fullName: currentUserData!.fullName,
        email: currentUserData!.email,
        phone: currentUserData!.phone,
        profileImage: imageUrl,
      );

      await _firestoreService.updateUser(currentUserData!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile image updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          uploadingImage = false;
        });
      }
    }
  }

  Future<void> saveProfile() async {
    if (isSaving) return;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are not logged in."),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (currentUserData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User information is not available."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final updatedUser = UserModel(
        uid: currentUserData!.uid,
        fullName: nameController.text.trim(),
        email: currentUserData!.email,
        phone: phoneController.text.trim(),
        profileImage: currentUserData!.profileImage,
      );

      await _firestoreService.updateUser(updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 115,
                                height: 115,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: selectedImage != null
                                      ? Image.file(
                                          selectedImage!,
                                          width: 115,
                                          height: 115,
                                          fit: BoxFit.cover,
                                        )
                                      : currentUserData != null &&
                                            currentUserData!
                                                .profileImage
                                                .isNotEmpty
                                      ? Image.network(
                                          currentUserData!.profileImage,
                                          width: 115,
                                          height: 115,
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }

                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.person,
                                                  size: 70,
                                                  color: Colors.blue,
                                                );
                                              },
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 70,
                                          color: Colors.blue,
                                        ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
  context: context,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(25),
    ),
  ),
  builder: (context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Choose Profile Photo",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.camera_alt),
              ),
              title: const Text("Camera"),
              onTap: () async {
                Navigator.pop(context);
                await pickImage(ImageSource.camera);
              },
            ),

            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_library),
              ),
              title: const Text("Gallery"),
              onTap: () async {
                Navigator.pop(context);
                await pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  },
);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: uploadingImage
                                        ? const Padding(
                                            padding: EdgeInsets.all(10),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Update Your Profile",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Keep your personal information up to date",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Personal Information",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildInputField(
                            controller: nameController,
                            label: "Full Name",
                            hint: "Enter your full name",
                            icon: Icons.person_outline,
                            color: Colors.blue,
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter your name";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          _buildInputField(
                            controller: phoneController,
                            label: "Phone Number",
                            hint: "Enter your phone number",
                            icon: Icons.phone_outlined,
                            color: Colors.green,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter phone number";
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (currentUserData != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.email, color: Colors.white),
                          ),
                          title: const Text("Email Address"),
                          subtitle: Text(currentUserData!.email),
                          trailing: const Icon(Icons.lock_outline),
                        ),
                      ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isSaving ? "Saving..." : "Save Changes",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
