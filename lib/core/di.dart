import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import '../data/datasources/task_local_data_source.dart';
import '../data/datasources/workspace_local_data_source.dart';
import '../data/datasources/tag_local_data_source.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/repositories/workspace_repository_impl.dart';
import '../data/repositories/tag_repository_impl.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/workspace_repository.dart';
import '../domain/repositories/tag_repository.dart';
import '../domain/usecases/create_task_use_case.dart';
import '../domain/usecases/create_workspace_use_case.dart';
import '../domain/usecases/create_tag_use_case.dart';
import '../domain/usecases/delete_task_use_case.dart';
import '../domain/usecases/delete_workspace_use_case.dart';
import '../domain/usecases/delete_tag_use_case.dart';
import '../domain/usecases/get_all_tasks_use_case.dart';
import '../domain/usecases/get_all_workspaces_use_case.dart';
import '../domain/usecases/get_all_tags_use_case.dart';
import '../domain/usecases/get_tasks_by_workspace_id_use_case.dart';
import '../domain/usecases/update_task_use_case.dart';
import '../domain/usecases/update_workspace_use_case.dart';
import '../presentation/blocs/task_bloc.dart';
import '../presentation/blocs/workspace_bloc.dart';
import '../presentation/blocs/tag_bloc.dart';
import 'app_state_provider.dart';

/// Контейнер внедрения зависимостей
/// Управляет всеми зависимостями приложения используя простой паттерн service locator
/// Инициализирует SQLite базу данных и предоставляет экземпляры репозиториев, use cases и BLoCs
class DI {
  static late Database _database;
  static late TaskLocalDataSource _taskLocalDataSource;
  static late WorkspaceLocalDataSource _workspaceLocalDataSource;
  static late TagLocalDataSource _tagLocalDataSource;
  static late TaskRepository _taskRepository;
  static late WorkspaceRepository _workspaceRepository;
  static late TagRepository _tagRepository;
  static late AppStateProvider _appStateProvider;
  static late GetAllTasksUseCase _getAllTasksUseCase;
  static late GetAllWorkspacesUseCase _getAllWorkspacesUseCase;
  static late GetAllTagsUseCase _getAllTagsUseCase;
  static late GetTasksByWorkspaceIdUseCase _getTasksByWorkspaceIdUseCase;
  static late CreateTaskUseCase _createTaskUseCase;
  static late CreateWorkspaceUseCase _createWorkspaceUseCase;
  static late CreateTagUseCase _createTagUseCase;
  static late UpdateTaskUseCase _updateTaskUseCase;
  static late UpdateWorkspaceUseCase _updateWorkspaceUseCase;
  static late DeleteTaskUseCase _deleteTaskUseCase;
  static late DeleteWorkspaceUseCase _deleteWorkspaceUseCase;
  static late DeleteTagUseCase _deleteTagUseCase;

