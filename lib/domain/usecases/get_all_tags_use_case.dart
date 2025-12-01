import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class GetAllTagsUseCase {
  final TagRepository repository;

  GetAllTagsUseCase(this.repository);

  Future<List<Tag>> call() async {
    return await repository.getAllTags();
  }
}
