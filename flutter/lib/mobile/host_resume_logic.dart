/// Remembers that the owner had screen sharing on. Android drops the screen
/// capture grant whenever the app process dies (update, reboot, memory), so
/// the next launch starts the service again and the owner only taps the
/// system "Start now" button once.
const String kHostWasOnOption = 'portal-host-on';

bool shouldResumeHost(String? saved, bool serviceRunning) =>
    saved == 'Y' && !serviceRunning;
