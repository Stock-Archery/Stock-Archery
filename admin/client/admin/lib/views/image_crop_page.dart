import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Free-form crop screen: drag any corner/edge to crop whatever
/// size and aspect ratio you want. No fixed ratios.
class ImageCropPage extends StatefulWidget {
  final File imageFile;

  const ImageCropPage({super.key, required this.imageFile});

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  final _controller = CropController();
  late final Future<Uint8List> _imageBytes;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageFile.readAsBytes();
  }

  void _handleCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final out = File(
            '${Directory.systemTemp.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await out.writeAsBytes(croppedImage);
          if (mounted) Navigator.pop(context, out);
        } catch (_) {
          if (mounted) Navigator.pop(context, null);
        }
      case CropFailure():
        if (!mounted) return;
        setState(() => _cropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crop failed, please try again')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Crop image',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cropping
                ? null
                : () {
                    setState(() => _cropping = true);
                    _controller.crop();
                  },
            child: Text(
              'Done',
              style: GoogleFonts.outfit(
                color: const Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Drag any corner or edge to crop freely — any size, any shape.',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: FutureBuilder<Uint8List>(
                future: _imageBytes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Crop(
                          image: snapshot.data!,
                          controller: _controller,
                          onCropped: _handleCropped,
                          // No aspectRatio = fully free crop rect.
                          baseColor: const Color(0xFF1E293B),
                          maskColor: Colors.black54,
                        ),
                      ),
                      if (_cropping)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
