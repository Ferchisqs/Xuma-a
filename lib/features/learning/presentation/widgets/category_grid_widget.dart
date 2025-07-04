import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCardWidget(
          category: categories[index],
          onTap: () {
            Navigator.pushNamed(
              context,
              '/lesson-list',
              arguments: categories[index],
            );
          },
        );
      },
    );
  }
}