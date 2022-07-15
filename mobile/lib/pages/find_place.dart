import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/place.dart';
import 'package:mobile/services/place.dart';

class FindPlaceWidget extends StatefulWidget {
  const FindPlaceWidget({Key? key}) : super(key: key);

  @override
  State<FindPlaceWidget> createState() => _FindPlaceWidgetState();
}

class _FindPlaceWidgetState extends State<FindPlaceWidget> {
  final placeService = Get.find<PlaceService>();
  final queryController = TextEditingController();
  List<PlaceDto>? results;
  int page = 0;

  loadResults(String text) async {
    final resp = await placeService.search(text, 0);
    setState(() {
      if (!resp.hasError) {
        results = resp.body!;
        page = 0;
      } else {
        log(resp.bodyString ?? "err occurred in find place");
      }
    });
  }

  loadResultsForPage(int npage) async {
    final resp = await placeService.search(queryController.text, npage);
    setState(() {
      if (!resp.hasError) {
        results = resp.body!;
        page = npage;
      } else {
        log(resp.bodyString ?? "err occurred in find place");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
        width: double.maxFinite,
        height: size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: size.width, // take as much width as possible
                child: TextFormField(
                  controller: queryController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Search",
                  ),
                  onChanged: (text) async {
                    if (text == "") {
                      setState(() {
                        results = null;
                        page = 0;
                      });
                    } else {
                      await loadResults(text);
                    }
                  },
                ),
              ),
              if (results != null)
                Flexible(
                  child:

                  SingleChildScrollView(
                    physics: ScrollPhysics(),
                    child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: results!.length,
                        itemBuilder: (context, index) =>
                            buildPlaceMiniTile(context, results![index])),
                  ),
                ),
              ButtonBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    disabledColor: Colors.grey,
                      onPressed: results == null || page <= 0 ? null : () async {
                        if (page > 0) {
                          await loadResultsForPage(page-1);
                        }
                      },
                      color: Colors.blueAccent,
                      icon: const Icon(Icons.arrow_back_ios)
                  ),
                  IconButton(
                      disabledColor: Colors.grey,
                      onPressed: results == null || results!.isEmpty ? null : () async {
                        await loadResultsForPage(page+1);
                      },
                      color: Colors.blueAccent,
                      icon: const Icon(Icons.arrow_forward_ios)
                  ),
                ],
              )
            ],
          ),
        );
  }

  Widget buildPlaceMiniTile(BuildContext context, PlaceDto place) {
    final size = MediaQuery.of(context).size;
    return ListTile(
      onTap: () {
        Navigator.pop(context, place);
      },
      leading: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: size.width * 0.2),
        child: CachedNetworkImage(
          imageUrl: place.imageLink,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(place.name),
      subtitle: Text(
        place.formattedAddress,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: const TextStyle(fontSize: 10.0),
      ),
    );
  }
}
