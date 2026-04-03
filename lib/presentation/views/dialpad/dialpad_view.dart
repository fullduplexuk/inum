import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:inum/presentation/blocs/contacts/contacts_state.dart';
import 'package:inum/presentation/design_system/colors.dart';

class DialpadView extends StatefulWidget {
  const DialpadView({super.key});

  @override
  State<DialpadView> createState() => _DialpadViewState();
}

class _DialpadViewState extends State<DialpadView> {
  final _numberController = TextEditingController();
  final List<String> _recentNumbers = [];
  bool _showRecents = false;

  static const _keys = [
    _DialKey('1', ''),
    _DialKey('2', 'ABC'),
    _DialKey('3', 'DEF'),
    _DialKey('4', 'GHI'),
    _DialKey('5', 'JKL'),
    _DialKey('6', 'MNO'),
    _DialKey('7', 'PQRS'),
    _DialKey('8', 'TUV'),
    _DialKey('9', 'WXYZ'),
    _DialKey('*', ''),
    _DialKey('0', '+'),
    _DialKey('#', ''),
  ];

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      _numberController.text += key;
      _numberController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numberController.text.length),
      );
      _showRecents = false;
    });
  }

  void _onBackspace() {
    if (_numberController.text.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _numberController.text = _numberController.text
            .substring(0, _numberController.text.length - 1);
        _numberController.selection = TextSelection.fromPosition(
          TextPosition(offset: _numberController.text.length),
        );
      });
    }
  }

  void _onLongPressZero() {
    HapticFeedback.mediumImpact();
    setState(() {
      _numberController.text += '+';
      _numberController.selection = TextSelection.fromPosition(
        TextPosition(offset: _numberController.text.length),
      );
    });
  }

  void _makeAudioCall() {
    final number = _numberController.text.trim();
    if (number.isEmpty) return;

    if (!_recentNumbers.contains(number)) {
      _recentNumbers.insert(0, number);
      if (_recentNumbers.length > 10) _recentNumbers.removeLast();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $number... (SIP bridge placeholder)')),
    );
  }

  void _makeVideoCall() {
    final number = _numberController.text.trim();
    if (number.isEmpty) return;

    if (!_recentNumbers.contains(number)) {
      _recentNumbers.insert(0, number);
      if (_recentNumbers.length > 10) _recentNumbers.removeLast();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video calling $number... (SIP bridge placeholder)')),
    );
  }

  void _openSms() {
    final number = _numberController.text.trim();
    if (number.isEmpty) return;
    context.push('${RouterEnum.smsView.routeName}/$number');
  }

  String? _resolveContactName(String number) {
    final contactsState = context.read<ContactsCubit>().state;
    if (contactsState is ContactsLoaded) {
      for (final c in contactsState.contacts) {
        if (c.username == number || c.displayName == number) {
          return c.displayName;
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final number = _numberController.text;
    final contactName = number.isNotEmpty ? _resolveContactName(number) : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialpad'),
        centerTitle: false,
        actions: [
          if (number.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sms_outlined),
              tooltip: 'Send SMS',
              onPressed: _openSms,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Number display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showRecents = !_showRecents),
                          child: Text(
                            number.isEmpty ? 'Enter number' : number,
                            style: TextStyle(
                              fontSize: number.length > 15 ? 24 : 32,
                              fontWeight: FontWeight.w300,
                              color: number.isEmpty
                                  ? customGreyColor500
                                  : (isDark ? Colors.white : Colors.black),
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (number.isNotEmpty)
                        GestureDetector(
                          onTap: _onBackspace,
                          onLongPress: () {
                            HapticFeedback.heavyImpact();
                            setState(() {
                              _numberController.clear();
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.backspace_outlined, size: 24),
                          ),
                        ),
                    ],
                  ),
                  if (contactName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        contactName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: inumSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Recent numbers dropdown
            if (_showRecents && _recentNumbers.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: isDark ? darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _recentNumbers.length,
                  itemBuilder: (context, index) {
                    final recent = _recentNumbers[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 18),
                      title: Text(recent),
                      onTap: () {
                        setState(() {
                          _numberController.text = recent;
                          _numberController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: recent.length),
                          );
                          _showRecents = false;
                        });
                      },
                    );
                  },
                ),
              ),

            const Spacer(),

            // Dialpad grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: _keys.length,
                itemBuilder: (context, index) {
                  final key = _keys[index];
                  return _DialpadButton(
                    digit: key.digit,
                    letters: key.letters,
                    onTap: () => _onKeyPress(key.digit),
                    onLongPress: key.digit == '0' ? _onLongPressZero : null,
                    isDark: isDark,
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Call buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Video call
                _ActionCircle(
                  icon: Icons.videocam,
                  color: inumSecondary,
                  size: 56,
                  onTap: _makeVideoCall,
                ),
                const SizedBox(width: 32),
                // Audio call (primary)
                _ActionCircle(
                  icon: Icons.call,
                  color: Colors.green,
                  size: 68,
                  onTap: _makeAudioCall,
                ),
                const SizedBox(width: 32),
                // SMS
                _ActionCircle(
                  icon: Icons.sms,
                  color: inumPrimary,
                  size: 56,
                  onTap: _openSms,
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DialKey {
  final String digit;
  final String letters;
  const _DialKey(this.digit, this.letters);
}

class _DialpadButton extends StatefulWidget {
  final String digit;
  final String letters;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isDark;

  const _DialpadButton({
    required this.digit,
    required this.letters,
    required this.onTap,
    this.onLongPress,
    required this.isDark,
  });

  @override
  State<_DialpadButton> createState() => _DialpadButtonState();
}

class _DialpadButtonState extends State<_DialpadButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isDark
                ? Colors.white.withAlpha(15)
                : Colors.grey.withAlpha(25),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.digit,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (widget.letters.isNotEmpty)
                Text(
                  widget.letters,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark
                        ? Colors.white.withAlpha(120)
                        : customGreyColor600,
                    letterSpacing: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
