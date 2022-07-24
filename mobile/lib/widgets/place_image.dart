import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PlaceImage extends StatelessWidget {

  String imageLink;

  PlaceImage({Key? key, required this.imageLink}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (imageLink.startsWith("data:")) {
      final _byteImage = Base64Decoder().convert(imageLink.split(',').last);
      image = Image.memory(_byteImage);
    } else {
      image =  CachedNetworkImage(
        imageUrl: imageLink,
        fit: BoxFit.cover,
      );
    }
    return image;
  }

}