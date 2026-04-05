import 'package:flutter/material.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/presentation/views/chat/chat_view.dart';
import 'package:inum/presentation/views/dashboard/dashboard_view.dart';

/// Desktop split view: channel list on the left, chat view on the right.
class SplitView extends StatefulWidget {
  const SplitView({super.key});

  /// Notifier for selecting a channel from the dashboard panel.
  static final channelNotifier = ValueNotifier<({String id, String name})?>(null);

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  String? _selectedChannelId;
  String? _selectedChannelName;
  double _leftPanelWidth = 320;
  static const double _minLeftWidth = 250;
  static const double _maxLeftWidth = 500;

  @override
  void initState() {
    super.initState();
    SplitView.channelNotifier.addListener(_onChannelNotified);
  }

  @override
  void dispose() {
    SplitView.channelNotifier.removeListener(_onChannelNotified);
    super.dispose();
  }

  void _onChannelNotified() {
    final val = SplitView.channelNotifier.value;
    if (val != null) {
      setState(() {
        _selectedChannelId = val.id;
        _selectedChannelName = val.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel: channel list
        SizedBox(
          width: _leftPanelWidth,
          child: const DashboardView(),
        ),
        // Draggable divider
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _leftPanelWidth =
                    (_leftPanelWidth + details.delta.dx).clamp(_minLeftWidth, _maxLeftWidth);
              });
            },
            child: Container(
              width: 6,
              color: customGreyColor200,
              child: Center(
                child: Container(
                  width: 2,
                  height: 40,
                  decoration: BoxDecoration(
                    color: customGreyColor400,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Right panel: chat view or placeholder
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: (_selectedChannelId != null && _selectedChannelName != null)
                ? ChatView(
                    key: ValueKey(_selectedChannelId),
                    channelId: _selectedChannelId!,
                    channelName: _selectedChannelName!,
                  )
                : const _EmptyRightPanel(),
          ),
        ),
      ],
    );
  }
}

class _EmptyRightPanel extends StatelessWidget {
  const _EmptyRightPanel();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: customGreyColor400),
            SizedBox(height: 16),
            Text(
              'Select a conversation',
              style: TextStyle(fontSize: 18, color: customGreyColor500),
            ),
          ],
        ),
      ),
    );
  }
}
