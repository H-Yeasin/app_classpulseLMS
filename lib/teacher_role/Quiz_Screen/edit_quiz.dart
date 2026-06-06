import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/providers/grading_provider.dart';
import 'package:opalmer_education/core/providers/teacher_provider.dart';

class EditQuizScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const EditQuizScreen({super.key, required this.sessionId});

  @override
  ConsumerState<EditQuizScreen> createState() => _EditQuizScreenState();
}

class _EditQuizScreenState extends ConsumerState<EditQuizScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<_EditableQuestion> _questions = [];
  final Set<int> _uploadingImageIndexes = {};

  bool _isLoading = true;
  String? _loadError;
  String _classLabel = 'Class';
  String _status = 'draft';

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final service = ref.read(gradingServiceProvider);
      final session = await service.getSessionDetails(widget.sessionId);
      final questions = await service.getSessionQuestions(widget.sessionId);

      for (final question in _questions) {
        question.dispose();
      }
      _questions
        ..clear()
        ..addAll(questions.map(_EditableQuestion.fromJson));

      final classInfo = session['classId'];
      final subject = classInfo is Map ? classInfo['subject'] : null;
      final grade = classInfo is Map ? classInfo['grade'] : null;

      _titleController.text = session['title']?.toString() ?? '';
      _timeController.text = (session['time'] ?? 5).toString();
      _classLabel = [
        if (subject != null && subject.toString().trim().isNotEmpty)
          subject.toString(),
        if (grade != null) 'Grade $grade',
      ].join(' - ');
      if (_classLabel.isEmpty) _classLabel = 'Class';
      _status = session['status']?.toString().toLowerCase() ?? 'draft';

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_EditableQuestion.empty());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index).dispose();
    });
  }

  Future<void> _pickQuestionImage(int index) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingImageIndexes.add(index));
    try {
      final imageUrl = await ref
          .read(gradingActionProvider.notifier)
          .uploadQuestionImage(picked.path);
      if (!mounted) return;
      setState(() {
        _questions[index].imageUrlController.text = imageUrl;
        _questions[index].type = 'image';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingImageIndexes.remove(index));
      }
    }
  }

  Future<void> _saveQuiz({required bool publish}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Please enter a quiz title');
      return;
    }

    if (_questions.isEmpty) {
      _showSnack('Please add at least one question');
      return;
    }

    final payload = <Map<String, dynamic>>[];
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final questionText = question.questionController.text.trim();
      final answer = question.answerController.text.trim();
      final options = question.optionControllers
          .map((controller) => controller.text.trim())
          .where((option) => option.isNotEmpty)
          .toList();

      if (questionText.isEmpty) {
        _showSnack('Question ${i + 1} is missing question text');
        return;
      }
      if (options.isEmpty) {
        _showSnack('Question ${i + 1} needs at least one option');
        return;
      }
      if (answer.isEmpty || !options.contains(answer)) {
        _showSnack('Question ${i + 1} answer must match one option');
        return;
      }

      payload.add({
        'question': questionText,
        'options': options,
        'answer': answer,
        'explanation': question.explanationController.text.trim(),
        'difficulty': question.difficulty,
        'type': question.type,
        'imagePrompt': question.imagePromptController.text.trim(),
        'imageUrl': question.imageUrlController.text.trim(),
      });
    }

    final success = await ref
        .read(gradingActionProvider.notifier)
        .updateExistingSession(
          sessionId: widget.sessionId,
          title: title,
          time: int.tryParse(_timeController.text.trim()),
          questions: payload,
          publish: publish,
        );

    if (!mounted) return;
    if (success) {
      ref.invalidate(teacherQuizzesProvider);
      Navigator.pop(context, true);
    } else {
      _showSnack('Failed to update quiz');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final gradingState = ref.watch(gradingActionProvider);

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
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ),
        title: const Text(
          'Edit Quiz',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: _buildBody(gradingState),
    );
  }

  Widget _buildBody(AsyncValue<void> gradingState) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadQuiz,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 116),
          children: [
            _buildInputLabel('Class'),
            const SizedBox(height: 8),
            _buildReadonlyField(_classLabel),
            const SizedBox(height: 16),
            _buildInputLabel('Quiz Title'),
            const SizedBox(height: 8),
            _buildTextField(
              hint: 'Enter Title',
              controller: _titleController,
            ),
            const SizedBox(height: 16),
            _buildInputLabel('Quiz Time (minutes)'),
            const SizedBox(height: 8),
            _buildTextField(
              hint: '00 min',
              controller: _timeController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF871DAD),
                  tooltip: 'Add question',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_questions.length, (index) {
              return _buildEditableQuestionCard(index);
            }),
          ],
        ),
        if (gradingState.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
        Positioned(
          bottom: 12,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _saveQuiz(publish: false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF871DAD),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF871DAD),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _saveQuiz(publish: _status == 'draft'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF871DAD),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _status == 'draft' ? 'PUBLISH' : 'UPDATE',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableQuestionCard(int index) {
    final question = _questions[index];
    final imageUrl = question.imageUrlController.text.trim();
    final resolvedImageUrl = ApiConstants.buildImageUrl(imageUrl);
    final isUploading = _uploadingImageIndexes.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
              IconButton(
                onPressed: _questions.length == 1
                    ? null
                    : () => _removeQuestion(index),
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
                tooltip: 'Remove question',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            hint: 'Question',
            controller: question.questionController,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: question.type,
                  items: const ['normal', 'scenario', 'image', 'challenge'],
                  onChanged: (value) => setState(() => question.type = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: question.difficulty,
                  items: const ['easy', 'medium', 'hard'],
                  onChanged: (value) {
                    setState(() => question.difficulty = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputLabel('Options'),
          const SizedBox(height: 8),
          ...List.generate(question.optionControllers.length, (optionIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      hint:
                          'Option ${String.fromCharCode(65 + optionIndex)}',
                      controller: question.optionControllers[optionIndex],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: question.optionControllers.length <= 1
                        ? null
                        : () {
                            setState(() {
                              question
                                  .optionControllers[optionIndex]
                                  .dispose();
                              question.optionControllers.removeAt(optionIndex);
                            });
                          },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.redAccent,
                    tooltip: 'Remove option',
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              setState(() {
                question.optionControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add option'),
          ),
          const SizedBox(height: 8),
          _buildInputLabel('Answer'),
          const SizedBox(height: 8),
          _buildTextField(
            hint: 'Must match one option exactly',
            controller: question.answerController,
          ),
          const SizedBox(height: 12),
          _buildInputLabel('Explanation'),
          const SizedBox(height: 8),
          _buildTextField(
            hint: 'Explanation',
            controller: question.explanationController,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildInputLabel('Question Image'),
          const SizedBox(height: 8),
          if (resolvedImageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resolvedImageUrl,
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: Colors.grey.shade100,
                  child: Text(
                    'Image preview unavailable',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          _buildTextField(
            hint: 'Image URL',
            controller: question.imageUrlController,
            suffixIcon: IconButton(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.visibility_outlined),
              color: const Color(0xFF871DAD),
              tooltip: 'Preview image',
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            hint: 'Image prompt',
            controller: question.imagePromptController,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : () => _pickQuestionImage(index),
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined),
                  label: Text(isUploading ? 'Uploading' : 'Upload image'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: imageUrl.isEmpty
                    ? null
                    : () {
                        setState(() {
                          question.imageUrlController.clear();
                          if (question.type == 'image') {
                            question.type = 'normal';
                          }
                        });
                      },
                icon: const Icon(Icons.close),
                color: Colors.redAccent,
                tooltip: 'Remove image',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildReadonlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Text(
        value,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.toUpperCase()),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _EditableQuestion {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final TextEditingController answerController;
  final TextEditingController explanationController;
  final TextEditingController imagePromptController;
  final TextEditingController imageUrlController;
  String difficulty;
  String type;

  _EditableQuestion({
    required this.questionController,
    required this.optionControllers,
    required this.answerController,
    required this.explanationController,
    required this.imagePromptController,
    required this.imageUrlController,
    required this.difficulty,
    required this.type,
  });

  factory _EditableQuestion.fromJson(dynamic raw) {
    final json = raw is Map ? raw : <String, dynamic>{};
    final options = json['options'] is List
        ? List<String>.from(
            (json['options'] as List).map((option) => option.toString()),
          )
        : <String>[];

    return _EditableQuestion(
      questionController: TextEditingController(
        text: json['question']?.toString() ?? '',
      ),
      optionControllers: (options.isEmpty ? ['', '', '', ''] : options)
          .map((option) => TextEditingController(text: option))
          .toList(),
      answerController: TextEditingController(
        text: json['answer']?.toString() ?? '',
      ),
      explanationController: TextEditingController(
        text: json['explanation']?.toString() ?? '',
      ),
      imagePromptController: TextEditingController(
        text: json['imagePrompt']?.toString() ?? '',
      ),
      imageUrlController: TextEditingController(
        text: json['imageUrl']?.toString() ?? '',
      ),
      difficulty: json['difficulty']?.toString() ?? 'medium',
      type: json['type']?.toString() ?? 'normal',
    );
  }

  factory _EditableQuestion.empty() {
    return _EditableQuestion(
      questionController: TextEditingController(),
      optionControllers: List.generate(4, (_) => TextEditingController()),
      answerController: TextEditingController(),
      explanationController: TextEditingController(),
      imagePromptController: TextEditingController(),
      imageUrlController: TextEditingController(),
      difficulty: 'medium',
      type: 'normal',
    );
  }

  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
    answerController.dispose();
    explanationController.dispose();
    imagePromptController.dispose();
    imageUrlController.dispose();
  }
}
