import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../utils/task_date_utils.dart';

class AddTaskScreen extends StatefulWidget {
  final TaskService taskService;
  final TaskModel? task; // If editing an existing task

  const AddTaskScreen({
    super.key,
    required this.taskService,
    this.task,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TaskCategory _selectedCategory = TaskCategory.homework;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime _selectedDate = TaskDateUtils.todayDateOnly();
  // Default to 1 hour from now so a 5-minute reminder is never immediately
  // in the past when the user saves without changing the time.
  TimeOfDay _selectedTime = _defaultTaskTime();
  int? _reminderMinutes = 5;

  static TimeOfDay _defaultTaskTime() {
    final later = DateTime.now().add(const Duration(hours: 1));
    return TimeOfDay(hour: later.hour, minute: 0);
  }
  List<String> _tags = [];
  bool _isLoading = false;

  final List<String> _predefinedTags = [
    'Important', 'Fun', 'Quick', 'Hard', 'Easy', 'Creative', 'Study', 'Play'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _initializeWithExistingTask();
    }
  }

  void _initializeWithExistingTask() {
    final task = widget.task!;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _selectedCategory = task.category;
    _selectedPriority = task.priority;
    final localDue = TaskDateUtils.toLocalDateTime(task.dueDate);
    _selectedDate = TaskDateUtils.dateOnly(localDue);
    _selectedTime = TimeOfDay.fromDateTime(localDue);
    _reminderMinutes = task.reminderMinutes;
    _tags = List.from(task.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8D0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskTitleField(),
                      const SizedBox(height: 20),
                      _buildTaskDescriptionField(),
                      const SizedBox(height: 20),
                      _buildCategorySelector(),
                      const SizedBox(height: 20),
                      _buildPrioritySelector(),
                      const SizedBox(height: 20),
                      _buildDateTimeSelector(),
                      const SizedBox(height: 20),
                      _buildReminderSelector(),
                      const SizedBox(height: 20),
                      _buildTagsSelector(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9A826), Color(0xFFFF8C00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task != null ? 'Edit Task' : 'Add New Task',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Fill in the details below 📝',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Title *',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'What do you need to do?',
            prefixIcon: const Icon(Icons.task_alt, color: Color(0xFFF9A826)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a task title';
            }
            return null;
          },
          style: GoogleFonts.roboto(),
        ),
      ],
    );
  }

  Widget _buildTaskDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add more details about your task...',
            prefixIcon: const Icon(Icons.description, color: Color(0xFFF9A826)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: GoogleFonts.roboto(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TaskCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF9A826) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF9A826) : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFFF9A826),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getCategoryLabel(category),
                      style: GoogleFonts.roboto(
                        color: isSelected ? Colors.white : const Color(0xFF2D3748),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority *',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: TaskPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPriority = priority;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _getPriorityColor(priority) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _getPriorityColor(priority) : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getPriorityIcon(priority),
                          color: isSelected ? Colors.white : _getPriorityColor(priority),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPriorityLabel(priority),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: isSelected ? Colors.white : _getPriorityColor(priority),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date & Time *',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFFF9A826)),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: GoogleFonts.roboto(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFF9A826)),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: GoogleFonts.roboto(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReminderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildReminderChip('No reminder', null),
            _buildReminderChip('5 minutes before', 5),
            _buildReminderChip('15 minutes before', 15),
            _buildReminderChip('30 minutes before', 30),
            _buildReminderChip('1 hour before', 60),
            _buildReminderChip('1 day before', 1440),
          ],
        ),
      ],
    );
  }

  Widget _buildReminderChip(String label, int? minutes) {
    final isSelected = _reminderMinutes == minutes;
    return GestureDetector(
      onTap: () {
        setState(() {
          _reminderMinutes = minutes;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9A826) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF9A826) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: isSelected ? Colors.white : const Color(0xFF2D3748),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _predefinedTags.map((tag) {
            final isSelected = _tags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _tags.remove(tag);
                  } else {
                    _tags.add(tag);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: isSelected ? Colors.blue[800] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF9A826),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.task != null ? 'Update Task' : 'Create Task',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: TaskDateUtils.todayDateOnly(),
      lastDate: TaskDateUtils.todayDateOnly().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dueDateTime = TaskDateUtils.combineDateAndTime(
        _selectedDate,
        _selectedTime,
      );

      // Guard: if a reminder is set, make sure the trigger time is still in
      // the future. Without this check, the alarm is silently skipped while
      // the user believes it was scheduled.
      if (_reminderMinutes != null && _reminderMinutes! > 0) {
        final reminderTrigger =
            dueDateTime.subtract(Duration(minutes: _reminderMinutes!));
        if (!reminderTrigger.isAfter(DateTime.now())) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'The reminder time has already passed. '
                  'Please set a later due date/time or choose a shorter reminder.',
                  style: GoogleFonts.roboto(),
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      if (widget.task != null) {
        // Update existing task
        await widget.taskService.updateTask(
          taskId: widget.task!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          dueDate: dueDateTime,
          priority: _selectedPriority,
          reminderMinutes: _reminderMinutes,
          syncReminder: true,
          tags: _tags,
        );
      } else {
        // Create new task
        await widget.taskService.addTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          dueDate: dueDateTime,
          priority: _selectedPriority,
          reminderMinutes: _reminderMinutes,
          tags: _tags,
        );
      }

      setState(() => _isLoading = false);

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task != null
                  ? 'Task updated successfully!'
                  : 'Task created successfully!',
              style: GoogleFonts.roboto(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: $e', style: GoogleFonts.roboto()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods
  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.homework:
        return Icons.school;
      case TaskCategory.chores:
        return Icons.cleaning_services;
      case TaskCategory.reading:
        return Icons.menu_book;
      case TaskCategory.exercise:
        return Icons.fitness_center;
      case TaskCategory.creativity:
        return Icons.palette;
      case TaskCategory.learning:
        return Icons.lightbulb;
      case TaskCategory.family:
        return Icons.family_restroom;
      case TaskCategory.other:
        return Icons.more_horiz;
    }
  }

  String _getCategoryLabel(TaskCategory category) {
    switch (category) {
      case TaskCategory.homework:
        return 'Homework';
      case TaskCategory.chores:
        return 'Chores';
      case TaskCategory.reading:
        return 'Reading';
      case TaskCategory.exercise:
        return 'Exercise';
      case TaskCategory.creativity:
        return 'Creativity';
      case TaskCategory.learning:
        return 'Learning';
      case TaskCategory.family:
        return 'Family';
      case TaskCategory.other:
        return 'Other';
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }
} 