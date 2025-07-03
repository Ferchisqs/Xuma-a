import 'package:equatable/equatable.dart';
import '../errors/failures.dart';
import '../utils/either.dart';

// Base use case with parameters
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Use case without parameters
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

// No parameters class
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}