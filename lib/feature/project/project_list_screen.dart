import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/project_model.dart';
import '../../core/database/transaction_model.dart';
import '../../core/database/category_model.dart';
import '../../core/database/account_model.dart';
import '../../core/database/auto_draft_model.dart';
import '../../core/database/template_model.dart';
import '../../core/database/tag_model.dart';
import '../../core/service/project_service.dart';
import '../../core/design_system/theme.dart';
import 'project_form_screen.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  Isar? _isar;
  bool _isLoading = true;
  Map<String, List<JiveProject>> _groupedProjects = {};
  Map<int, double> _projectSpending = {};

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);

    final isar = await _ensureIsar();
    final service = ProjectService(isar);
    final grouped = await service.getProjectsGrouped();

    final spending = <int, double>{};
    for (final projects in grouped.values) {
      for (final project in projects) {
        spending[project.id] = await service.calculateProjectSpending(project.id);
      }
    }

    if (!mounted) return;
    setState(() {
      _groupedProjects = grouped;
      _projectSpending = spending;
      _isLoading = false;
    });
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    if (Isar.getInstance() != null) {
      _isar = Isar.getInstance()!;
      return _isar!;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        JiveTransactionSchema,
        JiveCategorySchema,
        JiveCategoryOverrideSchema,
        JiveAccountSchema,
        JiveAutoDraftSchema,
        JiveTemplateSchema,
        JiveTagSchema,
        JiveProjectSchema,
      ],
      directory: dir.path,
    );
    return _isar!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目追踪'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createProject),
        ],
      ),
      backgroundColor: JiveTheme.surfaceWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedProjects.isEmpty
              ? _buildEmptyState()
              : _buildProjectList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('暂无项目', style: GoogleFonts.lato(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('创建项目追踪旅行、装修等专项支出',
              style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createProject,
            icon: const Icon(Icons.add),
            label: const Text('新建项目'),
            style: ElevatedButton.styleFrom(
              backgroundColor: JiveTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    final groups = _groupedProjects.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final projects = _groupedProjects[group]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(group,
                  style: GoogleFonts.lato(
                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            ),
            ...projects.map((p) => _buildProjectCard(p)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildProjectCard(JiveProject project) {
    final spent = _projectSpending[project.id] ?? 0;
    final progress = project.budget > 0 ? (spent / project.budget).clamp(0.0, 1.0) : 0.0;
    final remaining = project.budget > 0 ? project.budget - spent : 0.0;
    final color = project.colorHex != null
        ? Color(int.parse(project.colorHex!.replaceFirst('#', '0xFF')))
        : JiveTheme.primaryGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openProject(project),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getProjectIcon(project.iconName), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(project.name,
                        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (project.budget > 0) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(progress > 0.9 ? Colors.red : color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('已用 ¥${spent.toStringAsFixed(0)}',
                        style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade600)),
                    Text('剩余 ¥${remaining.toStringAsFixed(0)}',
                        style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: remaining < 0 ? Colors.red : Colors.grey.shade700)),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text('已支出 ¥${spent.toStringAsFixed(2)}',
                    style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProjectIcon(String? iconName) {
    switch (iconName) {
      case 'travel': return Icons.flight;
      case 'home': return Icons.home;
      case 'car': return Icons.directions_car;
      default: return Icons.folder;
    }
  }

  void _createProject() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => const ProjectFormScreen()));
    if (result == true) _loadProjects();
  }

  void _openProject(JiveProject project) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => ProjectDetailScreen(projectId: project.id)));
    if (result == true) _loadProjects();
  }
}
