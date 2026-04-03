import 'package:flutter/material.dart';
import 'package:inum/presentation/views/dashboard/dashboard_view.dart';
import 'package:inum/presentation/views/profile/profile_view.dart';

class BottomTabView extends StatefulWidget {
  final int initialTab;
  const BottomTabView({super.key, this.initialTab = 0});

  @override
  State<BottomTabView> createState() => _BottomTabViewState();
}

class _BottomTabViewState extends State<BottomTabView> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  static const _placeholderPage = Center(child: Text('Coming Soon'));

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const DashboardView();
      case 1:
        return _placeholderPage;
      case 2:
        return _placeholderPage;
      case 3:
        return const ProfileView();
      default:
        return const DashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
