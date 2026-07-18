import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpos/dio_client/dio_client.dart';
import 'package:mpos/resources/api_routes.dart';

class DashBaordScrren extends StatefulWidget {
  const DashBaordScrren({super.key});

  @override
  State<DashBaordScrren> createState() => _DashBaordScrrenState();
}

class _DashBaordScrrenState extends State<DashBaordScrren> {
  final _dio = DioClient().dio;
  late _DashboardData _dashboard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dashboard = _DashboardData.fallback();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _dio.get(ApiRoutes.dashboard);
      final payload = _asMap(response.data);
      if (mounted) {
        setState(() => _dashboard = _DashboardData.fromJson(payload));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _messageFor(error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFor(Object error) {
    final value = error.toString();
    if (value.contains('SocketException') || value.contains('Connection')) {
      return 'Dashboard API unavailable. Showing saved sample data.';
    }
    return 'Could not load dashboard. Showing saved sample data.';
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          dashboard.storeName,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            color: colorScheme.onSurface,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[
                _StatusBanner(message: _error!),
                const SizedBox(height: 12),
              ],
              _HeaderCard(metrics: dashboard.metrics),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _MetricCard(
                    title: 'Net Sales',
                    value: _money(dashboard.metrics.netSales),
                    icon: Icons.trending_up,
                    color: const Color(0xFF10B981),
                  ),
                  _MetricCard(
                    title: 'Collected',
                    value: _money(dashboard.metrics.collected),
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF3B82F6),
                  ),
                  _MetricCard(
                    title: 'Credit Due',
                    value: _money(dashboard.metrics.creditDue),
                    icon: Icons.credit_card,
                    color: const Color(0xFFF59E0B),
                  ),
                  _MetricCard(
                    title: 'Items Sold',
                    value: _number(dashboard.metrics.itemsSold),
                    icon: Icons.shopping_bag_outlined,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _QuickActions(),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Sales Overview'),
              const SizedBox(height: 10),
              _SalesChartCard(points: dashboard.chart),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Cashier Sales & Credit'),
              const SizedBox(height: 10),
              if (dashboard.cashiers.isEmpty)
                const _EmptyCard(message: 'No cashier sales found yet.')
              else
                ...dashboard.cashiers.map(
                  (cashier) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CashierCard(cashier: cashier),
                  ),
                ),
              const SizedBox(height: 6),
              const _SectionTitle(title: 'Recent Sales'),
              const SizedBox(height: 10),
              if (dashboard.recentSales.isEmpty)
                const _EmptyCard(message: 'No recent sales found yet.')
              else
                ...dashboard.recentSales.map(
                  (sale) => _RecentSaleTile(sale: sale),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  final _DashboardMetrics metrics;
  final List<_ChartPoint> chart;
  final List<_CashierSummary> cashiers;
  final List<_RecentSale> recentSales;
  final String storeName;

  const _DashboardData({
    required this.metrics,
    required this.chart,
    required this.cashiers,
    required this.recentSales,
    required this.storeName,
  });

  factory _DashboardData.fromJson(Map<String, dynamic> payload) {
    final wrappedData = _asMap(payload['data']);
    final root = wrappedData.isNotEmpty ? wrappedData : payload;
    final storeProfile = _asMap(root['store_profile']);
    return _DashboardData(
      metrics: _DashboardMetrics.fromJson(_asMap(root['metrics'])),
      chart: _asList(root['chart'])
          .map((item) => _ChartPoint.fromJson(_asMap(item)))
          .toList(),
      cashiers: _asList(root['cashier_summaries'])
          .map((item) => _CashierSummary.fromJson(_asMap(item)))
          .toList(),
      recentSales: _asList(root['recent_sales'])
          .map((item) => _RecentSale.fromJson(_asMap(item)))
          .toList(),
      storeName: _text(
        storeProfile['store_name'] ?? storeProfile['name'],
        fallback: 'NOVA POS',
      ),
    );
  }

  factory _DashboardData.fallback() {
    return _DashboardData(
      metrics: const _DashboardMetrics(
        netSales: 0,
        collected: 0,
        creditDue: 0,
        itemsSold: 0,
        todayTarget: 0,
        targetProgress: 0,
      ),
      chart: const [],
      cashiers: const [],
      recentSales: const [],
      storeName: 'NOVA POS',
    );
  }
}

class _DashboardMetrics {
  final double netSales;
  final double collected;
  final double creditDue;
  final double itemsSold;
  final double todayTarget;
  final double targetProgress;

  const _DashboardMetrics({
    required this.netSales,
    required this.collected,
    required this.creditDue,
    required this.itemsSold,
    required this.todayTarget,
    required this.targetProgress,
  });

  factory _DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final netSales = _num(json['net_sales'] ?? json['total_sales']);
    final todayTarget = _num(json['today_target']);
    final progress = _num(json['target_progress']);
    return _DashboardMetrics(
      netSales: netSales,
      collected: _num(json['collected'] ?? json['paid_amount']),
      creditDue: _num(json['credit_due'] ?? json['credit_amount']),
      itemsSold: _num(json['items_sold'] ?? json['total_items']),
      todayTarget: todayTarget,
      targetProgress: progress > 0
          ? progress
          : todayTarget > 0
              ? (netSales / todayTarget) * 100
              : 0,
    );
  }
}

class _ChartPoint {
  final String label;
  final double total;

  const _ChartPoint({required this.label, required this.total});

  factory _ChartPoint.fromJson(Map<String, dynamic> json) {
    return _ChartPoint(
      label: _text(
        json['label'] ?? json['date'] ?? json['day'] ?? json['sold_at'],
        fallback: '',
      ),
      total: _num(json['total'] ?? json['net_sales'] ?? json['sales']),
    );
  }
}

class _CashierSummary {
  final String name;
  final String role;
  final double totalSales;
  final double collected;
  final double credit;

  const _CashierSummary({
    required this.name,
    required this.role,
    required this.totalSales,
    required this.collected,
    required this.credit,
  });

  factory _CashierSummary.fromJson(Map<String, dynamic> json) {
    return _CashierSummary(
      name: _text(json['cashier_name'] ?? json['name'], fallback: 'Cashier'),
      role: _text(json['role'] ?? json['role_name'], fallback: 'Cashier'),
      totalSales: _num(json['total_sales'] ?? json['sales']),
      collected: _num(json['collected'] ?? json['paid_amount']),
      credit: _num(json['credit'] ?? json['credit_amount']),
    );
  }
}

class _RecentSale {
  final String saleNo;
  final String customer;
  final double total;
  final String paymentMethod;

  const _RecentSale({
    required this.saleNo,
    required this.customer,
    required this.total,
    required this.paymentMethod,
  });

  factory _RecentSale.fromJson(Map<String, dynamic> json) {
    return _RecentSale(
      saleNo: _text(json['sale_no'] ?? json['invoice_no'], fallback: 'POS'),
      customer: _text(
        json['customer_name'] ??
            json['customer'] ??
            json['customer_display_name'],
        fallback: 'Walk-in customer',
      ),
      total: _num(json['total_amount'] ?? json['total'] ?? json['net_total']),
      paymentMethod: _text(json['payment_method'], fallback: 'Cash'),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;

  const _StatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF92400E).withValues(alpha: 0.4) : const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final _DashboardMetrics metrics;

  const _HeaderCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final progress = (metrics.targetProgress / 100).clamp(0.0, 1.0).toDouble();
    final targetLabel = metrics.todayTarget > 0
        ? '${_money(metrics.netSales)} / ${_money(metrics.todayTarget)}'
        : '${_money(metrics.netSales)} today';

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
            'Good day',
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
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${metrics.targetProgress.clamp(0, 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            targetLabel,
            style: const TextStyle(color: Colors.white),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      children: [
        _ActionButton(
          icon: Icons.point_of_sale,
          label: 'Open POS',
          onTap: () => context.go('/pos_terminal'),
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.receipt_long,
          label: 'Reports',
          onTap: () => context.go('/pos-management'),
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.inventory_2_outlined,
          label: 'Products',
          onTap: () => context.go('/pos-management'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colorScheme.onSurface),
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
      ),
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  final List<_ChartPoint> points;

  const _SalesChartCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 210,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 Days Sales',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'No chart data',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  )
                : CustomPaint(
                    painter: _LineChartPainter(points, theme.colorScheme.primary),
                    child: Container(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<_ChartPoint> chartPoints;
  final Color primaryColor;

  const _LineChartPainter(this.chartPoints, this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final totals = chartPoints.map((point) => point.total).toList();
    final maxValue = totals.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final effectiveMax = maxValue <= 0 ? 1 : maxValue;

    final paintLine = Paint()
      ..color = primaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final widthStep = chartPoints.length == 1
        ? size.width
        : size.width / (chartPoints.length - 1);
    final points = <Offset>[];
    for (var index = 0; index < chartPoints.length; index++) {
      final value = chartPoints[index].total;
      final x = chartPoints.length == 1 ? size.width / 2 : index * widthStep;
      final y = size.height - ((value / effectiveMax) * (size.height * 0.86));
      points.add(Offset(x, y.clamp(6, size.height - 6).toDouble()));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    final dotPaint = Paint()..color = const Color(0xFF23C16B);
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.chartPoints != chartPoints;
  }
}

class _CashierCard extends StatelessWidget {
  final _CashierSummary cashier;

  const _CashierCard({required this.cashier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = cashier.credit > 0
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Text(
                  cashier.name.isEmpty ? 'C' : cashier.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cashier.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      cashier.role,
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Text(
                _money(cashier.totalSales),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniValue(
                  label: 'Collected',
                  value: _money(cashier.collected),
                ),
              ),
              Expanded(
                child: _MiniValue(
                  label: 'Credit',
                  value: _money(cashier.credit),
                ),
              ),
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
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
  final _RecentSale sale;

  const _RecentSaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            child: Icon(Icons.receipt_long, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.saleNo,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${sale.customer} / ${sale.paymentMethod}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Text(
            _money(sale.total),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return BoxDecoration(
    color: theme.cardTheme.color ?? theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.2)),
    boxShadow: isDark ? [] : [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

double _num(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _text(dynamic value, {required String fallback}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _number(num value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final reverseIndex = rounded.length - i;
    buffer.write(rounded[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _money(num value) => 'LKR ${_number(value)}';
