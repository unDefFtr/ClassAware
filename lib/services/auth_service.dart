import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  DateTime? _authenticatedUntil;
  Timer? _authTimer;
  final ValueNotifier<bool> authActive = ValueNotifier(false);

  Future<bool> _isLockedForIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('auth_enabled') ?? false;
    if (!enabled) return false;
    if (index == 2) {
      return prefs.getBool('lock_apps') ?? false;
    }
    if (index == 3) {
      return prefs.getBool('lock_settings') ?? false;
    }
    return false;
  }

  bool get isAuthenticated {
    final until = _authenticatedUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  Future<void> _setAuthenticatedForDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final mins = prefs.getInt('auth_unlock_minutes') ?? 10;
    _authenticatedUntil = DateTime.now().add(Duration(minutes: mins));
    _authTimer?.cancel();
    _authTimer = Timer(Duration(minutes: mins), () {
      _authenticatedUntil = null;
      authActive.value = false;
    });
    authActive.value = true;
  }

  Future<bool> ensureAuthenticated(BuildContext context, {String reason = ''}) async {
    if (isAuthenticated) return true;
    final prefs = await SharedPreferences.getInstance();
    final allowPin = prefs.getBool('auth_use_pin') ?? true;
    final allowBio = prefs.getBool('auth_use_bio') ?? false;
    final allowNfc = prefs.getBool('auth_use_nfc') ?? false;

    final methods = <_AuthMethod>[];
    if (allowBio) methods.add(_AuthMethod.biometrics);
    if (allowNfc) methods.add(_AuthMethod.nfc);
    if (allowPin) methods.add(_AuthMethod.pin);

    if (!context.mounted) return false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(reason.isEmpty ? '身份验证' : reason)),
              if (methods.contains(_AuthMethod.biometrics))
                ListTile(
                  leading: const Icon(Icons.face),
                  title: const Text('人脸/生物识别'),
                  onTap: () async {
                    final nav = Navigator.of(ctx);
                    final ok = await _authBiometrics();
                    nav.pop(ok);
                  },
                ),
              if (methods.contains(_AuthMethod.nfc))
                ListTile(
                  leading: const Icon(Icons.nfc),
                  title: const Text('NFC 卡片'),
                  onTap: () async {
                    final nav = Navigator.of(ctx);
                    final ok = await _authNfc(ctx);
                    nav.pop(ok);
                  },
                ),
              if (methods.contains(_AuthMethod.pin))
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('数字密码'),
                  onTap: () async {
                    final nav = Navigator.of(ctx);
                    final ok = await _authPin(ctx);
                    nav.pop(ok);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (result == true) {
      await _setAuthenticatedForDuration();
      return true;
    }
    return false;
  }

  void forceLock() {
    _authTimer?.cancel();
    _authenticatedUntil = null;
    authActive.value = false;
  }

  Future<bool> _authBiometrics() async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    if (!canCheck) return false;
    try {
      final ok = await auth.authenticate(
        localizedReason: '请进行生物识别验证',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _authPin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hashSaved = prefs.getString('auth_pin_hash');
    if (hashSaved == null || hashSaved.isEmpty) return false;
    if (!context.mounted) return false;
    String pin = '';
    String err = '';
    int filledCount = 0;
    bool animatingError = false;
    const int pinLen = 6;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              void submitIfReady() {
                if (pin.length == pinLen) {
                  final hash = sha256.convert(utf8.encode(pin)).toString();
                  final match = hash == hashSaved;
                  if (match) {
                    Navigator.of(ctx).pop(true);
                  } else {
                    Future<void> runErrorAnimation() async {
                      animatingError = true;
                      setState(() { err = '密码错误'; });
                      for (int i = filledCount; i > 0; i--) {
                        await Future.delayed(const Duration(milliseconds: 80));
                        setState(() { filledCount = i - 1; });
                      }
                      setState(() { pin = ''; });
                      animatingError = false;
                    }
                    runErrorAnimation();
                  }
                }
              }
              Widget dot(int index) {
                final filled = index < filledCount;
                return SizedBox(
                  width: 14,
                  height: 14,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: filled ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              Widget key(String label, double size, {VoidCallback? onTap}) {
                bool pressed = false;
                return StatefulBuilder(
                  builder: (kctx, setKeyState) {
                    final radius = pressed ? BorderRadius.circular(size * 0.22) : BorderRadius.circular(size / 2);
                    final bg = pressed ? Theme.of(ctx).colorScheme.primaryContainer : Theme.of(ctx).colorScheme.surfaceVariant;
                    final fg = pressed ? Theme.of(ctx).colorScheme.onPrimaryContainer : Theme.of(ctx).colorScheme.onSurface;
                    return GestureDetector(
                      onTapDown: (_) { setKeyState(() { pressed = true; }); },
                      onTapCancel: () { setKeyState(() { pressed = false; }); },
                      onTapUp: (_) {
                        setKeyState(() { pressed = false; });
                        final action = onTap ?? () {
                          if (animatingError) return;
                          if (pin.length >= 12) return;
                          setState(() { pin += label; err = ''; filledCount = pin.length; });
                          submitIfReady();
                        };
                        action();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: radius,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: (size * 0.4).clamp(16.0, 28.0),
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              Widget backspace(double size) {
                bool pressed = false;
                return StatefulBuilder(
                  builder: (kctx, setKeyState) {
                    final radius = pressed ? BorderRadius.circular(size * 0.22) : BorderRadius.circular(size / 2);
                    final bg = pressed ? Theme.of(ctx).colorScheme.primaryContainer : Theme.of(ctx).colorScheme.surfaceVariant;
                    final fg = pressed ? Theme.of(ctx).colorScheme.onPrimaryContainer : Theme.of(ctx).colorScheme.onSurface;
                    return GestureDetector(
                      onTapDown: (_) { setKeyState(() { pressed = true; }); },
                      onTapCancel: () { setKeyState(() { pressed = false; }); },
                      onTapUp: (_) {
                        setKeyState(() { pressed = false; });
                        if (animatingError) return;
                        if (pin.isEmpty) return;
                        setState(() { pin = pin.substring(0, pin.length - 1); err = ''; filledCount = pin.length; });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: radius,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.backspace, size: (size * 0.35).clamp(16.0, 24.0), color: fg),
                      ),
                    );
                  },
                );
              }
              return LayoutBuilder(
                builder: (dlgCtx, dlgCons) {
                  final screenH = MediaQuery.of(ctx).size.height;
                  final screenW = MediaQuery.of(ctx).size.width;
                  final maxPanelH = screenH * 0.7;
                  const space = 12.0;
                  const extra = 220.0;
                  final s = ((maxPanelH - extra - space * 3) / 4).clamp(44.0, 72.0);
                  final gridH = s * 4 + space * 3;
                  final gridW = s * 3 + space * 2;
                  final panelW = (gridW + 48).clamp(320.0, screenW * 0.9);
                  return Focus(
                    autofocus: true,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        final key = event.logicalKey;
                        if (key == LogicalKeyboardKey.backspace) {
                          if (animatingError) return KeyEventResult.handled;
                          if (pin.isEmpty) return KeyEventResult.handled;
                          setState(() {
                            pin = pin.substring(0, pin.length - 1);
                            err = '';
                            filledCount = pin.length;
                          });
                          return KeyEventResult.handled;
                        }
                        if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
                          submitIfReady();
                          return KeyEventResult.handled;
                        }
                        final label = key.keyLabel;
                        if (label.isNotEmpty && RegExp(r'^[0-9]$').hasMatch(label)) {
                          if (animatingError) return KeyEventResult.handled;
                          if (pin.length >= pinLen) return KeyEventResult.handled;
                          setState(() {
                            pin += label;
                            err = '';
                            filledCount = pin.length;
                          });
                          submitIfReady();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxPanelH,
                        maxWidth: panelW,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              err.isNotEmpty ? '密码错误' : '输入密码',
                              style: TextStyle(
                                color: err.isNotEmpty
                                    ? Theme.of(ctx).colorScheme.error
                                    : Theme.of(ctx).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(ctx).colorScheme.outlineVariant,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  pinLen,
                                  (i) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: dot(i),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: SizedBox(
                                height: gridH,
                                width: gridW,
                                child: GridView.count(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: space,
                                  crossAxisSpacing: space,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    key('1', s), key('2', s), key('3', s),
                                    key('4', s), key('5', s), key('6', s),
                                    key('7', s), key('8', s), key('9', s),
                                    const SizedBox.shrink(),
                                    key('0', s),
                                    backspace(s),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    final hash = sha256.convert(utf8.encode(pin)).toString();
                                    Navigator.of(ctx).pop(hash == hashSaved);
                                  },
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
    return ok == true;
  }

  Future<bool> _authNfc(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final allowed = prefs.getStringList('auth_nfc_uids') ?? const [];
    if (allowed.isEmpty) return false;
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) return false;
    String? uid;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: const {NfcPollingOption.iso14443, NfcPollingOption.iso18092},
        onDiscovered: (tag) async {
          final raw = tag.data;
          List<int>? idBytes;
          if (raw is Map && raw['id'] is List) {
            idBytes = (raw['id'] as List).cast<int>();
          } else if (raw is Map && raw['nfca'] is Map && raw['nfca']['identifier'] is List) {
            idBytes = (raw['nfca']['identifier'] as List).cast<int>();
          } else if (raw is Map && raw['mifareultralight'] is Map && raw['mifareultralight']['identifier'] is List) {
            idBytes = (raw['mifareultralight']['identifier'] as List).cast<int>();
          } else if (raw is Map && raw['ndef'] is Map && raw['ndef']['identifier'] is List) {
            idBytes = (raw['ndef']['identifier'] as List).cast<int>();
          }
          if (idBytes != null) {
            uid = idBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
          }
          await NfcManager.instance.stopSession();
        },
      );
    } catch (_) {}
    if (uid == null) return false;
    return allowed.map((e) => e.toLowerCase()).contains(uid!.toLowerCase());
  }

  Future<String?> readNfcUidOnce() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) return null;
    String? uid;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: const {NfcPollingOption.iso14443, NfcPollingOption.iso18092},
        onDiscovered: (tag) async {
          final raw = tag.data;
          List<int>? idBytes;
          if (raw is Map && raw['id'] is List) {
            idBytes = (raw['id'] as List).cast<int>();
          } else if (raw is Map && raw['nfca'] is Map && raw['nfca']['identifier'] is List) {
            idBytes = (raw['nfca']['identifier'] as List).cast<int>();
          } else if (raw is Map && raw['mifareultralight'] is Map && raw['mifareultralight']['identifier'] is List) {
            idBytes = (raw['mifareultralight']['identifier'] as List).cast<int>();
          } else if (raw is Map && raw['ndef'] is Map && raw['ndef']['identifier'] is List) {
            idBytes = (raw['ndef']['identifier'] as List).cast<int>();
          }
          if (idBytes != null) {
            uid = idBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
          }
          await NfcManager.instance.stopSession();
        },
      );
    } catch (_) {}
    return uid;
  }

  Future<bool> guardForIndex(BuildContext context, int index) async {
    final locked = await _isLockedForIndex(index);
    if (!locked) return true;
    if (!context.mounted) return false;
    return ensureAuthenticated(context, reason: index == 2 ? '访问所有应用' : '访问设置');
  }

  Future<bool> shouldLockApps() async {
    return await _isLockedForIndex(2);
  }

  Future<bool> shouldLockSettings() async {
    return await _isLockedForIndex(3);
  }
}

enum _AuthMethod { biometrics, nfc, pin }