import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/place_profile_page.dart';
import 'package:mobile/widgets/place_image.dart';

import '../dto/place.dart';

/// Dialog widget shown when the user presses the Suggest button
/// in the create_outing_page and a list of places are passed to
/// the widget. When the dialog is closed, it returns the selected
/// place dto.
class RecommenderDialog extends StatelessWidget {

  final List<PlaceDto> places;

  const RecommenderDialog({
    Key? key,
    required this.places
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    for(int i = 0; i < places.length; i++) {
      print(places[i]);
    }
    return AlertDialog(
      title: const Text("Here are the best places for you!"),
      content: Container(
        height: size.height / 2,
        width: size.width / 2,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: places.length,
            itemBuilder: (context, index) => buildSuggestedPlaceListTile(context, places[index])
          ),
        ),
      );
  }

  Widget buildSuggestedPlaceListTile(BuildContext context, PlaceDto place) {
    return Card(
      elevation: 8.0,
      child: ListTile(
        title: InkWell(
          onTap: () {
            Get.to(() => PlaceProfilePage(place: place));
          },
          child: Column(
            children: <Widget>[
              PlaceImage(imageLink: place.imageLink),
              Text(place.name),
            ],
          ),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, place);
          },
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          label: const Text("Choose")
        ),
      ),
    );
  }
}

