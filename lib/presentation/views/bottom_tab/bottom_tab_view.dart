import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/presentation/blocs/call_history/call_history_cubit.dart';
import 'package:inum/presentation/blocs/call_history/call_history_state.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/presentation/views/call_history/call_history_view.dart';
import 'package:inum/presentation/views/contacts/contacts_view.dart';
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

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const DashboardView();
      case 1:
        return const CallHistoryView();
      case 2:
        return const ContactsView();
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
      bottomNavigationBar: BlocBuilder<CallHistoryCubit, CallHistoryState>(
        builder: (context, callHistoryState) {
          final missedCount = callHistoryState is CallHistoryLoaded
              ? callHistoryState.missedCount
              : 0;

          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              // Clear missed call badge when tapping Calls tab
              if (index == 1 && missedCount > 0) {
                context.read<CallHistoryCubit>().clearMissedBadge();
              }
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chats',
              ),
              NavigationDestination(
                icon: missedCount > 0
                    ? Badge(
                        label: Text(
                          missedCount > 99 ? '99+' : missedCount.toString(),
                          style: const TextStyle(fontSize: 10, color: white),
                        ),
                        child: const Icon(Icons.call_outlined),
                      )
                    : const Icon(Icons.call_outlined),
                selectedIcon: const Icon(Icons.call),
                label: 'Calls',
              ),
              const NavigationDestination(
                icon: Icon(Icons.contacts_outlined),
                selectedIcon: Icon(Icons.contacts),
                label: 'Contacts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
