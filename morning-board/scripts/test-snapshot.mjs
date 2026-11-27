import assert from "node:assert/strict";
import { bandFor, buildSnapshot, readinessScore, SCENARIOS } from "../prototype/snapshot.js";

function test(name, fn) {
  try {
    fn();
    console.log(`ok  - ${name}`);
  } catch (error) {
    console.error(`fail - ${name}`);
    console.error(error);
    process.exitCode = 1;
  }
}

test("high HRV + sleep maps to push", () => {
  const { score, band } = readinessScore({
    hrvNightMs: 70,
    hrvBaselineMs: 55,
    restingHeartRate: 50,
    rhrBaseline: 56,
    sleepHours: 8,
    sleepTargetHours: 7.5,
  });
  assert.equal(band, "push");
  assert.ok(score >= 70);
});

test("low sleep + HRV maps to recover", () => {
  const { score, band } = readinessScore({
    hrvNightMs: 35,
    hrvBaselineMs: 55,
    restingHeartRate: 62,
    rhrBaseline: 56,
    sleepHours: 5,
    sleepTargetHours: 7.5,
  });
  assert.equal(band, "recover");
  assert.ok(score < 45);
});

test("band thresholds", () => {
  assert.equal(bandFor(20), "recover");
  assert.equal(bandFor(55), "maintain");
  assert.equal(bandFor(80), "push");
});

test("rested scenario builds insight", () => {
  const snapshot = buildSnapshot(SCENARIOS.rested.samples, { isDemo: true });
  assert.equal(snapshot.readinessBand, "push");
  assert.match(snapshot.insight.toLowerCase(), /push|sleep/);
  assert.equal(snapshot.isDemo, true);
});

test("waiting on sleep keeps null sleepHours", () => {
  const snapshot = buildSnapshot(SCENARIOS.waiting.samples);
  assert.equal(snapshot.sleepHours, null);
  assert.match(snapshot.insight, /Waiting/);
});

if (!process.exitCode) {
  console.log("\nAll snapshot tests passed.");
}
