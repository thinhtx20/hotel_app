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
  final String? timeFilterLabel;
  final VoidCallback? onTimeFilterTap;
  final bool canChangeTimeFilter;

  static const double _searchHeight = 46;
  static const double _tabsHeight = 38;

  /// Chiều cao cố định — [SliverStickyHeader] cần biết trước để ghim.
  static const double height = _searchHeight + AppSpacing.md + _tabsHeight;

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
    this.timeFilterLabel,
    this.onTimeFilterTap,
    this.canChangeTimeFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar + Time Filter Chip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: _searchHeight,
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
              if (timeFilterLabel != null) ...[
                const SizedBox(width: AppSpacing.sm),
                PressableScale(
                  onTap: canChangeTimeFilter ? onTimeFilterTap : null,
                  child: Container(
                    height: _searchHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: canChangeTimeFilter ? palette.surface : palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      border: Border.all(
                        color: canChangeTimeFilter ? palette.accent.withValues(alpha: 0.5) : palette.border,
                      ),
                      boxShadow: canChangeTimeFilter && !palette.isDark ? AppShadows.soft : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: canChangeTimeFilter ? palette.accent : palette.inkMuted,
                        ),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 170),
                          child: Text(
                            timeFilterLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: canChangeTimeFilter ? palette.accent : palette.ink,
                            ),
                          ),
                        ),
                        if (canChangeTimeFilter) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down_rounded, size: 16, color: palette.accent),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Pill Tabs
        SizedBox(
          height: _tabsHeight,
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
