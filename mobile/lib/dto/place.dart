class PointDto {
  double lon;
  double lat;

  PointDto(this.lon, this.lat);

  PointDto.fromJson(Map<String, dynamic> json):
    lon = json["longitude"],
    lat = json["latitude"];

  Map<String, dynamic> toJson() => {
    "longitude": lon,
    "latitude": lat,
  };
}

class PlaceDto {
  int id;
  String name;
  String location;
  PointDto position;
  String formattedAddress;
  String imageLink;
  String about;
  String placeType;

  PlaceDto(this.id, this.name, this.location, this.position,
      this.formattedAddress, this.imageLink, this.about, this.placeType);

  PlaceDto.fromJson(Map<String, dynamic> json):
    id = json["id"],
    name = json["name"] ?? "-",
    location = json["location"] ?? "-",
    position = PointDto.fromJson(json["position"]),
    formattedAddress = json["formattedAddress"] ?? "-",
    imageLink = json["imageLink"],
    about = json["about"] ?? "-",
    placeType = json["placeType"];

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "location": location,
    "position": position.toJson(),
    "formattedAddress": formattedAddress,
    "imageLink": imageLink,
    "about": about,
    "placeType": placeType
  };
}