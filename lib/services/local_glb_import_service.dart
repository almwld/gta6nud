import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class RigLandmark {
  const RigLandmark({
    required this.name,
    required this.x,
    required this.y,
    required this.z,
  });

  final String name;
  final double x;
  final double y;
  final double z;

  List<double> get vector => [x, y, z];
}

class GlbInspection {
  const GlbInspection({
    required this.meshCount,
    required this.nodeCount,
    required this.skinCount,
    required this.jointCount,
    required this.animationNames,
    required this.hasPositionBounds,
    required this.rigLandmarks,
    this.autoRigApplied = false,
  });

  final int meshCount;
  final int nodeCount;
  final int skinCount;
  final int jointCount;
  final List<String> animationNames;
  final bool hasPositionBounds;
  final List<RigLandmark> rigLandmarks;
  final bool autoRigApplied;

  bool get alreadyRigged => skinCount > 0 && jointCount > 0;
  bool get hasAnimations => animationNames.isNotEmpty;
}

class ImportedGlb {
  const ImportedGlb({
    required this.name,
    required this.localPath,
    required this.dataUri,
    required this.inspection,
  });

  final String name;
  final String localPath;
  final String dataUri;
  final GlbInspection inspection;
}

/// Imports GLB v2 and builds a basic humanoid glTF skin for unrigged meshes.
///
/// The generated rig contains a joint hierarchy, inverse-bind matrices and
/// per-vertex JOINTS_0/WEIGHTS_0. Weights are estimated from the four nearest
/// joints, so unusual poses, props, clothing and non-humanoid meshes still
/// need artist review. Existing skins are preserved.
class LocalGlbImportService {
  const LocalGlbImportService();

  static const int maxFileBytes = 150 * 1024 * 1024;
  static const int _jsonChunk = 0x4E4F534A;
  static const int _binChunk = 0x004E4942;
  static const int _glbMagic = 0x46546C67;

  Future<ImportedGlb?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['glb'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final selected = result.files.single;
    final sourceBytes = selected.bytes ??
        (selected.path == null ? null : await File(selected.path!).readAsBytes());
    if (sourceBytes == null) {
      throw const FormatException('تعذر قراءة الملف المحدد من الهاتف.');
    }
    if (sourceBytes.length > maxFileBytes) {
      throw const FormatException('حجم GLB يتجاوز الحد المدعوم (150 MB).');
    }

    final riggedBytes = autoRig(sourceBytes);
    final inspection = inspect(riggedBytes);
    final directory = await getApplicationDocumentsDirectory();
    final modelsDirectory = Directory('${directory.path}/imported_models');
    await modelsDirectory.create(recursive: true);
    final safeName = _safeFileName(selected.name);
    final destination = File('${modelsDirectory.path}/$safeName');
    await destination.writeAsBytes(riggedBytes, flush: true);

    return ImportedGlb(
      name: selected.name,
      localPath: destination.path,
      dataUri: 'data:model/gltf-binary;base64,${base64Encode(riggedBytes)}',
      inspection: inspection,
    );
  }

