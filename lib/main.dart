// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/app/app_router.dart';
import 'package:devoverflow/app/app_theme.dart';
import 'package:devoverflow/features/auth/presentation/cubit/auth_status_cubit.dart';
import 'package:devoverflow/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:devoverflow/features/bookmarks/presentation/cubit/bookmark_cubit.dart';
import 'package:devoverflow/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:devoverflow/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:devoverflow/features/settings/presentation/cubit/settings_state.dart';
import 'package:devoverflow/features/home/presentation/cubit/home_cubit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap the app with a MultiBlocProvider to make cubits available globally.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthStatusCubit>(
          create: (context) => AuthStatusCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(
            authStatusCubit: context.read<AuthStatusCubit>(),
          ),
        ),
        BlocProvider<BookmarkCubit>(
          create: (context) => BookmarkCubit(),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(),
        ),
        BlocProvider<SettingsCubit>(
          create: (context) => SettingsCubit(),
        ),
        BlocProvider<HomeCubit>(
            create: (context) => HomeCubit()
        ),
      ],
      // The BlocBuilder now correctly serves as the child of the MultiBlocProvider.
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          // This MaterialApp.router is rebuilt whenever the theme changes.
          return MaterialApp.router(
            title: 'DevOverflow',
            // The theme is now dynamically set based on the cubit's state.
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,

            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
