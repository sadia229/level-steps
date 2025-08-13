import 'package:flutter/material.dart';

class Level {
  final String title;
  final IconData icon;
  final bool unlocked;

  const Level(this.title, this.icon, {this.unlocked = false});
}

class LevelNode extends StatelessWidget {
  final Level level;

  const LevelNode(this.level, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: level.unlocked ? Colors.orange : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade100, width: 4),
              ),
              child: Icon(level.icon, color: Colors.white, size: 36),
            ),
            if (!level.unlocked)
              const Positioned(
                bottom: 4,
                right: 4,
                child: Icon(Icons.lock, size: 20, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          level.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade900,
          ),
        ),
      ],
    );
  }
}

class LevelPathPainter extends CustomPainter {
  final List<Offset> points; // Flattened list of all node centers
  final List<List<Level>> levelRows; // Structure of levels by row
  final double
  centerX; // Center X coordinate of the screen/layout for reference
  final Paint _paint = Paint()
    ..color = Colors.grey.shade400.withOpacity(0.3)
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke;

  // Default horizontal offset for paths that turn
  static const double _defaultHorizontalOffset = 120.0;
  // Decreased horizontal offset specifically for the D-F connection
  static const double _dFHorizontalOffset =
      130.0; // Value changed from 150.0 to 130.0

  LevelPathPainter(this.points, this.levelRows, this.centerX);

