abstract class Either<L, R> {
  const Either();
  
  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;
  
  T fold<T>(T Function(L) leftFunction, T Function(R) rightFunction);
  
  R? get right => isRight ? (this as Right<L, R>).value : null;
  L? get left => isLeft ? (this as Left<L, R>).value : null;
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
  
  @override
  T fold<T>(T Function(L) leftFunction, T Function(R) rightFunction) {
    return leftFunction(value);
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Left && runtimeType == other.runtimeType && value == other.value;
  
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => 'Left($value)';
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
  
  @override
  T fold<T>(T Function(L) leftFunction, T Function(R) rightFunction) {
    return rightFunction(value);
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Right && runtimeType == other.runtimeType && value == other.value;
  
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => 'Right($value)';
}