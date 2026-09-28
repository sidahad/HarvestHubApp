import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  FlutterSoundRecorder? _recorder;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  bool _isInitialized = false;

  // Initialize recorder
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    _isInitialized = true;
  }

  // Check and request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      // Initialize if needed
      await _initialize();

      // Check permission
      if (!await requestPermission()) {
        throw Exception('Microphone permission denied');
      }

      // Check if already recording
      if (_recorder!.isRecording) {
        return false;
      }

      // Create temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      _currentRecordingPath = '${tempDir.path}/$fileName';

      // Start recording
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Codec.aacADTS,
      );

      _recordingStartTime = DateTime.now();
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  // Stop recording and return file path
  Future<Map<String, dynamic>?> stopRecording() async {
    try {
      if (_recorder == null || !_recorder!.isRecording) {
        return null;
      }

      // Stop recording
      await _recorder!.stopRecorder();
      
      if (_currentRecordingPath == null) {
        return null;
      }

      // Calculate duration
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!).inSeconds
          : 0;

      final result = {
        'path': _currentRecordingPath!,
        'duration': duration,
      };

      // Reset
      _currentRecordingPath = null;
      _recordingStartTime = null;

      return result;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      if (_recorder != null && _recorder!.isRecording) {
        await _recorder!.stopRecorder();
      }
      
      // Delete temp file if exists
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _currentRecordingPath = null;
      _recordingStartTime = null;
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  // Get recording duration
  int getRecordingDuration() {
    if (_recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inSeconds;
  }

  // Check if recording
  Future<bool> isRecording() async {
    if (_recorder == null) return false;
    return _recorder!.isRecording;
  }

  // Dispose
  Future<void> dispose() async {
    if (_recorder != null) {
      if (_recorder!.isRecording) {
        await _recorder!.stopRecorder();
      }
      await _recorder!.closeRecorder();
      _recorder = null;
      _isInitialized = false;
    }
  }
}
