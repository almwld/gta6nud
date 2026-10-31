import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/services/local_glb_import_service.dart';

Uint8List makeGlb({
  bool rigged = false,
  int viewLength = 36,
  bool includeUnskinnablePrimitive = false,
  bool duplicateMeshNode = false,
}) {
  final positions = ByteData(36)
    ..setFloat32(0, -0.5, Endian.little)
    ..setFloat32(4, 0, Endian.little)
    ..setFloat32(8, -0.2, Endian.little)
    ..setFloat32(12, 0.5, Endian.little)
    ..setFloat32(16, 0, Endian.little)
    ..setFloat32(20, 0.2, Endian.little)
    ..setFloat32(24, 0, Endian.little)
    ..setFloat32(28, 2, Endian.little)
    ..setFloat32(32, 0, Endian.little);
  final document = <String, dynamic>{
    'asset': {'version': '2.0'},
    'buffers': [
      {'byteLength': 36}
    ],
    'bufferViews': [
      {'buffer': 0, 'byteOffset': 0, 'byteLength': viewLength}
    ],
    'meshes': [
      {
        'primitives': [
          {'attributes': {'POSITION': 0}},
          if (includeUnskinnablePrimitive) {'attributes': <String, dynamic>{}},
        ]
      }
    ],
    'accessors': [
      {
        'bufferView': 0,
        'componentType': 5126,
        'count': 3,
        'type': 'VEC3',
        'min': [-0.5, 0.0, -0.2],
        'max': [0.5, 2.0, 0.2],
      }
    ],
    'nodes': [
      {'name': 'Body', 'mesh': 0},
      if (duplicateMeshNode) {'name': 'BodyInstance', 'mesh': 0},
    ],
    'scenes': [
      {'nodes': [0]}
    ],
    'scene': 0,
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
  final totalLength = 12 + 8 + paddedLength + 8 + 36;
  final bytes = Uint8List(totalLength);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x46546C67, Endian.little);
  data.setUint32(4, 2, Endian.little);
  data.setUint32(8, totalLength, Endian.little);
  data.setUint32(12, paddedLength, Endian.little);
  data.setUint32(16, 0x4E4F534A, Endian.little);
  bytes.setRange(20, 20 + jsonBytes.length, jsonBytes);
  for (var i = 20 + jsonBytes.length; i < 20 + paddedLength; i++) {
    bytes[i] = 0x20;
  }
  final binHeader = 20 + paddedLength;
  data.setUint32(binHeader, 36, Endian.little);
  data.setUint32(binHeader + 4, 0x004E4942, Endian.little);
  bytes.setRange(binHeader + 8, binHeader + 44, positions.buffer.asUint8List());
  return bytes;
}

Map<String, dynamic> glbJson(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final jsonLength = data.getUint32(12, Endian.little);
  return jsonDecode(utf8.decode(bytes.sublist(20, 20 + jsonLength)).trim())
      as Map<String, dynamic>;
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

  test('auto-rigs unskinned GLB with hierarchy, inverse binds and vertex weights', () {
    final output = service.autoRig(makeGlb());
    final document = glbJson(output);
    final inspection = service.inspect(output);
    final mesh = (document['meshes'] as List).single as Map;
    final primitive = (mesh['primitives'] as List).single as Map;
    final attributes = primitive['attributes'] as Map;
    final accessors = document['accessors'] as List;
    final nodes = document['nodes'] as List;
    final skins = document['skins'] as List;
    final skin = skins.single as Map;

    expect(inspection.alreadyRigged, isTrue);
    expect(inspection.autoRigApplied, isTrue);
    expect(inspection.jointCount, 18);
    expect(skin['inverseBindMatrices'], isA<int>());
    expect((skin['joints'] as List).length, 18);
    expect(attributes['JOINTS_0'], isA<int>());
    expect(attributes['WEIGHTS_0'], isA<int>());
    expect((accessors[attributes['JOINTS_0'] as int] as Map)['componentType'], 5123);
    expect((accessors[attributes['WEIGHTS_0'] as int] as Map)['componentType'], 5126);
    expect((nodes[1] as Map)['children'], isNotEmpty);
    // The original mesh node remains at index 0; generated joints are appended.
    expect((nodes[0] as Map)['skin'], 0);
    expect(ByteData.sublistView(output).getUint32(8, Endian.little), output.length);
  });


  test('skins a shared mesh only once when multiple nodes reference it', () {
    final output = service.autoRig(makeGlb(duplicateMeshNode: true));
    final document = glbJson(output);
    final accessors = document['accessors'] as List;
    final nodes = document['nodes'] as List;

    // POSITION, inverse-bind matrices, JOINTS_0 and WEIGHTS_0.
    expect(accessors.length, 4);
    expect((nodes[0] as Map)['skin'], 0);
    expect((nodes[1] as Map)['skin'], 0);
  });

  test('rejects a mesh with an unskinnable primitive instead of assigning a partial skin', () {
    expect(
      () => service.autoRig(makeGlb(includeUnskinnablePrimitive: true)),
      throwsFormatException,
    );
  });

  test('does not replace a skin that already exists', () {
    final source = makeGlb(rigged: true);
    final output = service.autoRig(source);
    expect(output, source);
  });

  test('proposes deterministic humanoid landmarks for an unrigged mesh', () {
    final result = service.inspect(makeGlb());

    expect(result.alreadyRigged, isFalse);
    expect(result.hasPositionBounds, isTrue);
    expect(result.rigLandmarks.length, greaterThanOrEqualTo(15));
    expect(result.rigLandmarks.first.name, 'root');
    expect(result.rigLandmarks.any((point) => point.name == 'head'), isTrue);
  });


  test('rejects POSITION accessors that exceed their bufferView', () {
    expect(
      () => service.autoRig(makeGlb(viewLength: 12)),
      throwsFormatException,
    );
  });

  test('rejects non-finite POSITION components before generating weights', () {
    final bytes = makeGlb();
    final data = ByteData.sublistView(bytes);
    final jsonLength = data.getUint32(12, Endian.little);
    final binaryStart = 20 + jsonLength + 8;
    data.setFloat32(binaryStart, double.nan, Endian.little);

    expect(() => service.autoRig(bytes), throwsFormatException);
  });

  test('rejects invalid GLB headers', () {
    expect(
      () => service.inspect(Uint8List.fromList([1, 2, 3, 4])),
      throwsFormatException,
    );
  });
}
