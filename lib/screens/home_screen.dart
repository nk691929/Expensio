import 'package:animationandcharts/screens/account_screen.dart';
import 'package:animationandcharts/screens/categories_screen.dart';
import 'package:animationandcharts/screens/dashboard_screen.dart';
import 'package:animationandcharts/screens/settings_screen.dart';
import 'package:animationandcharts/services/notification_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(userId: widget.userId), // 🏠 Home
    AccountsScreen(userId: widget.userId), // 💼 Accounts
    CategoriesScreen(userId: widget.userId), // 🗂️ Categories
    SettingsScreen(userId: widget.userId), // ⚙️ Settings
  ];

  @override
  void initState() {
    super.initState();
    NotificationService.scheduleDailyNotification(
      title: "💰 Daily Reminder",
      body: "Don't forget to add today's transactions!",
      hour: 9, // 8:00 PM
      minute: 19,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(colorScheme),
    );
  }

  Widget _buildBottomNav(ColorScheme colorScheme) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onBackground.withOpacity(0.5),
      onTap: (index) {
        setState(() {
          _currentIndex = index; // ✅ Just update index, no navigation
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.add_circle_outline),
        //   label: "Add",
        // ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: "Accounts",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          label: "Categories",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: "Settings",
        ),
      ],
    );
  }
}
