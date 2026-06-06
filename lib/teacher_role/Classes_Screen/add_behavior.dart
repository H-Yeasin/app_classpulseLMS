import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/teacher_provider.dart';

class AddBehaviorScreen extends ConsumerStatefulWidget {
  final String studentId;
  final Map<String, dynamic>? student;
  final String? behaviorId;
  final String? initialMessage;
  final String? initialState;

  const AddBehaviorScreen({
    super.key,
    required this.studentId,
    this.student,
    this.behaviorId,
    this.initialMessage,
    this.initialState,
  }) : super();

  @override
  ConsumerState<AddBehaviorScreen> createState() => _AddBehaviorScreenState();
}

class _AddBehaviorScreenState extends ConsumerState<AddBehaviorScreen> {
  late final TextEditingController _messageController;
  late String _selectedState;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messageController =
        TextEditingController(text: widget.initialMessage ?? '');
    _selectedState = widget.initialState ?? "positive";
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a message")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      "studentId": widget.studentId,
      "message": _messageController.text,
      "state": _selectedState,
    };

    final isEditing = widget.behaviorId != null;

    try {
      final bool success;
      if (isEditing) {
        success = await ref.read(updateBehaviorProvider({
          "behaviorId": widget.behaviorId,
          "data": {
            "studentId": widget.studentId,
            "message": _messageController.text,
            "state": _selectedState,
          }
        }).future);
      } else {
        success = await ref.read(createBehaviorProvider(data).future);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing
                  ? "Behavior log updated successfully"
                  : "Behavior log added successfully"),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing
                  ? "Failed to update behavior log"
                  : "Failed to add behavior log"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF871DAD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          "Add Behavior Log",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Message",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Enter behavior message",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Student Behavior",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedState,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: "positive",
                        child: Text("Positive"),
                      ),
                      DropdownMenuItem(
                        value: "negative",
                        child: Text("Negative"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedState = val);
                    },
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF871DAD),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "ADD",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
