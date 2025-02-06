import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// Definisikan kelas DashboardScreen sebagai StatefulWidget
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

// StreamSubscription untuk mendengarkan perubahan data sensor
class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription<DatabaseEvent>? sensorDataSubscription;

  // Controller untuk input threshold
  final tempUpperController = TextEditingController();
  final tempLowerController = TextEditingController();
  final humidityUpperController = TextEditingController();
  final humidityLowerController = TextEditingController();

  // Variabel untuk menyimpan perangkat yang dipilih, data perangkat, dan data sensor
  String selectedDevice = '';
  List<String> devices = [];
  List<double> temperatureData = [];
  List<double> humidityData = [];

  // Referensi ke Firebase Realtime Database
  final databaseRef = FirebaseDatabase.instance.ref();

  // Plugin untuk notifikasi lokal
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Variabel untuk menyimpan nilai sensor dan threshold
  double temperature = 0.0;
  double humidity = 0.0;
  double tlowerlimit = 0.0;
  double tupperLimit = 0.0;
  double hlowerlimit = 0.0;
  double hupperlimit = 0.0;

  double previousTemperature = 0.0;
  double previousHumidity = 0.0;

  double tempUpperLimit = 50.0;
  double tempLowerLimit = 0.0;
  double humidityUpperLimit = 100.0;
  double humidityLowerLimit = 0.0;

  DateTime? lastNotificationTime;

  @override
  void initState() {
    super.initState();
    _initializeFlutterLocalNotifications();
    _loadDevices();
    _setupFirebaseMessaging();
  }

  @override
  void dispose() {
    // Pastikan untuk membuang controller saat tidak lagi digunakan
    tempUpperController.dispose();
    tempLowerController.dispose();
    humidityUpperController.dispose();
    humidityLowerController.dispose();

    sensorDataSubscription?.cancel();
    super.dispose();
  }

  // Inisialisasi notifikasi lokal
  void _initializeFlutterLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        // Contoh: Navigasi ke halaman tertentu
        if (notificationResponse.payload != null) {
          // Navigasi atau tindakan lain
          print(
              'Notifikasi diklik dengan payload: ${notificationResponse.payload}');
        }
      },
    );
    _createNotificationChannel();
  }

  // Membuat channel notifikasi
  void _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Setup Firebase Messaging
  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // Tampilkan notifikasi menggunakan flutter_local_notifications
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // Ganti dengan channel ID Anda
              'High Importance Notifications', // Ganti dengan channel name Anda
              channelDescription:
                  'This channel is used for important notifications', // Ganti dengan deskripsi channel Anda
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
    });

    FirebaseMessaging.instance.subscribeToTopic('Envirolink');
  }

  // Memuat daftar perangkat dari Firebase
  void _loadDevices() {
    databaseRef.child('sensors').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map<dynamic, dynamic>) {
        setState(() {
          devices = data.keys.map((key) => key.toString()).toList();
          if (selectedDevice.isEmpty && devices.isNotEmpty) {
            selectedDevice = devices.first;
            _fetchSensorData(selectedDevice);
          }
        });
      }
    });
  }

  // Mengambil data sensor dari Firebase
  void _fetchSensorData(String device) {
    // Batalkan listener sebelumnya jika ada
    sensorDataSubscription?.cancel();

    setState(() {
      // Reset grafik setiap kali perangkat baru dipilih
      temperatureData.clear();
      humidityData.clear();
    });

    // Atur listener baru untuk perangkat yang dipilih
    final sensorRef = databaseRef.child('sensors/$device');
    final thresholdRef = databaseRef.child('thresholds/$device');

    sensorDataSubscription = sensorRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map<dynamic, dynamic>) {
        setState(() {
          temperature = data['temperature']?.toDouble() ?? 0.0;
          humidity = data['humidity']?.toDouble() ?? 0.0;
          if (temperatureData.length >= 10) temperatureData.removeAt(0);
          temperatureData.add(temperature);
          if (humidityData.length >= 10) humidityData.removeAt(0);
          humidityData.add(humidity);
          _checkThresholds();
        });
      }
    });

    // Ambil data threshold
    thresholdRef.onValue.listen((event) {
      final thresholdData = event.snapshot.value;
      if (thresholdData is Map<dynamic, dynamic>) {
        setState(() {
          tupperLimit = thresholdData['tempUpperLimit']?.toDouble() ?? 0.0;
          tlowerlimit = thresholdData['tempLowerLimit']?.toDouble() ?? 0.0;
          hupperlimit = thresholdData['humidityUpperLimit']?.toDouble() ?? 0.0;
          hlowerlimit = thresholdData['humidityLowerLimit']?.toDouble() ?? 0.0;
        });
      }
    });
  }

  // Memeriksa apakah nilai sensor melebihi threshold
  void _checkThresholds() {
    // Cek transisi untuk suhu dari Aman ke Bahaya
    if ((previousTemperature <= tempUpperLimit &&
            temperature > tempUpperLimit) ||
        (previousTemperature >= tempLowerLimit &&
            temperature < tempLowerLimit)) {
      print('Temperature threshold exceeded - Aman ke Bahaya');
      _sendNotification(
          'Temperature Alert', 'Temperature is out of the safe range!');
      _showAlert('Temperature Alert', 'Temperature is out of the safe range!');
    }

    // Cek transisi untuk suhu dari Bahaya ke Aman
    if ((previousTemperature > tempUpperLimit &&
            temperature <= tempUpperLimit) ||
        (previousTemperature < tempLowerLimit &&
            temperature >= tempLowerLimit)) {
      print('Temperature threshold back to safe range - Bahaya ke Aman');
      _sendNotification(
          'Temperature Safe', 'Temperature is back within the safe range.');
      _showAlert(
          'Temperature Safe', 'Temperature is back within the safe range.');
    }

    // Cek transisi untuk kelembaban dari Aman ke Bahaya
    if ((previousHumidity <= hupperlimit && humidity > hupperlimit) ||
        (previousHumidity >= hlowerlimit && humidity < hlowerlimit)) {
      print('Humidity threshold exceeded - Aman ke Bahaya');
      _sendNotification('Humidity Alert', 'Humidity is out of the safe range!');
      _showAlert('Humidity Alert', 'Humidity is out of the safe range!');
    }

    // Cek transisi untuk kelembaban dari Bahaya ke Aman
    if ((previousHumidity > humidityUpperLimit &&
            humidity <= humidityUpperLimit) ||
        (previousHumidity < humidityLowerLimit &&
            humidity >= humidityLowerLimit)) {
      print('Humidity threshold back to safe range - Bahaya ke Aman');
      _sendNotification(
          'Humidity Safe', 'Humidity is back within the safe range.');
      _showAlert('Humidity Safe', 'Humidity is back within the safe range.');
    }

    // Perbarui nilai sebelumnya dengan nilai saat ini
    previousTemperature = temperature;
    previousHumidity = humidity;
  }

  // Mengirim notifikasi
  void _sendNotification(String title, String body) async {
    print('Sending notification: $title - $body');
    const accessToken =
        'ya29.a0AXeO80TnsvGvOjIjPKv8-_gq0ge1YQW_1eXkzRgcO9UTcN4-1SyRS9vpa_R6W6Ef4_M_9Rwi2cMSRVjkRws3nR8x0YM-8PK15z2AxFWVwFKmkcFiJ5uwCz76nsUmbwsx5nCuzg_cTmWE8VoIffc1D8krDX9D4ncemLf7aR4waCgYKAWwSARASFQHGX2MiAZtHrGX4kteEFpSmdblXjw0175';
    //dpt token dr cmd
    // gcloud init
    // gcloud auth application-default login
    // gcloud auth application-default print-access-token

    // curl -X POST -H "Authorization: Bearer ya29.a0AXeO80TnsvGvOjIjPKv8-_gq0ge1YQW_1eXkzRgcO9UTcN4-1SyRS9vpa_R6W6Ef4_M_9Rwi2cMSRVjkRws3nR8x0YM-8PK15z2AxFWVwFKmkcFiJ5uwCz76nsUmbwsx5nCuzg_cTmWE8VoIffc1D8krDX9D4ncemLf7aR4waCgYKAWwSARASFQHGX2MiAZtHrGX4kteEFpSmdblXjw0175" -H "Content-Type: application/json" -d "{ \"message\": { \"topic\": \"Envirolink\", \"notification\": { \"title\": \"Envirolink Alert Notification\", \"body\": \"Temperature or Humidity is out of the safe range!\" } } }" "https://fcm.googleapis.com/v1/projects/envirolink-5b459/messages:send"
    final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/envirolink-5b459/messages:send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final bodyJson = {
      "message": {
        "topic": "Envirolink",
        "notification": {
          "title": title,
          "body": body,
        },
      }
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(bodyJson),
    );

    if (response.statusCode == 200) {
      print('Notifikasi berhasil dikirim');
    } else {
      print('Gagal mengirim notifikasi: ${response.body}');
    }
  }

  //menampilkan alert dialog
  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Menampilkan dialog untuk menambahkan perangkat baru
  void _showAddDeviceDialog() {
    String deviceName = '';
    String location = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Device Name'),
                onChanged: (value) {
                  setState(() {
                    deviceName = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(labelText: 'Location'),
                onChanged: (value) {
                  setState(() {
                    location = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (deviceName.isNotEmpty && location.isNotEmpty) {
                  _addDeviceToFirebase(deviceName, location);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Menambahkan perangkat baru ke Firebase
  void _addDeviceToFirebase(String deviceName, String location) {
    final newDeviceRef = databaseRef.child('sensors').child(deviceName);
    newDeviceRef.set({
      'deviceName': deviceName,
      'location': location,
      'temperature': 0.0,
      'humidity': 0.0,
      'timestamp': DateTime.now().toIso8601String(),
    }).then((_) {
      setState(() {
        devices.add(deviceName);
        if (selectedDevice.isEmpty) selectedDevice = deviceName;
      });
      print('Device added successfully!');
    }).catchError((error) {
      print('Failed to add device: $error');
    });
  }

  // Menyimpan threshold ke Firebase
  void _saveThresholds() {
    final thresholdRef = databaseRef.child('thresholds/$selectedDevice');
    thresholdRef.set({
      'tempUpperLimit': tempUpperLimit,
      'tempLowerLimit': tempLowerLimit,
      'humidityUpperLimit': humidityUpperLimit,
      'humidityLowerLimit': humidityLowerLimit,
    }).then((_) {
      print('Thresholds saved successfully!');
      _checkThresholds();
    }).catchError((error) {
      print('Failed to save thresholds: $error');
    });
  }

  // Memuat threshold dari Firebase
  void _loadThresholds() {
    final thresholdRef = databaseRef.child('thresholds/$selectedDevice');
    thresholdRef.once().then((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data is Map<dynamic, dynamic>) {
        setState(() {
          tempUpperLimit = data['tempUpperLimit']?.toDouble() ?? 50.0;
          tempLowerLimit = data['tempLowerLimit']?.toDouble() ?? 0.0;
          humidityUpperLimit = data['humidityUpperLimit']?.toDouble() ?? 100.0;
          humidityLowerLimit = data['humidityLowerLimit']?.toDouble() ?? 0.0;

          // Set nilai awal ke controller
          tempUpperController.text = tempUpperLimit.toString();
          tempLowerController.text = tempLowerLimit.toString();
          humidityUpperController.text = humidityUpperLimit.toString();
          humidityLowerController.text = humidityLowerLimit.toString();
        });
      } else {
        // Jika tidak ada data threshold, gunakan nilai default
        setState(() {
          tempUpperLimit = 50.0;
          tempLowerLimit = 0.0;
          humidityUpperLimit = 100.0;
          humidityLowerLimit = 0.0;
        });
      }
    }).catchError((error) {
      print('Failed to load thresholds: $error');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedDevice.isNotEmpty) {
      _loadThresholds();
    }
  }

  // Menghapus perangkat dari Firebase
  void _deleteDevice(String deviceName) {
    databaseRef.child('sensors').child(deviceName).remove().then((_) {
      setState(() {
        devices.remove(deviceName);
        if (selectedDevice == deviceName) {
          selectedDevice = devices.isNotEmpty ? devices.first : '';
          if (selectedDevice.isNotEmpty) {
            _fetchSensorData(selectedDevice);
          } else {
            temperature = 0.0;
            humidity = 0.0;
          }
        }
      });
      print('Device deleted successfully!');
    }).catchError((error) {
      print('Failed to delete device: $error');
    });
  }

  // Menampilkan dialog untuk menghapus perangkat
  void _showDeleteDeviceDialog() {
    String selectedDevicetoDelete = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deleted Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: selectedDevicetoDelete.isEmpty
                    ? null
                    : selectedDevicetoDelete,
                hint: const Text('Select Device to Delete'),
                items: devices.map((device) {
                  return DropdownMenuItem<String>(
                    value: device,
                    child: Text(device),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDevicetoDelete = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedDevicetoDelete.isNotEmpty) {
                  _deleteDevice(selectedDevicetoDelete);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDeviceDialog,
          ),
          if (devices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteDeviceDialog,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: selectedDevice.isEmpty ? null : selectedDevice,
                hint: const Text('Select Device',
                    style: TextStyle(color: Colors.white)),
                items: devices.map((device) {
                  return DropdownMenuItem<String>(
                    value: device,
                    child: Text(device),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDevice = value!;
                    _fetchSensorData(selectedDevice);
                    _loadThresholds();
                  });
                },
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  SensorCard(
                    title: 'Temperature',
                    icon: Icons.thermostat,
                    value: '$temperature°C',
                    graphData: temperatureData,
                    upperLimitText: "${tempUpperLimit.toStringAsFixed(1)}°C",
                    lowerLimitText: "${tempLowerLimit.toStringAsFixed(1)}°C",
                  ),
                  SensorCard(
                    title: 'Humidity',
                    icon: Icons.water_drop,
                    value: '$humidity% RH',
                    graphData: humidityData,
                    upperLimitText:
                        "${humidityUpperLimit.toStringAsFixed(1)}°C",
                    lowerLimitText:
                        "${humidityLowerLimit.toStringAsFixed(1)}°C",
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildThresholdSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThresholdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set Thresholds',
            style: TextStyle(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: TextField(
              decoration: const InputDecoration(
                labelText: 'Temperature Upper Limit (°C)',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                tempUpperLimit = double.tryParse(value) ?? tempUpperLimit;
              },
            )),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Temperature Lower Limit (°C)',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  tempLowerLimit = double.tryParse(value) ?? tempLowerLimit;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Humidity Upper Limit (%)',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  humidityUpperLimit =
                      double.tryParse(value) ?? humidityUpperLimit;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Humidity Lower Limit (%)',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  humidityLowerLimit =
                      double.tryParse(value) ?? humidityLowerLimit;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _saveThresholds,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1DB954),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Thresholds'),
        ),
      ],
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final List<double> graphData;
  final String? upperLimitText;
  final String? lowerLimitText;

  const SensorCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.graphData,
    this.upperLimitText,
    this.lowerLimitText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF222222),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 1,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFFFFFFFF),
                ),
                const SizedBox(width: 5),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFFFFFFF))),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF))),
                Spacer(),
                if (upperLimitText != null && lowerLimitText != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upper limit = $upperLimitText",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      Text(
                        "Lower limit = $lowerLimitText",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 100,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: graphData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                                e.key.toDouble() *
                                    (100 / (graphData.length - 1)),
                                e.value,
                              ))
                          .toList(),
                      barWidth: 3,
                      color: const Color(0xFF1DB954),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    verticalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[800]!,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[800]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.white, width: 1),
                      bottom: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SensorGraph extends StatelessWidget {
  final String title;
  final List<double> data;

  const SensorGraph({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    //anomali
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 10),
        Expanded(
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                    isCurved: true,
                    spots: [
                      const FlSpot(0, 10),
                      const FlSpot(1, 20),
                      const FlSpot(2, 30)
                    ],
                    barWidth: 3,
                    color: const Color(0xFF1DB954)),
              ],
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}
