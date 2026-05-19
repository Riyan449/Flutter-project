// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
// import 'package:permission_handler/permission_handler.dart';
//
// class BluetoothScreen extends StatefulWidget {
//   const BluetoothScreen({super.key});
//
//   @override
//   State<BluetoothScreen> createState() => _BluetoothScreenState();
// }
//
// class _BluetoothScreenState extends State<BluetoothScreen> {
//   BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
//   List<BluetoothDevice> bondedDevices = [];
//   List<BluetoothDiscoveryResult> discoveryResults = [];
//   bool isDiscovering = false;
//   StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Get current state
//     FlutterBluetoothSerial.instance.state.then((state) {
//       setState(() {
//         _bluetoothState = state;
//       });
//       if (state == BluetoothState.STATE_ON) {
//         _getBondedDevices();
//         _startDiscovery();
//       }
//     });
//
//     // Listen for state changes
//     FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
//       setState(() {
//         _bluetoothState = state;
//         if (state == BluetoothState.STATE_OFF) {
//           bondedDevices = [];
//           discoveryResults = [];
//         } else if (state == BluetoothState.STATE_ON) {
//           _getBondedDevices();
//           _startDiscovery();
//         }
//       });
//     });
//
//     _checkPermissions();
//   }
//
//   Future<void> _checkPermissions() async {
//     await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.location,
//     ].request();
//
//     _getBondedDevices();
//   }
//
//   void _getBondedDevices() {
//     FlutterBluetoothSerial.instance.getBondedDevices().then((List<BluetoothDevice> devices) {
//       setState(() {
//         bondedDevices = devices;
//       });
//     });
//   }
//
//   Future<void> _enableBluetooth() async {
//     // First, ensure all permissions are granted
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.location,
//     ].request();
//
//     if (statuses[Permission.bluetoothConnect]?.isGranted != true) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Bluetooth permissions are required.")),
//         );
//       }
//       return;
//     }
//
//     // Then, request to enable Bluetooth
//     try {
//       bool? success = await FlutterBluetoothSerial.instance.requestEnable();
//       if (success != true) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Could not enable Bluetooth automatically. Please enable it from system settings.")),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error enabling Bluetooth: $e")),
//         );
//       }
//     }
//   }
//
//   Future<void> _startDiscovery() async {
//     if (isDiscovering) return;
//
//     // Check location service status (required for discovery on Android)
//     bool isLocationEnabled = await Permission.location.serviceStatus.isEnabled;
//     if (!isLocationEnabled) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please turn on Location (GPS) to find nearby devices.")),
//         );
//       }
//       // Depending on the Android version, we might still be able to discover
//       // but it's often required. We'll proceed but it might find 0 devices.
//     }
//
//     // Request permissions before starting discovery
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.location,
//     ].request();
//
//     if (statuses[Permission.bluetoothScan]?.isGranted != true) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Bluetooth Scan permission is required to find devices.")),
//         );
//       }
//       return;
//     }
//
//     setState(() {
//       isDiscovering = true;
//       discoveryResults = [];
//     });
//
//     try {
//       _discoveryStreamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
//         setState(() {
//           final existingIndex = discoveryResults.indexWhere((element) => element.device.address == r.device.address);
//           if (existingIndex >= 0) {
//             discoveryResults[existingIndex] = r;
//           } else {
//             discoveryResults.add(r);
//           }
//         });
//       }, onDone: () {
//         if (mounted) {
//           setState(() {
//             isDiscovering = false;
//           });
//         }
//       }, onError: (error) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Error during discovery: $error")),
//           );
//           setState(() {
//             isDiscovering = false;
//           });
//         }
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed to start discovery: $e")),
//         );
//         setState(() {
//           isDiscovering = false;
//         });
//       }
//     }
//   }
//
//   void _stopDiscovery() {
//     _discoveryStreamSubscription?.cancel();
//     setState(() {
//       isDiscovering = false;
//     });
//   }
//
//   Future<void> _connectToDevice(BluetoothDevice device) async {
//     // Navigate back with the address or handle connection here
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Connecting to ${device.name ?? device.address}...")),
//     );
//
//     // In many trolley apps, you'd navigate back and pass the address to the next screen
//     Navigator.pop(context, device.address);
//   }
//
//   @override
//   void dispose() {
//     _discoveryStreamSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     bool isBluetoothOn = _bluetoothState == BluetoothState.STATE_ON;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Bluetooth Devices"),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         actions: [
//           if (isBluetoothOn)
//             IconButton(
//               icon: Icon(isDiscovering ? Icons.stop : Icons.refresh),
//               onPressed: isDiscovering ? _stopDiscovery : _startDiscovery,
//             ),
//         ],
//       ),
//       body: !isBluetoothOn
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
//                   const SizedBox(height: 16),
//                   const Text("Bluetooth is turned off"),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _enableBluetooth,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFFFF6B35),
//                       foregroundColor: Colors.black,
//                       textStyle: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     child: const Text("Enable Bluetooth"),
//                   ),
//                 ],
//               ),
//             )
//           : ListView(
//               children: [
//                 // Bonded (Paired) Devices Section
//                 if (bondedDevices.isNotEmpty) ...[
//                   const ListTile(
//                     title: Text("PAIRED DEVICES",
//                         style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
//                   ),
//                   ...bondedDevices.map((device) => ListTile(
//                         leading: const Icon(Icons.bluetooth_connected, color: Color(0xFFFF6B35)),
//                         title: Text(device.name ?? "Unknown Device"),
//                         subtitle: Text(device.address),
//                         trailing: ElevatedButton(
//                           onPressed: () => _connectToDevice(device),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFFFF6B35),
//                             foregroundColor: Colors.black,
//                             textStyle: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           child: const Text("Connect"),
//                         ),
//                       )),
//                 ],
//
//                 // Discovered (Nearby) Devices Section
//                 const ListTile(
//                   title: Text("AVAILABLE DEVICES NEARBY",
//                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
//                 ),
//
//                 if (isDiscovering && discoveryResults.isEmpty)
//                   const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(20.0),
//                       child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
//                     ),
//                   )
//                 else if (discoveryResults.isEmpty)
//                   const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(20.0),
//                       child: Text("No nearby devices found. Click refresh to scan."),
//                     ),
//                   )
//                 else
//                   ...discoveryResults.map((result) => ListTile(
//                         leading: const Icon(Icons.bluetooth, color: Color(0xFFFF6B35)),
//                         title: Text(result.device.name ?? "Unknown Device"),
//                         subtitle: Text("${result.device.address} (RSSI: ${result.rssi})"),
//                         trailing: ElevatedButton(
//                           onPressed: () => _connectToDevice(result.device),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFFFF6B35),
//                             foregroundColor: Colors.black,
//                             textStyle: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           child: const Text("Connect"),
//                         ),
//                       )),
//               ],
//             ),
//     );
//   }
// }








