import 'package:cached_network_image/cached_network_image.dart';
import 'package:flashmsg/const.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewPage extends StatelessWidget {
  final String photoUrl;

  const PhotoViewPage({Key key, this.photoUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
          heroTag: photoUrl,
          imageProvider: CachedNetworkImageProvider(photoUrl),
          loadingChild: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
          ),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2.0,
          transitionOnUserGestures: true,
        )
    );
  }

}