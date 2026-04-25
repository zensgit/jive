import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import '../../core/database/book_model.dart';
import '../../core/service/book_service.dart';
import '../../core/service/object_share_policy_service.dart';
import 'book_stats_screen.dart';

/// 多账本管理屏幕
class BookManagerScreen extends StatefulWidget {
  const BookManagerScreen({super.key});

  @override
  State<BookManagerScreen> createState() => _BookManagerScreenState();
}

class _BookManagerScreenState extends State<BookManagerScreen> {
  late final Isar _isar;
  List<JiveBook> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _isar = Isar.getInstance()!;
    await _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await BookService(_isar).getAllBooks();
    if (mounted) {
      setState(() {
        _books = books;
        _isLoading = false;
      });
    }
  }

  Future<void> _createBook() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建账本'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入账本名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (result == null || result.isEmpty) return;

    await BookService(_isar).createBook(name: result);
    await _loadBooks();
  }

  Future<void> _setDefault(JiveBook book) async {
    await BookService(_isar).setDefaultBook(book.id);
    await _loadBooks();
  }

  Future<void> _archiveBook(JiveBook book) async {
    if (book.isDefault) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('不能归档默认账本')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('归档账本'),
        content: Text('确定要归档"${book.name}"吗？归档后不会删除数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('归档'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await BookService(_isar).archiveBook(book.id);
    await _loadBooks();
  }

  Future<void> _editBook(JiveBook book) async {
    final nameController = TextEditingController(text: book.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑账本'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入账本名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (result == null || result.isEmpty) return;

    book.name = result;
    await BookService(_isar).updateBook(book);
    await _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账本管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: '账本统计',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookStatsScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _createBook),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? const Center(child: Text('暂无账本'))
          : ListView.builder(
              itemCount: _books.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => _buildBookTile(_books[index]),
            ),
    );
  }

  Widget _buildBookTile(JiveBook book) {
    final isDefault = book.isDefault;
    final sharePolicy = const ObjectSharePolicyService().evaluate(
      book: book,
      objectLabel: '场景',
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDefault
              ? const Color(0xFF2E7D32)
              : Colors.grey.shade300,
          child: Icon(
            Icons.book,
            color: isDefault ? Colors.white : Colors.grey.shade600,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                book.name,
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '默认',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (book.isArchived) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '已归档',
                  style: GoogleFonts.lato(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
            if (sharePolicy.visibility != ObjectShareVisibility.private) ...[
              const SizedBox(width: 8),
              _buildShareBadge(sharePolicy.label),
            ],
          ],
        ),
        subtitle: Text(
          '${book.currency} • 创建于 ${book.createdAt.toString().substring(0, 10)}',
          style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (ctx) => [
            if (!isDefault)
              const PopupMenuItem(value: 'default', child: Text('设为默认')),
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            if (!isDefault && !book.isArchived)
              const PopupMenuItem(value: 'archive', child: Text('归档')),
          ],
          onSelected: (action) {
            switch (action) {
              case 'default':
                _setDefault(book);
                break;
              case 'edit':
                _editBook(book);
                break;
              case 'archive':
                _archiveBook(book);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildShareBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 11,
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
