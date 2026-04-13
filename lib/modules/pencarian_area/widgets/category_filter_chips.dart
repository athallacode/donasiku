import 'package:flutter/material.dart';
import '../models/category.dart';
import '../../../theme.dart';

/// Widget filter chips horizontal scrollable untuk kategori donasi
class CategoryFilterChips extends StatelessWidget {
  final Set<DonationCategory> selectedCategories;
  final ValueChanged<DonationCategory> onToggle;
  final VoidCallback onClearAll;

  const CategoryFilterChips({
    super.key,
    required this.selectedCategories,
    required this.onToggle,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAllSelected = selectedCategories.isEmpty;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Chip "Semua" di paling kiri
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: onClearAll,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isAllSelected
                      ? AppTheme.emeraldGreen
                      : AppTheme.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isAllSelected
                        ? AppTheme.emeraldGreen
                        : AppTheme.borderGrey,
                  ),
                  boxShadow: isAllSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.emeraldGreen.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.apps_rounded,
                      size: 17,
                      color: isAllSelected ? Colors.white : AppTheme.textGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Semua',
                      style: AppTheme.labelBold.copyWith(
                        color: isAllSelected ? Colors.white : AppTheme.textDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chip untuk setiap kategori
          ...DonationCategory.values.map((cat) {
            final isSelected = selectedCategories.contains(cat);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onToggle(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.emeraldGreen
                        : AppTheme.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.emeraldGreen
                          : AppTheme.borderGrey,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.emeraldGreen.withAlpha(40),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cat.icon,
                        size: 17,
                        color: isSelected ? Colors.white : cat.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: AppTheme.labelBold.copyWith(
                          color: isSelected ? Colors.white : AppTheme.textDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
