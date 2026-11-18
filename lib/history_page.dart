
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryPage extends StatelessWidget {
  final DatabaseReference database;

  const HistoryPage({
    super.key,
    required this.database,
  });

  Map<String, dynamic> asMap(Object? value) {
    if (value is Map) {
      return value.map(
            (key, value) => MapEntry(key.toString(), value),
      );
    }
    return {};
  }

  double number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String showValue(Object? value) {
    if (value == null || value.toString().isEmpty) {
      return '--';
    }
    return value.toString();
  }

  String showTime(Map<String, dynamic> data) {
    final value = data['timestamp'];

    if (value is num) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      ).toLocal();

      String two(int n) => n.toString().padLeft(2, '0');

      return '${two(date.day)}/${two(date.month)} '
          '${two(date.hour)}:${two(date.minute)}';
    }

    return showValue(data['time'] ?? value);
  }

  Widget temperatureChart(
      List<Map<String, dynamic>> records,
      ) {
    final recent = records.reversed.take(8).toList();

    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxValue = 40;

    for (final record in recent) {
      final temp = number(record['temperature']);
      if (temp > maxValue) maxValue = temp;
    }

    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temperature History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Latest 8 readings (°C)',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < recent.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.end,
                          children: [
                            Text(
                              number(
                                recent[i]['temperature'],
                              ).toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Container(
                              height: 120 *
                                  (number(
                                    recent[i]['temperature'],
                                  ).clamp(0, maxValue) /
                                      maxValue),
                              decoration: BoxDecoration(
                                color: Colors.cyan,
                                borderRadius:
                                BorderRadius.circular(6),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget historyCard(
      Map<String, dynamic> data,
      ) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.cyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  showTime(data),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              'Temperature: '
                  '${showValue(data['temperature'])} °C',
            ),

            Text(
              'Humidity: '
                  '${showValue(data['humidity'])} %',
            ),

            Text(
              'Gas: ${showValue(data['gas'])}',
            ),

            Text(
              'Light: ${showValue(data['light'])}',
            ),

            const SizedBox(height: 5),

            Text(
              'Status: ${showValue(data['status'])}',
              style: const TextStyle(
                color: Colors.cyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: database.child('History').onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'History error: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final history = asMap(
          snapshot.data!.snapshot.value,
        );

        if (history.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 60,
                    color: Colors.cyan,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No History Yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Historical sensor readings will '
                        'appear here after ESP32 saves '
                        'data to Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final entries = history.entries.toList();

        // Sort by timestamp if available.
        entries.sort((a, b) {
          final aData = asMap(a.value);
          final bData = asMap(b.value);

          final aTime =
          number(aData['timestamp']);
          final bTime =
          number(bData['timestamp']);

          if (aTime != bTime) {
            return bTime.compareTo(aTime);
          }

          return b.key.compareTo(a.key);
        });

        final records = entries
            .take(30)
            .map((entry) => asMap(entry.value))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Sensor History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${history.length} saved records',
              style: const TextStyle(
                color: Colors.white60,
              ),
            ),

            const SizedBox(height: 15),

            temperatureChart(records),

            const SizedBox(height: 15),

            const Text(
              'Recent Readings',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            for (final record in records)
              historyCard(record),
          ],
        );
      },
    );
  }
}
