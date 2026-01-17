// // lib/screens/profile/profile_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_text_styles.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/user_provider.dart';
// import '../../widgets/common/app_text_field.dart';
// import '../../widgets/common/gradient_button.dart';
// import 'package:flutter_contacts/flutter_contacts.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   late TextEditingController nameController;
//   late TextEditingController contactNameController;
//   late TextEditingController contactPhoneController;

//   @override
//   void initState() {
//     super.initState();
//     nameController = TextEditingController();
//     contactNameController = TextEditingController();
//     contactPhoneController = TextEditingController();

//     context.read<UserProvider>().fetchProfile();
//     // Prompt for contacts permission so the Add button can open the picker
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       final granted = await FlutterContacts.requestPermission();
//       if (!granted) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content: Text(
//                     'Contacts permission is required to add emergency contacts')),
//           );
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     contactNameController.dispose();
//     contactPhoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         centerTitle: true,
//       ),
//       body: Consumer<UserProvider>(
//         builder: (context, userProvider, _) {
//           if (userProvider.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final user = userProvider.user;
//           if (user != null) {
//             nameController.text = user.name ?? '';
//           }

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Profile Header
//                 Center(
//                   child: Column(
//                     children: [
//                       Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: AppColors.surface,
//                         ),
//                         child: const Icon(
//                           Icons.person,
//                           size: 50,
//                           color: AppColors.primary,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         user?.name ?? 'User',
//                         style: AppTextStyles.headlineMedium,
//                       ),
//                       Text(
//                         user?.email ?? 'email@example.com',
//                         style: AppTextStyles.bodySmall,
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 32),

//                 // Personal Info
//                 Text('Personal Information', style: AppTextStyles.titleLarge),
//                 const SizedBox(height: 12),

//                 AppTextField(
//                   controller: nameController,
//                   label: 'Full Name',
//                   hint: 'Your name',
//                   prefixIcon: Icons.person,
//                 ),

//                 const SizedBox(height: 12),
//                 // Save updated details
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () async {
//                       final provider = context.read<UserProvider>();
//                       final success = await provider
//                           .updateProfile(nameController.text.trim());
//                       if (!mounted) return;
//                       if (success) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Profile updated')));
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                             content:
//                                 Text(provider.error ?? 'Failed to update')));
//                       }
//                     },
//                     icon: const Icon(Icons.save),
//                     label: const Text('Save'),
//                   ),
//                 ),

//                 const SizedBox(height: 16),
//                 Text(
//                   'Phone: ${user?.phone ?? 'Not provided'}',
//                   style: AppTextStyles.bodyMedium,
//                 ),

//                 const SizedBox(height: 32),

//                 // Emergency Contacts
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Emergency Contacts',
//                       style: AppTextStyles.titleLarge,
//                     ),
//                     TextButton.icon(
//                       onPressed: () async {
//                         // Request contacts permission; if granted open system picker
//                         final granted =
//                             await FlutterContacts.requestPermission();
//                         if (!mounted) return;
//                         if (!granted) {
//                           // If permission denied, allow manual entry as fallback
//                           final nameCtl = TextEditingController();
//                           final phoneCtl = TextEditingController();
//                           final manual = await showDialog<bool>(
//                             context: context,
//                             builder: (ctx) => AlertDialog(
//                               title: const Text('Add Contact Manually'),
//                               content: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   TextField(
//                                     controller: nameCtl,
//                                     decoration: const InputDecoration(
//                                         labelText: 'Name'),
//                                   ),
//                                   TextField(
//                                     controller: phoneCtl,
//                                     decoration: const InputDecoration(
//                                         labelText: 'Phone'),
//                                     keyboardType: TextInputType.phone,
//                                   ),
//                                 ],
//                               ),
//                               actions: [
//                                 TextButton(
//                                     onPressed: () => Navigator.pop(ctx, false),
//                                     child: const Text('Cancel')),
//                                 ElevatedButton(
//                                   onPressed: () => Navigator.pop(ctx, true),
//                                   child: const Text('Add'),
//                                 ),
//                               ],
//                             ),
//                           );

//                           if (!mounted) return;
//                           if (manual != true) return;

//                           final name = nameCtl.text.trim();
//                           final phone = phoneCtl.text.trim();
//                           if (name.isEmpty || phone.isEmpty) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                     content: Text(
//                                         'Please provide both name and phone')));
//                             return;
//                           }

//                           final provider = context.read<UserProvider>();
//                           final messenger = ScaffoldMessenger.of(context);
//                           final success =
//                               await provider.addContact(name, phone);
//                           if (!mounted) return;
//                           if (success) {
//                             messenger.showSnackBar(
//                                 const SnackBar(content: Text('Contact added')));
//                           } else {
//                             messenger.showSnackBar(SnackBar(
//                                 content: Text(provider.error ??
//                                     'Failed to add contact')));
//                           }
//                           return;
//                         }

//                         final picked = await FlutterContacts.openExternalPick();
//                         if (!mounted) return;
//                         if (picked == null) return;

//                         final name = picked.displayName;
//                         final phone = (picked.phones.isNotEmpty)
//                             ? picked.phones.first.number
//                             : '';

//                         if (phone.isEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                                 content: Text(
//                                     'Selected contact has no phone number')),
//                           );
//                           return;
//                         }

//                         final provider = context.read<UserProvider>();
//                         final messenger = ScaffoldMessenger.of(context);
//                         final success = await provider.addContact(name, phone);
//                         if (!mounted) return;
//                         if (success) {
//                           messenger.showSnackBar(
//                               const SnackBar(content: Text('Contact added')));
//                         } else {
//                           messenger.showSnackBar(SnackBar(
//                               content: Text(
//                                   provider.error ?? 'Failed to add contact')));
//                         }
//                       },
//                       icon: const Icon(Icons.add),
//                       label: const Text('Add'),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 12),

//                 if (userProvider.contacts.isEmpty)
//                   Center(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 24),
//                       child: Column(
//                         children: [
//                           Icon(
//                             Icons.person_add,
//                             size: 50,
//                             color: AppColors.outlineVariant,
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'No emergency contacts yet',
//                             style: AppTextStyles.bodySmall,
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 else
//                   ...userProvider.contacts.map((contact) {
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 12),
//                       child: Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: AppColors.outline),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     contact.name,
//                                     style: AppTextStyles.titleSmall,
//                                   ),
//                                   Text(
//                                     contact.phone,
//                                     style: AppTextStyles.bodySmall,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.delete,
//                                   color: AppColors.danger),
//                               onPressed: () {
//                                 userProvider.deleteContact(contact.id);
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }),

