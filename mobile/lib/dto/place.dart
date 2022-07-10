enum PlaceType{
  attraction("attraction"),
  restaurant("restaurant");

  const PlaceType(this.text);
  final String text;

  factory PlaceType.fromJson(String v) {
    return values.firstWhere((e) => e.text == v);
  }
}

class Point {
  double latitude;
  double longitude;
  Point(this.longitude, this.latitude);
  Point.fromJson(Map<String, dynamic> json)
      :  latitude = json["latitude"],
        longitude = json["longitude"];
  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude
  };
}

class PlaceDto {
  int id;
  String name;
  String about;
  String formattedAddress;
  String imageLink;
  String location;
  PlaceType placeType;
  Point position;


  PlaceDto(this.id,
    this.name,
    this.about,
    this.formattedAddress,
    this.imageLink,
    this.location,
    this.placeType,
    this.position);

  PlaceDto.fromJson(Map<String, dynamic> json) :
      id = json["id"],
      name = json["name"],
      about = json["about"],
      formattedAddress = json["formattedAddress"],
      imageLink = json["imageLink"],
      location = json["location"],
      placeType = PlaceType.fromJson(json["placeType"]),
      position = Point.fromJson(json["position"]);

}