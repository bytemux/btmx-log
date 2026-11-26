# btmx-log

Chat with your future self. Product idea: [docs/idea/btmx-log.md](docs/idea/btmx-log.md).

Current state: walking skeleton (step 0 of the MVP).

- Chat list with search by name; new chats; the **Inbox** chat is created on first launch.
- Telegram-like chat screen. Limit: 4,096 characters per message.
- Storage: SwiftData store `Application Support/btmx-log.store`. The models follow CloudKit rules,
  so iCloud sync needs only the iCloud capability (see below), not a data migration.
- Settings: export all chats to Markdown or JSON; About (version, git commit, author).

## Scripts (run on the Mac, from the repo root)

| Command | What it does |
|---|---|
| `scripts/build-and-run.sh` | Build, install, launch on `iPhone 17`, save `build/launch.png` |
| `scripts/test-xcuitest.sh` | Run unit tests (`BtmxLogTests`) and UI tests (`BtmxLogUITests`); screenshots exported to `build/attachments/` |

Use another simulator: `SIM="iPhone 18 Pro" scripts/test-xcuitest.sh`

Both scripts pass the current git commit to the build (`GIT_COMMIT`). A build from Xcode shows `dev`.

## Run the app in Xcode

Open `BtmxLog.xcodeproj`, pick an iPhone simulator, press ⌘R. Tests: ⌘U.

## Turn on iCloud sync (needs a paid Apple Developer account)

1. Xcode → target `BtmxLog` → Signing & Capabilities: choose your team.
2. Add the **iCloud** capability, tick **CloudKit**, add a container (for example `iCloud.dev.btmx.BtmxLog`).
3. Add the **Background Modes** capability, tick **Remote notifications**.

The store uses `cloudKitDatabase: .automatic`, so sync starts without other code changes.

### Must fix before sync goes live: duplicate Inbox

Each device creates an Inbox chat on first launch (`JournalStore.ensureInbox`). Two devices that
start empty, or a reinstall before the first sync finishes, create two Inbox chats; CloudKit
then syncs both. SwiftData + CloudKit cannot enforce a unique Inbox (no unique constraints).
Fix: after a sync import, find all chats with `isInbox == true`, keep the oldest (`createdAt`),
move the other chats' messages into it, and delete the extra chats.
