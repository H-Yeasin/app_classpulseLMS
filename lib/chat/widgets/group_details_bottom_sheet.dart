import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GroupDetailsBottomSheet extends StatefulWidget {
  const GroupDetailsBottomSheet({super.key});

  @override
  State<GroupDetailsBottomSheet> createState() =>
      _GroupDetailsBottomSheetState();

  static Future<GroupDetailsResult?> show(BuildContext context) {
    return showModalBottomSheet<GroupDetailsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GroupDetailsBottomSheet(),
    );
  }
}

class GroupDetailsResult {
  final String name;
  final File? avatar;

  GroupDetailsResult({required this.name, this.avatar});
}

class _GroupDetailsBottomSheetState extends State<GroupDetailsBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isNameEmpty = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        _isNameEmpty = _nameController.text.trim().isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Ignore errors for now
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'New Group',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  _selectedImage != null ? FileImage(_selectedImage!) : null,
              child: _selectedImage == null
                  ? const Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Colors.grey,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set Group Image',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Group Subject',
              filled: true,
              fillColor: const Color(0xFFF1F0F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isNameEmpty
                  ? null
                  : () {
                      Navigator.pop(
                        context,
                        GroupDetailsResult(
                          name: _nameController.text.trim(),
                          avatar: _selectedImage,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF871DAD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'CREATE GROUP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
