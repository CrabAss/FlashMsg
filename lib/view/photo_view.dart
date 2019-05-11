import 'package:cached_network_image/cached_network_image.dart';
import 'package:flashmsg/config/const.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewScreen extends StatelessWidget {
  final String photoUrl;

  const PhotoViewScreen({Key key, this.photoUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
          heroTag: photoUrl,
          imageProvider: CachedNetworkImageProvider(photoUrl),
          loadingChild: Container(
            child: Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor)
              ),
            ),
          ),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.0,
          transitionOnUserGestures: true,
        )
    );
  }

}