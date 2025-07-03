import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/nav_item_entity.dart';

abstract class NavigationRepository {
  Future<Either<Failure, List<NavItemEntity>>> getNavItems();
  Future<Either<Failure, bool>> updateCurrentPage(String route);
}