import '../entities/tag.dart';

abstract class TagRepository {
  Future<List<Tag>> getAllTags();
  Future<Tag> createTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(int id);
  Future<Tag?> getTagById(int id);
  Future<List<Tag>> getTagsByIds(List<int> ids);
  Future<void> incrementTagUsage(int tagId);
  Future<void> decrementTagUsage(int tagId);

  /// Watch all tags for changes
  Stream<List<Tag>> watchAllTags();
}
