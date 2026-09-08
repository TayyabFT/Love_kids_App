import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/task_service.dart';
import '../utils/task_date_utils.dart';

// Task Card Widget
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());
    final dueToday = TaskDateUtils.isToday(task.dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue 
              ? Colors.red.withValues(alpha: 0.3)
              : dueToday 
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? Colors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: task.isCompleted ? Colors.green : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // Task Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Priority
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: task.isCompleted
                                    ? Colors.grey[400]
                                    : const Color(0xFF2D3748),
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getPriorityLabel(task.priority),
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getPriorityColor(task.priority),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: task.isCompleted ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),
                      
                      // Category and Due Date
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(task.category),
                            size: 16,
                            color: const Color(0xFFF9A826),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getCategoryLabel(task.category),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color(0xFFF9A826),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isOverdue 
                                ? Colors.red 
                                : dueToday 
                                    ? Colors.orange 
                                    : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TaskDateUtils.formatDueDate(task.dueDate),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: isOverdue 
                                  ? Colors.red 
                                  : dueToday 
                                      ? Colors.orange 
                                      : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Tags
                      if (task.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: task.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action Buttons
                if (!task.isCompleted) ...[
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Reward badge for completed tasks
          if (task.isCompleted && task.rewards > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Earned ${task.rewards} stars! 🌟',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

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
}

// Category Card Widget
class CategoryCard extends StatelessWidget {
  final TaskCategory category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  size: 32,
                  color: _getCategoryColor(category),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getCategoryLabel(category),
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _getCategoryDescription(category),
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  String _getCategoryDescription(TaskCategory category) {
    switch (category) {
      case TaskCategory.homework:
        return 'School assignments';
      case TaskCategory.chores:
        return 'House tasks';
      case TaskCategory.reading:
        return 'Reading time';
      case TaskCategory.exercise:
        return 'Physical activity';
      case TaskCategory.creativity:
        return 'Art & crafts';
      case TaskCategory.learning:
        return 'Study & learn';
      case TaskCategory.family:
        return 'Family time';
      case TaskCategory.other:
        return 'Other tasks';
    }
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.homework:
        return Colors.blue;
      case TaskCategory.chores:
        return Colors.green;
      case TaskCategory.reading:
        return Colors.purple;
      case TaskCategory.exercise:
        return Colors.red;
      case TaskCategory.creativity:
        return Colors.pink;
      case TaskCategory.learning:
        return Colors.orange;
      case TaskCategory.family:
        return Colors.teal;
      case TaskCategory.other:
        return Colors.grey;
    }
  }
}

// Achievement Card Widget
class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.isUnlocked ? Colors.green[200]! : Colors.grey[200]!,
        ),
        boxShadow: achievement.isUnlocked
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement.isUnlocked 
                  ? Colors.green[100] 
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievement.icon,
              size: 24,
              color: achievement.isUnlocked 
                  ? Colors.green 
                  : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievement.title,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: achievement.isUnlocked 
                            ? const Color(0xFF2D3748)
                            : Colors.grey[600],
                      ),
                    ),
                    if (achievement.isUnlocked) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: achievement.isUnlocked 
                        ? Colors.grey[600]
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (achievement.isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Unlocked!',
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Achievement model (if not already defined elsewhere)
class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  Achievement(this.title, this.description, this.icon, this.isUnlocked);
} 