//                 const SizedBox(height: 32),

//                 // Logout Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: GradientButton(
//                     label: 'Logout',
//                     onPressed: () {
//                       showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: const Text('Logout'),
//                           content: const Text(
//                             'Are you sure you want to logout?',
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('Cancel'),
//                             ),
//                             ElevatedButton(
//                               onPressed: () {
//                                 context.read<AuthProvider>().logout();
//                                 Navigator.pushReplacementNamed(
//                                   context,
//                                   '/login',
//                                 );
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.danger,
//                               ),
//                               child: const Text('Logout'),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     gradient: AppColors.dangerGradient,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/gradient_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController nameController;
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    context.read<UserProvider>().fetchProfile();
    _loadProfileImage();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _profileImagePath = imagePath;
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', path);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _profileImagePath = pickedFile.path;
        });
        await _saveProfileImage(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.danger),
                title: const Text('Remove Picture'),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
                    _profileImage = null;
                    _profileImagePath = null;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('profile_image_path');
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickContactFromPhone() async {
    try {
      // Request permission
      final granted = await FlutterContacts.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts permission is required'),
            ),
          );
        }
        return;
      }

      // Pick contact
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      // Fetch full contact details
      final fullContact = await FlutterContacts.getContact(contact.id);
      if (fullContact == null) return;

      final name = fullContact.displayName;
      final phone =
          fullContact.phones.isNotEmpty ? fullContact.phones.first.number : '';

      if (phone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected contact has no phone number'),
            ),
          );
        }
        return;
      }

      // Add contact
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.addContact(name, phone);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact added successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userProvider.error ?? 'Failed to add contact'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading && userProvider.user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userProvider.user;
          if (user != null) {
            nameController.text = user.name ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withAlpha((0.3 * 255).round()),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 58,
                          backgroundColor: AppColors.surface,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Name and Email
                Center(
                  child: Column(
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: AppTextStyles.headlineMedium,
                      ),
                      Text(
                        user?.email ?? user?.phone ?? 'No contact info',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Personal Info
                Text('Personal Information', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),

                AppTextField(
                  controller: nameController,
                  label: 'Full Name',
                  hint: 'Your name',
                  prefixIcon: Icons.person,
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final provider = context.read<UserProvider>();
                      final success = await provider.updateProfile(
                        nameController.text.trim(),
                      );
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.error ?? 'Failed to update'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),

                const SizedBox(height: 32),

                // Emergency Contacts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Emergency Contacts',
                      style: AppTextStyles.titleLarge,
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickContactFromPhone,
                      icon: const Icon(Icons.contacts, size: 20),
                      label: const Text('Add from Phone'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (userProvider.contacts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add,
                            size: 50,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No emergency contacts yet',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...userProvider.contacts.map((contact) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.outline),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.05 * 255).round()),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withAlpha((0.1 * 255).round()),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.name,
                                    style: AppTextStyles.titleSmall,
                                  ),
                                  Text(
                                    contact.phone,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: AppColors.danger),
                              onPressed: () {
                                userProvider.deleteContact(contact.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Logout',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                context.read<AuthProvider>().logout();
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                    gradient: AppColors.dangerGradient,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
