import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A reusable hero card container with a looping, muted background video.
/// Preserves rounded corners, provides fallback decoration, and keeps foreground
/// UI (text, buttons, badges) interactive and readable with a subtle overlay.
class HeroCardVideoBackground extends StatefulWidget {
  final String videoAsset;
  final BorderRadius borderRadius;
  final Decoration? fallbackDecoration;
  final Gradient? overlayGradient;
  final Color? overlayColor;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const HeroCardVideoBackground({
    super.key,
    required this.videoAsset,
    required this.borderRadius,
    this.fallbackDecoration,
    this.overlayGradient,
    this.overlayColor,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  @override
  State<HeroCardVideoBackground> createState() =>
      _HeroCardVideoBackgroundState();
}

class _HeroCardVideoBackgroundState extends State<HeroCardVideoBackground> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.asset(widget.videoAsset);
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        await controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.fallbackDecoration,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            // Video Layer
            if (_isInitialized &&
                !_hasError &&
                _controller != null &&
                _controller!.value.isInitialized)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width > 0
                        ? _controller!.value.size.width
                        : 16,
                    height: _controller!.value.size.height > 0
                        ? _controller!.value.size.height
                        : 9,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),

            // Semi-transparent Overlay (Dark/Green tint to ensure crisp text contrast)
            if (_isInitialized && !_hasError)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.overlayColor,
                    gradient: widget.overlayColor == null
                        ? (widget.overlayGradient ??
                            LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.62),
                                Colors.black.withValues(alpha: 0.72),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ))
                        : null,
                  ),
                ),
              ),

            // Foreground UI Content
            Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
