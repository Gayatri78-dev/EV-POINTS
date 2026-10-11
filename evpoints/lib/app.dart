import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/map/screens/home_map_screen.dart';
import 'features/spots/screens/spot_detail_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/map/providers/map_provider.dart';
import 'features/map/providers/location_provider.dart';
import 'features/profile/providers/profile_provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();

    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _authProvider,
      redirect: (context, state) {
        final isAuthenticated = _authProvider.isAuthenticated;
        final location = state.matchedLocation;

        final publicRoutes = ['/splash', '/login', '/register'];
        final isPublic = publicRoutes.contains(location);

        if (!isAuthenticated && !isPublic) return '/login';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (_, state) {
            final indexStr = state.uri.queryParameters['index'];
            final index = int.tryParse(indexStr ?? '') ?? 0;
            return HomeMapScreen(initialIndex: index);
          },
        ),
        GoRoute(
          path: '/spot/:id',
          name: 'spot-detail',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return SpotDetailScreen(spotId: id);
          },
        ),
        GoRoute(
          path: '/profile/edit',
          name: 'edit-profile',
          builder: (_, __) => const EditProfileScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(state.error?.message ?? 'Page not found'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poppins = GoogleFonts.poppinsTextTheme();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<MapProvider>(create: (_) => MapProvider()),
        ChangeNotifierProvider<LocationProvider>(create: (_) => LocationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (ctx) => ProfileProvider(ctx.read<AuthProvider>()),
          update: (ctx, auth, prev) => prev ?? ProfileProvider(auth),
        ),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: AppColors.primary,
          textTheme: poppins,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withOpacity(0.12),
            height: 64,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              return IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 24,
              );
            }),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }
}
