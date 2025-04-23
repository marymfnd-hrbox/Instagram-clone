import 'package:flutter/material.dart';
import 'package:testt/widgets/custom_image.dart';
import 'package:testt/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;

  const PostTile(this.post);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => print("showing posts"),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
