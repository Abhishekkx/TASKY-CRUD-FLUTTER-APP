import 'package:get_it/get_it.dart';
import 'package:crud_app/data/repositories/task_repository.dart';
import 'package:crud_app/data/services/api_service.dart';
import 'package:crud_app/data/services/database_helper.dart';
import 'package:crud_app/data/services/connectivity_service.dart';
import 'package:crud_app/logic/blocs/task_bloc.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);
  getIt.registerSingleton<ApiService>(ApiService());
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());
  getIt.registerSingleton<TaskRepository>(
    TaskRepository(
      dbHelper: getIt<DatabaseHelper>(),
      apiService: getIt<ApiService>(),
    ),
  );
  getIt.registerFactory<TaskBloc>(() => TaskBloc(getIt<TaskRepository>()));
}