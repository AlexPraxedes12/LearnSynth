import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';

import '../content_provider.dart';

/// Visualizes concept relationships as an interactive graph to help build mental models.
class ContextualAssociationScreen extends StatelessWidget {
  const ContextualAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final groups = p.conceptGroups;
    final flat = p.conceptTopics;

    /// Returns a simple node widget with the given [text] and [color].
    Widget nodeWidget(String text, Color color) => Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(text),
        );

    /// Builds the graph using [graphview] based on the available concept data.
    Widget buildGraph() {
      final graph = Graph();
      final Map<String, Node> nodeMap = {};
      final Map<String, Color> colorMap = {};

      Node getNode(String id) => nodeMap.putIfAbsent(id, () => Node.Id(id));

      if (groups.isNotEmpty) {
        for (var i = 0; i < groups.length; i++) {
          final g = groups[i];
          final groupNode = getNode(g.title);
          colorMap[g.title] = Colors.grey.shade700;
          final color = Colors.primaries[i % Colors.primaries.length];
          for (final topic in g.topics ?? []) {
            final topicNode = getNode(topic);
            colorMap[topic] = color;
            graph.addEdge(groupNode, topicNode);
          }
        }
      } else if (flat.isNotEmpty) {
        final root = getNode('Topics');
        colorMap['Topics'] = Colors.grey.shade700;
        for (var i = 0; i < flat.length; i++) {
          final topic = flat[i];
          final node = getNode(topic);
          colorMap[topic] = Colors.primaries[i % Colors.primaries.length];
          graph.addEdge(root, node);
        }
      }

      final builder = FruchtermanReingoldAlgorithm();
      return InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.01,
        maxScale: 5,
        child: GraphView(
          graph: graph,
          algorithm: builder,
          builder: (Node node) {
            final id = node.key!.value as String;
            return nodeWidget(id, colorMap[id] ?? Colors.blue);
          },
        ),
      );
    }

    /// Renders a simple legend mapping each group to its color.
    Widget legend() {
      if (groups.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < groups.length; i++)
              Chip(
                label: Text(groups[i].title),
                backgroundColor:
                    Colors.primaries[i % Colors.primaries.length].withOpacity(0.3),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Concept Map')),
      body: groups.isEmpty && flat.isEmpty
          ? const Center(child: Text('No concept map available'))
          : Column(
              children: [
                Expanded(child: buildGraph()),
                legend(),
              ],
            ),
    );
  }
}


