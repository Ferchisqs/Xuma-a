import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showDrawerButton;
  final VoidCallback? onBackPressed;

  final bool showEcoTip;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showDrawerButton = false,
    this.onBackPressed,
    this.showEcoTip = false, // ✅ Valor por defecto
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.earthGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: showDrawerButton,
        leading: leading ??
            (showDrawerButton
                ? null
                : (Navigator.of(context).canPop()
                    ? IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                        ),
                        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                      )
                    : null)),
        title: Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (showEcoTip)
            IconButton(
              icon: const Icon(Icons.eco, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tip ecológico: Reduce, reusa, recicla.'),
                  ),
                );
              },
            ),
          if (actions != null) ...actions!,
        ],
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
