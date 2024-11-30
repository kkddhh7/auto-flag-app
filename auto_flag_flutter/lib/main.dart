import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/list_screen.dart';
import 'screens/map_screen.dart';
import 'screens/add_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/detail_screen.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'provider/user_provider.dart';
import 'provider/bottom_navigation_provider.dart';

void main() async {
  await dotenv.load(
      fileName:
          '/Users/kkddhh/Desktop/project/auto-flag/auto-flag-app/auto_flag_flutter/.env');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavigationProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<UserProvider>().isLoggedIn;

    final userId = context.watch<UserProvider>().userId;

    final List<Widget> _screens = [
      ListScreen(),
      MapScreen(),
      AddScreen(),
      FriendsScreen(),
      if (userId != null) ProfileScreen(userId: userId),
      if (userId != null)
        DetailScreen(
          registrationTime: DateTime(2022, 11, 19),
          imagePath: '',
          placeName: 'Sample Place',
          address: '1234 Sample Street',
          memo: 'This is a sample memo.',
          latitude: 37.240873,
          longitude: 127.079747,
        ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: false,
      body: isLoggedIn
          ? Consumer<BottomNavigationProvider>(
              builder: (context, provider, child) {
                return _screens[provider.currentIndex];
              },
            )
          : LoginScreen(),
      bottomNavigationBar: isLoggedIn
          ? Consumer<BottomNavigationProvider>(
              builder: (context, provider, child) {
                return BottomNavigation(
                  onTap: (index) {
                    provider.setCurrentIndex(index);
                  },
                );
              },
            )
          : null,
    );
  }
}
