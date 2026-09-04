class DashboardStats {
  final double todayRevenue;
  final double yesterdayRevenue;
  final double totalRevenue;
  final double? revenueChangePercent;
  final double occupancyRate;
  final int occupiedRooms;
  final int totalRooms;
  final int availableRooms;
  final int cleaningRooms;
  final int reservedRooms;
  final int maintenanceRooms;
  final int checkInsToday;
  final int checkOutsToday;
  final int activeBookings;
  final int pendingBookings;
  final int unpaidInvoices;
  final Map<String, int> roomStatusBreakdown;
  final List<dynamic>? weeklyRevenue;

  const DashboardStats({
    required this.todayRevenue,
    this.yesterdayRevenue = 0,
    this.totalRevenue = 0,
    this.revenueChangePercent,
    required this.occupancyRate,
    required this.occupiedRooms,
    required this.totalRooms,
    required this.availableRooms,
    required this.cleaningRooms,
    required this.reservedRooms,
    required this.maintenanceRooms,
    required this.checkInsToday,
    required this.checkOutsToday,
    this.activeBookings = 0,
    required this.pendingBookings,
    this.unpaidInvoices = 0,
    this.roomStatusBreakdown = const {},
    this.weeklyRevenue,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    /// Chấp nhận cả số lẫn chuỗi phần trăm dạng "50.0%" (khóa `rooms.occupancyRate`).
    num parseNum(dynamic val, [num fallback = 0]) {
      if (val == null) return fallback;
      if (val is num) return val;
      final text = val.toString().replaceAll('%', '').trim();
      return num.tryParse(text) ?? fallback;
    }

    final rooms = json['rooms'] as Map?;
    final activity = json['todayActivity'] as Map?;

    final rawRevenue = json['todayRevenue'] ?? json['totalRevenueToday'];
    final todayRevenue = parseNum(rawRevenue).toDouble();
    final revenueChangePercent = json['revenueChangePercent'] != null
        ? parseNum(json['revenueChangePercent']).toDouble()
        : null;

    final totalRooms = parseNum(json['totalRooms'] ?? rooms?['total']).toInt();
    final occupiedRooms =
        parseNum(json['occupiedRooms'] ?? rooms?['occupied']).toInt();

    final rawRate = json['occupancyRate'] ?? rooms?['occupancyRate'];
    final double occupancyRate = rawRate != null
        ? parseNum(rawRate).toDouble()
        : (totalRooms > 0 ? (occupiedRooms / totalRooms * 100) : 0.0);

    final checkInsToday = parseNum(
      json['checkInsToday'] ??
          json['todayCheckIns'] ??
          activity?['expectedCheckIns'],
    ).toInt();

    final checkOutsToday = parseNum(
      json['checkOutsToday'] ??
          json['todayCheckOuts'] ??
          activity?['expectedCheckOuts'],
    ).toInt();

    final activeBookings = parseNum(
      json['activeBookings'] ?? activity?['activeBookings'],
    ).toInt();

    final pendingBookings = parseNum(json['pendingBookings']).toInt();
    final unpaidInvoices = parseNum(json['unpaidInvoices']).toInt();

    final breakdownRaw = json['roomStatusBreakdown'] as Map?;
    final Map<String, int> roomStatusBreakdown = {};
    if (breakdownRaw != null) {
      breakdownRaw.forEach((k, v) {
        roomStatusBreakdown[k.toString()] = parseNum(v).toInt();
      });
    }

    final availableRooms = roomStatusBreakdown['AVAILABLE'] ??
        parseNum(json['availableRooms'] ?? rooms?['available']).toInt();
    final cleaningRooms = roomStatusBreakdown['CLEANING'] ??
        parseNum(json['cleaningRooms'] ?? rooms?['cleaning']).toInt();
    final reservedRooms = roomStatusBreakdown['RESERVED'] ??
        parseNum(json['reservedRooms'] ?? rooms?['reserved']).toInt();
    final maintenanceRooms = roomStatusBreakdown['MAINTENANCE'] ??
        parseNum(json['maintenanceRooms'] ?? rooms?['maintenance']).toInt();

    final weeklyRevenue = json['weeklyRevenue'] as List? ??
        json['revenueWeekly'] as List?;

    return DashboardStats(
      todayRevenue: todayRevenue,
      yesterdayRevenue: parseNum(json['yesterdayRevenue']).toDouble(),
      totalRevenue: parseNum(json['totalRevenue']).toDouble(),
      revenueChangePercent: revenueChangePercent,
      occupancyRate: occupancyRate,
      occupiedRooms: occupiedRooms,
      totalRooms: totalRooms,
      availableRooms: availableRooms,
      cleaningRooms: cleaningRooms,
      reservedRooms: reservedRooms,
      maintenanceRooms: maintenanceRooms,
      checkInsToday: checkInsToday,
      checkOutsToday: checkOutsToday,
      activeBookings: activeBookings,
      pendingBookings: pendingBookings,
      unpaidInvoices: unpaidInvoices,
      roomStatusBreakdown: roomStatusBreakdown,
      weeklyRevenue: weeklyRevenue,
    );
  }
}
