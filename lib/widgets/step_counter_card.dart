// lib/widgets/step_counter_card.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/fitgenie_theme.dart';
import '../services/step_counter_service.dart';


class StepCounterCard extends StatefulWidget {
  final String userId;
  final int stepsGoal;
  final double userWeight;

  const StepCounterCard({
    super.key,
    required this.userId,
    this.stepsGoal = 10000,
    this.userWeight = 70,
  });

  @override
  State<StepCounterCard> createState() => _StepCounterCardState();
}

class _StepCounterCardState extends State<StepCounterCard>
    with SingleTickerProviderStateMixin {
  final StepCounterService _stepService = StepCounterService();

  int _steps = 0;
  double _calories = 0;
  double _distance = 0;
  int _activeMinutes = 0;
  String _status = 'unknown';
  bool _isInitialized = false;
  bool _hasPermission = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initializeStepCounter();
  }

  Future<void> _initializeStepCounter() async {
    final success = await _stepService.initialize(widget.userId);

    if (success) {
      _stepService.onStepsChanged = (steps) {
        if (mounted) {
          setState(() {
            _steps = steps;
            _updateStats();
          });
        }
      };

      _stepService.onStatusChanged = (status) {
        if (mounted) {
          setState(() => _status = status);
        }
      };

      setState(() {
        _isInitialized = true;
        _steps = _stepService.todaySteps;
        _updateStats();
      });
    } else {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  void _updateStats() {
    final stats = _stepService.getStats(weightKg: widget.userWeight);
    _calories = stats['calories'];
    _distance = stats['distance'];
    _activeMinutes = stats['activeMinutes'];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.stepsGoal > 0
        ? (_steps / widget.stepsGoal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: FitGenieTheme.primary.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: FitGenieTheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FitGenieTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_walk,
                  color: FitGenieTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step Counter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        _buildStatusIndicator(),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_hasPermission)
                IconButton(
                  icon: const Icon(Icons.warning, color: Colors.orange),
                  onPressed: _requestPermission,
                  tooltip: 'Enable Permission',
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Circular Progress with Steps
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              children: [
                // Background Circle
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _StepProgressPainter(
                    progress: progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    progressColor: FitGenieTheme.primary,
                    strokeWidth: 12,
                  ),
                ),
                // Center Content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Walking Icon Animation
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              _status == 'walking'
                                  ? math.sin(_animationController.value * 2 * math.pi) * 3
                                  : 0,
                            ),
                            child: Icon(
                              _status == 'walking'
                                  ? Icons.directions_walk
                                  : Icons.accessibility_new,
                              color: FitGenieTheme.primary,
                              size: 28,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Steps Count
                      Text(
                        _formatNumber(_steps),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'of ${_formatNumber(widget.stepsGoal)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.local_fire_department,
                value: '${_calories.round()}',
                label: 'kcal',
                color: Colors.orange,
              ),
              _buildDivider(),
              _buildStatItem(
                icon: Icons.straighten,
                value: _distance.toStringAsFixed(1),
                label: 'km',
                color: Colors.blue,
              ),
              _buildDivider(),
              _buildStatItem(
                icon: Icons.timer,
                value: '$_activeMinutes',
                label: 'min',
                color: Colors.purple,
              ),
            ],
          ),

          // Progress Text
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: progress >= 1.0
                  ? Colors.green.withOpacity(0.2)
                  : FitGenieTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              progress >= 1.0
                  ? '🎉 Goal Achieved! Great job!'
                  : '${(progress * 100).toInt()}% of daily goal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: progress >= 1.0 ? Colors.green : FitGenieTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final opacity = _status == 'walking'
            ? 0.5 + 0.5 * math.sin(_animationController.value * 2 * math.pi)
            : 1.0;

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _getStatusText() {
    if (!_hasPermission) return 'Permission needed';
    if (!_isInitialized) return 'Initializing...';

    switch (_status) {
      case 'walking':
        return 'Walking';
      case 'stopped':
        return 'Idle';
      default:
        return 'Tracking';
    }
  }

  Color _getStatusColor() {
    if (!_hasPermission) return Colors.orange;
    if (!_isInitialized) return Colors.grey;

    switch (_status) {
      case 'walking':
        return Colors.green;
      case 'stopped':
        return Colors.grey;
      default:
        return FitGenieTheme.primary;
    }
  }

  Future<void> _requestPermission() async {
    final success = await _stepService.initialize(widget.userId);
    if (success) {
      setState(() {
        _hasPermission = true;
        _isInitialized = true;
      });
    }
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.1),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return number.toString();
  }
}

// ============ CUSTOM PAINTER FOR PROGRESS RING ============

class _StepProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _StepProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        colors: [
          progressColor.withOpacity(0.6),
          progressColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StepProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}