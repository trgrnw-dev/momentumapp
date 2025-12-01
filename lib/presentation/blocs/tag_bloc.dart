import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_all_tags_use_case.dart';
import '../../domain/usecases/create_tag_use_case.dart';
import '../../domain/usecases/delete_tag_use_case.dart';
import 'tag_event.dart';
import 'tag_state.dart';

class TagBloc extends Bloc<TagEvent, TagState> {
  final GetAllTagsUseCase getAllTagsUseCase;
  final CreateTagUseCase createTagUseCase;
  final DeleteTagUseCase deleteTagUseCase;

  TagBloc({
    required this.getAllTagsUseCase,
    required this.createTagUseCase,
    required this.deleteTagUseCase,
  }) : super(TagInitial()) {
    on<LoadTagsEvent>(_onLoadTags);
    on<CreateTagEvent>(_onCreateTag);
    on<DeleteTagEvent>(_onDeleteTag);
    on<RefreshTagsEvent>(_onRefreshTags);
  }

  Future<void> _onLoadTags(
    LoadTagsEvent event,
    Emitter<TagState> emit,
  ) async {
    try {
      emit(TagLoading());

      final tags = await getAllTagsUseCase();

      if (tags.isEmpty) {
        emit(TagEmpty());
      } else {
        emit(TagLoaded(tags: tags));
      }
    } catch (e) {
      emit(
        TagError(message: 'Failed to load tags: ${e.toString()}'),
      );
    }
  }

  /// Create a new tag
  Future<void> _onCreateTag(
    CreateTagEvent event,
    Emitter<TagState> emit,
  ) async {
    try {
      emit(TagOperationInProgress('Creating tag...'));

      await createTagUseCase(event.tag);

      // Reload all tags after creation
      final tags = await getAllTagsUseCase();
      emit(
        TagOperationSuccess(
          message: 'Tag created successfully',
          tags: tags,
        ),
      );
    } catch (e) {
      emit(
        TagError(message: 'Failed to create tag: ${e.toString()}'),
      );
    }
  }

  /// Delete a tag
  Future<void> _onDeleteTag(
    DeleteTagEvent event,
    Emitter<TagState> emit,
  ) async {
    try {
      emit(TagOperationInProgress('Deleting tag...'));

      await deleteTagUseCase(event.tagId);

      // Reload all tags after deletion
      final tags = await getAllTagsUseCase();
      emit(
        TagOperationSuccess(
          message: 'Tag deleted successfully',
          tags: tags,
        ),
      );
    } catch (e) {
      emit(
        TagError(message: 'Failed to delete tag: ${e.toString()}'),
      );
    }
  }

  /// Refresh tags (reload from database)
  Future<void> _onRefreshTags(
    RefreshTagsEvent event,
    Emitter<TagState> emit,
  ) async {
    try {
      final tags = await getAllTagsUseCase();

      if (tags.isEmpty) {
        emit(TagEmpty());
      } else {
        emit(TagLoaded(tags: tags));
      }
    } catch (e) {
      emit(
        TagError(message: 'Failed to refresh tags: ${e.toString()}'),
      );
    }
  }
}
