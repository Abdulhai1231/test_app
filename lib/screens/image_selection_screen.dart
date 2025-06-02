import 'package:flutter/material.dart';

class ImageSelectionScreen extends StatelessWidget {
  const ImageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Zugriff auf das aktuelle Theme für konsistente Styles
    final theme = Theme.of(context);
    
    // Liste mit den Pfaden zu den Shop-Logos
    final storeImages = [
      'images/Aldi.png',
      'images/Netto.png',
      'images/Penny.png',
      'images/Rewe.png',
      'images/Lidl.png',
      'images/Kaufland.png',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Store'), // Titel der Seite
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Überschrift
            Text(
              'Choose a store logo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Untertitel / Erklärungstext
            Text(
              'This will help identify your shopping list',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            // Grid mit den Store-Logos
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 Logos pro Zeile
                  childAspectRatio: 1, // quadratische Zellen
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: storeImages.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      // Bei Tippen wird die Auswahl zurückgegeben und die Seite geschlossen
                      onTap: () => Navigator.pop(context, storeImages[index]),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(storeImages[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
