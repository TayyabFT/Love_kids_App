import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/task_service.dart';
import '../utils/task_date_utils.dart';
import '../widgets/task_widgets.dart';
import 'add_task_screen.dart';

class TaskManagement extends StatefulWidget {
  const TaskManagement({super.key});

  @override
  State<TaskManagement> createState() => _TaskManagementState();
}

class _TaskManagementState extends State<TaskManagement> 
    with TickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  
  late TabController _tabController;
  TaskStats? _stats;
  bool _isLoading = true;
  
  final TaskCategory _selectedCategory = TaskCategory.homework;
  TaskFilter _currentFilter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _taskService.initializeNotifications(); // also initialized in main()
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadStats() async {
    final stats = await _taskService.getTaskStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8D0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading && _stats == null)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              if (_stats != null) _buildStatsCards(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(),
                    _buildCategoriesView(),
                    _buildRewardsView(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: const Color(0xFFF9A826),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Task',
          style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.w600),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Task Manager',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Stay organized and earn rewards! 🌟',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_stats?.totalRewards ?? 0}',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) {
      return const SizedBox.shrink(); // Return empty widget if stats not loaded
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Completed',
              '${_stats!.completedTasks}',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              '${_stats!.pendingTasks}',
              Icons.pending,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Streak',
              '${_stats!.currentStreak}d',
              Icons.local_fire_department,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFF9A826),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFFF9A826),
        labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.list), text: 'Tasks'),
          Tab(icon: Icon(Icons.category), text: 'Categories'),
          Tab(icon: Icon(Icons.emoji_events), text: 'Rewards'),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getUserTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final tasks = _filterTasks(snapshot.data!);

        return Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(
                    task: tasks[index],
                    onToggle: () => _toggleTask(tasks[index]),
                    onEdit: () => _editTask(tasks[index]),
                    onDelete: () => _deleteTask(tasks[index].id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TaskFilter.values.map((filter) {
            final isSelected = _currentFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  _getFilterLabel(filter),
                  style: GoogleFonts.roboto(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _currentFilter = filter;
                  });
                },
                backgroundColor: Colors.grey[100],
                selectedColor: const Color(0xFFF9A826),
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getFilterLabel(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.pending:
        return 'Pending';
      case TaskFilter.completed:
        return 'Completed';
      case TaskFilter.overdue:
        return 'Overdue';
      case TaskFilter.today:
        return 'Today';
    }
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    switch (_currentFilter) {
      case TaskFilter.all:
        return tasks;
      case TaskFilter.pending:
        return tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.completed:
        return tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.overdue:
        return tasks
            .where((task) => 
                !task.isCompleted && task.dueDate.isBefore(DateTime.now()))
            .toList();
      case TaskFilter.today:
        return tasks
            .where((task) => TaskDateUtils.isToday(task.dueDate))
            .toList();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet!',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first task',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Categories',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: TaskCategory.values.length,
              itemBuilder: (context, index) {
                final category = TaskCategory.values[index];
                return CategoryCard(
                  category: category,
                  onTap: () => _viewCategoryTasks(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsView() {
    if (_stats == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRewardsSummary(),
          const SizedBox(height: 24),
          _buildAchievements(),
          const SizedBox(height: 24),
          _buildMotivationalQuotes(),
        ],
      ),
    );
  }

  Widget _buildRewardsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Total Rewards',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${_stats?.totalRewards ?? 0} Stars',
            style: GoogleFonts.roboto(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep completing tasks to earn more rewards!',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    if (_stats == null) {
      return const SizedBox.shrink();
    }
    
    final achievements = [
      Achievement('First Task', 'Complete your first task', Icons.start, _stats!.completedTasks >= 1),
      Achievement('Task Master', 'Complete 10 tasks', Icons.workspace_premium, _stats!.completedTasks >= 10),
      Achievement('Streak Starter', 'Maintain a 3-day streak', Icons.local_fire_department, _stats!.currentStreak >= 3),
      Achievement('Consistent', 'Maintain a 7-day streak', Icons.stars, _stats!.currentStreak >= 7),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        ...achievements.map((achievement) => AchievementCard(achievement: achievement)),
      ],
    );
  }

  Widget _buildMotivationalQuotes() {
    final quotes = [
      "Great job! You're building amazing habits! 🌟",
      "Every completed task is a step toward success! 🚀",
      "You're doing fantastic! Keep up the great work! 💪",
      "Organization leads to success! You're on the right track! ✨",
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.format_quote, color: Colors.blue, size: 32),
          const SizedBox(height: 8),
          Text(
            quotes[DateTime.now().day % quotes.length],
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.blue[800],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(taskService: _taskService),
      ),
    ).then((_) => _loadStats());
  }

  void _toggleTask(TaskModel task) async {
    await _taskService.updateTask(
      taskId: task.id,
      isCompleted: !task.isCompleted,
    );
    _loadStats();
    
    if (!task.isCompleted) {
      _showCompletionCelebration();
    }
  }

  void _editTask(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          taskService: _taskService,
          task: task,
        ),
      ),
    ).then((_) => _loadStats());
  }

  void _deleteTask(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task', style: GoogleFonts.roboto()),
        content: Text('Are you sure you want to delete this task?', style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.roboto()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.roboto(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _taskService.deleteTask(taskId);
      _loadStats();
    }
  }

  void _viewCategoryTasks(TaskCategory category) {
    // Implementation for viewing tasks by category
  }

  void _showCompletionCelebration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Congratulations!',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You completed a task and earned 10 stars! 🌟',
              style: GoogleFonts.roboto(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Awesome!', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }
}

// Enums and Models
enum TaskFilter { all, pending, completed, overdue, today }

// Additional UI Components will be in separate files for better organization