  /// Adds a humanoid skin to an unrigged GLB. Existing rigged files are intact.
  Uint8List autoRig(Uint8List bytes) {
    final parsed = _parse(bytes);
    final document = parsed.document;
    final meshes = _list(document['meshes']);
    final nodes = _list(document['nodes']);
    document['nodes'] = nodes;
    final skins = _list(document['skins']);
    document['skins'] = skins;
    if (skins.isNotEmpty) return Uint8List.fromList(bytes);

    // Auto-generated joints are placed in scene space. Refuse to bind a mesh
    // whose node or any ancestor applies a transform, because sharing one
    // generated skin across differently transformed instances would produce
    // incorrect inverse-bind matrices and visible offsets.
    _validateMeshNodeTransforms(document, meshes);

    final bounds = _positionBounds(document);
    if (bounds == null) {
      throw const FormatException(
        'لا يمكن إنشاء الهيكل: لا توجد بيانات POSITION قابلة للقراءة.',
      );
    }
    final landmarks = _humanoidLandmarks(bounds);
    final binary = BytesBuilder(copy: false)..add(parsed.binary);
    final bufferViews = _list(document['bufferViews']);
    final accessors = _list(document['accessors']);
    final jointNodes = _appendJointHierarchy(document, landmarks);
    final inverseBindBytes = _inverseBindMatrices(landmarks);
    final inverseBindAccessor = _appendAccessor(
      document,
      binary,
      bufferViews,
      accessors,
      inverseBindBytes,
      componentType: 5126,
      count: landmarks.length,
      type: 'MAT4',
    );

    final skinIndex = skins.length;
    skins.add({
      'name': 'AutoRig_Humanoid',
      'inverseBindMatrices': inverseBindAccessor,
      'skeleton': jointNodes.first,
      'joints': jointNodes,
    });

    // Process each mesh once. A mesh is skinned only when every primitive
    // has valid POSITION data; assigning a skin to a partially processed mesh
    // would produce an invalid glTF asset.
    final skinnedMeshIndices = <int>{};
    for (var meshIndex = 0; meshIndex < meshes.length; meshIndex++) {
      final mesh = meshes[meshIndex];
      if (mesh is! Map) continue;
      final primitives = _list(mesh['primitives']);
      if (primitives.isEmpty || primitives.any((item) => item is! Map)) continue;

      final prepared = <(Map, List<List<double>>) >[];
      var meshIsSkinnable = true;
      for (final primitive in primitives.cast<Map>()) {
        final attributes = primitive['attributes'];
        if (attributes is! Map || attributes['POSITION'] is! int) {
          meshIsSkinnable = false;
          break;
        }
        try {
          final positions = _readPositions(
            document,
            parsed.binary,
            attributes['POSITION'] as int,
          );
          prepared.add((primitive, positions));
        } on FormatException {
          meshIsSkinnable = false;
          break;
        }
      }
      if (!meshIsSkinnable || prepared.length != primitives.length) continue;

      for (final entry in prepared) {
        final primitive = entry.$1;
        final positions = entry.$2;
        final attributes = primitive['attributes'] as Map;
        final generated = _buildVertexWeights(positions, landmarks);
        attributes['JOINTS_0'] = _appendAccessor(
          document,
          binary,
          bufferViews,
          accessors,
          generated.$1,
          componentType: 5123,
          count: positions.length,
          type: 'VEC4',
        );
        attributes['WEIGHTS_0'] = _appendAccessor(
          document,
          binary,
          bufferViews,
          accessors,
          generated.$2,
          componentType: 5126,
          count: positions.length,
          type: 'VEC4',
        );
      }
      skinnedMeshIndices.add(meshIndex);
    }

    for (final node in nodes.whereType<Map>()) {
      final meshIndex = node['mesh'];
      if (meshIndex is int && skinnedMeshIndices.contains(meshIndex)) {
        node['skin'] = skinIndex;
      }
    }

    if (skinnedMeshIndices.isEmpty) {
      throw const FormatException(
        'لم يتم العثور على Mesh يحتوي جميع primitives قابلة للـSkinning.',
      );
    }

    final newBinary = binary.takeBytes();
    final buffers = _list(document['buffers']);
    document['buffers'] = buffers;
    if (buffers.isEmpty) {
      buffers.add({'byteLength': newBinary.length});
    } else {
      (buffers.first as Map)['byteLength'] = newBinary.length;
    }
    final rebuilt = _rebuildGlb(
      document,
      newBinary,
      parsed.otherChunks,
    );
    return rebuilt;
  }