  /// Инициализирует все зависимости
  /// Должен быть вызван перед использованием любых зависимостей
  static Future<void> init() async {
    try {
      debugPrint('DI: Инициализация SQLite базы данных...');
      // Инициализация SQLite базы данных
      final dir = await getApplicationDocumentsDirectory();
      final path = join(dir.path, 'momentum.db');
      _database = await openDatabase(
        path,
        version: 2,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
      debugPrint('DI: База данных успешно инициализирована');
    } catch (e) {
      debugPrint('DI: Ошибка инициализации базы данных: $e');
      rethrow;
    }

    // Инициализация источников данных
    debugPrint('DI: Инициализация источников данных...');
    _taskLocalDataSource = TaskLocalDataSource(_database);
    _workspaceLocalDataSource = WorkspaceLocalDataSource(_database);
    _tagLocalDataSource = TagLocalDataSourceImpl(_database);
    debugPrint('DI: Источники данных инициализированы');

    // Инициализация репозиториев
    debugPrint('DI: Инициализация репозиториев...');
    _workspaceRepository = WorkspaceRepositoryImpl(localDataSource: _workspaceLocalDataSource);
    _taskRepository = TaskRepositoryImpl(
      localDataSource: _taskLocalDataSource,
      workspaceRepository: _workspaceRepository,
    );
    _tagRepository = TagRepositoryImpl(localDataSource: _tagLocalDataSource);
    _appStateProvider = AppStateProvider();
    debugPrint('DI: Репозитории инициализированы');

    // Инициализация use cases
    _getAllTasksUseCase = GetAllTasksUseCase(_taskRepository);
    _getAllWorkspacesUseCase = GetAllWorkspacesUseCase(_workspaceRepository);
    _getAllTagsUseCase = GetAllTagsUseCase(_tagRepository);
    _getTasksByWorkspaceIdUseCase = GetTasksByWorkspaceIdUseCase(_taskRepository);
    _createTaskUseCase = CreateTaskUseCase(_taskRepository);
    _createWorkspaceUseCase = CreateWorkspaceUseCase(_workspaceRepository);
    _createTagUseCase = CreateTagUseCase(_tagRepository);
    _updateTaskUseCase = UpdateTaskUseCase(_taskRepository);
    _updateWorkspaceUseCase = UpdateWorkspaceUseCase(_workspaceRepository);
    _deleteTaskUseCase = DeleteTaskUseCase(_taskRepository);
    _deleteWorkspaceUseCase = DeleteWorkspaceUseCase(_workspaceRepository, _taskRepository);
    _deleteTagUseCase = DeleteTagUseCase(_tagRepository);

    // Инициализация начальных данных если база данных пуста (отключено)
    // await _initializeSeedData();
  }

  /// Обновление базы данных
  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Исправление null значений order в существующих рабочих пространствах
      await db.execute('UPDATE workspaces SET `order` = 0 WHERE `order` IS NULL');
    }
  }

  /// Создание таблиц базы данных
  static Future<void> _createDatabase(Database db, int version) async {
    // Создание таблицы задач
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dueDate INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        category TEXT,
        workspaceId INTEGER,
        progress REAL,
        estimatedHours INTEGER,
        tagIds TEXT
      )
    ''');

    // Создание таблицы рабочих пространств
    await db.execute('''
      CREATE TABLE workspaces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        iconName TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        `order` INTEGER NOT NULL DEFAULT 0,
        totalTasks INTEGER NOT NULL DEFAULT 0,
        completedTasks INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Создание таблицы тегов
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorHex TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        usageCount INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Получить экземпляр базы данных
  static Database get database => _database;

  /// Получить локальный источник данных задач
  static TaskLocalDataSource get taskLocalDataSource => _taskLocalDataSource;

  /// Получить локальный источник данных рабочих пространств
  static WorkspaceLocalDataSource get workspaceLocalDataSource => _workspaceLocalDataSource;

  /// Получить локальный источник данных тегов
  static TagLocalDataSource get tagLocalDataSource => _tagLocalDataSource;

  /// Получить репозиторий задач
  static TaskRepository get taskRepository => _taskRepository;

  /// Получить репозиторий рабочих пространств
  static WorkspaceRepository get workspaceRepository => _workspaceRepository;

  /// Получить репозиторий тегов
  static TagRepository get tagRepository => _tagRepository;

  /// Получить провайдер состояния приложения
  static AppStateProvider get appStateProvider => _appStateProvider;

  /// Получить use case получения всех задач
  static GetAllTasksUseCase get getAllTasksUseCase => _getAllTasksUseCase;

  /// Получить use case получения всех рабочих пространств
  static GetAllWorkspacesUseCase get getAllWorkspacesUseCase => _getAllWorkspacesUseCase;

  /// Получить use case получения всех тегов
  static GetAllTagsUseCase get getAllTagsUseCase => _getAllTagsUseCase;

  /// Получить use case получения задач по ID рабочего пространства
  static GetTasksByWorkspaceIdUseCase get getTasksByWorkspaceIdUseCase => _getTasksByWorkspaceIdUseCase;

  /// Получить use case создания задачи
  static CreateTaskUseCase get createTaskUseCase => _createTaskUseCase;

  /// Получить use case создания рабочего пространства
  static CreateWorkspaceUseCase get createWorkspaceUseCase => _createWorkspaceUseCase;

  /// Получить use case создания тега
  static CreateTagUseCase get createTagUseCase => _createTagUseCase;

  /// Получить use case обновления задачи
  static UpdateTaskUseCase get updateTaskUseCase => _updateTaskUseCase;

  /// Получить use case обновления рабочего пространства
  static UpdateWorkspaceUseCase get updateWorkspaceUseCase => _updateWorkspaceUseCase;

  /// Получить use case удаления задачи
  static DeleteTaskUseCase get deleteTaskUseCase => _deleteTaskUseCase;

  /// Получить use case удаления рабочего пространства
  static DeleteWorkspaceUseCase get deleteWorkspaceUseCase => _deleteWorkspaceUseCase;

  /// Получить use case удаления тега
  static DeleteTagUseCase get deleteTagUseCase => _deleteTagUseCase;

  /// Создать экземпляр Task BLoC
  /// Создает новый экземпляр каждый раз (для BlocProvider)
  static TaskBloc createTaskBloc() {
    return TaskBloc(
      getAllTasksUseCase: _getAllTasksUseCase,
      getTasksByWorkspaceIdUseCase: _getTasksByWorkspaceIdUseCase,
      createTaskUseCase: _createTaskUseCase,
      updateTaskUseCase: _updateTaskUseCase,
      deleteTaskUseCase: _deleteTaskUseCase,
      taskRepository: _taskRepository,
      tagRepository: _tagRepository,
      appStateProvider: _appStateProvider,
    );
  }

  /// Создать экземпляр Workspace BLoC
  /// Создает новый экземпляр каждый раз (для BlocProvider)
  static WorkspaceBloc createWorkspaceBloc() {
    return WorkspaceBloc(
      getAllWorkspacesUseCase: _getAllWorkspacesUseCase,
      createWorkspaceUseCase: _createWorkspaceUseCase,
      updateWorkspaceUseCase: _updateWorkspaceUseCase,
      deleteWorkspaceUseCase: _deleteWorkspaceUseCase,
      workspaceRepository: _workspaceRepository,
    );
  }

  /// Создать экземпляр Tag BLoC
  /// Создает новый экземпляр каждый раз (для BlocProvider)
  static TagBloc createTagBloc() {
    return TagBloc(
      getAllTagsUseCase: _getAllTagsUseCase,
      createTagUseCase: _createTagUseCase,
      deleteTagUseCase: _deleteTagUseCase,
    );
  }


  /// Освобождение ресурсов
  /// Вызывать при закрытии приложения
  static Future<void> dispose() async {
    await _database.close();
  }
}
