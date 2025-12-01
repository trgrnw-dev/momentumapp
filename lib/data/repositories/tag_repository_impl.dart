import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../datasources/tag_local_data_source.dart';
import '../models/tag_model.dart';

class TagRepositoryImpl implements TagRepository {
  final TagLocalDataSource localDataSource;

  TagRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Tag>> getAllTags() async {
    final models = await localDataSource.getAllTags();
    return models.map((model) => _toEntity(model)).toList();
  }

  @override
  Future<Tag> createTag(Tag tag) async {
    final model = _toModel(tag);
    final createdModel = await localDataSource.createTag(model);
    return _toEntity(createdModel);
  }

  @override
  Future<void> updateTag(Tag tag) async {
    final model = _toModel(tag);
    await localDataSource.updateTag(model);
  }

  @override
  Future<void> deleteTag(int id) async {
    await localDataSource.deleteTag(id);
  }

  @override
  Future<Tag?> getTagById(int id) async {
    final model = await localDataSource.getTagById(id);
    return model != null ? _toEntity(model) : null;
  }

  @override
  Future<List<Tag>> getTagsByIds(List<int> ids) async {
    final models = await localDataSource.getTagsByIds(ids);
    return models.map((model) => _toEntity(model)).toList();
  }

  @override
  Future<void> incrementTagUsage(int tagId) async {
    await localDataSource.incrementTagUsage(tagId);
  }

  @override
  Future<void> decrementTagUsage(int tagId) async {
    await localDataSource.decrementTagUsage(tagId);
  }

  @override
  Stream<List<Tag>> watchAllTags() {
    return localDataSource.watchAllTags().map((tagModels) => 
      tagModels.map((model) => _toEntity(model)).toList()
    );
  }

  TagModel _toModel(Tag entity) {
    return TagModel.fromEntity(entity);
  }

  Tag _toEntity(TagModel model) {
    return Tag(
      id: model.id,
      name: model.name,
      colorHex: model.colorHex,
      createdAt: model.createdAt,
      usageCount: model.usageCount,
    );
  }
}
