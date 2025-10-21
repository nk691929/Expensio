// lib/screens/profile_screen.dart
// import 'dart:io';

import 'package:animationandcharts/models/user_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';

import '../providers/user_provider.dart'; // <-- adjust path if needed
import '../providers/auth_provider.dart'; // <-- adjust path if needed

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // bool _isUploadingImage = false;
  bool _isSavingProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Pick image from gallery and upload using the notifier
  // Future<void> _pickAndUploadImage(String userId) async {
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(const SnackBar(content: Text("In Future Update")));
  //   // NOTE: add image_picker dependency in pubspec.yaml:
  //   // image_picker: ^0.8.x
  //   // final picker = ImagePicker();
  //   // final picked = await picker.pickImage(
  //   //   source: ImageSource.gallery,
  //   //   imageQuality: 75,
  //   // );
  //   // if (picked == null) return;

  //   // final file = File(picked.path);
  //   // setState(() => _isUploadingImage = true);

  //   // try {
  //   //   await ref
  //   //       .read(userNotifierProvider.notifier)
  //   //       .uploadProfileImage(userId, file);
  //   //   if (mounted) {
  //   //     ScaffoldMessenger.of(
  //   //       context,
  //   //     ).showSnackBar(const SnackBar(content: Text('Profile image updated')));
  //   //   }
  //   // } catch (e) {
  //   //   if (mounted) {
  //   //     ScaffoldMessenger.of(
  //   //       context,
  //   //     ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
  //   //   }
  //   // } finally {
  //   //   if (mounted) setState(() => _isUploadingImage = false);
  //   // }
  // }

  /// Open edit modal and update name + bio in Firestore directly
  Future<void> _editProfileModal(UserModel? userModel) async {
    if (userModel == null) return;

    _nameController.text = userModel.name;
    _bioController.text = userModel.bio ?? '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Edit Profile",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: "Bio",
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSavingProfile
                      ? null
                      : () async {
                          final newName = _nameController.text.trim();
                          final newBio = _bioController.text.trim();

                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Name can't be empty"),
                              ),
                            );
                            return;
                          }

                          // show loading locally in modal
                          setState(() => _isSavingProfile = true);
                          setModalState(() {});

                          try {
                            // update Firestore directly (stream will reflect changes)
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userModel.id)
                                .update({
                                  'name': newName,
                                  'bio': newBio,
                                  'updatedAt': DateTime.now().toIso8601String(),
                                });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated'),
                                ),
                              );
                            }
                            Navigator.pop(context);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update failed: $e')),
                              );
                            }
                          } finally {
                            if (mounted)
                              setState(() => _isSavingProfile = false);
                          }
                        },
                  icon: const Icon(Icons.save),
                  label: _isSavingProfile
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Save Changes"),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 🆕 Confirm password before account deletion
  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text("Delete Account"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Please enter your password to confirm account deletion. This action cannot be undone.",
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);

                        final password = passwordController.text.trim();
                        if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Password is required")),
                          );
                          setState(() => isDeleting = false);
                          return;
                        }

                        final isCorrect = await ref
                            .read(authServiceProvider)
                            .verifyPassword(password);

                        if (!isCorrect) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Incorrect password ❌")),
                          );
                          setState(() => isDeleting = false);
                          return;
                        }

                        try {
                          await ref.read(authServiceProvider).deleteAccount();
                          if (context.mounted) {
                            Navigator.pop(ctx, true);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Deletion failed: $e")),
                          );
                          setState(() => isDeleting = false);
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Delete"),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _logout(BuildContext context) async {
  bool isLoading = false;

  await showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Logout"),
            content: isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Logging out, please wait..."),
                    ],
                  )
                : const Text("Are you sure you want to logout? 🔐"),
            actions: isLoading
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: () async {
                        setState(() => isLoading = true);

                        try {
                          await ref.read(authServiceProvider).signOut();

                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog after logout
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Logout failed: $e")),
                            );
                          }
                        }
                      },
                      child: const Text("Logout"),
                    ),
                  ],
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      // not logged in -> navigate to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final userStream = ref.watch(userStreamProvider(firebaseUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: userStream.when(
        data: (userModel) {
          // show UI using real data (fallbacks to earlier dummy values)
          final displayName = userModel?.name ?? "John Doe";
          final displayEmail = userModel?.email ?? firebaseUser.email ?? "—";
          final displayBio =
              userModel?.bio ??
              "Passionate about budgeting and building financial freedom 💸";
          // final profileImageUrl = userModel?.profileImageUrl ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // 👤 Profile Picture
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      // backgroundImage:
                      // profileImageUrl.isNotEmpty
                      //     ? NetworkImage(profileImageUrl)
                      //     : null,
                      child:
                          //  profileImageUrl.isEmpty
                          //     ?
                          Icon(
                            Icons.person,
                            size: 60,
                            color: colorScheme.primary,
                          ),
                      // : null,
                    ),
                    // Positioned(
                    //   bottom: 0,
                    //   right: 4,
                    //   child: GestureDetector(
                    //     onTap: _isUploadingImage
                    //         ? null
                    //         : () => _pickAndUploadImage(userModel!.id),
                    //     child: Container(
                    //       padding: const EdgeInsets.all(8),
                    //       decoration: BoxDecoration(
                    //         shape: BoxShape.circle,
                    //         color: colorScheme.primary,
                    //       ),
                    //       child: _isUploadingImage
                    //           ? const SizedBox(
                    //               height: 18,
                    //               width: 18,
                    //               child: CircularProgressIndicator(
                    //                 strokeWidth: 2,
                    //                 color: Colors.white,
                    //               ),
                    //             )
                    //           : const Icon(
                    //               Icons.camera_alt,
                    //               size: 20,
                    //               color: Colors.white,
                    //             ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 20),

                // name & email
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayEmail,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 20),

                // bio
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    displayBio,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.4,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Edit Profile
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: userModel == null
                      ? null
                      : () => _editProfileModal(userModel),
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Profile"),
                ),

                const SizedBox(height: 16),

                // Logout
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: Text(
                    "Logout",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🆕 Delete Account
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _confirmAndDeleteAccount(context),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Delete Account"),
                ),
              ],
            ),
          );
        },
        loading: () {
          // keep layout but show placeholders
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 48),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        },
        error: (e, st) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Failed to load profile: $e"),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    // retry by ref.refreshing the stream
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) ref.invalidate(userStreamProvider(uid));
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
