import 'package:flutter/material.dart';
import 'image_viewer_dialog.dart';

class RichTextContent extends StatelessWidget {
  final String content;

  const RichTextContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // Simple image URL regex pattern
    final imageUrlPattern = RegExp(
      r'https?://[^\s]+\.(?:png|jpg|jpeg|gif|webp)(?:\?[^\s]*)?',
      caseSensitive: false,
    );

    final matches = imageUrlPattern.allMatches(content);

    if (matches.isEmpty) {
      // No images found, just return text
      return Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Color(0xFF2c3e50),
        ),
      );
    }

    // Split content by image URLs and create widgets
    final widgets = <Widget>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before the image
      if (match.start > lastEnd) {
        final textBefore = content.substring(lastEnd, match.start);
        if (textBefore.isNotEmpty) {
          widgets.add(
            Text(
              textBefore,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF2c3e50),
              ),
            ),
          );
        }
      }

      // Add the image
      final imageUrl = match.group(0)!;
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GestureDetector(
            onTap: () =>
                ImageViewerDialog.show(context, imageUrl, title: 'Image'),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: 300,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey.shade400,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text after the last image
    if (lastEnd < content.length) {
      final remainingText = content.substring(lastEnd);
      if (remainingText.isNotEmpty) {
        widgets.add(
          Text(
            remainingText,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF2c3e50),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
