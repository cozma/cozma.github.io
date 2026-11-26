"""Mirrors AlertRouter / WatchAudioCapability decisions for Linux CI.

The authoritative tests live in WhyAreYouRunningWatchTests (XCTest on a Mac).
This file keeps the same rules green in environments without Xcode.
"""

from __future__ import annotations

import unittest


SPEAKER_AND_BANNER = "speakerAndBanner"
TEXT_AND_IMAGE = "textAndImage"
DEFAULT_COOLDOWN = 30 * 60
MINIMUM_SPEAKER_WATCHOS_MAJOR = 9


def presentation(can_play_through_speaker: bool) -> str:
    return SPEAKER_AND_BANNER if can_play_through_speaker else TEXT_AND_IMAGE


def should_trigger(
    kind: str,
    last_triggered_at: float | None,
    now: float,
    cooldown: float = DEFAULT_COOLDOWN,
) -> bool:
    if kind != "runningStarted":
        return False
    if last_triggered_at is not None and (now - last_triggered_at) < cooldown:
        return False
    return True


def can_play_through_speaker(system_major_version: int) -> bool:
    return system_major_version >= MINIMUM_SPEAKER_WATCHOS_MAJOR


class AlertRouterTests(unittest.TestCase):
    def test_speaker_presentation_when_capable(self):
        self.assertEqual(presentation(True), SPEAKER_AND_BANNER)

    def test_image_presentation_when_not_capable(self):
        self.assertEqual(presentation(False), TEXT_AND_IMAGE)

    def test_triggers_on_running_started(self):
        self.assertTrue(should_trigger("runningStarted", None, 100))

    def test_ignores_non_running_events(self):
        self.assertFalse(should_trigger("other", None, 100))

    def test_respects_cooldown(self):
        self.assertFalse(should_trigger("runningStarted", 100, 200, cooldown=300))

    def test_allows_trigger_after_cooldown(self):
        self.assertTrue(should_trigger("runningStarted", 100, 500, cooldown=300))

    def test_speaker_capability_cutoff(self):
        self.assertFalse(can_play_through_speaker(8))
        self.assertTrue(can_play_through_speaker(9))
        self.assertTrue(can_play_through_speaker(11))


if __name__ == "__main__":
    unittest.main()
