import 'package:flutter/material.dart';

import '../services/spotify_service.dart';
import '../theme.dart';

// Spotify brand green
const _spotifyGreen = Color(0xFF1DB954);

/// Compact Spotify mini-player bar shown above the AI strip in the bottom bar.
/// Handles play/pause, next, previous and shows current track info.
class SpotifyMiniPlayer extends StatefulWidget {
  final SpotifyTrack track;
  const SpotifyMiniPlayer({super.key, required this.track});

  @override
  State<SpotifyMiniPlayer> createState() => _SpotifyMiniPlayerState();
}

class _SpotifyMiniPlayerState extends State<SpotifyMiniPlayer> {
  bool _acting = false;

  Future<void> _do(Future<void> Function() action) async {
    if (_acting) return;
    setState(() => _acting = true);
    await action();
    if (mounted) setState(() => _acting = false);
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    return GestureDetector(
      onTap: () => _showFullPlayer(context),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Spotify icon / album art
            Container(
              width: 32,
              height: 32,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFF1A2B40),
              ),
              child: track.albumArtUrl != null
                  ? Image.network(
                      track.albumArtUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _spotifyIcon(),
                    )
                  : _spotifyIcon(),
            ),
            const SizedBox(width: 10),

            // Track info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: const TextStyle(color: textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Controls
            _ctrl(
              icon: Icons.skip_previous_rounded,
              onTap: () => _do(SpotifyService.instance.previous),
            ),
            const SizedBox(width: 2),
            _ctrl(
              icon: track.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 26,
              onTap: () => _do(
                track.isPlaying
                    ? SpotifyService.instance.pause
                    : SpotifyService.instance.play,
              ),
            ),
            const SizedBox(width: 2),
            _ctrl(
              icon: Icons.skip_next_rounded,
              onTap: () => _do(SpotifyService.instance.next),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrl({
    required IconData icon,
    required VoidCallback onTap,
    double size = 22,
  }) {
    return GestureDetector(
      onTap: _acting ? null : onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, color: _acting ? textMuted : textPrimary, size: size),
      ),
    );
  }

  Widget _spotifyIcon() {
    return const Center(
      child: Icon(Icons.music_note_rounded, color: _spotifyGreen, size: 18),
    );
  }

  void _showFullPlayer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SpotifyFullPlayer(),
    );
  }
}

// ── Full player bottom sheet ──────────────────────────────────────────────────

class _SpotifyFullPlayer extends StatefulWidget {
  const _SpotifyFullPlayer();

  @override
  State<_SpotifyFullPlayer> createState() => _SpotifyFullPlayerState();
}

class _SpotifyFullPlayerState extends State<_SpotifyFullPlayer> {
  bool _acting = false;

  Future<void> _do(Future<void> Function() action) async {
    if (_acting) return;
    setState(() => _acting = true);
    await action();
    if (mounted) setState(() => _acting = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SpotifyTrack?>(
      valueListenable: SpotifyService.instance.currentTrack,
      builder: (_, track, __) {
        if (track == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => Navigator.of(context).pop());
          return const SizedBox.shrink();
        }
        return _buildSheet(track);
      },
    );
  }

  Widget _buildSheet(SpotifyTrack track) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Album art
          Container(
            width: 200,
            height: 200,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF1A2B40),
              boxShadow: [
                BoxShadow(
                  color: _spotifyGreen.withValues(alpha: 0.25),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: track.albumArtUrl != null
                ? Image.network(track.albumArtUrl!, fit: BoxFit.cover)
                : const Center(
                    child: Icon(Icons.music_note_rounded,
                        color: _spotifyGreen, size: 64)),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            track.title,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            track.artist,
            style: const TextStyle(color: textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Spotify badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note_rounded, color: _spotifyGreen, size: 12),
              const SizedBox(width: 4),
              const Text(
                'Spotify',
                style: TextStyle(
                    color: _spotifyGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Progress bar
          if (track.durationMs > 0)
            _ProgressBar(
              progress: track.progressMs / track.durationMs,
              progressMs: track.progressMs,
              durationMs: track.durationMs,
            ),
          const SizedBox(height: 24),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _bigCtrl(
                icon: Icons.skip_previous_rounded,
                size: 36,
                onTap: () => _do(SpotifyService.instance.previous),
              ),
              _bigCtrl(
                icon: track.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                size: 64,
                color: _spotifyGreen,
                onTap: () => _do(
                  track.isPlaying
                      ? SpotifyService.instance.pause
                      : SpotifyService.instance.play,
                ),
              ),
              _bigCtrl(
                icon: Icons.skip_next_rounded,
                size: 36,
                onTap: () => _do(SpotifyService.instance.next),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bigCtrl({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
    Color color = textPrimary,
  }) {
    return GestureDetector(
      onTap: _acting ? null : onTap,
      child: Icon(icon, color: _acting ? textMuted : color, size: size),
    );
  }
}

// ── Simple progress bar ───────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final int progressMs;
  final int durationMs;

  const _ProgressBar({
    required this.progress,
    required this.progressMs,
    required this.durationMs,
  });

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor:
                const AlwaysStoppedAnimation<Color>(_spotifyGreen),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt(progressMs),
                style: const TextStyle(color: textMuted, fontSize: 11)),
            Text(_fmt(durationMs),
                style: const TextStyle(color: textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
