import 'package:flutter_hbb/models/platform_model.dart';

import '../common.dart';

/// Remembers that the owner had screen sharing on. Android drops the screen
/// capture grant whenever the app process dies (update, reboot, memory), so
/// the next launch starts the service again and the owner only taps the
/// system "Start now" button once.
const String kHostWasOnOption = 'portal-host-on';

bool shouldResumeHost(String? saved, bool serviceRunning) =>
    saved == 'Y' && !serviceRunning;

Future<void> rememberHostState(bool on) async {
  if (!isAndroid) return;
  await bind.mainSetLocalOption(key: kHostWasOnOption, value: on ? 'Y' : 'N');
}

Future<void> resumeHostIfNeeded() async {
  if (!isAndroid || bind.isOutgoingOnly()) return;
  final saved = bind.mainGetLocalOption(key: kHostWasOnOption);
  if (!shouldResumeHost(saved, gFFI.serverModel.isStart)) return;
  await gFFI.serverModel.startService();
}