  GlbInspection inspect(Uint8List bytes) {
    final document = _parse(bytes).document;
    final meshes = _list(document['meshes']);
    final nodes = _list(document['nodes']);
    final skins = _list(document['skins']);
    final animations = _list(document['animations']);
    var jointCount = 0;
    for (final skin in skins) {
      if (skin is Map) jointCount += _list(skin['joints']).length;
    }
    final bounds = _positionBounds(document);
    final landmarks = bounds == null ? <RigLandmark>[] : _humanoidLandmarks(bounds);
    return GlbInspection(
      meshCount: meshes.length,
      nodeCount: nodes.length,
      skinCount: skins.length,
      jointCount: jointCount,
      animationNames: animations
          .whereType<Map>()
          .map((item) => (item['name'] as String?)?.trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
      hasPositionBounds: bounds != null,
      rigLandmarks: landmarks,
      autoRigApplied: skins.whereType<Map>().any((skin) => skin['name'] == 'AutoRig_Humanoid'),
    );
  }

  _ParsedGlb _parse(Uint8List bytes) {
    if (bytes.length < 20) throw const FormatException('ملف GLB قصير أو تالف.');
    final data = ByteData.sublistView(bytes);
    if (data.getUint32(0, Endian.little) != _glbMagic ||
        data.getUint32(4, Endian.little) != 2 ||
        data.getUint32(8, Endian.little) != bytes.length) {
      throw const FormatException('ترويسة GLB غير صالحة أو الإصدار غير مدعوم.');
    }
    var offset = 12;
    Map<String, dynamic>? document;
    Uint8List binary = Uint8List(0);
    final other = <_GlbChunk>[];
    while (offset + 8 <= bytes.length) {
      final length = data.getUint32(offset, Endian.little);
      final type = data.getUint32(offset + 4, Endian.little);
      offset += 8;
      if (length > bytes.length - offset) {
        throw const FormatException('أحد مقاطع GLB يتجاوز نهاية الملف.');
      }
      final chunk = Uint8List.fromList(bytes.sublist(offset, offset + length));
      if (type == _jsonChunk) {
        final decoded = jsonDecode(utf8.decode(chunk, allowMalformed: false).trim());
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('بيانات glTF JSON غير صالحة.');
        }
        document = decoded;
      } else if (type == _binChunk) {
        binary = chunk;
      } else {
        other.add(_GlbChunk(type, chunk));
      }
      offset += length;
    }
    if (document == null) throw const FormatException('لم يتم العثور على JSON chunk.');
    return _ParsedGlb(document, binary, other);
  }

  void _validateMeshNodeTransforms(
    Map<String, dynamic> document,
    List<dynamic> meshes,
  ) {
    final nodes = _list(document['nodes']);
    final parents = <int, int>{};
    for (var parentIndex = 0; parentIndex < nodes.length; parentIndex++) {
      final node = nodes[parentIndex];
      if (node is! Map) continue;
      for (final child in _list(node['children'])) {
        if (child is int && child >= 0 && child < nodes.length) {
          parents[child] = parentIndex;
        }
      }
    }

    for (var nodeIndex = 0; nodeIndex < nodes.length; nodeIndex++) {
      final node = nodes[nodeIndex];
      if (node is! Map) continue;
      final meshIndex = node['mesh'];
      if (meshIndex is! int || meshIndex < 0 || meshIndex >= meshes.length) {
        continue;
      }
      var currentIndex = nodeIndex;
      final visited = <int>{};
      while (visited.add(currentIndex)) {
        final current = nodes[currentIndex];
        if (current is Map && _hasNonIdentityTransform(current)) {
          throw const FormatException(
            'Auto-Rig يتطلب Mesh بعقدة وتحويلات آباء Identity؛ طبّع Transform للمجسم قبل الاستيراد.',
          );
        }
        final parentIndex = parents[currentIndex];
        if (parentIndex == null) break;
        currentIndex = parentIndex;
      }
    }
  }

  bool _hasNonIdentityTransform(Map node) {
    final matrix = node['matrix'];
    if (matrix != null) {
      if (matrix is! List || matrix.length != 16) return true;
      const identity = <double>[
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ];
      for (var i = 0; i < identity.length; i++) {
        final value = matrix[i];
        if (value is! num || !value.isFinite ||
            (value.toDouble() - identity[i]).abs() > 1e-6) {
          return true;
        }
      }
    }

    bool matches(dynamic value, List<double> expected) {
      if (value == null) return true;
      if (value is! List || value.length != expected.length) return false;
      for (var i = 0; i < expected.length; i++) {
        final component = value[i];
        if (component is! num || !component.isFinite ||
            (component.toDouble() - expected[i]).abs() > 1e-6) {
          return false;
        }
      }
      return true;
    }

    return !matches(node['translation'], const [0, 0, 0]) ||
        !matches(node['rotation'], const [0, 0, 0, 1]) ||
        !matches(node['scale'], const [1, 1, 1]);
  }

