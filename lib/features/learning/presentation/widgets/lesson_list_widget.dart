import 'package:flutter/material.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import 'lesson_item_widget.dart';

class LessonListWidget extends StatelessWidget {
  final List<LessonEntity> lessons;
  final CategoryEntity category;

  const LessonListWidget({
    Key? key,
    required this.lessons,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron lecciones',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: lessons.map((lesson) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LessonItemWidget(
            lesson: lesson,
            category: category,
          ),
        );
      }).toList(),
    );
  }
}
