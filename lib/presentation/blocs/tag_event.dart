import 'package:equatable/equatable.dart';
import '../../domain/entities/tag.dart';

/// Base class for all Tag events
abstract class TagEvent extends Equatable {
  const TagEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all tags
class LoadTagsEvent extends TagEvent {
  const LoadTagsEvent();
}

/// Event to create a new tag
class CreateTagEvent extends TagEvent {
  final Tag tag;

  const CreateTagEvent(this.tag);

  @override
  List<Object?> get props => [tag];
}

/// Event to update an existing tag
class UpdateTagEvent extends TagEvent {
  final Tag tag;

  const UpdateTagEvent(this.tag);

  @override
  List<Object?> get props => [tag];
}

/// Event to delete a tag
class DeleteTagEvent extends TagEvent {
  final int tagId;

  const DeleteTagEvent(this.tagId);

  @override
  List<Object?> get props => [tagId];
}

/// Event to refresh tags (reload from database)
class RefreshTagsEvent extends TagEvent {
  const RefreshTagsEvent();
}
