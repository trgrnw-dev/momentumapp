import 'package:sqflite/sqflite.dart';
import '../models/tag_model.dart';

abstract class TagLocalDataSource {
  Future<List<TagModel>> getAllTags();
  Future<TagModel> createTag(TagModel tag);
  Future<void> updateTag(TagModel tag);
  Future<void> deleteTag(int id);
  Future<TagModel?> getTagById(int id);
  Future<List<TagModel>> getTagsByIds(List<int> ids);
  Future<void> incrementTagUsage(int tagId);
  Future<void> decrementTagUsage(int tagId);
  Stream<List<TagModel>> watchAllTags();
}

class TagLocalDataSourceImpl implements TagLocalDataSource {
  final Database database;

  TagLocalDataSourceImpl(this.database);

  @override
  Future<List<TagModel>> getAllTags() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tags',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => TagModel.fromMap(maps[i]));
  }

  @override
  Future<TagModel> createTag(TagModel tag) async {
    final tagMap = tag.toMap();
    tagMap.remove('id'); // Remove id for auto-increment
    final id = await database.insert('tags', tagMap);
    return tag.copyWith(id: id);
  }

  @override
  Future<void> updateTag(TagModel tag) async {
    await database.update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  @override
  Future<void> deleteTag(int id) async {
    await database.delete(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<TagModel?> getTagById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TagModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<TagModel>> getTagsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    
    final placeholders = ids.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await database.query(
      'tags',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return List.generate(maps.length, (i) => TagModel.fromMap(maps[i]));
  }

  @override
  Future<void> incrementTagUsage(int tagId) async {
    await database.rawUpdate(
      'UPDATE tags SET usageCount = usageCount + 1 WHERE id = ?',
      [tagId],
    );
  }

  @override
  Future<void> decrementTagUsage(int tagId) async {
    await database.rawUpdate(
      'UPDATE tags SET usageCount = MAX(0, usageCount - 1) WHERE id = ?',
      [tagId],
    );
  }

  /// Watch all tags for changes (SQLite doesn't have built-in streams)
  @override
  Stream<List<TagModel>> watchAllTags() async* {
    while (true) {
      yield await getAllTags();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
