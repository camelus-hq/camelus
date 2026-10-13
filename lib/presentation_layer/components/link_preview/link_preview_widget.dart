import 'package:material_ui/material_ui.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinkPreviewWidget extends ConsumerWidget {
  const LinkPreviewWidget({
    super.key,
    required double fontSize,
    required this.url,
  }) : _fontSize = fontSize;

  final double _fontSize;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LinkPreview(
      insidePadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 18),
      //outsidePadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      sideBorderWidth: 0,
      onLinkPreviewDataFetched: (data) {},
      titleTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: _fontSize - 2,
        decoration: TextDecoration.none,
      ),
      enableAnimation: true,

      text: url,
      descriptionTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: _fontSize - 4,
        decoration: TextDecoration.none,
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,

      maxWidth: MediaQuery.of(context).size.width,

      hideImage: false,
      imageBuilder: (imageUrl) {
        return Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