  List<int> _appendJointHierarchy(
    Map<String, dynamic> document,
    List<RigLandmark> bones,
  ) {
    final nodes = _list(document['nodes']);
    final joints = <int>[];
    final children = <int, List<int>>{
      0: [1], 1: [2, 12, 13], 2: [3], 3: [4, 6, 7],
      4: [5], 6: [8], 8: [10], 7: [9], 9: [11],
      12: [14], 13: [15], 14: [16], 15: [17],
    };
    final parents = <int, int>{
      1: 0, 2: 1, 3: 2, 4: 3, 5: 4,
      6: 3, 7: 3, 8: 6, 9: 7, 10: 8, 11: 9,
      12: 1, 13: 1, 14: 12, 15: 13, 16: 14, 17: 15,
    };
    for (var i = 0; i < bones.length; i++) {
      final translation = i == 0
          ? bones[i].vector
          : _subtract(bones[i].vector, bones[parents[i]!] .vector);
      final node = <String, dynamic>{
        'name': bones[i].name,
        'translation': translation,
        if (children[i] != null) 'children': <int>[],
      };
      joints.add(nodes.length);
      nodes.add(node);
    }
    for (final entry in children.entries) {
      final parentNode = nodes[joints[entry.key]] as Map;
      parentNode['children'] = entry.value.map((index) => joints[index]).toList();
    }
    final scenes = _list(document['scenes']);
    if (scenes.isEmpty) {
      document['scenes'] = [
        {'nodes': [joints.first]}
      ];
    } else {
      final sceneIndex = (document['scene'] as int?) ?? 0;
      if (sceneIndex >= 0 && sceneIndex < scenes.length && scenes[sceneIndex] is Map) {
        final roots = _list((scenes[sceneIndex] as Map)['nodes']);
        roots.add(joints.first);
        (scenes[sceneIndex] as Map)['nodes'] = roots;
      }
    }
    return joints;
  }

