import 'package:flutter/material.dart';

class ImageSelectionScreen extends StatelessWidget {
  final Function(String path) onImageSelected;

  const ImageSelectionScreen({super.key, required this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    final storeImages = [
      'images/Aldi.png',
      'images/Netto.png',
      'images/Penny.png',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Store'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemCount: storeImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onImageSelected(storeImages[index]),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(storeImages[index]),
            ),
          );
        },
      ),
    );
  }
}
