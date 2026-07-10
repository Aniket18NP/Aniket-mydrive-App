import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final FirestoreService _firestoreService =
      FirestoreService();

  bool isLoading = true;
  bool isSaving = false;

  UserModel? currentUserData;

  // =========================================================
  // INITIALIZE
  // =========================================================

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // =========================================================
  // LOAD CURRENT USER DATA
  // =========================================================

  Future<void> loadUser() async {
    try {
      final firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You are not logged in.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final UserModel? user =
          await _firestoreService.getUser(
        firebaseUser.uid,
      );

      if (!mounted) return;

      if (user == null) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User profile not found.',
            ),
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
          content: Text(
            'Failed to load profile: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> saveProfile() async {
    if (isSaving) return;

    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final firebaseUser =
        FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are not logged in.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (currentUserData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User information is not available.',
          ),
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

      await _firestoreService.updateUser(
        updatedUser,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // INPUT FIELD
  // =========================================================

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
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
            ),
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
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Form(
                key: _formKey,

                child: Column(
                  children: [
                    // =========================================
                    // PROFILE IMAGE
                    // =========================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(22),
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
                                  color: Colors.blue.shade50,
                                  border: Border.all(
                                    color:
                                        Colors.blue.shade100,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 68,
                                  color: Colors.blue,
                                ),
                              ),

                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration:
                                      const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Update Your Profile',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Keep your personal information up to date',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =========================================
                    // PERSONAL INFORMATION FORM
                    // =========================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // FULL NAME

                          _buildInputField(
                            controller: nameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            color: Colors.blue,
                            keyboardType:
                                TextInputType.name,
                            validator: (value) {
                              final name =
                                  value?.trim() ?? '';

                              if (name.isEmpty) {
                                return 'Please enter your full name';
                              }

                              if (name.length < 2) {
                                return 'Name must contain at least 2 characters';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // PHONE NUMBER

                          _buildInputField(
                            controller: phoneController,
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            icon: Icons.phone_outlined,
                            color: Colors.green,
                            keyboardType:
                                TextInputType.phone,
                            validator: (value) {
                              final phone =
                                  value?.trim() ?? '';

                              if (phone.isEmpty) {
                                return 'Please enter your phone number';
                              }

                              final digitsOnly =
                                  phone.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );

                              if (digitsOnly.length < 10) {
                                return 'Please enter a valid phone number';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =========================================
                    // EMAIL INFORMATION
                    // =========================================

                    if (currentUserData != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.orange
                                    .withValues(alpha: 0.10),
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.email_outlined,
                                color: Colors.orange,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email Address',
                                    style: TextStyle(
                                      color:
                                          Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    currentUserData!.email,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    'Email cannot be changed here',
                                    style: TextStyle(
                                      color:
                                          Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              Icons.lock_outline,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // =========================================
                    // SAVE BUTTON
                    // =========================================

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),

                        onPressed:
                            isSaving ? null : saveProfile,

                        icon: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),

                        label: Text(
                          isSaving
                              ? 'Saving...'
                              : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
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