import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/teacher_class_model.dart';
import '../../core/providers/teacher_provider.dart';
import '../../core/providers/auth_provider.dart';
import 'assign_students_screen.dart';

class AddClassScreen extends ConsumerStatefulWidget {
  final TeacherClassModel? classToEdit;

  const AddClassScreen({Key? key, this.classToEdit}) : super(key: key);

  @override
  ConsumerState<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends ConsumerState<AddClassScreen> {
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  int? _selectedGrade;
  final Set<String> _selectedDays = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  final List<int> _grades = List.generate(12, (index) => index + 1);
  final List<String> _weekDays = const [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  bool get _isEditing => widget.classToEdit != null;

  @override
  void initState() {
    super.initState();

    final classToEdit = widget.classToEdit;
    if (classToEdit == null) return;

    _classNameController.text = classToEdit.subject;
    _sectionController.text = classToEdit.section ?? '';
    _selectedGrade = classToEdit.grade;
    _hydrateSchedule(classToEdit.schedule);
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    final className = _classNameController.text.trim();
    final section = _sectionController.text.trim();

    if (className.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class name')),
      );
      return;
    }

    if (_selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a grade')),
      );
      return;
    }

    if (_selectedDays.isEmpty || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose days and time')),
      );
      return;
    }

    if (_timeToMinutes(_endTime!) <= _timeToMinutes(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider);
      final apiClient = ref.read(apiClientProvider);

      if (user == null) throw Exception('User not logged in');

      final payload = {
        if (!_isEditing) 'teacherId': user.id,
        'grade': _selectedGrade,
        'subject': className,
        if (_isEditing || section.isNotEmpty) 'section': section,
        'schedule': _scheduleText,
      };

      final response = _isEditing
          ? await apiClient.put(
              '/classes/${widget.classToEdit!.id}',
              data: payload,
            )
          : await apiClient.post('/classes', data: payload);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          final savedClass = TeacherClassModel.fromJson(response.data['data']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Class updated successfully!'
                    : 'Class added successfully!',
              ),
            ),
          );
          // Refresh the classes list
          ref.invalidate(teacherClassesProvider);
          if (_isEditing) {
            Navigator.pop(context, savedClass);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AssignStudentsScreen(classData: savedClass),
              ),
            );
          }
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to save class');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        title: Text(
          _isEditing ? "Edit Class" : "Add Class",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildLabel("Class Name"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _classNameController,
                  hintText: 'Enter class name',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                _buildLabel("Grade"),
                const SizedBox(height: 8),
                _buildDropdown<int>(
                  value: _selectedGrade,
                  hintText: 'Select grade',
                  items: _grades
                      .map(
                        (grade) => DropdownMenuItem<int>(
                          value: grade,
                          child: Text('Grade $grade'),
                        ),
                      )
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGrade = newValue;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildLabel("Section"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _sectionController,
                  hintText: 'Example: A',
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                _buildLabel("Schedule"),
                const SizedBox(height: 12),
                _buildDaySelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeButton(
                        label: 'Start time',
                        value: _startTime,
                        onTap: () => _pickTime(isStartTime: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeButton(
                        label: 'End time',
                        value: _endTime,
                        onTap: () => _pickTime(isStartTime: false),
                      ),
                    ),
                  ],
                ),
                if (_scheduleText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _scheduleText,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveClass,
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
                        : Text(
                            _isEditing ? "UPDATE" : "ADD",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF444444),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF871DAD)),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hintText,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hintText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade600,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _weekDays.map((day) {
        final isSelected = _selectedDays.contains(day);

        return ChoiceChip(
          label: Text(day),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          selectedColor: const Color(0xFF871DAD),
          backgroundColor: const Color(0xFFF3F4F6),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF444444),
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF871DAD)
                  : const Color(0xFFF3F4F6),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 20,
              color: Color(0xFF871DAD),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? label : value.format(context),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: value == null
                      ? Colors.grey.shade600
                      : const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isStartTime}) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? _startTime ?? TimeOfDay.now()),
    );

    if (selectedTime == null) return;

    setState(() {
      if (isStartTime) {
        _startTime = selectedTime;
      } else {
        _endTime = selectedTime;
      }
    });
  }

  String get _scheduleText {
    if (_selectedDays.isEmpty || _startTime == null || _endTime == null) {
      return '';
    }

    final orderedDays = _weekDays
        .where((day) => _selectedDays.contains(day))
        .join('/');

    return '$orderedDays ${_startTime!.format(context)} - ${_endTime!.format(context)}';
  }

  int _timeToMinutes(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }

  void _hydrateSchedule(String? schedule) {
    if (schedule == null || schedule.trim().isEmpty) return;

    final match = RegExp(r'^(.+?)\s+(.+?)\s*-\s*(.+)$').firstMatch(schedule);
    if (match == null) return;

    final days = match.group(1)?.split('/') ?? [];
    _selectedDays
      ..clear()
      ..addAll(days.where(_weekDays.contains));
    _startTime = _parseTimeOfDay(match.group(2));
    _endTime = _parseTimeOfDay(match.group(3));
  }

  TimeOfDay? _parseTimeOfDay(String? rawValue) {
    if (rawValue == null) return null;

    final value = rawValue.trim().toUpperCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(value);
    if (match == null) return null;

    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final period = match.group(3);

    if (hour == null || minute == null) return null;
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }
}

