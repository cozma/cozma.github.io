# App Store / Xcode copy — Why Are You Running?

Copy-paste drafts for everything you’ll fill in **Xcode** and **App Store Connect**.
Tweak tone or URLs to match your real support site before submit.

---

## 1. Xcode → Target → General

| Field | Value |
| --- | --- |
| Display Name | `Why Running?` |
| Bundle Identifier | `com.YOURNAME.WhyAreYouRunning.watchkitapp` (must match App Store Connect) |
| Version | `1.0` |
| Build | `1` (bump every upload) |
| Deployment | watchOS 8.0+ |
| Category (Xcode) | Entertainment (or Health & Fitness) |

**Signing & Capabilities**

- Team: your Apple Developer team
- Capabilities to keep enabled: **HealthKit**, **Background Modes → Workout Processing**
- Entitlements already in repo: `WhyAreYouRunning.entitlements`

**App Icon**

- Provide a 1024×1024 marketing icon in `Assets.xcassets` → AppIcon (required to archive).

---

## 2. Xcode → Info / Privacy usage strings

These already live in `Info.plist`. Use these polished versions (or paste into the target’s Info tab):

**Privacy — Health Share Usage Description** (`NSHealthShareUsageDescription`)

```
Why Are You Running? reads Running workouts from Health so it can notify you when a run starts. Workout data stays on your devices and is never uploaded by this app.
```

**Privacy — Motion Usage Description** (`NSMotionUsageDescription`)

```
Motion activity is used only to detect when you begin running, so the app can show its alert. Motion data is processed on your Apple Watch and is not shared.
```

Optional if Xcode prompts for it later:

**Privacy — Health Update Usage Description** (`NSHealthUpdateUsageDescription`) — only if you ever *write* workouts (this app does not). Skip unless you add write access.

---

## 3. Xcode archive questionnaire (common prompts)

**Export compliance / encryption**

- Uses encryption? → **No** (HTTPS-only system frameworks don’t count for the typical “no” path for this app).
- If asked about exempt encryption: this app does not implement custom crypto.

**Advertising Identifier**

- No ads → do not enable ATT; answer that you do not track users.

---

## 4. App Store Connect → App Information

| Field | Draft |
| --- | --- |
| Name | `Why Are You Running?` (30 char limit — this is 20) |
| Subtitle | `A watch alert when you start a run` (30 chars max — trim if needed: `Alerts when your run starts`) |
| Privacy Policy URL | Host the policy below (required). Example: `https://YOURDOMAIN/why-are-you-running/privacy` |
| Category (primary) | **Entertainment** |
| Category (secondary) | **Health & Fitness** |
| Content Rights | You own or have rights to all included assets (your audio + still). |
| Age Rating | Complete questionnaire → expect **4+** |

**Subtitle alternatives (≤30 characters)**

```
Run-start alert for Apple Watch
Asks when you start running
```

---

## 5. App Store Connect → Pricing & Availability

- Price: **Free** (or paid — your call)
- Availability: all territories you want
- Apple Watch: check **Apple Watch** as a destination (watch-only app)

---

## 6. Version / localization (English — U.S.)

### Promotional Text (170 chars, optional, appears above description)

```
Start a run on Apple Watch and get a timely “Why are you running?” alert — with sound on newer watches, or a banner + image on older ones.
```

### Description

```
Why Are You Running? is a tiny Apple Watch app with one job: notice when you start running, then ask the question.

HOW IT WORKS
• Listens for running motion and Running workouts from Apple Health
• On newer Apple Watches, plays your alert sound through the speaker and shows a banner
• On older Apple Watches, shows a notification with text and an image
• Keeps listening when the watch is locked — best when you start a Running workout
• Includes a Test alert button so you can try it without going for a jog
• Uses a cooldown so a long run doesn’t keep repeating the alert

PERMISSIONS
• Motion — to detect when running begins
• Health (Running workouts) — to catch workouts you start in the Workout app
• Notifications — to deliver the alert (time-sensitive while you exercise)

Your motion and workout data are used on-device to trigger the alert. This app does not create an account and does not upload your health data to a server.

Replace the bundled placeholder sound with your own audio before you ship if you want a custom clip — keep the filename run_alert.wav in the Xcode project.
```

*(Delete the last paragraph from the public store listing if you don’t want to mention Xcode/filename — it’s builder-facing. Public-facing version without it:)*

```
Why Are You Running? is a tiny Apple Watch app with one job: notice when you start running, then ask the question.

HOW IT WORKS
• Listens for running motion and Running workouts from Apple Health
• On newer Apple Watches, plays an alert sound through the speaker and shows a banner
• On older Apple Watches, shows a notification with text and an image
• Keeps listening when the watch is locked — best when you start a Running workout
• Includes a Test alert button so you can try it without going for a jog
• Uses a cooldown so a long run doesn’t keep repeating the alert

PERMISSIONS
• Motion — to detect when running begins
• Health (Running workouts) — to catch workouts you start in the Workout app
• Notifications — to deliver the alert (time-sensitive while you exercise)

Your motion and workout data are used on-device to trigger the alert. This app does not create an account and does not upload your health data to a server.
```

