import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/domain/models/call/call_model.dart';
import 'package:inum/presentation/blocs/call/call_cubit.dart';
import 'package:inum/presentation/blocs/call/call_state.dart';
import 'package:inum/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:inum/presentation/blocs/contacts/contacts_state.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/presentation/design_system/widgets/user_avatar.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallCubit, CallState>(
      listener: (context, state) {
        if (state is CallActive) {
          // Navigate to call screen when accepted
          Navigator.of(context).pushReplacementNamed('/call');
        } else if (state is CallIdle || state is CallEnded) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state is! CallIncoming) {
          return const SizedBox.shrink();
        }
        return _IncomingCallBody(callModel: state.callModel);
      },
    );
  }
}

class _IncomingCallBody extends StatefulWidget {
  final CallModel callModel;
  const _IncomingCallBody({required this.callModel});

  @override
  State<_IncomingCallBody> createState() => _IncomingCallBodyState();
}

class _IncomingCallBodyState extends State<_IncomingCallBody>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Phase 7: Resolve caller identity from contacts or SIP number.
  String _resolveCallerName() {
    final callModel = widget.callModel;
    final rawName = callModel.participants.isNotEmpty
        ? callModel.participants.first.username
        : '';

    if (rawName.isEmpty) return 'Unknown Caller';

    // Check if it looks like a phone number (SIP call)
    final isPhoneNumber = RegExp(r'^[\+]?[\d\s\-\(\)]+$').hasMatch(rawName);

    if (isPhoneNumber) {
      // Try to resolve from contacts
      final contactsState = context.read<ContactsCubit>().state;
      if (contactsState is ContactsLoaded) {
        for (final contact in contactsState.contacts) {
          if (contact.username == rawName ||
              contact.displayName == rawName) {
            return contact.displayName;
          }
        }
      }
      return rawName; // Show the phone number as-is
    }

    return rawName;
  }

  /// Phase 7: Determine if the caller is from SIP (phone number).
  bool _isSipCall() {
    final rawName = widget.callModel.participants.isNotEmpty
        ? widget.callModel.participants.first.username
        : '';
    return RegExp(r'^[\+]?[\d\s\-\(\)]+$').hasMatch(rawName);
  }

  @override
  Widget build(BuildContext context) {
    final callModel = widget.callModel;
    final isVideo = callModel.callType == CallType.video;
    final callerName = _resolveCallerName();
    final isSip = _isSipCall();
    final rawNumber = callModel.participants.isNotEmpty
        ? callModel.participants.first.username
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOut,
          )),
          child: FadeTransition(
            opacity: _slideController,
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Pulse rings + avatar
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (int i = 0; i < 3; i++)
                            _buildPulseRing(
                              (_pulseController.value + i * 0.33) % 1.0,
                            ),
                          child!,
                        ],
                      ),
                    );
                  },
                  child: UserAvatar(
                    name: callerName,
                    radius: 55,
                    backgroundColor: inumPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                // Caller name
                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                // Phase 7: Show phone number below name if resolved from contacts
                if (isSip && callerName != rawNumber && rawNumber.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    rawNumber,
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 15,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Call type indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.phone,
                        color: inumSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                // Phase 7: SIP indicator badge
                if (isSip) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: inumSecondary.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, color: inumSecondary, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'SIP Call',
                          style: TextStyle(
                            color: inumSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                // Accept / Reject buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reject
                      _AnswerButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        label: 'Decline',
                        onTap: () =>
                            context.read<CallCubit>().rejectCall(),
                      ),
                      // Accept
                      _AnswerButton(
                        icon: isVideo ? Icons.videocam : Icons.call,
                        color: Colors.green,
                        label: 'Accept',
                        onTap: () =>
                            context.read<CallCubit>().acceptCall(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRing(double value) {
    return Container(
      width: 110 + (value * 90),
      height: 110 + (value * 90),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: inumSecondary.withAlpha((180 * (1 - value)).toInt()),
          width: 1.5,
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
