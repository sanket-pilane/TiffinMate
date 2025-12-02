import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tiffin_mate/core/theme/app_theme.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository_impl.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_bloc.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_event.dart';
import 'package:tiffin_mate/presentation/screens/auth_screen.dart';
import 'package:tiffin_mate/presentation/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final tiffinRepository = TiffinRepositoryImpl();
  await tiffinRepository.initialize();

  runApp(TiffinApp(repository: tiffinRepository));
}

class TiffinApp extends StatelessWidget {
  final TiffinRepository repository;

  const TiffinApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: MaterialApp(
        title: 'TiffinMate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // The StreamBuilder listens to Firebase Auth changes
        home: StreamBuilder<User?>(
          stream: repository.authStateChanges,
          builder: (context, snapshot) {
            // If the stream is waiting (app start), show a loader
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If user is logged in
            if (snapshot.hasData) {
              return MultiBlocProvider(
                providers: [
                  // Re-create the Bloc when the user changes to ensure data isolation
                  BlocProvider(
                    key: ValueKey(snapshot.data!.uid),
                    create: (context) =>
                        TiffinBloc(repository: repository)..add(LoadTiffins()),
                  ),
                ],
                child: const HomeScreen(),
              );
            }

            // If user is logged out
            return AuthScreen(repository: repository);
          },
        ),
      ),
    );
  }
}
