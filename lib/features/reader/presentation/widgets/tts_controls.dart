import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsControls extends StatefulWidget {
  final String text;
  final VoidCallback onClose;

  const TtsControls({super.key, required this.text, required this.onClose});

  @override
  State<TtsControls> createState() => _TtsControlsState();
}

class _TtsControlsState extends State<TtsControls> {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  double _speed = 0.5;
  double _pitch = 1.0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(_speed);
    await _tts.setPitch(_pitch);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _speak() async {
    if (widget.text.isEmpty) return;
    await _tts.speak(widget.text);
    setState(() => _isPlaying = true);
  }

  Future<void> _pause() async {
    await _tts.pause();
    setState(() => _isPlaying = false);
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: _stop,
                tooltip: '停止',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                iconSize: 48,
                color: theme.colorScheme.primary,
                onPressed: _isPlaying ? _pause : _speak,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _stop();
                  widget.onClose();
                },
                tooltip: '关闭',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('语速'),
              Expanded(
                child: Slider(
                  value: _speed,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(_speed * 2).toStringAsFixed(1)}x',
                  onChanged: (v) async {
                    setState(() => _speed = v);
                    await _tts.setSpeechRate(v);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('音调'),
              Expanded(
                child: Slider(
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _pitch.toStringAsFixed(1),
                  onChanged: (v) async {
                    setState(() => _pitch = v);
                    await _tts.setPitch(v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
