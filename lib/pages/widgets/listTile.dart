import 'package:flutter/material.dart';
import 'package:inhabit_realties/constants/contants.dart';

class DrawerListTile extends StatefulWidget {
  final String path;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const DrawerListTile({
    super.key,
    required this.path,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  State<DrawerListTile> createState() => _DrawerListTileState();
}

class _DrawerListTileState extends State<DrawerListTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkWhiteText : AppColors.lightDarkText;
    final brandColor =
        isDark ? AppColors.brandSecondary : AppColors.brandPrimary;
    final isLogout = widget.path == '/auth/logout';
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == widget.path;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected || isHovered
              ? (isDark
                  ? brandColor.withOpacity(0.1)
                  : brandColor.withOpacity(0.05))
              : Colors.transparent,
        ),
        child: ListTile(
          onTap: () {
            if (currentRoute != widget.path) {
              Navigator.pushNamed(context, widget.path);
            }
          },
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(
            widget.icon,
            color: isLogout
                ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                : (isSelected || isHovered
                    ? brandColor
                    : textColor.withOpacity(0.8)),
            size: 22,
          ),
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isLogout
                      ? (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                      : (isSelected || isHovered ? brandColor : textColor),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
          subtitle: widget.subtitle != null
              ? Text(
                  widget.subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withOpacity(0.6),
                        fontSize: 10,
                      ),
                )
              : null,
          trailing: widget.trailing,
        ),
      ),
    );
  }
}
