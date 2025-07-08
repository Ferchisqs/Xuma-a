import 'package:flutter/material.dart';
import '../../domain/entities/challenge_entity.dart';
import 'challenge_card_widget.dart';

class ChallengeGridWidget extends StatelessWidget {
  final List<ChallengeEntity> challenges;
  final bool isRefreshing;

  const ChallengeGridWidget({
    Key? key,
    required this.challenges,
    this.isRefreshing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay desafíos disponibles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        return ChallengeCardWidget(
          challenge: challenges[index],
        );
      },
    );
  }
}