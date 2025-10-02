import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'update_manager_widget.dart';
import 'shorebird_update_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shorebird Demo',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: UpdateManagerWidget(
        autoCheckOnStart: true,
        showPatchIndicator: true,
        // Uncomment untuk use custom track:
        // track: UpdateTrack.beta,
        // atau: track: UpdateTrack('my-custom-track'),
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _updater = ShorebirdUpdater();
  final _updateManager = ShorebirdUpdateManager();
  PatchInfo? _currentPatch;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPatch();
  }

  Future<void> _loadCurrentPatch() async {
    final patch = await _updater.readCurrentPatch();
    if (patch != null && mounted) {
      setState(() {
        _currentPatch = PatchInfo(
          patchNumber: patch.number,
          patchVersion: patch.number.toString(),
        );
      });
    }
  }

  Future<void> _manualCheckUpdate() async {
    if (_isCheckingUpdate) return;

    setState(() => _isCheckingUpdate = true);

    final status = await _updater.checkForUpdate();

    setState(() => _isCheckingUpdate = false);

    if (!mounted) return;

    if (status == UpdateStatus.outdated) {
      _showUpdateAvailableDialog();
    } else if (status == UpdateStatus.upToDate) {
      _showUpToDateDialog();
    } else {
      _showErrorDialog('Update unavailable');
    }
  }

  void _showUpdateAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.new_releases, color: Colors.orange),
            SizedBox(width: 8),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ada update baru tersedia!'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Download sekarang?',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadUpdate();
            },
            child: Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadUpdate() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        onPopInvokedWithResult: (a, b) async => false,
        child: Center(
          child: Card(
            margin: EdgeInsets.all(32),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Downloading...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await _updater.update();

      if (mounted) {
        Navigator.pop(context); // Close loading
        _showRestartDialog();
      }
    } on UpdateException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showErrorDialog('Update failed: $e');
      }
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Download Selesai!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patch sudah didownload ke device! 🎉',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PENTING!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Patch belum apply. Perlu RESTART APP untuk apply update.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK, Nanti'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _updateManager.restartApp();
            },
            icon: Icon(Icons.restart_alt),
            label: Text('Restart Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpToDateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Up to Date'),
          ],
        ),
        content: Text('App sudah menggunakan versi terbaru!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shorebird Auto Update'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon/Logo
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.rocket_launch, size: 80, color: Colors.blue),
              ),

              SizedBox(height: 32),

              // Welcome Text
              Text(
                'Welcome to Shorebird!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12),

              // UBAH TEXT INI UNTUK TESTING PATCH
              Text(
                'Version 1.0 - Original Build 🚀',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40),

              // Current Patch Info
              if (_currentPatch != null)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Currently Running',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Patch #${_currentPatch?.patchNumber}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade600),
                      SizedBox(height: 8),
                      Text(
                        'No Patch Installed',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 40),

              // Check for Updates Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isCheckingUpdate ? null : _manualCheckUpdate,
                  icon: _isCheckingUpdate
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(Icons.cloud_download, size: 24),
                  label: Text(
                    _isCheckingUpdate ? 'Checking...' : 'Check for Updates',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Info Box
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap patch indicator (bottom right) untuk quick check updates',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _updateManager.dispose();
    super.dispose();
  }
}
