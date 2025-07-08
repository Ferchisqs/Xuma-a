import 'package:flutter/material.dart';
import '../../domain/entities/trivia_category_entity.dart';
import 'trivia_category_card.dart';

class TriviaCategoryGrid extends StatelessWidget {
  final List<TriviaCategoryEntity> categories;

  const TriviaCategoryGrid({
    Key? key,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return TriviaCategoryCard(category: categories[index]);
      },
    );
  }
}