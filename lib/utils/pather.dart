/// Small helper class that can generate url paths pointing to a remote resource.
///
/// Mostly used by [BaseRoute] and its subclasses.
class Pather {
  /// API version string, e.g. 'v0' or 'v1'
  String version;

  /// target resource type, e.g. 'devices' or 'products'
  String type;

  /// account id of the currently logged in user
  String userId;

  Pather(this.version, this.type, [this.userId]);

  /// Creates a (relative) URL path pointing to the resource matching the given [id].
  String path([String id]) {
    // relative url
    String p = '/api/$version/$type';

    // userId part
    if (userId != null) p += '/$userId';

    // TODO: make function more generic, e.g. take 'suffix' instead of id
    // id part
    if (id != null) p += '/$id';

    return p;
  }
}
