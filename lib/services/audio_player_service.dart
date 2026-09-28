import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentPlayingUrl;
  bool _isPlaying = false;

  // Play audio from URL
  Future<void> play(String url) async {
    try {
      if (_currentPlayingUrl == url && _isPlaying) {
        // Already playing this audio, pause it
        await pause();
        return;
      }

      // Stop current audio if different
      if (_currentPlayingUrl != null && _currentPlayingUrl != url) {
        await stop();
      }

      _currentPlayingUrl = url;
      await _player.play(UrlSource(url));
      _isPlaying = true;

      // Listen for completion
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying = false;
    }
  }

  // Pause audio
  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  // Resume audio
  Future<void> resume() async {
    try {
      await _player.resume();
      _isPlaying = true;
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }

  // Stop audio
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentPlayingUrl = null;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  // Check if playing
  bool get isPlaying => _isPlaying;

  // Get current playing URL
  String? get currentPlayingUrl => _currentPlayingUrl;

  // Get duration
  Future<Duration?> getDuration() async {
    return await _player.getDuration();
  }

  // Get position
  Future<Duration?> getPosition() async {
    return await _player.getCurrentPosition();
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // Dispose
  void dispose() {
    _player.dispose();
  }
}
