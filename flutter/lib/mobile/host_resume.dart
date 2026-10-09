import 'package:flutter_hbb/models/platform_model.dart';

import '../common.dart';
import 'host_resume_logic.dart';

Future<void> resumeHostIfNeeded() async {
  if (!isAndroid || bind.isOutgoingOnly()) return;
  final saved = bind.mainGetLocalOption(key: kHostWasOnOption);
  if (!shouldResumeHost(saved, gFFI.serverModel.isStart)) return;
  await gFFI.serverModel.startService();
}
