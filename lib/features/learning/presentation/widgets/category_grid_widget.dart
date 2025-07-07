import 'package:flutter/material.dart';
import '../../domain/entities/category_entity.dart';
import 'category_card_widget.dart';

class CategoryGridWidget extends StatelessWidget {
  final List<CategoryEntity> categories;

  const CategoryGridWidget({
    Key? key,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🔄 Grid normal con altura fija para prevenir overflow
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // 🔄 Ratio ajustado para altura fija
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCardWidget(
          category: categories[index],
        );
      },
    );
  }
}