import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/strings.dart';
import '../services/ai_analysis_service.dart';
import '../services/api_service.dart';
import '../services/locale_service.dart';
import '../services/lock_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'pin_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _loading = true;

  // avatar
  String? _avatarUrl;
  String _userName = '';
  bool _avatarUploading = false;

  // AI analysis
  bool _aiEnabled = false;
  int _aiFrequencyDays = 1;
  bool _aiAnalyzing = false;

  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _load();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final pin = await LockService.instance.hasPin();
    final bio = await LockService.instance.biometricEnabled();
    final canBio = await LockService.instance.canUseBiometrics();
    try {
      final acc = await ApiService.instance.getAccountProfile();
      final accountData = acc['accountData'] as Map<String, dynamic>?;
      final profile = acc['profile'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _avatarUrl = accountData?['avatarUrl'] as String?;
          _userName = (profile?['name'] as String?) ?? '';
        });
      }
    } catch (_) {}
    final aiEnabled = await AiAnalysisService.instance.isEnabled();
    final aiFreq = await AiAnalysisService.instance.getFrequencyDays();
    if (mounted) {
      setState(() {
        _aiEnabled = aiEnabled;
        _aiFrequencyDays = aiFreq;
      });
    }
    if (mounted) {
      setState(() {
        _pinEnabled = pin;
        _biometricEnabled = bio;
        _biometricSupported = canBio;
        _loading = false;
      });
      _entranceCtrl.forward();
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 512);
    if (picked == null) return;
    setState(() => _avatarUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final mime = picked.mimeType ?? 'image/jpeg';
      final url = await ApiService.instance.uploadAvatar(bytes, mime);
      if (mounted) setState(() => _avatarUrl = url);
    } on DioException catch (e) {
      final serverMsg = (e.response?.data as Map?)?['message'] as String?;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(serverMsg ?? 'Upload failed: ${e.message}'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  Future<void> _removeAvatar() async {
    final confirm =
        await _confirmDialog(t('remove_photo_title'), t('remove_photo_body'));
    if (!confirm) return;
    setState(() => _avatarUploading = true);
    try {
      await ApiService.instance.removeAvatar();
      if (mounted) setState(() => _avatarUrl = null);
    } catch (_) {} finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  Future<void> _togglePin(bool val) async {
    if (val) {
      final set = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
      if (set == true) setState(() => _pinEnabled = true);
    } else {
      final confirm =
          await _confirmDialog(t('disable_pin_title'), t('disable_pin_body'));
      if (confirm) {
        await LockService.instance.clearPin();
        setState(() {
          _pinEnabled = false;
          _biometricEnabled = false;
        });
      }
    }
  }

  Future<void> _changePin() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
  }

  Future<void> _toggleBiometric(bool val) async {
    await LockService.instance.setBiometricEnabled(val);
    setState(() => _biometricEnabled = val);
  }

  Future<bool> _confirmDialog(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.13)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(body,
                        style:
                            const TextStyle(color: textMuted, fontSize: 13)),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.12)),
                            ),
                            alignment: Alignment.center,
                            child: Text(t('cancel'),
                                style:
                                    const TextStyle(color: textMuted)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.35)),
                            ),
                            alignment: Alignment.center,
                            child: Text(t('confirm'),
                                style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> _logout() async {
    final confirm =
        await _confirmDialog(t('sign_out_title'), t('sign_out_body'));
    if (!confirm || !mounted) return;
    await ApiService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: teal, strokeWidth: 2));
    }

    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(_entranceCtrl.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - v)),
            child: child,
          ),
        );
      },
      child: ListView(
        padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            bottom: 120),
        children: [
          // ── Profile section ─────────────────────────────────────
          _sectionHeader('PROFILE'),
          _glassSection(
            child: Column(
              children: [
                // Avatar circle
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _avatarUploading
                        ? Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: surfaceColor.withValues(alpha: 0.5)),
                            child: const CircularProgressIndicator(
                                color: teal, strokeWidth: 2),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: teal.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: -4,
                                ),
                              ],
                              border: Border.all(
                                color: teal.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: const Color(0xFF1A2942),
                              backgroundImage:
                                  (_avatarUrl != null &&
                                          _avatarUrl!.isNotEmpty)
                                      ? NetworkImage(_avatarUrl!)
                                      : null,
                              child: (_avatarUrl == null ||
                                      _avatarUrl!.isEmpty)
                                  ? Text(
                                      _userName.isNotEmpty
                                          ? _userName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: teal,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700),
                                    )
                                  : null,
                            ),
                          ),
                    GestureDetector(
                      onTap: _avatarUploading ? null : _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: teal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: teal.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_userName.isNotEmpty)
                  Text(
                    _userName,
                    style: const TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _glassButton(
                      icon: Icons.upload_outlined,
                      label: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? t('change_photo')
                          : t('upload_photo'),
                      color: teal,
                      onTap: _avatarUploading ? null : _pickAvatar,
                    ),
                    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _glassButton(
                        icon: Icons.delete_outline,
                        label: t('remove'),
                        color: const Color(0xFFEF4444),
                        onTap: _avatarUploading ? null : _removeAvatar,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Security section
          _sectionHeader(t('section_security')),
          _glassSection(
            child: Column(
              children: [
                _switchTile(
                  title: t('pin_lock'),
                  subtitle: t('pin_lock_sub'),
                  icon: Icons.lock_outline_rounded,
                  value: _pinEnabled,
                  onChanged: _togglePin,
                ),
                if (_pinEnabled) ...[
                  _divider(),
                  _arrowTile(
                    title: t('change_pin'),
                    icon: Icons.pin_outlined,
                    onTap: _changePin,
                  ),
                ],
                if (_pinEnabled && _biometricSupported) ...[
                  _divider(),
                  _switchTile(
                    title: t('biometric'),
                    subtitle: t('biometric_sub'),
                    icon: Icons.fingerprint,
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // AI Analysis section
          _sectionHeader(t('section_ai')),
          _glassSection(
            child: Column(
              children: [
                _switchTile(
                  title: t('ai_auto_analyse'),
                  subtitle: t('ai_auto_sub'),
                  icon: Icons.auto_awesome_outlined,
                  iconColor: teal,
                  value: _aiEnabled,
                  onChanged: (val) async {
                    await AiAnalysisService.instance
                        .setEnabled(val, frequencyDays: _aiFrequencyDays);
                    setState(() => _aiEnabled = val);
                  },
                ),
                if (_aiEnabled) ...[
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(t('frequency'),
                            style:
                                const TextStyle(color: textPrimary)),
                        const Spacer(),
                        DropdownButton<int>(
                          value: _aiFrequencyDays,
                          dropdownColor: const Color(0xFF0C1525),
                          style: const TextStyle(color: textPrimary),
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(
                                value: 0,
                                child: Text(t('freq_manual'))),
                            DropdownMenuItem(
                                value: 1,
                                child: Text(t('freq_daily'))),
                            DropdownMenuItem(
                                value: 2,
                                child: Text(t('freq_2days'))),
                            DropdownMenuItem(
                                value: 3,
                                child: Text(t('freq_3days'))),
                            DropdownMenuItem(
                                value: 7,
                                child: Text(t('freq_weekly'))),
                          ],
                          onChanged: (v) async {
                            if (v == null) return;
                            await AiAnalysisService.instance
                                .setFrequencyDays(v);
                            setState(() => _aiFrequencyDays = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                _divider(),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _aiAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: teal, strokeWidth: 2))
                        : const Icon(Icons.bolt_outlined,
                            color: teal, size: 16),
                  ),
                  title: Text(t('analyse_now'),
                      style: const TextStyle(color: textPrimary)),
                  subtitle: Text(t('analyse_now_sub'),
                      style:
                          const TextStyle(color: textMuted, fontSize: 12)),
                  onTap: _aiAnalyzing
                      ? null
                      : () async {
                          setState(() => _aiAnalyzing = true);
                          try {
                            await AiAnalysisService.instance.analyzeNow();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t('analysis_done'))),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _aiAnalyzing = false);
                            }
                          }
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Language section
          _sectionHeader(t('section_language')),
          _glassSection(
            child: Column(
              children: [
                _langTile('en'),
                _divider(),
                _langTile('uk'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Account section
          _sectionHeader(t('section_account')),
          _glassSection(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout_outlined,
                    color: Color(0xFFEF4444), size: 16),
              ),
              title: Text(t('sign_out'),
                  style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600)),
              onTap: _logout,
            ),
          ),

          const SizedBox(height: 24),
          Text(
            t('version'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _glassSection({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.09),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.11)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        color: Colors.white.withValues(alpha: 0.08),
        height: 1,
        indent: 16,
        endIndent: 16,
      );

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
            color: teal,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (iconColor ?? textMuted).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor ?? textMuted, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: textPrimary, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: teal,
            activeTrackColor: teal.withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            inactiveThumbColor: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _arrowTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: textMuted, size: 16),
      ),
      title:
          Text(title, style: const TextStyle(color: textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: textMuted),
      onTap: onTap,
    );
  }

  Widget _langTile(String code) {
    final selected = LocaleService.instance.langCode.value == code;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? teal.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: teal.withValues(alpha: 0.3))
              : null,
        ),
        child: Text(
          code == 'en' ? '🇬🇧' : '🇺🇦',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      title: Text(
        t('lang_$code'),
        style: TextStyle(
          color: selected ? teal : textPrimary,
          fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: teal, size: 20)
          : null,
      onTap: () async {
        await LocaleService.instance.setLang(code);
        if (mounted) setState(() {});
      },
    );
  }

  Widget _glassButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
