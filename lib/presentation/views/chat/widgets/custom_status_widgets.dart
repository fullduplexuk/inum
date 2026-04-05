import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/core/services/custom_status_service.dart';
import 'package:inum/presentation/blocs/custom_status/custom_status_cubit.dart';
import 'package:inum/presentation/design_system/colors.dart';

/// Custom status section for the profile view.
class CustomStatusSection extends StatefulWidget {
  const CustomStatusSection({super.key});

  @override
  State<CustomStatusSection> createState() => _CustomStatusSectionState();
}

class _CustomStatusSectionState extends State<CustomStatusSection> {
  final _textController = TextEditingController();
  String _selectedEmojiName = 'office';
  String _selectedEmoji = '\u{1F3E2}';
  StatusExpiryOption _selectedExpiry = StatusExpiryOption.dontClear;
  bool _showForm = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _setStatus() {
    if (_textController.text.trim().isEmpty) return;
    context.read<CustomStatusCubit>().setStatus(
          emojiName: _selectedEmojiName,
          text: _textController.text.trim(),
          expiry: _selectedExpiry,
        );
    _textController.clear();
    setState(() => _showForm = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomStatusCubit, CustomStatusState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom Status',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Current status display
            if (state.currentStatus != null && !state.currentStatus!.isExpired)
              _CurrentStatusCard(
                status: state.currentStatus!,
                onClear: () => context.read<CustomStatusCubit>().clearStatus(),
              ),

            // Confetti animation when status is just set
            if (state.justSet) const _ConfettiOverlay(),

            // Quick presets
            const SizedBox(height: 8),
            const Text(
              'Quick set:',
              style: TextStyle(fontSize: 13, color: customGreyColor600),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kStatusPresets.map((preset) {
                return ActionChip(
                  avatar: Text(preset.emoji, style: const TextStyle(fontSize: 16)),
                  label: Text(preset.text, style: const TextStyle(fontSize: 12)),
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<CustomStatusCubit>().setPreset(preset),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Toggle custom form
            TextButton.icon(
              onPressed: () => setState(() => _showForm = !_showForm),
              icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
              label: Text(_showForm ? 'Cancel' : 'Set custom status'),
            ),

            // Custom status form
            if (_showForm) ...[
              const SizedBox(height: 8),
              _buildEmojiPicker(),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'What is your status?',
                  prefixText: '$_selectedEmoji ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              _buildExpiryPicker(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _setStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inumPrimary,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: white,
                          ),
                        )
                      : const Text('Set Status'),
                ),
              ),
            ],

            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: errorColor, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmojiPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kStatusEmojis.map((e) {
        final isSelected = e['name'] == _selectedEmojiName;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedEmojiName = e['name']!;
              _selectedEmoji = e['emoji']!;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? inumPrimary.withAlpha(30) : transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: inumPrimary, width: 2)
                  : Border.all(color: customGreyColor300),
            ),
            alignment: Alignment.center,
            child: Text(e['emoji']!, style: const TextStyle(fontSize: 20)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpiryPicker() {
    return DropdownButtonFormField<StatusExpiryOption>(
      value: _selectedExpiry,
      decoration: InputDecoration(
        labelText: 'Clear after',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: StatusExpiryOption.values.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option.label),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedExpiry = val);
      },
    );
  }
}

/// Card showing the current custom status with clear button.
class _CurrentStatusCard extends StatelessWidget {
  final CustomStatus status;
  final VoidCallback onClear;

  const _CurrentStatusCard({
    required this.status,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inumSecondary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inumSecondary.withAlpha(40)),
      ),
      child: Row(
        children: [
          Text(status.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (status.remainingTimeText != null)
                  Text(
                    status.remainingTimeText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: customGreyColor600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
            tooltip: 'Clear status',
          ),
        ],
      ),
    );
  }
}

/// Confetti-like particle burst animation.
class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _particles = List.generate(20, (_) {
      return _Particle(
        x: _random.nextDouble() * 2 - 1,
        y: -_random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 3,
        vy: _random.nextDouble() * -4 - 2,
        color: [
          inumPrimary,
          inumSecondary,
          customOrangeColor,
          successColor,
          Colors.purple,
        ][_random.nextInt(5)],
        size: _random.nextDouble() * 6 + 3,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: const Size(double.infinity, 60),
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x, y, vx, vy, size;
  final Color color;
  const _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = progress;
      final x = size.width / 2 + (p.x + p.vx * t) * size.width / 4;
      final y = size.height / 2 + (p.y + p.vy * t + 5 * t * t) * 20;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withAlpha((opacity * 255).round());
      canvas.drawCircle(Offset(x, y), p.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

/// Inline status display for channel list / chat header.
class CustomStatusInline extends StatelessWidget {
  final CustomStatus? status;
  final bool showExpiry;
  final double fontSize;

  const CustomStatusInline({
    super.key,
    this.status,
    this.showExpiry = false,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (status == null || status!.isExpired) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(status!.emoji, style: TextStyle(fontSize: fontSize)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            status!.text,
            style: TextStyle(fontSize: fontSize, color: customGreyColor600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showExpiry && status!.remainingTimeText != null) ...[
          Text(
            ' \u{00B7} ${status!.remainingTimeText}',
            style: TextStyle(fontSize: fontSize - 1, color: customGreyColor500),
          ),
        ],
      ],
    );
  }
}
