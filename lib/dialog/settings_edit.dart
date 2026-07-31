import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_flow/models/user_profile_model.dart';
import 'package:habit_flow/viewmodels/habit_viewmodel.dart';
import 'package:image_picker/image_picker.dart';

void showEditProfileDialog(
    BuildContext context,
    UserProfileModel profile,
    HabitViewModel vm,
  ) {
    final controller = TextEditingController(text: profile.name);
    Uint8List? selectedImageBytes = profile.avatarData;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              title: Text(
                'Edit Profile',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFE4E1ED),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                       
                        final file = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          setState(() {
                            selectedImageBytes = bytes;
                          });
                        }
                      } catch (e) {
                        debugPrint('Failed to pick profile picture: $e');
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: selectedImageBytes != null
                              ? MemoryImage(selectedImageBytes!)
                              : (profile.avatarUrl.isNotEmpty
                                    ? NetworkImage(profile.avatarUrl)
                                          as ImageProvider
                                    : null),
                          backgroundColor: const Color(0xFF34343D),
                          child:
                              (selectedImageBytes == null &&
                                  profile.avatarUrl.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Color(0xFFC7C4D7),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF8083FF),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFC7C4D7),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF8083FF),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFC7C4D7),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newName = controller.text.trim();
                    if (newName.isNotEmpty) {
                      vm.updateProfile(
                        profile.copyWith(
                          name: newName,
                          avatarData: selectedImageBytes,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8083FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }