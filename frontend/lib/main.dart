import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/player_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/socket_service.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';
import 'providers/nav_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.init();

  runApp(NebularcApp(authService: authService));
}

class NebularcApp extends StatelessWidget {
  final AuthService authService;

  const NebularcApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProxyProvider<AuthService, SocketService>(
          create: (_) => SocketService(),
          update: (_, auth, socket) {
            if (auth.isLoggedIn && auth.user != null) {
              socket!.connect(
                userId: auth.user!.id.toString(),
                username: auth.user!.username,
              );
            }
            return socket!;
          },
        ),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Nebularc',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode, // system / light / dark
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}