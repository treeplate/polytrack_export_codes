import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'base62.dart';

List<int> decompress(String code) {
  assert(code.startsWith('PolyTrack2'));
  return zlib.decode(
    decode(utf8.decode(zlib.decode(decode(code.substring(10))!)))!,
  );
}

String compress(List<int> code) {
  return 'PolyTrack2${encode(zlib.encode(utf8.encode(encode(zlib.encode(code))!)))!}';
}

enum Season { summer, winter, desert }

class Part {}

class Track {
  final String trackName;
  final String authorName;
  // seconds since epoch
  final int? lastModified;
  final Season season;
  // half the sun direction in degrees
  final int sun;
  // smallest x, y, and z values in the file
  final int minX;
  final int minY;
  final int minZ;
  // the number of bytes used for storing xs, ys, and zs
  final int xBytes;
  final int yBytes;
  final int zBytes;
  final List<Part> parts;

  @override
  String toString() =>
      '$trackName by $authorName\nlast modified ${lastModified == null ? null : DateTime.fromMillisecondsSinceEpoch(1000 * lastModified!)}'
      '\n$season, sun direction ${sun * 2} degrees\nminXYZ: $minX,$minY,$minZ\nxyz bytes: $xBytes,$yBytes,$zBytes\nparts:\n${parts.join('\n')}';

  new(
    this.trackName,
    this.authorName,
    this.lastModified,
    this.season,
    this.sun,
    this.minX,
    this.minY,
    this.minZ,
    this.xBytes,
    this.yBytes,
    this.zBytes,
    this.parts,
  );
}

Track parseTrack(String code) {
  List<int> decompressed = decompress(code);
  ByteData byteData = ByteData.sublistView(Uint8List.fromList(decompressed));
  int nameLength = byteData.getUint8(0);
  String name = utf8.decode(byteData.buffer.asUint8List(1, nameLength));
  int authorLength = byteData.getUint8(1 + nameLength);
  String author = utf8.decode(
    byteData.buffer.asUint8List(1 + nameLength + 1, authorLength),
  );
  int lastModifiedExists = byteData.getUint8(1 + nameLength + 1 + authorLength);
  assert(lastModifiedExists == 0 || lastModifiedExists == 1);
  int? lastModified;
  if (lastModifiedExists == 1) {
    lastModified = byteData.getUint32(
      1 + nameLength + 1 + authorLength + 1,
      Endian.little,
    );
  }
  Season season =
      Season.values[byteData.getUint8(
        1 +
            nameLength +
            1 +
            authorLength +
            1 +
            (lastModifiedExists == 1 ? 4 : 0),
      )];
  int sun = byteData.getUint8(
    1 +
        nameLength +
        1 +
        authorLength +
        1 +
        (lastModifiedExists == 1 ? 4 : 0) +
        1,
  );
  int minX = byteData.getInt32(
    1 +
        nameLength +
        1 +
        authorLength +
        1 +
        (lastModifiedExists == 1 ? 4 : 0) +
        1 +
        1,
  );
  int minY = byteData.getInt32(
    1 +
        nameLength +
        1 +
        authorLength +
        1 +
        (lastModifiedExists == 1 ? 4 : 0) +
        1 +
        1 +
        4,
  );
  int minZ = byteData.getInt32(
    1 +
        nameLength +
        1 +
        authorLength +
        1 +
        (lastModifiedExists == 1 ? 4 : 0) +
        1 +
        1 +
        4 +
        4,
  );
  int xyz_bytes = byteData.getUint8(
    1 +
        nameLength +
        1 +
        authorLength +
        1 +
        (lastModifiedExists == 1 ? 4 : 0) +
        1 +
        1 +
        4 +
        4 +
        4,
  );
  int xBytes = xyz_bytes & 3;
  int yBytes = (xyz_bytes & 0xc) >> 2;
  int zBytes = (xyz_bytes & 0x30) >> 4;
  int offset =
      1 +
      nameLength +
      1 +
      authorLength +
      1 +
      (lastModifiedExists == 1 ? 4 : 0) +
      1 +
      1 +
      4 +
      4 +
      4 +
      1;
  List<Part> parts = [];
  while (offset < byteData.lengthInBytes) {
    throw UnimplementedError('tracks with parts');
  }
  return Track(
    name,
    author,
    lastModified,
    season,
    sun,
    minX,
    minY,
    minZ,
    xBytes,
    yBytes,
    zBytes,
    parts,
  );
}
