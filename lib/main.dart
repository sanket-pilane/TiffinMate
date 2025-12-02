import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tiffin_mate/core/theme/app_theme.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository_impl.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_bloc.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_event.dart';
import 'package:tiffin_mate/presentation/screens/home_screen.dart'; // Changed import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tiffinRepository = TiffinRepositoryImpl();
  await tiffinRepository.initialize();

  runApp(TiffinApp(repository: tiffinRepository));
}

class TiffinApp extends StatelessWidget {
  final TiffinRepositoryImpl
  repository; // Use specific type if needed or interface

  const TiffinApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              TiffinBloc(repository: repository)..add(LoadTiffins()),
        ),
      ],
      child: MaterialApp(
        title: 'TiffinMate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(), // Changed to HomeScreen
      ),
    );
  }
}
