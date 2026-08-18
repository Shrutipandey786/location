import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PushToTalkButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onStateChanged;

  const PushToTalkButton({
    super.key,
    this.onPressed,
    this.onStateChanged,
  });

  @override
  State<PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<PushToTalkButton>
    with SingleTickerProviderStateMixin {
  bool _isTalking = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _toggleTalk(bool active) {
    setState(() {
      _isTalking = active;
      if (_isTalking) {
        _waveController.repeat(reverse: true);
      } else {
        _waveController.stop();
      }
    });

    if (widget.onStateChanged != null) {
      widget.onStateChanged!(_isTalking);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _toggleTalk(true),
      onTapUp: (_) => _toggleTalk(false),
      onTapCancel: () => _toggleTalk(false),
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          final scaleWave = 1.0 + (_waveController.value * 0.15);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glowing Wave Rings when talking
              if (_isTalking) ...[
                Transform.scale(
                  scale: scaleWave * 1.3,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryViolet.withOpacity(0.2),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: scaleWave * 1.15,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryIndigo.withOpacity(0.3),
                    ),
                  ),
                ),
              ],

              // Main PTT Intercom Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isTalking
                        ? [AppTheme.statusRed, AppTheme.primaryViolet]
                        : [AppTheme.primaryIndigo, AppTheme.primaryViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isTalking ? AppTheme.statusRed : AppTheme.primaryIndigo)
                          .withOpacity(0.5),
                      blurRadius: _isTalking ? 24 : 12,
                      spreadRadius: _isTalking ? 4 : 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isTalking ? Icons.graphic_eq : Icons.mic,
                      color: Colors.white,
                      size: 42,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isTalking ? "TALKING..." : "HOLD TO TALK",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AudioWaveformPainter extends StatelessWidget {
  final List<double> values;
  final Color color;

  const AudioWaveformPainter({
    super.key,
    required this.values,
    this.color = AppTheme.primaryIndigo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: values.map((v) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: math.max(4.0, 24.0 * v),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}
