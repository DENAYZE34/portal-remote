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
# ID/password live in the config dir named by APP_NAME and in the app identity: changing them resets users
grep -q 'RwLock::new("PortalDesk".to_owned())' libs/hbb_common/src/config.rs || { echo "APP_NAME changed: would reset ID and password"; fail=1; }
grep -q 'applicationId "com.portalremote.app"' flutter/android/app/build.gradle || { echo "applicationId changed: updates would not install over the old app"; fail=1; }
# The app must never contact RustDesk services at runtime
grep -n 'admin.rustdesk.com".to_owned' src/common.rs && { echo "RustDesk API fallback present"; fail=1; }
grep -n 'api.rustdesk.com/version' libs/hbb_common/src/lib.rs && { echo "RustDesk version-check URL present"; fail=1; }
grep -rnE "[\"']https://(www[.])?rustdesk[.]com/docs|[\"']https://github[.]com/rustdesk/rustdesk/issues" flutter/lib src/client.rs libs/hbb_common/src/config.rs && { echo "RustDesk links in app"; fail=1; }
grep -q 'const UPDATE_OWNER: &str = "DENAYZE34";' src/updater.rs && grep -q 'const UPDATE_REPO: &str = "portal-remote";' src/updater.rs || { echo "updater trusts a repository other than ours"; fail=1; }
exit $fail
