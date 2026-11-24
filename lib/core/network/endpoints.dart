/// API paths in one place, so mock and remote datasources stay in sync.
abstract class Endpoints {
  static const String courses = '/courses';

  static String courseById(String id) => '/courses/$id';
}
