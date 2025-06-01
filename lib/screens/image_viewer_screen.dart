// lib/screens/image_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String? imageName;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    this.imageName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54, // Keep semi-transparent black
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(imageName ?? 'Image', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)), // Use text theme
        centerTitle: true,
        actions: const [],
      ),
      body: Container(
        color: Colors.black, // Keep black background for image viewer
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 1.8,
          initialScale: PhotoViewComputedScale.contained,
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(
              value: event == null
                  ? null
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              color: Theme.of(context).colorScheme.primary, // Use primary color
            ),
          ),
          errorBuilder: (context, error, stackTrace) {
            print('PhotoView error: $error');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 80, color: Theme.of(context).colorScheme.error), // iOS Red
                  Text('Failed to load image', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)), // Use text theme
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}