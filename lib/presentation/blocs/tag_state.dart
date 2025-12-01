import 'package:equatable/equatable.dart';
import '../../domain/entities/tag.dart';

/// Base class for all Tag states
abstract class TagState extends Equatable {
  const TagState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TagInitial extends TagState {}

/// Loading state
class TagLoading extends TagState {}

/// Empty state - no tags found
class TagEmpty extends TagState {}

/// Loaded state - tags loaded successfully
class TagLoaded extends TagState {
  final List<Tag> tags;

  const TagLoaded({required this.tags});

  @override
  List<Object?> get props => [tags];
}

/// Operation in progress state
class TagOperationInProgress extends TagState {
  final String message;

  const TagOperationInProgress(this.message);

  @override
  List<Object?> get props => [message];
}

/// Operation success state
class TagOperationSuccess extends TagState {
  final String message;
  final List<Tag> tags;

  const TagOperationSuccess({
    required this.message,
    required this.tags,
  });

  @override
  List<Object?> get props => [message, tags];
}

/// Error state
class TagError extends TagState {
  final String message;

  const TagError({required this.message});

  @override
  List<Object?> get props => [message];
}
