# Authorization required

This toolkit is for networks you own or have **written permission** to test.

Before running anything:

1. Confirm the engagement covers the exact BSSID/SSID you are targeting.
2. Record the authorization reference in `config/scope.conf`.
3. Confirm the time window and whether client disruption is permitted.
4. Stop immediately if you observe traffic from networks outside scope.

Scripts in this repo are split so that the risky parts are opt-in and
gated on the scope allowlist. Nothing here verifies or recovers passphrases.

If you are unsure whether you are allowed to test a network: you are not.
