import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lullie_app/services/statistics_service.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int _selectedPeriod = 7; // Default to weekly view
  final List<int> _availablePeriods = [7, 30, 90]; // Days
  final StatisticsService _statisticsService = StatisticsService();
  
  List<Map<String, dynamic>> _sleepData = [];
  List<Map<String, dynamic>> _musicSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final sleepData = await _statisticsService.getSleepData();
      final musicSessions = await _statisticsService.getMusicSessions();
      
      // Filter data based on selected period
      final now = DateTime.now();
      final periodStart = now.subtract(Duration(days: _selectedPeriod));
      
      setState(() {
        _sleepData = sleepData.where((data) {
          final date = DateTime.parse(data['date']);
          return date.isAfter(periodStart);
        }).toList();
        
        _musicSessions = musicSessions.where((session) {
          final date = DateTime.parse(session['startTime']);
          return date.isAfter(periodStart);
        }).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/lulify-bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Period Selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _availablePeriods.map((days) {
                            final bool isSelected = days == _selectedPeriod;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ChoiceChip(
                                label: Text(
                                  '${days}d',
                                  style: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: Colors.deepPurple,
                                backgroundColor: Colors.black26,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setState(() => _selectedPeriod = days);
                                    _loadData();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sleep Duration Chart
                      if (_sleepData.isNotEmpty) ...[
                        _buildSection(
                          title: 'Sleep Duration',
                          height: 220,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}h',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= _sleepData.length) return const SizedBox();
                                        final date = DateTime.parse(_sleepData[value.toInt()]['date']);
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            '${date.day}/${date.month}',
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _sleepData.asMap().entries.map((entry) {
                                      return FlSpot(
                                        entry.key.toDouble(),
                                        entry.value['durationMinutes'] / 60,
                                      );
                                    }).toList(),
                                    isCurved: true,
                                    color: Colors.deepPurpleAccent,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.deepPurpleAccent.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                                minY: 0,
                                maxY: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Sleep Quality Chart
                      if (_sleepData.isNotEmpty) ...[
                        _buildSection(
                          title: 'Sleep Quality',
                          height: 220,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: BarChart(
                              BarChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= _sleepData.length) return const SizedBox();
                                        final date = DateTime.parse(_sleepData[value.toInt()]['date']);
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            '${date.day}/${date.month}',
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _sleepData.asMap().entries.map((entry) {
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value['quality'].toDouble(),
                                        color: Colors.deepPurpleAccent,
                                        width: 16,
                                        borderRadius: BorderRadius.circular(4),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: 5,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                maxY: 5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Summary Statistics
                      _buildSection(
                        title: 'Summary',
                        child: Column(
                          children: [
                            _buildSummaryItem(
                              icon: Icons.bedtime,
                              label: 'Average Sleep Duration',
                              value: _sleepData.isEmpty
                                  ? 'No data'
                                  : '${(_sleepData.map((d) => d['durationMinutes']).reduce((a, b) => a + b) / _sleepData.length / 60).toStringAsFixed(1)}h',
                            ),
                            const Divider(color: Colors.white24),
                            _buildSummaryItem(
                              icon: Icons.star,
                              label: 'Average Sleep Quality',
                              value: _sleepData.isEmpty
                                  ? 'No data'
                                  : '${(_sleepData.map((d) => d['quality']).reduce((a, b) => a + b) / _sleepData.length).toStringAsFixed(1)}/5',
                            ),
                            const Divider(color: Colors.white24),
                            _buildSummaryItem(
                              icon: Icons.music_note,
                              label: 'Music Sessions',
                              value: '${_musicSessions.length}',
                            ),
                            if (_musicSessions.isNotEmpty) ...[
                              const Divider(color: Colors.white24),
                              _buildSummaryItem(
                                icon: Icons.timer,
                                label: 'Average Music Duration',
                                value: '${(_musicSessions.map((s) => s['duration']).reduce((a, b) => a + b) / _musicSessions.length).toStringAsFixed(0)}m',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    double? height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (height == null) const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 