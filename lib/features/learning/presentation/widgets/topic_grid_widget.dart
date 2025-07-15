// lib/features/learning/presentation/widgets/topic_grid_widget.dart - ACTUALIZADO
import 'package:flutter/material.dart';
import '../../domain/entities/topic_entity.dart';
import 'topic_card_widget.dart';

class TopicGridWidget extends StatelessWidget {
  final List<TopicEntity> topics;

  const TopicGridWidget({
    Key? key,
    required this.topics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filtrar solo topics activos
    final activeTopics = topics.where((topic) => topic.isActive).toList();
    
    if (activeTopics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.topic_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay temas disponibles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Conectando con la API de contenido...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: activeTopics.length,
      itemBuilder: (context, index) {
        return TopicCardWidget(
          topic: activeTopics[index],
        );
      },
    );
  }
}