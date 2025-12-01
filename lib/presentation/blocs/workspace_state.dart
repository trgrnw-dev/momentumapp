import 'package:equatable/equatable.dart';
import '../../domain/entities/workspace.dart';

/// Base class for all workspace states
abstract class WorkspaceState extends Equatable {
  const WorkspaceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class WorkspaceInitial extends WorkspaceState {
  const WorkspaceInitial();
}

/// Loading state
class WorkspaceLoading extends WorkspaceState {
  const WorkspaceLoading();
}

/// Loaded state with workspaces
class WorkspaceLoaded extends WorkspaceState {
  final List<Workspace> workspaces;

  const WorkspaceLoaded({required this.workspaces});

  @override
  List<Object?> get props => [workspaces];
}

/// Empty state
class WorkspaceEmpty extends WorkspaceState {
  final String message;

  const WorkspaceEmpty({this.message = 'No workspaces found'});

  @override
  List<Object?> get props => [message];
}

/// Operation in progress state
class WorkspaceOperationInProgress extends WorkspaceState {
  final String message;

  const WorkspaceOperationInProgress(this.message);

  @override
  List<Object?> get props => [message];
}

/// Operation success state
class WorkspaceOperationSuccess extends WorkspaceState {
  final String message;
  final List<Workspace> workspaces;

  const WorkspaceOperationSuccess({
    required this.message,
    required this.workspaces,
  });

  @override
  List<Object?> get props => [message, workspaces];
}

/// Error state
class WorkspaceError extends WorkspaceState {
  final String message;
  final String? errorDetails;

  const WorkspaceError({
    required this.message,
    this.errorDetails,
  });

  @override
  List<Object?> get props => [message, errorDetails];
}
