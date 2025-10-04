import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// imageパッケージとdart:uiのCodecを使ってGIFとPNGの結果を比較表示するサンプル。
const String _gifAssetPath = 'assets/images/Tesseract.gif';

void main() {
  runApp(const MaterialApp(home: CompareGifPage()));
}

class CompareGifPage extends StatelessWidget {
  const CompareGifPage({super.key});

  // imageパッケージ利用: GIFの先頭フレームをPNGへ変換。
  Future<Uint8List> _toPngWithImagePackage() async {
    final data = await rootBundle.load(_gifAssetPath);
    final frame = img.decodeGif(data.buffer.asUint8List(), frame: 0);
    if (frame == null) throw Exception('フレームを取得できませんでした');
    return Uint8List.fromList(img.encodePng(frame, singleFrame: true));
  }

  // imageパッケージ非依存: dart:uiのCodecで先頭フレームをPNGへ変換。
  Future<Uint8List> _toPngWithUiCodec() async {
    final data = await rootBundle.load(_gifAssetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;
    final ByteData? pngBytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    codec.dispose();
    image.dispose();
    if (pngBytes == null) {
      throw Exception('PNGエンコードに失敗しました');
    }
    return pngBytes.buffer.asUint8List();
  }

  // 2通りの方法でPNGを生成し同時に返す。
  Future<Map<String, Uint8List>> _loadBothPng() async {
    final pngWithImage = await _toPngWithImagePackage();
    final pngWithUi = await _toPngWithUiCodec();
    return {'image': pngWithImage, 'ui': pngWithUi};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, Uint8List>>(
        future: _loadBothPng(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }

          final pngWithImage = snapshot.data!['image']!;
          final pngWithUi = snapshot.data!['ui']!;

          // 元GIFと、それぞれの手法で生成したPNGを縦並びで表示。
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GIF'),
                const SizedBox(height: 8),
                Image.asset(_gifAssetPath, width: 160, height: 160),
                const SizedBox(height: 24),
                const Text('PNG (imageパッケージ)'),
                const SizedBox(height: 8),
                Image.memory(pngWithImage, width: 160, height: 160),
                const SizedBox(height: 24),
                const Text('PNG (dart:ui)'),
                const SizedBox(height: 8),
                Image.memory(pngWithUi, width: 160, height: 160),
              ],
            ),
          );
        },
      ),
    );
  }
}
