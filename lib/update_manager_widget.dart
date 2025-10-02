import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'shorebird_update_manager.dart';

class UpdateManagerWidget extends StatefulWidget {
  final Widget child;
  final bool autoCheckOnStart;
  final UpdateTrack? track;
  final bool showPatchIndicator;

  const UpdateManagerWidget({
    super.key,
    required this.child,
    this.autoCheckOnStart = true,
    this.track,
    this.showPatchIndicator = true,
  });

  @override
  State<UpdateManagerWidget> createState() => _UpdateManagerWidgetState();
}

class _UpdateManagerWidgetState extends State<UpdateManagerWidget> {
  final _updateManager = ShorebirdUpdateManager();
  PatchInfo? _currentPatchInfo;

  @override
  void initState() {
    super.initState();
    _loadPatchInfo();
    if (widget.autoCheckOnStart) {
      // Delay sedikit agar UI sudah ready
      Future.delayed(Duration(milliseconds: 500), () {
        _checkForUpdates();
      });
    }
  }

  Future<void> _loadPatchInfo() async {
    final info = await _updateManager.getCurrentPatchInfo();
    if (mounted) {
      setState(() => _currentPatchInfo = info);
    }
  }

  Future<void> _checkForUpdates() async {
    if (widget.track != null) {
      await _updateManager.checkAndDownloadUpdateWithTrack(
        track: widget.track!,
        onUpdateReady: () {
          if (mounted) {
            _showRestartDialog();
          }
        },
        onNoUpdate: () {
          if (mounted) {
            _showUpToDateSnackbar();
          }
        },
        onError: (error) {
          if (mounted) {
            _showErrorSnackbar(error);
          }
        },
      );
    } else {
      await _updateManager.checkAndDownloadUpdate(
        onUpdateReady: () {
          if (mounted) {
            _showRestartDialog();
          }
        },
        onNoUpdate: () {
          if (mounted) {
            _showUpToDateSnackbar();
          }
        },
        onError: (error) {
          if (mounted) {
            _showErrorSnackbar(error);
          }
        },
      );
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        onPopInvokedWithResult: (a, b) async => false,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.system_update, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Update Ready!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patch berhasil didownload! 🎉',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Patch akan apply setelah restart app',
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
              child: Text('Nanti Aja'),
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
      ),
    );
  }

  void _showUpToDateSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('App sudah up to date!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('Error: $error')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Download progress overlay
        ValueListenableBuilder<bool>(
          valueListenable: _updateManager.isDownloading,
          builder: (context, isDownloading, _) {
            if (isDownloading) {
              return _buildDownloadingOverlay();
            }
            return SizedBox.shrink();
          },
        ),

        // Patch info indicator
        if (widget.showPatchIndicator)
          Positioned(bottom: 16, right: 16, child: _buildPatchIndicator()),
      ],
    );
  }

  Widget _buildDownloadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Card(
            margin: EdgeInsets.all(32),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_download, size: 64, color: Colors.blue),
                  SizedBox(height: 24),
                  Text(
                    'Downloading Update...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 24),
                  ValueListenableBuilder<double>(
                    valueListenable: _updateManager.downloadProgress,
                    builder: (context, progress, _) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatchIndicator() {
    if (_currentPatchInfo == null) return SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _checkForUpdates,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Patch #${_currentPatchInfo!.patchNumber}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.refresh, size: 14, color: Colors.white70),
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
