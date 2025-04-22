import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';
import 'project_model.dart';
import 'project_task_model.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool _isLoading = false;
  List<Project> _projects = [];
  Map<String, List<ProjectTask>> _projectTasks = {};

  @override
  void initState() {
    super.initState();
    _loadProjects();
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SupabaseService>().currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view projects'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProjects,
              child: _projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No projects yet',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _navigateToCreateProject,
                            child: const Text('Create Project'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
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
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email?.split('@')[0] ?? 'User',
                                      style: theme.textTheme.headlineMedium,
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.lightBlue[100],
                                child: Text(
                                  user.email?[0].toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Completed Projects section
                        _buildProjectSection(
                          'Completed Projects',
                          _projects.where((p) {
                            final tasks = _projectTasks[p.id] ?? [];
                            return tasks.isNotEmpty &&
                                tasks.every((task) => task.isCompleted);
                          }).toList(),
                        ),

                        // Ongoing Projects section
                        _buildProjectSection(
                          'Ongoing Projects',
                          _projects.where((p) {
                            final tasks = _projectTasks[p.id] ?? [];
                            return tasks.isEmpty ||
                                !tasks.every((task) => task.isCompleted);
                          }).toList(),
                        ),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateProject,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProjectSection(String title, List<Project> projects) {
    if (projects.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                // TODO: View all projects of this category
              },
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...projects.map((project) => _buildProjectCard(project)).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProjectCard(Project project) {
    final tasks = _projectTasks[project.id] ?? [];
    final progress = project.getProgress(tasks);
    final progressPercent = (progress * 100).round();

    return GestureDetector(
      onTap: () => _navigateToProjectDetail(project),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.grey[800],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Team members'),
                  const SizedBox(width: 16),
                  // This would be replaced with actual team member avatars
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.amber,
                    child: Text(
                      'U',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    tasks.isEmpty
                        ? 'No tasks'
                        : tasks.where((t) => t.isCompleted).length ==
                                tasks.length
                            ? 'Completed'
                            : 'Completed',
                  ),
                  const Spacer(),
                  Text('$progressPercent%'),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: tasks.isNotEmpty &&
                                tasks.every((t) => t.isCompleted)
                            ? Colors.green
                            : Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Due on: ${formatDate(project.dueDate)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
