import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class CreateTagUseCase {
  final TagRepository repository;

  CreateTagUseCase(this.repository);

  Future<Tag> call(Tag tag) async {
    return await repository.createTag(tag);
  }
}
