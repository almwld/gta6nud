enum NodeType { trigger, action, audio, camera }

class AdvancedNodeData {
  final String id;
  String label;
  NodeType type;
  final List<NodeSlot> inputs;
  final List<NodeSlot> outputs;
  Map<String, dynamic> internalValues;

  AdvancedNodeData({
    required this.id,
    required this.label,
    this.type = NodeType.action,
    List<NodeSlot>? inputs,
    List<NodeSlot>? outputs,
    Map<String, dynamic>? internalValues,
  })  : inputs = inputs ?? [],
        outputs = outputs ?? [],
        internalValues = internalValues ?? {};
}

class NodeSlot {
  final String name;
  final String type;
  NodeSlot({required this.name, this.type = 'trigger'});
}

class NodeWire {
  final String fromNodeId;
  final String fromSlotName;
  final String toNodeId;
  final String toSlotName;

  NodeWire({
    required this.fromNodeId,
    required this.fromSlotName,
    required this.toNodeId,
    required this.toSlotName,
  });
}
