import 'package:flutter/material.dart';
import '../../../theme.dart';

/// Widget slider untuk mengatur radius pencarian
class RadiusSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const RadiusSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.radar_rounded,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jarak Pencarian',
                    style: AppTheme.labelBold.copyWith(fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()} km',
                  style: AppTheme.labelBold.copyWith(
                    color: AppTheme.primaryBlue,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryBlue,
              inactiveTrackColor: AppTheme.primaryBlue.withAlpha(30),
              thumbColor: AppTheme.primaryBlue,
              overlayColor: AppTheme.primaryBlue.withAlpha(30),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 km', style: AppTheme.bodySmall.copyWith(fontSize: 10)),
                Text('50 km', style: AppTheme.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
