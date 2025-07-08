import 'package:equatable/equatable.dart';

enum AnimationType {
  idle,
  blink,
  happy,
  eating,
  loving,
  sleeping,
  excited
}

class CompanionAnimationEntity extends Equatable {
  final AnimationType type;
  final List<String> frames; // Rutas de las imágenes
  final int duration; // milisegundos
  final bool loop;

  const CompanionAnimationEntity({
    required this.type,
    required this.frames,
    required this.duration,
    required this.loop,
  });

  @override
  List<Object> get props => [type, frames, duration, loop];
}