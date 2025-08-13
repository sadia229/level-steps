import 'package:flutter/material.dart';

/// A class representing a single level in the game map.
class Level {
  final String title;
  final IconData icon;
  final bool unlocked;

  const Level(this.title, this.icon, {this.unlocked = false});
}

/// A custom painter for drawing the paths between level nodes.
class LevelPathPainter extends CustomPainter {
  final List<Offset> points; // Flattened list of all node centers
  final List<List<Level>> levelRows; // Structure of levels by row
  final double
  centerX; // Center X coordinate of the screen/layout for reference

  final Paint _paint = Paint()
    ..color = Colors.grey.shade400.withOpacity(0.3)
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke;

  // Constant for horizontal offset used in zig-zag paths
  static const double _zigZagOffsetStandard = 120.0;

  LevelPathPainter(this.points, this.levelRows, this.centerX);

  /// Helper to draw a zig-zag path: start (left/right) -> down -> end (left/right)
  void _drawZigZagPath(
    Canvas canvas,
    Offset start,
    Offset end,
    double horizontalOffset,
    bool startFromRight, // true for Right-Down-Left, false for Left-Down-Right
  ) {
    const double cornerRadius = 50.0;
    final double pathSegmentX;
    final Path customPath = Path();

    customPath.moveTo(start.dx, start.dy);

    if (startFromRight) {
      // Path goes right, then down, then left to reach the end.
      pathSegmentX = centerX + horizontalOffset;
      // Line 1: Move right from start's center.
      customPath.lineTo(pathSegmentX - cornerRadius, start.dy);
      // Arc 1: Turn down-right.
      customPath.arcToPoint(
        Offset(pathSegmentX, start.dy + cornerRadius),
        radius: const Radius.circular(cornerRadius),
        clockwise: true,
      );
      // Line 2: Move down along the vertical segment.
      customPath.lineTo(pathSegmentX, end.dy - cornerRadius);
      // Arc 2: Turn down-left.
      customPath.arcToPoint(
        Offset(pathSegmentX - cornerRadius, end.dy),
        radius: const Radius.circular(cornerRadius),
        clockwise: true,
      );
    } else {
      // Path goes left, then down, then right to reach the end.
      pathSegmentX = centerX - horizontalOffset;
      // Line 1: Move left from start's center.
      customPath.lineTo(pathSegmentX + cornerRadius, start.dy);
      // Arc 1: Turn down-left.
      customPath.arcToPoint(
        Offset(pathSegmentX, start.dy + cornerRadius),
        radius: const Radius.circular(cornerRadius),
        clockwise: false, // Counter-clockwise for left turn
      );
      // Line 2: Move down along the vertical segment.
      customPath.lineTo(pathSegmentX, end.dy - cornerRadius);
      // Arc 2: Turn down-right.
      customPath.arcToPoint(
        Offset(pathSegmentX + cornerRadius, end.dy),
        radius: const Radius.circular(cornerRadius),
        clockwise: false, // Counter-clockwise for right turn
      );
    }
    // Line 3: Move towards the end point.
    customPath.lineTo(end.dx, end.dy);
    canvas.drawPath(customPath, _paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate flat indices for the start of each row for easy lookup
    final List<int> rowStartFlatIndices = <int>[0];
    int currentFlatIndexForRows = 0;
    for (int r = 0; r < levelRows.length; r++) {
      currentFlatIndexForRows += levelRows[r].length;
      if (r < levelRows.length - 1) {
        rowStartFlatIndices.add(currentFlatIndexForRows);
      }
    }

    // 2. Draw horizontal paths within rows
    for (int r = 0; r < levelRows.length; r++) {
      final List<Level> currentRow = levelRows[r];
      if (currentRow.length > 1) {
        final int rowStartIndex = rowStartFlatIndices[r];
        for (int i = 0; i < currentRow.length - 1; i++) {
          final Offset startNodeCenter = points[rowStartIndex + i];
          final Offset endNodeCenter = points[rowStartIndex + i + 1];
          canvas.drawLine(startNodeCenter, endNodeCenter, _paint);
        }
      }
    }

    // 3. Draw vertical zig-zag paths between rows with alternating "left/right" flow
    for (int r = 0; r < levelRows.length - 1; r++) {
      final List<Level> currentRow = levelRows[r];
      final List<Level> nextRow = levelRows[r + 1];

      // Ensure both current and next row are not empty to make a connection
      if (currentRow.isNotEmpty && nextRow.isNotEmpty) {
        final int fromFlatIndex =
            rowStartFlatIndices[r] +
            currentRow.length -
            1; // Last node of current row
        final int toFlatIndex =
            rowStartFlatIndices[r + 1]; // First node of next row

        final Offset from = points[fromFlatIndex];
        final Offset to = points[toFlatIndex];

        // Alternate the direction:
        // If 'r' is even (0, 2, 4...), start from the left (Left-Down-Right).
        // If 'r' is odd (1, 3, 5...), start from the right (Right-Down-Left).
        final bool startFromRight = (r % 2 != 0);

        _drawZigZagPath(
          canvas,
          from,
          to,
          _zigZagOffsetStandard, // Use a consistent horizontal offset
          startFromRight,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LevelPathPainter old) {
    // Repaint if the layout (points, centerX) or level structure changes.
    return old.points != points ||
        old.levelRows != levelRows ||
        old.centerX != centerX;
  }
}

/// A widget that displays a single level node.
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

/// The main screen displaying the level map.
class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  // Data model for the game levels, structured by rows.
  // Expanded to demonstrate dynamic path generation for more levels.
  static const List<List<Level>> levelRows = <List<Level>>[
    <Level>[Level('Inception', Icons.movie, unlocked: true)],
    <Level>[
      Level('Interstellar', Icons.public),
      Level('Tenet', Icons.access_time),
    ],
    <Level>[Level('The Dark Knight', Icons.shield_moon)],
    <Level>[Level('The Prestige', Icons.auto_awesome)],
    <Level>[Level('Dunkirk', Icons.flight_takeoff, unlocked: true)],
    <Level>[Level('E', Icons.forest), Level('F', Icons.filter_drama)],
    <Level>[Level('Inception', Icons.movie, unlocked: true)],
    <Level>[
      Level('Interstellar', Icons.public),
      Level('Tenet', Icons.access_time),
    ],
    <Level>[Level('The Dark Knight', Icons.shield_moon)],
    <Level>[Level('The Prestige', Icons.auto_awesome)],
    <Level>[Level('Dunkirk', Icons.flight_takeoff, unlocked: true)],
    <Level>[Level('E', Icons.forest), Level('F', Icons.filter_drama)],
    //     <Level>[Level('D', Icons.diamond, unlocked: true)],
    //     <Level>[Level('E', Icons.forest), Level('F', Icons.filter_drama)],
    //     <Level>[Level('s', Icons.castle)],
    //     <Level>[Level('a', Icons.cruelty_free)],
    //     <Level>[Level('t', Icons.park)],
    //     <Level>[Level('A', Icons.star_border), Level('B', Icons.square)],
    //     <Level>[Level('C', Icons.cloud_circle)],
    //     <Level>[Level('huju', Icons.thunderstorm), Level('D', Icons.water)],
    //     <Level>[Level('E', Icons.waves), Level('F', Icons.wb_sunny)],
    //     <Level>[Level('Ddd', Icons.umbrella)],
    //     <Level>[Level('Edd', Icons.hourglass_empty), Level('Fss', Icons.palette)],
    //     <Level>[Level('tdddddd', Icons.landscape)],
    //     <Level>[Level('asdsd', Icons.rocket_launch)],
    //     <Level>[Level('Edd', Icons.hourglass_empty), Level('Fss', Icons.palette)],
    //     <Level>[Level('D', Icons.diamond, unlocked: true)],
    //     <Level>[Level('E', Icons.forest), Level('F', Icons.filter_drama)],
    //     <Level>[Level('a', Icons.cruelty_free)],
    //     <Level>[Level('t', Icons.park)],
    //     <Level>[Level('a', Icons.cruelty_free)],
    //     <Level>[Level('t', Icons.park, unlocked: true)],
    //     <Level>[Level('E', Icons.forest), Level('F', Icons.filter_drama)],
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

            // Compute center offsets for each node row-by-row
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

            // Flatten all levels for easy access when positioning LevelNodes
            final List<Level> allLevelsFlat = levelRows
                .expand<Level>((List<Level> row) => row)
                .toList();

            return SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth,
                height: totalHeight,
                child: Stack(
                  children: <Widget>[
                    // Draw paths connecting the nodes
                    CustomPaint(
                      size: Size.infinite,
                      painter: LevelPathPainter(
                        flatCenters,
                        LevelScreen.levelRows,
                        centerX,
                      ),
                    ),

                    // Position each LevelNode at its computed center
                    for (int idx = 0; idx < flatCenters.length; idx++)
                      Positioned(
                        left: flatCenters[idx].dx - nodeSize / 2,
                        top: flatCenters[idx].dy - nodeSize / 2,
                        child: LevelNode(
                          allLevelsFlat[idx], // Retrieve the Level object
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
