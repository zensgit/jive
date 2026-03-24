import 'package:isar/isar.dart';

import '../database/book_model.dart';

/// 多账本服务
class BookService {
  final Isar _isar;

  BookService(this._isar);

  static const defaultBookKey = 'book_default';

  /// 初始化默认账本
  Future<void> initDefaultBook() async {
    final existing = await _isar.jiveBooks
        .where()
        .keyEqualTo(defaultBookKey)
        .findFirst();
    if (existing != null) return;

    final now = DateTime.now();
    final book = JiveBook()
      ..key = defaultBookKey
      ..name = '默认账本'
      ..iconName = 'book'
      ..currency = 'CNY'
      ..order = 0
      ..isDefault = true
      ..isArchived = false
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveBooks.put(book);
    });
  }

  /// 获取默认账本
  Future<JiveBook?> getDefaultBook() async {
    return _isar.jiveBooks
        .where()
        .filter()
        .isDefaultEqualTo(true)
        .findFirst();
  }

  /// 获取所有账本（非归档）
  Future<List<JiveBook>> getActiveBooks() async {
    return _isar.jiveBooks
        .where()
        .filter()
        .isArchivedEqualTo(false)
        .sortByOrder()
        .findAll();
  }

  /// 获取所有账本
  Future<List<JiveBook>> getAllBooks() async {
    return _isar.jiveBooks.where().sortByOrder().findAll();
  }

  /// 创建新账本
  Future<JiveBook> createBook({
    required String name,
    String? iconName,
    String? colorHex,
    String currency = 'CNY',
  }) async {
    final count = await _isar.jiveBooks.count();
    final now = DateTime.now();
    final key = 'book_${now.millisecondsSinceEpoch}';

    final book = JiveBook()
      ..key = key
      ..name = name
      ..iconName = iconName ?? 'book'
      ..colorHex = colorHex
      ..currency = currency
      ..order = count
      ..isDefault = false
      ..isArchived = false
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveBooks.put(book);
    });

    return book;
  }

  /// 更新账本
  Future<void> updateBook(JiveBook book) async {
    book.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveBooks.put(book);
    });
  }

  /// 设为默认账本
  Future<void> setDefaultBook(int bookId) async {
    await _isar.writeTxn(() async {
      final allBooks = await _isar.jiveBooks.where().findAll();
      for (final book in allBooks) {
        book.isDefault = (book.id == bookId);
        book.updatedAt = DateTime.now();
      }
      await _isar.jiveBooks.putAll(allBooks);
    });
  }

  /// 归档账本
  Future<void> archiveBook(int bookId) async {
    final book = await _isar.jiveBooks.get(bookId);
    if (book == null || book.isDefault) return;
    book.isArchived = true;
    book.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveBooks.put(book);
    });
  }

  /// 删除账本（仅允许删除空账本）
  Future<bool> deleteBook(int bookId) async {
    final book = await _isar.jiveBooks.get(bookId);
    if (book == null || book.isDefault) return false;
    await _isar.writeTxn(() async {
      await _isar.jiveBooks.delete(bookId);
    });
    return true;
  }
}
