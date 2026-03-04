import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class SkillRating {
  final double clearExplanation;
  final double patient;
  final double wellPrepared;
  final double helpful;
  final double fun;

  const SkillRating({
    this.clearExplanation = 0,
    this.patient = 0,
    this.wellPrepared = 0,
    this.helpful = 0,
    this.fun = 0,
  });

  double get average =>
      (clearExplanation + patient + wellPrepared + helpful + fun) / 5;

  List<double> get values => [clearExplanation, patient, wellPrepared, helpful, fun];
}

class SkillRadarChart extends StatelessWidget {
  final SkillRating rating;
  final double size;
  final bool showLabels;
  final bool interactive;

  const SkillRadarChart({
    super.key,
    required this.rating,
    this.size = 200,
    this.showLabels = true,
    this.interactive = false,
  });

  static const List<String> labels = [
    'Clear\nExplanation',
    'Patient',
    'Well\nPrepared',
    'Helpful',
    'Fun',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          radarBorderData: const BorderSide(color: AppColors.radarGrid, width: 1),
          gridBorderData: const BorderSide(color: AppColors.radarGrid, width: 1),
          tickBorderData: const BorderSide(color: Colors.transparent),
          tickCount: 5,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
          titleTextStyle: AppTypography.bodySmall.copyWith(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
          titlePositionPercentageOffset: 0.2,
          getTitle: (index, angle) {
            if (!showLabels) return RadarChartTitle(text: '');
            return RadarChartTitle(
              text: labels[index],
              angle: 0,
            );
          },
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.radarFill,
              borderColor: AppColors.radarBorder,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: rating.values
                  .map((value) => RadarEntry(value: value))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SkillRadarWithLabels extends StatelessWidget {
  final SkillRating rating;
  final double size;

  const SkillRadarWithLabels({
    super.key,
    required this.rating,
    this.size = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkillRadarChart(
          rating: rating,
          size: size,
          showLabels: true,
        ),
      ],
    );
  }
}