  // Helper to draw the custom "right-down-left" path (e.g., A to C, D to F)
  void _drawCustomPathRight(
    Canvas canvas,
    Offset start,
    Offset end,
    double horizontalOffset,
  ) {
    const double cornerRadius = 50.0;
    // Determine an X-coordinate for the vertical segment of the path relative to screen center.
    final double pathSegmentX = centerX + horizontalOffset;
    final double pathSegmentY = end.dy;

    final Path customPath = Path();
    customPath.moveTo(start.dx, start.dy);

    // Line 1: Move right from start's center to pathSegmentX - cornerRadius.
    customPath.lineTo(pathSegmentX - cornerRadius, start.dy);

    // Arc 1: Turn down-right.
    customPath.arcToPoint(
      Offset(pathSegmentX, start.dy + cornerRadius),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Line 2: Move down along the vertical segment.
    customPath.lineTo(pathSegmentX, pathSegmentY - cornerRadius);

    // Arc 2: Turn down-left.
    customPath.arcToPoint(
      Offset(pathSegmentX - cornerRadius, pathSegmentY),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Line 3: Move left to end's center.
    customPath.lineTo(end.dx, end.dy);
    canvas.drawPath(customPath, _paint);
  }

  // Helper to draw the custom "left-down-right" path (e.g., B to D)
  void _drawCustomPathLeft(
    Canvas canvas,
    Offset start,
    Offset end,
    double horizontalOffset,
  ) {
    const double cornerRadius = 50.0;
    // Determine an X-coordinate for the vertical segment of the path relative to screen center.
    final double pathSegmentX = centerX - horizontalOffset;
    final double pathSegmentY = end.dy;

    final Path customPath = Path();
    customPath.moveTo(start.dx, start.dy);

    // Line 1: Move left from start's center.
    customPath.lineTo(pathSegmentX + cornerRadius, start.dy);

    // Arc 1: Turn down-left.
    customPath.arcToPoint(
      Offset(pathSegmentX, start.dy + cornerRadius),
      radius: const Radius.circular(cornerRadius),
      clockwise: false, // Counter-clockwise for left turn
    );

    // Line 2: Move down along the vertical segment.
    customPath.lineTo(pathSegmentX, pathSegmentY - cornerRadius);

    // Arc 2: Turn down-right.
    customPath.arcToPoint(
      Offset(pathSegmentX + cornerRadius, pathSegmentY),
      radius: const Radius.circular(cornerRadius),
      clockwise: false, // Counter-clockwise for right turn
    );

    // Line 3: Move right to end's center.
    customPath.lineTo(end.dx, end.dy);
    canvas.drawPath(customPath, _paint);
  }

  // New helper to draw a path from a single node to a single node in the next row,
  // going right, then down, then left. This is for zig-zag.
  void _drawSingleNodeRightDownLeftPath(
    Canvas canvas,
    Offset start,
    Offset end,
    double horizontalOffset,
  ) {
    const double cornerRadius = 50.0;
    // Vertical segment is offset from screen center.
    final double pathSegmentX = centerX + horizontalOffset;
    final double pathSegmentY = end.dy;

    final Path customPath = Path();
    customPath.moveTo(start.dx, start.dy);

    // Line 1: Move right from start's center.
    customPath.lineTo(pathSegmentX - cornerRadius, start.dy);

    // Arc 1: Turn down-right.
    customPath.arcToPoint(
      Offset(pathSegmentX, start.dy + cornerRadius),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Line 2: Move down along the vertical segment.
    customPath.lineTo(pathSegmentX, pathSegmentY - cornerRadius);

    // Arc 2: Turn down-left.
    customPath.arcToPoint(
      Offset(pathSegmentX - cornerRadius, pathSegmentY),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Line 3: Move left to end's center.
    customPath.lineTo(end.dx, end.dy);
    canvas.drawPath(customPath, _paint);
  }

  // New helper to draw a path from a single node to a single node in the next row,
  // going left, then down, then right. This is for zig-zag.
  void _drawSingleNodeLeftDownRightPath(
    Canvas canvas,
    Offset start,
    Offset end,
    double horizontalOffset,
  ) {
    const double cornerRadius = 50.0;
    // Vertical segment is offset from screen center.
    final double pathSegmentX = centerX - horizontalOffset;
    final double pathSegmentY = end.dy;

    final Path customPath = Path();
    customPath.moveTo(start.dx, start.dy);

    // Line 1: Move left from start's center.
    customPath.lineTo(pathSegmentX + cornerRadius, start.dy);

    // Arc 1: Turn down-left.
    customPath.arcToPoint(
      Offset(pathSegmentX, start.dy + cornerRadius),
      radius: const Radius.circular(cornerRadius),
      clockwise: false, // Counter-clockwise for left turn
    );

    // Line 2: Move down along the vertical segment.
    customPath.lineTo(pathSegmentX, pathSegmentY - cornerRadius);

    // Arc 2: Turn down-right.
    customPath.arcToPoint(
      Offset(pathSegmentX + cornerRadius, pathSegmentY),
      radius: const Radius.circular(cornerRadius),
      clockwise: false, // Counter-clockwise for right turn
    );

    // Line 3: Move right to end's center.
    customPath.lineTo(end.dx, end.dy);
    canvas.drawPath(customPath, _paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate flat indices for the start of each row for easy lookup
    final List<int> rowStartFlatIndices = <int>[];
    int currentFlatIndexForRows = 0;
    for (final List<Level> row in levelRows) {
      rowStartFlatIndices.add(currentFlatIndexForRows);
      currentFlatIndexForRows += row.length;
    }

    // Keep track of which sequential S-curves are replaced by these custom paths
    final Set<int> skippedScurveStartIndices = <int>{};

    // 2. Draw horizontal paths within rows (e.g., B to C, E to F)
    for (int r = 0; r < levelRows.length; r++) {
      final List<Level> currentRow = levelRows[r];
      if (currentRow.length > 1) {
        final int rowStartIndex = rowStartFlatIndices[r];
        for (int i = 0; i < currentRow.length - 1; i++) {
          final Offset startNodeCenter = points[rowStartIndex + i];
          final Offset endNodeCenter = points[rowStartIndex + i + 1];
          canvas.drawLine(startNodeCenter, endNodeCenter, _paint);
          // Mark these horizontal connections as skipped
          skippedScurveStartIndices.add(rowStartIndex + i);
        }
      }
    }

    // 3. Identify and draw custom "right-down-left" paths (e.g., A to C, D to F)
    for (int r = 0; r < levelRows.length; r++) {
      final List<Level> currentRow = levelRows[r];
      if (currentRow.length == 1) {
        if (r + 1 < levelRows.length && levelRows[r + 1].length == 2) {
          final int startIndex = rowStartFlatIndices[r];
          final int endIndex =
              rowStartFlatIndices[r + 1] +
              1; // Connect to the second node of the next row

          if (endIndex < points.length && startIndex < points.length) {
            // Determine the horizontal offset based on the specific connection
            double currentHorizontalOffset = _defaultHorizontalOffset;
            final Level startLevel = levelRows[r][0];
            final Level endLevel = levelRows[r + 1][1];
            if (startLevel.title == 'D' && endLevel.title == 'F') {
              currentHorizontalOffset = _dFHorizontalOffset;
            }

            _drawCustomPathRight(
              canvas,
              points[startIndex],
              points[endIndex],
              currentHorizontalOffset,
            );
            // Mark the sequential S-curves that this custom path implicitly covers as skipped.
            skippedScurveStartIndices.add(
              startIndex,
            ); // Skips connection to first node of next row
            if (startIndex + 1 < points.length) {
              skippedScurveStartIndices.add(
                startIndex + 1,
              ); // Skips connection from first to second node of next row
            }
          }
        }
      }
    }

    // 4. Identify and draw custom "left-down-right" paths (e.g., B to D, E to G)
    for (int r = 0; r < levelRows.length; r++) {
      final List<Level> currentRow = levelRows[r];
      if (currentRow.length == 2) {
        if (r + 1 < levelRows.length && levelRows[r + 1].length == 1) {
          final int startIndex =
              rowStartFlatIndices[r]; // Connect from the first node of the current two-node row
          final int endIndex = rowStartFlatIndices[r + 1];

          if (endIndex < points.length && startIndex < points.length) {
            _drawCustomPathLeft(
              canvas,
              points[startIndex],
              points[endIndex],
              _defaultHorizontalOffset,
            );
            // Mark the sequential S-curves that this custom path implicitly covers as skipped.
            skippedScurveStartIndices.add(
              startIndex,
            ); // Skips connection from first to second node of current row
            if (startIndex + 1 < points.length) {
              skippedScurveStartIndices.add(
                startIndex + 1,
              ); // Skips connection from second node of current row to next row
            }
          }
        }
      }
    }

    // 5. Identify and draw custom "single-node-to-single-node" paths (e.g., sadia to Afrin, Afrin to pinky, pinky to tuly)
    int singleConnectionCount = 0;
    for (int r = 0; r < levelRows.length - 1; r++) {
      final List<Level> currentRow = levelRows[r];
      final List<Level> nextRow = levelRows[r + 1];

      if (currentRow.length == 1 && nextRow.length == 1) {
        final int startIndex = rowStartFlatIndices[r];
        final int endIndex = rowStartFlatIndices[r + 1];

        if (endIndex < points.length && startIndex < points.length) {
          if (singleConnectionCount % 2 == 0) {
            // First, third, etc. single-to-single connection: Right-down-left
            _drawSingleNodeRightDownLeftPath(
              canvas,
              points[startIndex],
              points[endIndex],
              _defaultHorizontalOffset,
            );
          } else {
            // Second, fourth, etc. single-to-single connection: Left-down-right
            _drawSingleNodeLeftDownRightPath(
              canvas,
              points[startIndex],
              points[endIndex],
              _defaultHorizontalOffset,
            );
          }
          // Mark this connection as skipped for default S-curve drawing
          skippedScurveStartIndices.add(startIndex);
          singleConnectionCount++;
        }
      }
    }

    // 6. Draw remaining S-curves for vertical progression
    // This loop draws paths between all sequentially flattened nodes that haven't been covered by custom paths.
    for (int i = 0; i < points.length - 1; i++) {
      if (skippedScurveStartIndices.contains(i)) {
        continue;
      }

      // Draw the standard S-curve for remaining vertical connections
      final Offset from = points[i];
      final Offset to = points[i + 1];
      final double midY = (from.dy + to.dy) / 2;
      final Offset c1 = Offset(from.dx, midY);
      final Offset c2 = Offset(to.dx, midY);

      final Path path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, to.dx, to.dy);

      canvas.drawPath(path, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant LevelPathPainter old) {
    // Repaint if the layout (which defines 'points' and 'centerX') changes,
    // or if the underlying level structure (levelRows) conceptually changes.
    return old.points != points ||
        old.levelRows != levelRows ||
        old.centerX != centerX;
  }
}

class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  static const List<List<Level>> levelRows = <List<Level>>[
    <Level>[Level('D', Icons.star)],
    <Level>[Level('E', Icons.star), Level('F', Icons.star)],
    <Level>[Level('s', Icons.star)],
    <Level>[Level('a', Icons.star)],
    <Level>[Level('p', Icons.star)],
    <Level>[Level('t', Icons.star)],
    <Level>[Level('a', Icons.star)],
    <Level>[Level('a', Icons.star), Level('huju', Icons.star)],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Map', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext ctx, BoxConstraints constraints) {
            const double nodeSize = 60.0;
            const double hGap = 60.0;
            const double vGap = 120.0;
            final double centerX = constraints.maxWidth / 2;

            // 1) Compute center offsets for each node row-by-row
            final List<Offset> flatCenters = <Offset>[];
            for (int r = 0; r < levelRows.length; r++) {
              final List<Level> row = levelRows[r];
              final double rowWidth =
                  row.length * nodeSize + (row.length - 1) * hGap;
              final double startX = centerX - rowWidth / 2 + nodeSize / 2;
              final double y = 100 + r * vGap; // Tweak top margin here

              for (int i = 0; i < row.length; i++) {
                flatCenters.add(Offset(startX + i * (nodeSize + hGap), y));
              }
            }
            // Calculate total height needed for the scrollable content
            final double totalHeight =
                100 +
                (levelRows.length - 1) * vGap +
                nodeSize +
                50; // Add some extra padding at the bottom

            return SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth,
                height: totalHeight,
                child: Stack(
                  children: <Widget>[
                    // 2) Draw paths connecting the nodes
                    CustomPaint(
                      size: Size.infinite,
                      // Pass both the flattened node centers, the row structure, and centerX to the painter
                      painter: LevelPathPainter(
                        flatCenters,
                        LevelScreen.levelRows,
                        centerX,
                      ),
                    ),

                    // 3) Position each LevelNode at its computed center
                    for (int idx = 0; idx < flatCenters.length; idx++)
                      Positioned(
                        left: flatCenters[idx].dx - nodeSize / 2,
                        top: flatCenters[idx].dy - nodeSize / 2,
                        child: LevelNode(
                          // Retrieve the corresponding Level object from the flattened list
                          levelRows
                              .expand<Level>((List<Level> row) => row)
                              .toList()[idx],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() => runApp(const MaterialApp(home: LevelScreen()));
