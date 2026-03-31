import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../services/achievements_service.dart';
import '../services/api_service.dart';
import '../services/exp_service.dart';
import '../services/spotify_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
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

  void _openAiPlaylist() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiPlaylistSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: ValueListenableBuilder<SpotifyTrack?>(
              valueListenable: SpotifyService.instance.currentTrack,
              builder: (_, track, __) => track == null
                  ? _buildConnect(c)
                  : _buildPlayer(track, c),
            ),
          ),
        ],
      ),
    );
  }

  // ── Not connected / nothing playing ────────────────────────────────────────
  Widget _buildConnect(AppColors c) {
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
                Text(
                  'Spotify',
                  style: TextStyle(
                      color: c.text,
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
                  style: TextStyle(color: c.muted, fontSize: 14),
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
                if (connected) ...[
                  const SizedBox(height: 16),
                  _aiPlaylistBtn(c),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Full player ────────────────────────────────────────────────────────────
  Widget _buildPlayer(SpotifyTrack track, AppColors c) {
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
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: _spotifyGreen, shape: BoxShape.circle),
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
                color: c.surface,
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
              style: TextStyle(
                color: c.text,
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
              style: TextStyle(color: c.muted, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Progress bar
        if (track.durationMs > 0) ...[
          _ProgressBar(track: track, c: c),
          const SizedBox(height: 28),
        ],

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ctrl(Icons.skip_previous_rounded, 40,
                () => _do(SpotifyService.instance.previous), c),
            GestureDetector(
              onTap: _acting
                  ? null
                  : () => _do(track.isPlaying
                      ? SpotifyService.instance.pause
                      : SpotifyService.instance.play),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72, height: 72,
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
            _ctrl(Icons.skip_next_rounded, 40,
                () => _do(SpotifyService.instance.next), c),
          ],
        ),

        const SizedBox(height: 32),

        // ── AI Playlist button ──────────────────────────────────────────────
        _aiPlaylistBtn(c),
      ],
    );
  }

  Widget _aiPlaylistBtn(AppColors c) {
    return GestureDetector(
      onTap: _openAiPlaylist,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1DB954), Color(0xFF00E5CC)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _spotifyGreen.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎵', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Text(
              'Generate AI Playlist',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrl(IconData icon, double size, VoidCallback onTap, AppColors c) {
    return GestureDetector(
      onTap: _acting ? null : onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
        child: Icon(icon,
            color: _acting ? c.muted : c.text, size: size),
      ),
    );
  }
}

// ── AI Playlist bottom sheet ───────────────────────────────────────────────────
class _AiPlaylistSheet extends StatefulWidget {
  const _AiPlaylistSheet();

  @override
  State<_AiPlaylistSheet> createState() => _AiPlaylistSheetState();
}

class _AiPlaylistSheetState extends State<_AiPlaylistSheet> {
  final _ctrl = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _loading = false;
  List<Map<String, dynamic>> _tracks = [];
  String? _error;

  static const _tags = [
    ('🏋️ Gym', 'heavy gym workout music'),
    ('⚡ Hype', 'high energy hype music'),
    ('🧘 Chill', 'chill relaxing music'),
    ('🎯 Focus', 'focus concentration music'),
    ('🔥 Cardio', 'fast cardio running music'),
    ('😌 Recovery', 'calm recovery stretching music'),
    ('🎉 Party', 'party dance music'),
    ('😴 Sleep', 'calm sleep music'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _ctrl.text.trim();
    final tags = _selectedTags.join(', ');
    final prompt = [
      if (text.isNotEmpty) text,
      if (tags.isNotEmpty) tags,
    ].join(' + ');

    if (prompt.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _tracks = [];
      _error = null;
    });

    try {
      final tracks = await SpotifyService.instance.aiPlaylist(prompt);
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _loading = false;
        });
        await AchievementsService.instance.onSpotifyAiUsed();
        await ExpService.instance.earn(ExpReward.voiceAi);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not generate playlist. Check connection.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _playTrack(Map<String, dynamic> track) async {
    final uri = track['uri'] as String?;
    if (uri == null) return;
    HapticFeedback.selectionClick();
    await SpotifyService.instance.playUri(uri);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF0D0D1F) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: _spotifyGreen.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: c.isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1DB954), Color(0xFF00E5CC)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Playlist',
                        style: TextStyle(
                            color: c.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                    Text('Describe your vibe',
                        style: TextStyle(color: c.muted, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final (label, value) = tag;
                final selected = _selectedTags.contains(value);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedTags.remove(value);
                    } else {
                      _selectedTags.add(value);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? _spotifyGreen.withValues(alpha: 0.18)
                          : (c.isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? _spotifyGreen.withValues(alpha: 0.5)
                            : c.border,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? _spotifyGreen : c.muted,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Free text input
            Container(
              decoration: BoxDecoration(
                color: c.inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: c.text, fontSize: 14),
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  hintText:
                      'e.g. "heavy metal for bench press" or "lo-fi for stretching"',
                  hintStyle:
                      TextStyle(color: c.muted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Generate button
            GestureDetector(
              onTap: _loading ? null : _generate,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF00E5CC)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _spotifyGreen.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Generate Playlist',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                ),
              ),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 13)),
            ],

            // Track results
            if (_tracks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('${_tracks.length} tracks found',
                  style: TextStyle(
                      color: c.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._tracks.map((track) => _TrackRow(
                    track: track,
                    c: c,
                    onPlay: () => _playTrack(track),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Track row ─────────────────────────────────────────────────────────────────
class _TrackRow extends StatelessWidget {
  final Map<String, dynamic> track;
  final AppColors c;
  final VoidCallback onPlay;

  const _TrackRow({
    required this.track,
    required this.c,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final name = track['name'] as String? ?? 'Unknown';
    final artists = (track['artists'] as List?)
            ?.map((a) => a['name'] as String? ?? '')
            .join(', ') ??
        '';
    final images = track['album']?['images'] as List?;
    final artUrl = (images != null && images.isNotEmpty)
        ? images.last['url'] as String?
        : null;

    return GestureDetector(
      onTap: onPlay,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: artUrl != null
                  ? Image.network(artUrl,
                      width: 44, height: 44, fit: BoxFit.cover)
                  : Container(
                      width: 44, height: 44,
                      color: _spotifyGreen.withValues(alpha: 0.12),
                      child: const Icon(Icons.music_note_rounded,
                          color: _spotifyGreen, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: c.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(artists,
                      style: TextStyle(color: c.muted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                  color: _spotifyGreen, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final SpotifyTrack track;
  final AppColors c;
  const _ProgressBar({required this.track, required this.c});

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
              backgroundColor: c.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
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
                style: TextStyle(color: c.muted, fontSize: 11)),
            Text(_fmt(track.durationMs),
                style: TextStyle(color: c.muted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
