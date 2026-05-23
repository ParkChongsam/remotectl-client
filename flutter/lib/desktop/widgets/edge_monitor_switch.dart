// remotectl: 가장자리 자동 모니터 전환
// 단일 모니터 보기 모드일 때, 커서가 뷰어의 좌/우 가장자리에 dwell 시간 이상 머물면
// 인접한 호스트 모니터로 자동 전환한다. TeamViewer/AnyDesk의 "Smart Switch"에 해당하는 기능.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/model.dart';

class EdgeMonitorSwitch extends StatefulWidget {
  final FFI ffi;
  final Widget child;

  // 가장자리로 인식할 픽셀 폭.
  final double edgePx;
  // 가장자리에 머물러야 하는 시간 (ms).
  final Duration dwellDuration;

  const EdgeMonitorSwitch({
    super.key,
    required this.ffi,
    required this.child,
    this.edgePx = 5.0,
    this.dwellDuration = const Duration(milliseconds: 800),
  });

  @override
  State<EdgeMonitorSwitch> createState() => _EdgeMonitorSwitchState();
}

class _EdgeMonitorSwitchState extends State<EdgeMonitorSwitch> {
  Timer? _dwellTimer;
  int _activeDirection = 0; // -1: left, +1: right, 0: idle
  DateTime _lastSwitchAt = DateTime.fromMillisecondsSinceEpoch(0);

  // 모니터 전환 직후의 보호 시간 (연쇄 전환 방지).
  static const Duration _cooldown = Duration(milliseconds: 600);

  void _onHover(PointerHoverEvent event, BoxConstraints constraints) {
    final pi = widget.ffi.ffiModel.pi;
    if (pi.displays.length < 2) {
      _cancel();
      return;
    }
    // 전체 디스플레이 보기 모드에서는 적용하지 않음.
    if (pi.currentDisplay == kAllDisplayValue) {
      _cancel();
      return;
    }
    if (DateTime.now().difference(_lastSwitchAt) < _cooldown) {
      return;
    }

    final dx = event.localPosition.dx;
    final atRight = dx >= constraints.maxWidth - widget.edgePx;
    final atLeft = dx <= widget.edgePx;

    if (atRight) {
      if (_activeDirection != 1) _startDwell(1);
    } else if (atLeft) {
      if (_activeDirection != -1) _startDwell(-1);
    } else {
      if (_activeDirection != 0) _cancel();
    }
  }

  void _startDwell(int direction) {
    _dwellTimer?.cancel();
    _activeDirection = direction;
    _dwellTimer = Timer(widget.dwellDuration, () => _doSwitch(direction));
  }

  void _cancel() {
    _dwellTimer?.cancel();
    _dwellTimer = null;
    _activeDirection = 0;
  }

  void _doSwitch(int direction) {
    final ffi = widget.ffi;
    final pi = ffi.ffiModel.pi;
    if (pi.displays.length < 2) return;
    final n = pi.displays.length;
    final current = pi.currentDisplay;
    if (current == kAllDisplayValue) return;
    int next = (current + direction) % n;
    if (next < 0) next += n;
    if (next == current) return;
    _lastSwitchAt = DateTime.now();
    _activeDirection = 0;
    try {
      openMonitorInTheSameTab(next, ffi, pi);
    } catch (_) {
      // ignore — UI는 그대로 유지
    }
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) => _onHover(event, constraints),
          onExit: (_) => _cancel(),
          opaque: false,
          child: widget.child,
        );
      },
    );
  }
}
