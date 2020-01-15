import 'dart:convert';

/// Object holding authentication information of the currently logged in user.
class AuthInfo {
  final AuthInfoUser user;
  final AuthInfoSubUser sub_user; // ignore: non_constant_identifier_names
  final bool valid_password; // ignore: non_constant_identifier_names
  final String token;
  final String token_type; // ignore: non_constant_identifier_names
  final String expires_at; // ignore: non_constant_identifier_names
  final Map<String, bool> features;

  AuthInfo(this.user, this.sub_user, this.valid_password, this.token,
      this.token_type, this.expires_at, this.features);

  static AuthInfo fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> rawUser = json['user'];
    Map<String, dynamic> rawSubUser = json['sub_user'];

    // NOTE: some accounts are broken and have a stringified json instead of an object for `features`
    // for now, we just clear features in this case
    if (json["features"] != null && json["features"] is String) {
      json["features"] = null;
    }

    // NOTE: we have to do casting here, as every complex value of json is going to include `dynamic`, which leads to errors
    // e.g. `user["scopes"].runtimeType == List<dynamic>`. Unfortunately, Dart doesn't cast automatically in non-safe circumstances

    AuthInfoUser user = AuthInfoUser(
      rawUser["id"],
      rawUser["name"],
      rawUser["legacy_id"],
      rawUser["scopes"]?.cast<String>(),
      rawUser["role"],
    );

    AuthInfoSubUser subUser;
    if (rawSubUser != null) {
      subUser = AuthInfoSubUser(
        rawSubUser["id"],
        rawSubUser["name"],
        rawSubUser["username"],
        rawSubUser["user_id"],
        rawSubUser["scopes"]?.cast<String>(),
        rawSubUser["role"],
      );
    }

    return AuthInfo(
        user,
        subUser,
        json["valid_password"],
        json["token"],
        json["token_type"],
        json["expires_at"],
        json["features"]?.cast<String, bool>());
  }

  Map<String, dynamic> toJson() {
    return {
      "user": user.toJson(),
      "sub_user": sub_user?.toJson(),
      "valid_password": valid_password,
      "token": token,
      "token_type": token_type,
      "expires_at": expires_at,
      "features": features
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

/// Object holding information of the currently logged in user.
class AuthInfoUser {
  final String id;
  final String name;
  final String legacy_id; // ignore: non_constant_identifier_names
  final List<String> scopes;
  final String role;

  AuthInfoUser(this.id, this.name, this.legacy_id, this.scopes, this.role);

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "legacy_id": legacy_id,
        "scopes": scopes,
        "role": role
      };
}

/// Object holding information of the currently logged in sub user (e.g. when using org login).
class AuthInfoSubUser {
  final String id;
  final String name;
  final String username;
  final String user_id; // ignore: non_constant_identifier_names
  final List<String> scopes;
  final String role;

  AuthInfoSubUser(
      this.id, this.name, this.username, this.user_id, this.scopes, this.role);

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "username": username,
        "user_id": user_id,
        "scopes": scopes,
        "role": role,
      };

  @override
  String toString() => jsonEncode(toJson());
}
