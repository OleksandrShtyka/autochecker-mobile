import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/api_service.dart';
import '../services/spotify_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import 'spotify_auth_screen.dart';

const _spotifyGreen = Color(0xFF1DB954);

class SpotifyScreen extends StatefulWidget {
  const SpotifyScreen({super.key});

  @override
  State<SpotifyScreen> createState() => SpotifyScreenState();
}

class SpotifyScreenState extends State<SpotifyScreen> {
  bool _connecting = false;
  bool _acting = false;

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      final authUrl = await ApiService.instance.getSpotifyAuthUrl();
      if (!mounted) return;
      final code = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => SpotifyAuthScreen(authUrl: authUrl),
        ),
      );
      if (code != null) {
        await SpotifyService.instance.exchangeCode(code);
        await SpotifyService.instance.fetchCurrentTrack();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Spotify: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _do(Future<void> Function() action) async {
    if (_acting) return;
    setState(() => _acting = true);
    await action();
    if (mounted) setState(() => _acting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: ValueListenableBuilder<SpotifyTrack?>(
              valueListenable: SpotifyService.instance.currentTrack,
              builder: (_, track, __) => track == null
                  ? _buildConnect()
                  : _buildPlayer(track),
            ),
          ),
        ],
      ),
    );
  }

  // ── Not connected / nothing playing ────────────────────────────────────────
  Widget _buildConnect() {
    return FutureBuilder<bool>(
      future: SpotifyService.instance.isConnected,
      builder: (_, snap) {
        final connected = snap.data ?? false;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _spotifyGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _spotifyGreen.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _spotifyGreen.withValues(alpha: 0.2),
                        blurRadius: 32,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      color: _spotifyGreen, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Spotify',
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  connected
                      ? t('spotify_nothing_playing')
                      : t('spotify_connect_sub'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textMuted, fontSize: 14),
                ),
                const SizedBox(height: 32),
                if (!connected)
                  GestureDetector(
                    onTap: _connecting ? null : _connect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: _spotifyGreen,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: _spotifyGreen.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: _connecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.link_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  t('spotify_connect'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Full player ────────────────────────────────────────────────────────────
  Widget _buildPlayer(SpotifyTrack track) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.music_note_rounded,
                color: _spotifyGreen, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Spotify',
              style: TextStyle(
                  color: _spotifyGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _spotifyGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _spotifyGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _spotifyGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    track.isPlaying ? 'Playing' : 'Paused',
                    style: const TextStyle(
                        color: _spotifyGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Album art
        Center(
          child: Hero(
            tag: 'spotify_art',
            child: Container(
              width: 220,
              height: 220,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF1A2B40),
                boxShadow: [
                  BoxShadow(
                    color: _spotifyGreen.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: track.albumArtUrl != null
                  ? Image.network(track.albumArtUrl!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.music_note_rounded,
                          color: _spotifyGreen, size: 64)),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Track info
        Column(
          children: [
            Text(
              track.title,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 22,
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
              style: const TextStyle(color: textMuted, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Progress bar
        if (track.durationMs > 0) ...[
          _ProgressBar(track: track),
          const SizedBox(height: 28),
        ],

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ctrl(
              icon: Icons.skip_previous_rounded,
              size: 40,
              onTap: () => _do(SpotifyService.instance.previous),
            ),
            GestureDetector(
              onTap: _acting
                  ? null
                  : () => _do(
                        track.isPlaying
                            ? SpotifyService.instance.pause
                            : SpotifyService.instance.play,
                      ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _acting
                      ? _spotifyGreen.withValues(alpha: 0.6)
                      : _spotifyGreen,
                  shape: BoxShape.circle,
                  boxShadow: _acting
                      ? null
                      : [
                          BoxShadow(
                            color: _spotifyGreen.withValues(alpha: 0.45),
                            blurRadius: 24,
                            spreadRadius: -4,
                          ),
                        ],
                ),
                child: Icon(
                  track.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            _ctrl(
              icon: Icons.skip_next_rounded,
              size: 40,
              onTap: () => _do(SpotifyService.instance.next),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ctrl({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _acting ? null : onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon,
            color: _acting ? textMuted : textPrimary, size: size),
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final SpotifyTrack track;
  const _ProgressBar({required this.track});

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (track.progressMs / track.durationMs).clamp(0.0, 1.0);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 500),
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_spotifyGreen),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt(track.progressMs),
                style: const TextStyle(color: textMuted, fontSize: 11)),
            Text(_fmt(track.durationMs),
                style: const TextStyle(color: textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