  Uint8List _inverseBindMatrices(List<RigLandmark> bones) {
    final bytes = Uint8List(bones.length * 64);
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < bones.length; i++) {
      final offset = i * 64;
      for (var diagonal = 0; diagonal < 4; diagonal++) {
        data.setFloat32(offset + (diagonal * 4 + diagonal) * 4, 1, Endian.little);
      }
      data.setFloat32(offset + 48, -bones[i].x, Endian.little);
      data.setFloat32(offset + 52, -bones[i].y, Endian.little);
      data.setFloat32(offset + 56, -bones[i].z, Endian.little);
    }
    return bytes;
  }

  (Uint8List, Uint8List) _buildVertexWeights(
    List<List<double>> positions,
    List<RigLandmark> bones,
  ) {
    final jointBytes = Uint8List(positions.length * 8);
    final weightBytes = Uint8List(positions.length * 16);
    final jointData = ByteData.sublistView(jointBytes);
    final weightData = ByteData.sublistView(weightBytes);
    for (var vertex = 0; vertex < positions.length; vertex++) {
      final ranked = List<int>.generate(bones.length, (i) => i)
        ..sort((a, b) => _distanceSquared(positions[vertex], bones[a].vector)
            .compareTo(_distanceSquared(positions[vertex], bones[b].vector)));
      final selected = ranked.take(4).toList();
      final raw = selected
          .map((index) => 1.0 /
              math.max(1e-8, _distanceSquared(positions[vertex], bones[index].vector)))
          .toList();
      final total = raw.fold<double>(0, (sum, value) => sum + value);
      for (var slot = 0; slot < 4; slot++) {
        final index = selected[slot];
        jointData.setUint16((vertex * 4 + slot) * 2, index, Endian.little);
        weightData.setFloat32(
          (vertex * 4 + slot) * 4,
          raw[slot] / total,
          Endian.little,
        );
      }
    }
    return (jointBytes, weightBytes);
  }

  int _appendAccessor(
    Map<String, dynamic> document,
    BytesBuilder binary,
    List<dynamic> bufferViews,
    List<dynamic> accessors,
    Uint8List payload, {
    required int componentType,
    required int count,
    required String type,
  }) {
    final existingLength = binary.length;
    final padding = (4 - existingLength % 4) % 4;
    if (padding > 0) binary.add(Uint8List(padding));
    final offset = existingLength + padding;
    binary.add(payload);
    final viewIndex = bufferViews.length;
    bufferViews.add({
      'buffer': 0,
      'byteOffset': offset,
      'byteLength': payload.length,
    });
    final accessorIndex = accessors.length;
    accessors.add({
      'bufferView': viewIndex,
      'byteOffset': 0,
      'componentType': componentType,
      'count': count,
      'type': type,
    });
    document['bufferViews'] = bufferViews;
    document['accessors'] = accessors;
    return accessorIndex;
  }

  List<List<double>> _readPositions(
    Map<String, dynamic> document,
    Uint8List binary,
    int accessorIndex,
  ) {
    final accessors = _list(document['accessors']);
    final views = _list(document['bufferViews']);
    if (accessorIndex < 0 || accessorIndex >= accessors.length) {
      throw const FormatException('POSITION accessor غير صالح.');
    }
    final accessor = accessors[accessorIndex];
    if (accessor is! Map ||
        accessor['componentType'] != 5126 ||
        accessor['type'] != 'VEC3' ||
        accessor['bufferView'] is! int) {
      throw const FormatException('يدعم Auto-Rig حالياً POSITION بصيغة FLOAT VEC3 فقط.');
    }
    final viewIndex = accessor['bufferView'] as int;
    if (viewIndex < 0 || viewIndex >= views.length) {
      throw const FormatException('POSITION bufferView غير صالح.');
    }
    final view = views[viewIndex] as Map;
    if ((view['buffer'] ?? 0) != 0) {
      throw const FormatException('ملفات GLB ذات مخازن هندسية متعددة غير مدعومة.');
    }
    final count = accessor['count'] as int;
    final viewStart = view['byteOffset'] as int? ?? 0;
    final viewLength = view['byteLength'] as int?;
    final accessorOffset = accessor['byteOffset'] as int? ?? 0;
    final stride = view['byteStride'] as int? ?? 12;
    final start = viewStart + accessorOffset;
    if (viewLength == null ||
        count <= 0 ||
        stride < 12 ||
        stride > 252 ||
        stride % 4 != 0 ||
        viewStart < 0 ||
        accessorOffset < 0 ||
        viewLength < 0 ||
        viewStart + viewLength > binary.length ||
        start < viewStart ||
        start + (count - 1) * stride + 12 > viewStart + viewLength) {
      throw const FormatException(
        'بيانات POSITION ناقصة أو تتجاوز حدود bufferView/BIN.',
      );
    }
    final data = ByteData.sublistView(binary);
    return List.generate(count, (i) {
      final offset = start + i * stride;
      final position = [
        data.getFloat32(offset, Endian.little),
        data.getFloat32(offset + 4, Endian.little),
        data.getFloat32(offset + 8, Endian.little),
      ];
      if (position.any((component) => !component.isFinite)) {
        throw const FormatException('بيانات POSITION تحتوي قيمة غير منتهية.');
      }
      return position;
    });
  }

  Uint8List _rebuildGlb(
    Map<String, dynamic> document,
    Uint8List binary,
    List<_GlbChunk> otherChunks,
  ) {
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(document)));
    final jsonPadding = (4 - jsonBytes.length % 4) % 4;
    final paddedJson = Uint8List(jsonBytes.length + jsonPadding);
    paddedJson.setRange(0, jsonBytes.length, jsonBytes);
    for (var i = jsonBytes.length; i < paddedJson.length; i++) {
      paddedJson[i] = 0x20;
    }
    final binPadding = (4 - binary.length % 4) % 4;
    final paddedBinary = Uint8List(binary.length + binPadding)..setRange(0, binary.length, binary);
    final chunks = <_GlbChunk>[
      _GlbChunk(_jsonChunk, paddedJson),
      _GlbChunk(_binChunk, paddedBinary),
      ...otherChunks,
    ];
    final total = 12 + chunks.fold<int>(0, (sum, chunk) => sum + 8 + chunk.bytes.length);
    final output = Uint8List(total);
    final data = ByteData.sublistView(output);
    data.setUint32(0, _glbMagic, Endian.little);
    data.setUint32(4, 2, Endian.little);
    data.setUint32(8, total, Endian.little);
    var offset = 12;
    for (final chunk in chunks) {
      data.setUint32(offset, chunk.bytes.length, Endian.little);
      data.setUint32(offset + 4, chunk.type, Endian.little);
      output.setRange(offset + 8, offset + 8 + chunk.bytes.length, chunk.bytes);
      offset += 8 + chunk.bytes.length;
    }
    return output;
  }

  Map<String, List<double>>? _positionBounds(Map<String, dynamic> document) {
    final accessors = _list(document['accessors']);
    final meshes = _list(document['meshes']);
    List<double>? minimum;
    List<double>? maximum;
    for (final mesh in meshes.whereType<Map>()) {
      for (final primitive in _list(mesh['primitives']).whereType<Map>()) {
        final attributes = primitive['attributes'];
        if (attributes is! Map) continue;
        final index = attributes['POSITION'];
        if (index is! int || index < 0 || index >= accessors.length) continue;
        final accessor = accessors[index];
        if (accessor is! Map) continue;
        final min = _numericVector(accessor['min']);
        final max = _numericVector(accessor['max']);
        if (min.length != 3 || max.length != 3) continue;
        minimum ??= List<double>.from(min);
        maximum ??= List<double>.from(max);
        for (var axis = 0; axis < 3; axis++) {
          if (min[axis] < minimum[axis]) minimum[axis] = min[axis];
          if (max[axis] > maximum[axis]) maximum[axis] = max[axis];
        }
      }
    }
    if (minimum == null || maximum == null) return null;
    if (List.generate(3, (i) => maximum![i] - minimum![i])
        .any((extent) => !extent.isFinite || extent <= 0)) return null;
    return {'min': minimum, 'max': maximum};
  }

  List<RigLandmark> _humanoidLandmarks(Map<String, List<double>> bounds) {
    final min = bounds['min']!;
    final max = bounds['max']!;
    final cx = (min[0] + max[0]) / 2;
    final cz = (min[2] + max[2]) / 2;
    final h = max[1] - min[1];
    final w = max[0] - min[0];
    RigLandmark p(String name, double x, double y, double z) =>
        RigLandmark(name: name, x: x, y: y, z: z);
    return [
      p('root', cx, min[1], cz),
      p('pelvis', cx, min[1] + h * .52, cz),
      p('spine', cx, min[1] + h * .62, cz),
      p('chest', cx, min[1] + h * .72, cz),
      p('neck', cx, min[1] + h * .84, cz),
      p('head', cx, min[1] + h * .92, cz),
      p('shoulder_l', cx - w * .22, min[1] + h * .75, cz),
      p('shoulder_r', cx + w * .22, min[1] + h * .75, cz),
      p('elbow_l', cx - w * .34, min[1] + h * .58, cz),
      p('elbow_r', cx + w * .34, min[1] + h * .58, cz),
      p('wrist_l', cx - w * .40, min[1] + h * .40, cz),
      p('wrist_r', cx + w * .40, min[1] + h * .40, cz),
      p('hip_l', cx - w * .09, min[1] + h * .50, cz),
      p('hip_r', cx + w * .09, min[1] + h * .50, cz),
      p('knee_l', cx - w * .09, min[1] + h * .28, cz),
      p('knee_r', cx + w * .09, min[1] + h * .28, cz),
      p('ankle_l', cx - w * .09, min[1] + h * .06, cz),
      p('ankle_r', cx + w * .09, min[1] + h * .06, cz),
    ];
  }

  List<dynamic> _list(dynamic value) =>
      value is List ? value : <dynamic>[];

  List<double> _numericVector(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<num>().map((number) => number.toDouble()).toList();
  }

  List<double> _subtract(List<double> a, List<double> b) =>
      [a[0] - b[0], a[1] - b[1], a[2] - b[2]];

  double _distanceSquared(List<double> a, List<double> b) =>
      math.pow(a[0] - b[0], 2).toDouble() +
      math.pow(a[1] - b[1], 2).toDouble() +
      math.pow(a[2] - b[2], 2).toDouble();

  String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.toLowerCase().endsWith('.glb') ? cleaned : '$cleaned.glb';
  }
}

class _ParsedGlb {
  const _ParsedGlb(this.document, this.binary, this.otherChunks);
  final Map<String, dynamic> document;
  final Uint8List binary;
  final List<_GlbChunk> otherChunks;
}

class _GlbChunk {
  const _GlbChunk(this.type, this.bytes);
  final int type;
  final Uint8List bytes;
}
