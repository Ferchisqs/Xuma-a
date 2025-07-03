import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showDrawerButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showDrawerButton = false,
    this.onBackPressed,
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
        // 🔄 ARREGLAR LEADING - usar automáticamente el drawer del Scaffold
        automaticallyImplyLeading: showDrawerButton, // 🆕 Esto hace que funcione automáticamente
        leading: leading ??
            (showDrawerButton
                ? null // 🔄 Dejar que Flutter maneje automáticamente el drawer
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
        actions: actions,
        iconTheme: const IconThemeData(
          color: Colors.white, // 🆕 Asegurar que el ícono del drawer sea blanco
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}