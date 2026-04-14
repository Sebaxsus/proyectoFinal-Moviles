import 'package:flutter/material.dart';

void main() {
  runApp(const GasMonitorApp());
}

class GasMonitorApp extends StatelessWidget {
  const GasMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mockup',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0C101B), // Dark blue-black
        primaryColor: Colors.tealAccent,
        textTheme: ThemeData.dark().textTheme.copyWith(
              headlineSmall: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              titleLarge: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              bodyMedium: const TextStyle(fontSize: 14, color: Colors.white70),
              bodySmall: const TextStyle(fontSize: 12, color: Colors.blueAccent),
            ),
      ),
      home: const GasHomeScreen(),
    );
  }
}

class GasHomeScreen extends StatefulWidget {
  const GasHomeScreen({super.key});

  @override
  State<GasHomeScreen> createState() => _GasHomeScreenState();
}

class _GasHomeScreenState extends State<GasHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            // Top Status Area
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('9:41', style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      const Icon(Icons.circle_notifications_outlined, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            // App Bar Title Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.tealAccent, size: 28),
                  const SizedBox(width: 10),
                  Text('MockUp', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  // Online Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.tealAccent, size: 10),
                        const SizedBox(width: 5),
                        const Text('En línea',
                            style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen del Día Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen del Día',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Text('14/04/2026', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                  ],
                ),
                // Normal Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: Colors.greenAccent, size: 12),
                      const SizedBox(width: 5),
                      const Text('✓ Normal',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4 summary cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.4,
              children: [
                _buildSummaryCard(
                  context: context,
                  icon: const Icon(Icons.flash_on, color: Colors.tealAccent, size: 28),
                  value: '24.50 ppm',
                  label: 'Último Registro',
                ),
                _buildSummaryCard(
                  context: context,
                  icon: const Icon(Icons.insights, color: Colors.tealAccent, size: 28),
                  value: '21.80 ppm',
                  label: 'Promedio del Día',
                ),
                _buildSummaryCard(
                  context: context,
                  icon: const Icon(Icons.trending_up, color: Colors.deepOrangeAccent, size: 28),
                  value: '38.10 ppm',
                  label: 'Máximo del Día',
                  valueColor: Colors.deepOrangeAccent,
                ),
                _buildSummaryCard(
                  context: context,
                  icon: const Icon(Icons.trending_down, color: Colors.tealAccent, size: 28),
                  value: '8.30 ppm',
                  label: 'Mínimo del Día',
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Lecturas de Hoy Section
            Text('Lecturas de Hoy',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 15),

            // Chart area (Mock using Container/Painter or image placeholder)
            Container(
              height: 200,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF141A33),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Stylized line chart path (mock)
                  Expanded(
                    child: CustomPaint(
                      painter: ChartPainter(),
                    ),
                  ),
                  // X-axis labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('00:00',
                          style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
                      const Text('12:00',
                          style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
                      const Text('23:59',
                          style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0F1F),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.blueAccent,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 0 ? Icons.home_filled : Icons.home),
              label: 'Hoy',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Mes',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              label: 'General',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              label: 'Seguridad',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required Widget icon,
    required String value,
    required String label,
    Color valueColor = Colors.tealAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF141A33),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [icon, const Icon(Icons.star_border, color: Colors.blueAccent, size: 16)],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor),
              ),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.tealAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.1, size.height * 0.65);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.45);
    path.cubicTo(
        size.width * 0.4, size.height * 0.3, size.width * 0.5, size.height * 0.1, size.width * 0.6, size.height * 0.35);
    path.cubicTo(size.width * 0.7, size.height * 0.6, size.width * 0.85,
        size.height * 0.7, size.width, size.height * 0.7);

    // Fill the path
    canvas.drawPath(path, fillPaint);

    // Draw the line
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}