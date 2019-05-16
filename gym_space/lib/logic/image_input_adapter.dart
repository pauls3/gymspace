import 'dart:io';

import 'package:GymSpace/global.dart';
import 'package:flutter/material.dart';

class ImageInputAdapter {
  final File imageFile;
  final String photoURL;

  ImageInputAdapter({
    this.imageFile,
    this.photoURL
  });

  Widget toImageWidget() {
    if (imageFile != null ) 
      return Image.file(imageFile);
    else {
      return FadeInImage(
        image: NetworkImage(photoURL),
        placeholder: AssetImage(Defaults.userPhoto),
        fit: BoxFit.contain,
      );
    }
  }
} 