### Keywords (100 characters max, comma-separated, no spaces after commas preferred)

```
run,running,jog,workout,watch,alert,notification,humor,fitness,health,motion
```

(Count as you paste — trim from the end if over 100.)

### What’s New (Version 1.0)

```
Initial release. Detects when you start a run and delivers the Why Are You Running? alert on Apple Watch.
```

### Support URL

Use any page you control (GitHub README is fine for v1):

```
https://github.com/cozma/cozma.github.io/tree/main/why-are-you-running
```

### Marketing URL (optional)

```
https://cozma.github.io
```

### Copyright

```
2026 YOUR NAME
```

---

## 7. App Review Information (App Store Connect)

**Contact**

- First / Last / Phone / Email: your real review contact

**Demo account**

- None — no login. Leave blank / “No account required.”

**Notes for Review** (paste this)

```
Thank you for reviewing Why Are You Running?

This is a watch-only app. No iPhone companion UI is required.

HOW TO DEMO WITHOUT RUNNING OUTSIDE
1. Install on an Apple Watch (or Watch simulator paired in Xcode).
2. Launch “Why Running?”.
3. Allow Notifications (including Time Sensitive if prompted), Motion, and Health when prompted.
4. Tap “Test alert”.
   - On watchOS 9+: you should hear the alert sound and see a banner.
   - On older watchOS: you should see a notification with text and an image attachment.

LOCKED-WATCH / BACKGROUND PATH
• Leave the app (wrist down / locked is fine).
• Start a Running workout in the Workout app.
• HealthKit background delivery should wake the app and post a time-sensitive notification (speaker audio may also play on newer watches during that brief wake).
• Background refresh may also catch recent running motion; workout start is the most reliable demo.

DATA USE
• Reads Motion activity and HealthKit Running workouts only to detect run start.
• Does not write Health data.
• Does not track users, show ads, or upload health/motion data to a server.

Please contact me if anything fails in review — happy to help quickly.
```

**Attachment**

- Optional: short screen recording of tapping **Test alert**.

---

## 8. Age Rating questionnaire (expected answers)

Answer honestly in the form; for this app you should be able to select **None** for:

- Cartoon/fantasy violence, realistic violence, sexual content, nudity, profanity, drugs, medical/treatment info, gambling, horror, etc.

Result should land at **4+**.

---

## 9. App Privacy (nutrition labels)

Declare in App Store Connect → App Privacy:

**Data Not Collected** — if you ship exactly as designed (on-device only, no analytics SDK, no accounts, no server).

If you later add analytics/crash reporting, update this before that build goes live.

**Tracking:** **No**

**Health & Fitness / Motion:** not “collected” by you if it never leaves the device / isn’t linked to identity. Do **not** claim you collect Health data unless you transmit or store it off-device.

---

## 10. Privacy Policy (host this page; link it in App Store Connect)

```
Privacy Policy — Why Are You Running?

Last updated: November 26, 2026

Why Are You Running? (“the App”) is an Apple Watch application that detects when you start running and shows an alert.

Information the App uses
• Motion activity (to detect running)
• HealthKit Running workout data (to detect workouts you start)
• Notification permission (to deliver alerts)

This information is processed on your Apple Watch (and related Apple devices via Apple’s system frameworks) solely to trigger the alert. The App does not create user accounts and does not upload your motion or Health data to our servers. We do not sell personal data.

Permissions
You can revoke Motion, Health, and Notification access in watchOS / iPhone Settings. If permissions are revoked, run detection or alerts may stop working.

Third parties
The App does not include third-party advertising or analytics SDKs in the current version.

Children
The App does not target children under 13 and does not knowingly collect personal information from children.

Contact
Questions about this policy: YOUR_EMAIL@example.com

Changes
We may update this policy when the App’s data practices change. The “Last updated” date will change when we do.
```

---

## 11. Screenshots (App Store Connect → watchOS)

Apple requires watch screenshots for the sizes you support. Practical set:

1. Home screen with status “Listening for a run…”
2. After **Test alert** (banner / notification if visible)
3. Mode label showing Speaker vs Text + image (optional)

Tips:

- Use a Series 10 / recent watch screenshot size Apple lists in Connect.
- No “Vine” or third-party trademarked branding in screenshots.
- Caption text on the image is optional; keep it minimal.

---

## 12. Pre-submit checklist

- [ ] Replace `Resources/run_alert.wav` with your final audio
- [ ] Final App Icon (1024×1024)
- [ ] Privacy policy URL live
- [ ] Usage description strings match Section 2 (rebuild after editing Info.plist)
- [ ] Archive in Xcode → Distribute App → App Store Connect
- [ ] Select the build in Connect → answer export compliance
- [ ] Paste Review Notes from Section 7
- [ ] Submit for Review
