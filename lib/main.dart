import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tiffin_mate/core/services/notification_service.dart';
import 'package:tiffin_mate/core/theme/app_theme.dart';
import 'package:tiffin_mate/data/repositories/audit_repository.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository_impl.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_bloc.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_event.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_state.dart';
import 'package:tiffin_mate/data/repositories/admin_repository_impl.dart';
import 'package:tiffin_mate/logic/blocs/admin_bloc.dart';
import 'package:tiffin_mate/presentation/screens/admin_dashboard.dart';
import 'package:tiffin_mate/presentation/screens/auth_screen.dart';
import 'package:tiffin_mate/presentation/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Initialize Service ONLY (Don't request permissions here)
  final notificationService = NotificationService();
  await notificationService.initialize();

  final tiffinRepository = TiffinRepositoryImpl();
  await tiffinRepository.initialize();

  final auditRepository = AuditRepository();
  final adminRepository = AdminRepositoryImpl(auditRepository: auditRepository);

  runApp(
    TiffinApp(
      repository: tiffinRepository,
      auditRepository: auditRepository,
      adminRepository: adminRepository,
      notificationService: notificationService,
    ),
  );
}

class TiffinApp extends StatelessWidget {
  final TiffinRepository repository;
  final AuditRepository auditRepository;
  final AdminRepositoryImpl adminRepository;
  final NotificationService notificationService;

  const TiffinApp({
    super.key,
    required this.repository,
    required this.auditRepository,
    required this.adminRepository,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: RepositoryProvider.value(
        value: auditRepository,
        child: RepositoryProvider.value(
          value: adminRepository,
          child: RepositoryProvider.value(
            value: notificationService, // 2. Provide the service to the app
            child: MaterialApp(
              title: 'TiffinMate',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system,
              home: StreamBuilder<User?>(
                stream: repository.authStateChanges,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasData) {
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          key: ValueKey(snapshot.data!.uid),
                          create: (context) => TiffinBloc(
                            repository: repository,
                            auditRepository: auditRepository,
                          )..add(LoadTiffins()),
                        ),
                        BlocProvider(
                          create: (context) =>
                              AdminBloc(repository: adminRepository)
                                ..add(LoadUsers()),
                        ),
                      ],
                      // 3. Pass the service to HomeScreen or let HomeScreen look it up
                      child: BlocBuilder<TiffinBloc, TiffinState>(
                        builder: (context, state) {
                          if (state.userProfile?.role == 'admin') {
                            return const AdminDashboard();
                          }
                          return const UserHomeScreen();
                        },
                      ),
                    );
                  }

                  return AuthScreen(repository: repository);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
