import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashBaordScrren extends StatelessWidget {
  const DashBaordScrren({super.key});

  @override
  Widget build(BuildContext context) {
    final sales = [
      {
        'saleNo': 'POS-001',
        'customer': 'Walk-in customer',
        'amount': 13068,
        'method': 'Cash',
      },
      {
        'saleNo': 'POS-002',
        'customer': 'Tharindu Stores',
        'amount': 9936,
        'method': 'Credit',
      },
      {
        'saleNo': 'POS-003',
        'customer': 'Colombo Mini Mart',
        'amount': 7074,
        'method': 'Card',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'NOVA POS',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            color: Color(0xFF111827),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: const [
                _MetricCard(
                  title: 'Net Sales',
                  value: 'LKR 30,078',
                  icon: Icons.trending_up,
                  color: Color(0xFF23C16B),
                ),
                _MetricCard(
                  title: 'Collected',
                  value: 'LKR 24,142',
                  icon: Icons.payments_outlined,
                  color: Color(0xFF2F80ED),
                ),
                _MetricCard(
                  title: 'Credit Due',
                  value: 'LKR 5,936',
                  icon: Icons.credit_card,
                  color: Color(0xFFF59E0B),
                ),
                _MetricCard(
                  title: 'Items Sold',
                  value: '35',
                  icon: Icons.shopping_bag_outlined,
                  color: Color(0xFFE056FD),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const _QuickActions(),

            const SizedBox(height: 16),
            const _SectionTitle(title: 'Sales Overview'),
            const SizedBox(height: 10),
            const _SalesChartCard(),

            const SizedBox(height: 16),
            const _SectionTitle(title: 'Cashier Sales & Credit'),
            const SizedBox(height: 10),
            const _CashierCard(
              name: 'Super Admin',
              role: 'Super Admin',
              sales: 'LKR 20,142',
              collected: 'LKR 20,142',
              credit: 'LKR 0',
              color: Color(0xFF23C16B),
            ),
            const SizedBox(height: 10),
            const _CashierCard(
              name: 'Cashier 01',
              role: 'Cashier',
              sales: 'LKR 9,936',
              collected: 'LKR 4,000',
              credit: 'LKR 5,936',
              color: Color(0xFFF59E0B),
            ),

            const SizedBox(height: 16),
            const _SectionTitle(title: 'Recent Sales'),
            const SizedBox(height: 10),
            ...sales.map(
                  (sale) => _RecentSaleTile(
                saleNo: sale['saleNo'].toString(),
                customer: sale['customer'].toString(),
                amount: 'LKR ${sale['amount']}',
                method: sale['method'].toString(),
              ),
            ),
          ],
        ),
      ),

    );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF23C16B),
            Color(0xFF2F80ED),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good day, Super Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Today sales target progress',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.60,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                '60%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'LKR 30,078 / LKR 50,000',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _ActionButton(icon: Icons.point_of_sale, label: 'Open POS'),
        SizedBox(width: 10),
        _ActionButton(icon: Icons.receipt_long, label: 'Reports'),
        SizedBox(width: 10),
        _ActionButton(icon: Icons.inventory_2_outlined, label: 'Products'),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF111827)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 Days Sales',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: CustomPaint(
              painter: _LineChartPainter(),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF2F80ED)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF2F80ED).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.18, size.height * 0.55),
      Offset(size.width * 0.34, size.height * 0.68),
      Offset(size.width * 0.50, size.height * 0.35),
      Offset(size.width * 0.68, size.height * 0.45),
      Offset(size.width * 0.84, size.height * 0.25),
      Offset(size.width, size.height * 0.30),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    final dotPaint = Paint()..color = const Color(0xFF23C16B);
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CashierCard extends StatelessWidget {
  final String name;
  final String role;
  final String sales;
  final String collected;
  final String credit;
  final Color color;

  const _CashierCard({
    required this.name,
    required this.role,
    required this.sales,
    required this.collected,
    required this.credit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Text(
                  name.substring(0, 1),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      role,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Text(
                sales,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniValue(label: 'Collected', value: collected)),
              Expanded(child: _MiniValue(label: 'Credit', value: credit)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  final String saleNo;
  final String customer;
  final String amount;
  final String method;

  const _RecentSaleTile({
    required this.saleNo,
    required this.customer,
    required this.amount,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.receipt_long, color: Color(0xFF2F80ED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saleNo,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '$customer / $method',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE5E7EB)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}