import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/supabase_service.dart';
import '../dashboard/task_model.dart';
import '../dashboard/task_tile.dart';
import '../project/project_model.dart';
import '../project/project_task_model.dart';
import '../project/project_detail_screen.dart';
import '../project/create_project_screen.dart';
import '../project/edit_project_screen.dart';
import '../utils/date_formatter.dart';
import '../auth/profile_model.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _taskController = TextEditingController();
  bool _isLoading = false;
  Profile? _userProfile;
  List<Project> _projects = [];
  Map<String, List<ProjectTask>> _projectTasks = {};

  @override
  void initState() {
    super.initState();
    // Ensure the user has a profile and redirect if not logged in
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final supabaseService = context.read<SupabaseService>();
      final user = supabaseService.currentUser;

      if (user == null) {
        // Redirect to login if not logged in
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
      }

      await supabaseService.ensureCurrentUserHasProfile();
      _loadUserProfile();
      _loadProjects();
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final supabaseService = context.read<SupabaseService>();
      final user = supabaseService.currentUser;
      if (user == null) return;

      final profile = await supabaseService.getUserProfile(user.id);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      // Handle error quietly
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final supabaseService = context.read<SupabaseService>();
      final user = supabaseService.currentUser;
      if (user == null) return;

      final projects = await supabaseService.getProjects(user.id);

      final projectTasks = <String, List<ProjectTask>>{};
      for (final project in projects) {
        projectTasks[project.id] =
            await supabaseService.getProjectTasks(project.id);
      }

      if (mounted) {
        setState(() {
          _projects = projects;
          _projectTasks = projectTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final supabaseService = context.read<SupabaseService>();
      final user = supabaseService.currentUser;
      if (user == null) return;

      await supabaseService.addTask(
        Task(
          id: const Uuid().v4(),
          title: _taskController.text.trim(),
          isCompleted: false,
          userId: user.id,
          createdAt: DateTime.now(),
        ),
      );
      _taskController.clear();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToCreateProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
    );

    if (result == true && mounted) {
      _loadProjects();
    }
  }

  void _navigateToProjectDetail(Project project) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(
          projectId: project.id,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadProjects();
    }
  }

  void _navigateToEditProject(Project project) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjectScreen(project: project),
      ),
    );

    if (result == true && mounted) {
      _loadProjects();
    }
  }

  Future<void> _showAddTaskDialog() async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskController,
                decoration: const InputDecoration(
                  labelText: 'New Task',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _addTask,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Add Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method to refresh tasks
  Future<void> _refreshTasks() async {
    if (mounted) {
      setState(
          () {}); // This will trigger a rebuild of the FutureBuilder for tasks
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabaseService = context.watch<SupabaseService>();
    final user = supabaseService.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          // Profile icon button
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabaseService.logout();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadProjects();
                await _loadUserProfile();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back!',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userProfile?.username ??
                                    user.email?.split('@')[0] ??
                                    'User',
                                style: theme.textTheme.headlineMedium,
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.lightBlue[100],
                          backgroundImage: _userProfile?.avatarUrl != null
                              ? NetworkImage(_userProfile!.avatarUrl!)
                              : null,
                          child: _userProfile?.avatarUrl == null
                              ? Text(
                                  _userProfile?.username.isNotEmpty == true
                                      ? _userProfile!.username[0].toUpperCase()
                                      : user.email?[0].toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),

                  // Projects section title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Projects',
                        style: theme.textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: _navigateToCreateProject,
                        child: const Text('Add New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Projects list
                  if (_projects.isEmpty)
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'No projects yet',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _navigateToCreateProject,
                              child: const Text('Create Project'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 220, // Fixed height for the horizontal list
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          final tasks = _projectTasks[project.id] ?? [];
                          final progress = project.getProgress(tasks);
                          final progressPercent = (progress * 100).round();

                          return GestureDetector(
                            onTap: () => _navigateToProjectDetail(project),
                            onLongPress: () => _navigateToEditProject(project),
                            child: Container(
                              width: 250,
                              margin: const EdgeInsets.only(right: 16),
                              child: Card(
                                color: Colors.grey[800],
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              project.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () =>
                                                _navigateToEditProject(project),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        project.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                          'Due: ${formatDate(project.dueDate)}'),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${tasks.where((t) => t.isCompleted).length}/${tasks.length} tasks',
                                          ),
                                          Text('$progressPercent%'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Progress bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.grey[700],
                                          color: progress == 1.0
                                              ? Colors.green
                                              : Colors.amber,
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Tasks section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Tasks',
                        style: theme.textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: _showAddTaskDialog,
                        child: const Text('Add New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tasks list
                  FutureBuilder<List<Task>>(
                    future: supabaseService.getTasks(user.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !_isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        );
                      }

                      final tasks = snapshot.data ?? [];

                      if (tasks.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'No tasks yet',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _showAddTaskDialog,
                                  child: const Text('Add Task'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: tasks
                            .map((task) => TaskTile(
                                  task: task,
                                  onTaskUpdated: _refreshTasks,
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
