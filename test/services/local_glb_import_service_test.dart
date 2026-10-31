import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/services/local_glb_import_service.dart';

Uint8List makeGlb({bool rigged = false}) {
  final document = <String, dynamic>{
    'asset': {'version': '2.0'},
    'meshes': [
      {
        'primitives': [
          {'attributes': {'POSITION': 0}}
        ]
      }
    ],
    'accessors': [
      {
        'min': [-0.5, 0.0, -0.2],
        'max': [0.5, 2.0, 0.2],
      }
    ],
    'nodes': [
      {'name': 'Body', 'mesh': 0}
    ],
    if (rigged)
      'skins': [
        {'joints': [0, 1, 2]}
      ],
    'animations': [
      {'name': 'Idle'}
    ],
  };
  final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(document)));
  final paddedLength = (jsonBytes.length + 3) & ~3;
  final totalLength = 12 + 8 + paddedLength;
  final bytes = Uint8List(totalLength);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x46546C67, Endian.little);
  data.setUint32(4, 2, Endian.little);
  data.setUint32(8, totalLength, Endian.little);
  data.setUint32(12, paddedLength, Endian.little);
  data.setUint32(16, 0x4E4F534A, Endian.little);
  bytes.setRange(20, 20 + jsonBytes.length, jsonBytes);
  for (var i = 20 + jsonBytes.length; i < totalLength; i++) {
    bytes[i] = 0x20;
  }
  return bytes;
}

void main() {
  const service = LocalGlbImportService();

  test('inspects an existing GLB skin and animation clips', () {
    final result = service.inspect(makeGlb(rigged: true));

    expect(result.meshCount, 1);
    expect(result.nodeCount, 1);
    expect(result.alreadyRigged, isTrue);
    expect(result.jointCount, 3);
    expect(result.animationNames, ['Idle']);
  });

  test('proposes deterministic humanoid landmarks for an unrigged mesh', () {
    final result = service.inspect(makeGlb());

    expect(result.alreadyRigged, isFalse);
    expect(result.hasPositionBounds, isTrue);
    expect(result.rigLandmarks.length, greaterThanOrEqualTo(15));
    expect(result.rigLandmarks.first.name, 'root');
    expect(result.rigLandmarks.any((point) => point.name == 'head'), isTrue);
  });

  test('rejects invalid GLB headers', () {
    expect(
      () => service.inspect(Uint8List.fromList([1, 2, 3, 4])),
      throwsFormatException,
    );
  });
}
