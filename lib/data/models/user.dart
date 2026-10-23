import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Автор постов. Содержит вложенные модели Address (с Geo) и Company.
/// explicitToJson: true — вложенные объекты тоже превращаются в JSON.
@JsonSerializable(checked: true, explicitToJson: true)
class User {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String? phone;
  final String? website;
  final Address? address;
  final Company? company;

  const User({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(checked: true, explicitToJson: true)
class Address {
  final String? street;
  final String? suite;
  final String? city;
  final String? zipcode;
  final Geo? geo;

  const Address({this.street, this.suite, this.city, this.zipcode, this.geo});

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable(checked: true)
class Geo {
  final String? lat;
  final String? lng;

  const Geo({this.lat, this.lng});

  factory Geo.fromJson(Map<String, dynamic> json) => _$GeoFromJson(json);

  Map<String, dynamic> toJson() => _$GeoToJson(this);
}

@JsonSerializable(checked: true)
class Company {
  final String name;
  final String? catchPhrase;

  const Company({required this.name, this.catchPhrase});

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);

  Map<String, dynamic> toJson() => _$CompanyToJson(this);
}
