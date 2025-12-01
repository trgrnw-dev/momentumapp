import 'package:equatable/equatable.dart';

/// Base class for all workspace events
abstract class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

/// Load all workspaces event
class LoadWorkspacesEvent extends WorkspaceEvent {
  const LoadWorkspacesEvent();
}

/// Create workspace event
class CreateWorkspaceEvent extends WorkspaceEvent {
  final String name;
  final String? description;
  final String iconName;
  final String colorHex;

  const CreateWorkspaceEvent({
    required this.name,
    this.description,
    required this.iconName,
    required this.colorHex,
  });

  @override
  List<Object?> get props => [name, description, iconName, colorHex];
}

/// Update workspace event
class UpdateWorkspaceEvent extends WorkspaceEvent {
  final int id;
  final String name;
  final String? description;
  final String iconName;
  final String colorHex;

  const UpdateWorkspaceEvent({
    required this.id,
    required this.name,
    this.description,
    required this.iconName,
    required this.colorHex,
  });

  @override
  List<Object?> get props => [id, name, description, iconName, colorHex];
}

/// Delete workspace event
class DeleteWorkspaceEvent extends WorkspaceEvent {
  final int workspaceId;

  const DeleteWorkspaceEvent(this.workspaceId);

  @override
  List<Object?> get props => [workspaceId];
}

/// Update workspace order event
class UpdateWorkspaceOrderEvent extends WorkspaceEvent {
  final int workspaceId;
  final int newOrder;

  const UpdateWorkspaceOrderEvent({
    required this.workspaceId,
    required this.newOrder,
  });

  @override
  List<Object?> get props => [workspaceId, newOrder];
}

/// Update workspace task counts event
class UpdateWorkspaceTaskCountsEvent extends WorkspaceEvent {
  final int workspaceId;
  final int totalTasks;
  final int completedTasks;

  const UpdateWorkspaceTaskCountsEvent({
    required this.workspaceId,
    required this.totalTasks,
    required this.completedTasks,
  });

  @override
  List<Object?> get props => [workspaceId, totalTasks, completedTasks];
}
