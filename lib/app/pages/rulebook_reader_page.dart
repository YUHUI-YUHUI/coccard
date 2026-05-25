import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class RulebookReaderPage extends StatelessWidget {
  const RulebookReaderPage({super.key});

  static const assetPath =
      'assets/reference/coc7_keeper_rulebook_v2002.pdf';
  static const fileName = 'coc7_keeper_rulebook_v2002.pdf';

  Future<Uint8List> _loadPdf(PdfPageFormat _) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('守秘人规则书'),
      ),
      body: PdfPreview.builder(
        build: _loadPdf,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: fileName,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        pagesBuilder: (context, pages) => _RulebookPageView(pages: pages),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  '规则书加载失败',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RulebookPageView extends StatefulWidget {
  const _RulebookPageView({required this.pages});

  final List<PdfPreviewPageData> pages;

  @override
  State<_RulebookPageView> createState() => _RulebookPageViewState();
}

class _RulebookPageViewState extends State<_RulebookPageView> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageCount = widget.pages.length;
    if (pageCount == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayPage = (_currentPage + 1).clamp(1, pageCount).toInt();

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: pageCount,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemBuilder: (context, index) {
            final page = widget.pages[index];
            return Padding(
              padding: const EdgeInsets.all(12),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: page.aspectRatio,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image(image: page.image, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Card(
            color: colorScheme.surface.withOpacity(0.94),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage == 0
                        ? null
                        : () => _goToPage(_currentPage - 1),
                  ),
                  Expanded(
                    child: Text(
                      '$displayPage / $pageCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage >= pageCount - 1
                        ? null
                        : () => _goToPage(_currentPage + 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}
