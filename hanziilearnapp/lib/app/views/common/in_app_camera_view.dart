import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/views/common/widgets/camera_capture_controls.dart';

class InAppCameraView extends StatefulWidget {
  const InAppCameraView({super.key});

  @override
  State<InAppCameraView> createState() => _InAppCameraViewState();
}

class _InAppCameraViewState extends State<InAppCameraView> {
  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('Không tìm thấy camera trên thiết bị.');
      }
      _cameraIndex = _cameraIndex.clamp(0, _cameras.length - 1);
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      await _controller?.dispose();
      setState(() {
        _controller = controller;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _capturing || _initializing) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _setupCamera();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing || !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể chụp ảnh: $e')));
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Chụp ảnh'),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.whiteText, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _controller == null
                      ? const SizedBox()
                      : CameraPreview(_controller!),
                ),
                CameraCaptureControls(
                  isCapturing: _capturing,
                  onSwitchCamera: _switchCamera,
                  onCapture: _capture,
                  onClose: () => Navigator.pop(context),
                ),
              ],
            ),
    );
  }
}
