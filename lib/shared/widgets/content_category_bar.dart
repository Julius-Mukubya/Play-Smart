import 'package:flutter/material.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/shared/types/domain_types.dart';

class ContentCategoryItem {
  final String label;
  final IconData icon;
  final ContentType? contentType;
  final MomentType? momentTag;

  const ContentCategoryItem({
    required this.label,
    required this.icon,
    this.contentType,
    this.momentTag,
  });
}

/// Category and moment filter bar matching the search athletes pill style.
class ContentCategoryBar extends StatefulWidget {
  final Function(ContentType? type, MomentType? moment) onFilterChanged;
  final ContentType? selectedType;
  final MomentType? selectedMoment;

  const ContentCategoryBar({
    super.key,
    required this.onFilterChanged,
    this.selectedType,
    this.selectedMoment,
  });

  @override
  State<ContentCategoryBar> createState() => _ContentCategoryBarState();
}

class _ContentCategoryBarState extends State<ContentCategoryBar> {
  static const List<ContentCategoryItem> _items = [
    ContentCategoryItem(label: 'All', icon: Icons.auto_awesome),
    ContentCategoryItem(label: 'Videos', icon: Icons.videocam_rounded, contentType: ContentType.video),
    ContentCategoryItem(label: 'Photos', icon: Icons.photo_library_rounded, contentType: ContentType.photo),
    ContentCategoryItem(label: 'Posts', icon: Icons.article_rounded, contentType: ContentType.post),
    ContentCategoryItem(label: 'Goals', icon: Icons.sports_soccer_rounded, momentTag: MomentType.goal),
    ContentCategoryItem(label: 'Assists', icon: Icons.handshake_outlined, momentTag: MomentType.assist),
    ContentCategoryItem(label: 'Saves', icon: Icons.front_hand_outlined, momentTag: MomentType.save),
    ContentCategoryItem(label: 'Tackles', icon: Icons.shield_outlined, momentTag: MomentType.tackle),
    ContentCategoryItem(label: 'Sprints', icon: Icons.directions_run_rounded, momentTag: MomentType.sprint),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = _items[i];
          final active = _selectedIndex == i;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = i);
              widget.onFilterChanged(item.contentType, item.momentTag);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accentPrimary
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: active
                      ? AppColors.accentPrimary
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
