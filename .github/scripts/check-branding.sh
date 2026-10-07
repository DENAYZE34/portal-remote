#!/bin/bash
# Fails the build if RustDesk branding returns to the user-visible UI.
set -e
fail=0
grep -q 'if (true) {' flutter/lib/common.dart || { echo "loadPowered not hidden"; fail=1; }
grep -rn "rustdesk.com/download\|github.com/rustdesk/rustdesk/releases" flutter/lib | grep -v "^\S*:\s*[0-9]*:\s*//" && { echo "RustDesk download links in UI"; fail=1; }
grep -q 'RENDEZVOUS_SERVERS: &\[&str\] = &\["152.70.22.194"\]' libs/hbb_common/src/config.rs || { echo "server changed"; fail=1; }
grep -q 'DENAYZE34/portal-remote/releases/latest' src/common.rs || { echo "updater url changed"; fail=1; }
grep -q "offstage: true || !(!_svcStopped.value" flutter/lib/desktop/pages/connection_page.dart || { echo "setup-server tip visible"; fail=1; }
[ -f flutter/assets/icon.png ] || { echo no-portal-icon; fail=1; }
grep -qi "rustdesk|purslane" flutter/android/app/src/main/res/values/strings.xml && { echo "RustDesk in Android strings"; fail=1; }
grep -qi "LegalCopyright.*rustdesk|Purslane" flutter/windows/runner/Runner.rc flutter/lib/desktop/pages/desktop_setting_page.dart && { echo "RustDesk/Purslane in copyright"; fail=1; }
grep -q "PortalDesk-setup-{}-{}.{}" src/updater.rs || { echo "updater asset name != release asset"; fail=1; }
exit $fail