import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  List<BluetoothDevice> bondedDevices = [];
  List<BluetoothDiscoveryResult> discoveryResults = [];

  bool isDiscovering = false;

  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  BluetoothConnection? connection;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    await _checkPermissions();

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });

      if (state == BluetoothState.STATE_ON) {
        _getBondedDevices();
        _startDiscovery();
      }
    });

    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      setState(() {
        _bluetoothState = state;
      });

      if (state == BluetoothState.STATE_ON) {
        _getBondedDevices();
        _startDiscovery();
      } else {
        bondedDevices.clear();
        discoveryResults.clear();
      }
    });
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _enableBluetooth() async {
    try {
      bool? enabled = await FlutterBluetoothSerial.instance.requestEnable();

      if (enabled != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable Bluetooth manually")),
        );
      }
    } catch (e) {
      debugPrint("Enable Bluetooth error: $e");
    }
  }

  Future<void> _getBondedDevices() async {
    try {
      List<BluetoothDevice> devices =
      await FlutterBluetoothSerial.instance.getBondedDevices();

      if (!mounted) return;

      setState(() {
        bondedDevices = devices;
      });
    } catch (e) {
      debugPrint("Bonded devices error: $e");
    }
  }

  Future<void> _startDiscovery() async {
    if (isDiscovering) return;

    setState(() {
      isDiscovering = true;
      discoveryResults.clear();
    });

    try {
      _discoverySubscription =
          FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
            final index = discoveryResults.indexWhere(
                  (element) => element.device.address == result.device.address,
            );

            setState(() {
              if (index >= 0) {
                discoveryResults[index] = result;
              } else {
                discoveryResults.add(result);
              }
            });
          });

      _discoverySubscription?.onDone(() {
        if (mounted) {
          setState(() {
            isDiscovering = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        isDiscovering = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Discovery failed: $e")),
        );
      }
    }
  }

  void _stopDiscovery() {
    _discoverySubscription?.cancel();
    setState(() {
      isDiscovering = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _stopDiscovery();

      if (!device.isBonded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pairing with ${device.name ?? device.address}..."),
          ),
        );
        bool bonded = false;
        try {
          bonded = (await FlutterBluetoothSerial.instance.bondDeviceAtAddress(device.address)) ?? false;
        } catch (e) {
          bonded = false;
        }
        if (!bonded) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to pair with ${device.name ?? device.address}")),
          );
          return;
        }
        _getBondedDevices();
        // Give Android a moment to update the internal bond state before attempting connection
        await Future.delayed(const Duration(seconds: 1));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connecting to ${device.name ?? device.address}..."),
        ),
      );

      connection = await BluetoothConnection.toAddress(device.address);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connected to ${device.name ?? device.address}"),
        ),
      );

      Navigator.pop(context, connection);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();
      bool isSocketError = errorMessage.contains("read failed") || errorMessage.contains("socket might closed");

      if (isSocketError) {
        errorMessage = "Connection Failed: The device might not support Serial communication (SPP).";
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Connection Issue"),
          content: Text("$errorMessage\n\nWould you like to simulate a successful connection for testing purposes?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, "SIMULATED_${device.address}"); // Return a simulated result
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.black),
              child: const Text("Simulate Success"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isBluetoothOn = _bluetoothState == BluetoothState.STATE_ON;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/logo/bluetooth.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.3),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Bluetooth Devices"),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isBluetoothOn)
            IconButton(
              icon: Icon(
                isDiscovering ? Icons.stop : Icons.refresh,
                color: Colors.white,
              ),
              onPressed: isDiscovering ? _stopDiscovery : _startDiscovery,
            ),
        ],
      ),
      body: !isBluetoothOn
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bluetooth_disabled,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text("Bluetooth is turned off"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _enableBluetooth,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 2,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text("Enable Bluetooth"),
            ),
          ],
        ),
      )
          : ListView(
        children: [
          if (bondedDevices.isNotEmpty) ...[
            const ListTile(
              title: Text(
                "PAIRED DEVICES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...bondedDevices.map(
                  (device) => ListTile(
                leading: const Icon(
                  Icons.bluetooth_connected,
                  color: Color(0xFFFF6B35),
                ),
                title: Text(device.name ?? "Unknown Device"),
                subtitle: Text(device.address),
                trailing: ElevatedButton(
                  onPressed: () => _connectToDevice(device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 2,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Connect"),
                ),
              ),
            ),
          ],
          const ListTile(
            title: Text(
              "AVAILABLE DEVICES NEARBY",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          if (isDiscovering && discoveryResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6B35),
                ),
              ),
            )
          else if (discoveryResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text("No nearby devices found. Click refresh."),
              ),
            )
          else
            ...discoveryResults.map(
                  (result) => ListTile(
                leading: const Icon(
                  Icons.bluetooth,
                  color: Color(0xFFFF6B35),
                ),
                title: Text(result.device.name ?? "Unknown Device"),
                subtitle: Text(
                  "${result.device.address} (RSSI: ${result.rssi})",
                ),
                trailing: ElevatedButton(
                  onPressed: () => _connectToDevice(result.device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 2,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Connect"),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}