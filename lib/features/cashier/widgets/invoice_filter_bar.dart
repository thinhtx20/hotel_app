import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

class InvoiceFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final List<String> tabs;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final int Function(int tabIndex) getTabCount;

  const InvoiceFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.tabs,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.getTabCount,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: palette.border),
              boxShadow: palette.isDark ? null : AppShadows.soft,
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(fontSize: 13, color: palette.ink),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã HĐ, tên khách, số phòng...',
                hintStyle: TextStyle(fontSize: 13, color: palette.inkFaint),
                prefixIcon: Icon(Icons.search_rounded, color: palette.inkMuted, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: palette.inkMuted),
                        onPressed: onSearchClear,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Pill Tabs
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, idx) {
              final title = tabs[idx];
              final isSelected = idx == selectedTabIndex;
              final count = getTabCount(idx);

              return PressableScale(
                onTap: () => onTabSelected(idx),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.gold : null,
                    color: isSelected ? null : palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: isSelected ? null : Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : palette.inkMuted,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          height: 20,
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : palette.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected ? AppColors.secondary : palette.inkMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
