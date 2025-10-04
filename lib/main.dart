import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// imageパッケージでGIFの単一フレームをPNGへ変換し、比較表示するサンプル。

const String _gifAssetPath = 'assets/images/Tesseract.gif';

void main() {
  runApp(const MaterialApp(home: CompareGifPage()));
}

class CompareGifPage extends StatelessWidget {
  const CompareGifPage({super.key});

  // GIFから先頭フレームのみをPNGバイト列に変換する。
  Future<Uint8List> _toPng() async {
    final data = await rootBundle.load(_gifAssetPath);
    final frame = img.decodeGif(data.buffer.asUint8List(), frame: 0);
    if (frame == null) throw Exception('フレームを取得できませんでした');
    return Uint8List.fromList(img.encodePng(frame, singleFrame: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Uint8List>(
        future: _toPng(),
        builder: (context, snapshot) {
          Widget pngView;
          if (snapshot.connectionState != ConnectionState.done) {
            pngView = const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            pngView = Text('エラー: ${snapshot.error}');
          } else {
            pngView = Image.memory(snapshot.data!, width: 160, height: 160);
          }

          // 上段に元GIF、下段に変換PNGを縦並びで表示する。
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GIF'),
                const SizedBox(height: 8),
                Image.asset(_gifAssetPath, width: 160, height: 160),
                const SizedBox(height: 24),
                const Text('PNG'),
                const SizedBox(height: 8),
                pngView,
              ],
            ),
          );
        },
      ),
    );
  }
}
