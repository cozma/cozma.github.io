/**
 * JS mirror of MorningBoardKit SnapshotBuilder / ReadinessCalculator.
 * Kept in sync so the web prototype and Swift kit share one heuristic.
 */

export function clamp(value, min = 0, max = 100) {
  return Math.min(max, Math.max(min, value));
}

export function readinessScore(input) {
  let weighted = 0;
  let weightSum = 0;

  if (input.hrvNightMs != null && input.hrvBaselineMs > 0) {
    const ratio = input.hrvNightMs / input.hrvBaselineMs;
    const hrvScore = clamp(((ratio - 0.7) / 0.5) * 100);
    weighted += hrvScore * 0.45;
    weightSum += 0.45;
  }

  if (input.restingHeartRate != null && input.rhrBaseline > 0) {
    const delta = (input.rhrBaseline - input.restingHeartRate) / input.rhrBaseline;
    const rhrScore = clamp(50 + delta * 200);
    weighted += rhrScore * 0.25;
    weightSum += 0.25;
  }

  if (input.sleepHours != null && input.sleepTargetHours > 0) {
    const sleepScore = clamp((input.sleepHours / input.sleepTargetHours) * 100);
    weighted += sleepScore * 0.3;
    weightSum += 0.3;
  }

  const raw = weightSum > 0 ? weighted / weightSum : 55;
  const score = Math.round(raw);
  return { score, band: bandFor(score) };
}

export function bandFor(score) {
  if (score < 45) return "recover";
  if (score < 70) return "maintain";
  return "push";
}

export function formatHours(value) {
  const hours = Math.floor(value);
  const minutes = Math.round((value - hours) * 60);
  if (minutes === 0) return `${hours}h`;
  return `${hours}h ${minutes}m`;
}

export function insightLine({ band, sleepHours, sleepTargetHours = 7.5, cueStyle = "quiet" }) {
  let sleepNote;
  if (sleepHours == null) {
    sleepNote = "Waiting on last night’s sleep sync.";
  } else if (sleepHours + 0.35 < sleepTargetHours) {
    sleepNote =
      cueStyle === "coachy"
        ? `Sleep came in light at ${formatHours(sleepHours)}.`
        : `You slept ${formatHours(sleepHours)}.`;
  } else {
    sleepNote =
      cueStyle === "coachy"
        ? `Solid night — ${formatHours(sleepHours)} of sleep.`
        : `${formatHours(sleepHours)} of sleep on the board.`;
  }

  const map = {
    recover: {
      quiet: `${sleepNote} Today’s cue: recover.`,
      coachy: `${sleepNote} Protect the day — walk, stretch, skip the hammer session.`,
    },
    maintain: {
      quiet: `${sleepNote} Today’s cue: maintain.`,
      coachy: `${sleepNote} Steady work fits — keep intensity in the middle.`,
    },
    push: {
      quiet: `${sleepNote} Today’s cue: push.`,
      coachy: `${sleepNote} Green light — stack a hard session if the schedule allows.`,
    },
  };
  return map[band][cueStyle];
}

export function buildSnapshot(samples, { generatedAt = new Date(), isDemo = false } = {}) {
  const readiness = readinessScore({
    hrvNightMs: samples.hrvNightMs,
    hrvBaselineMs: samples.hrvBaselineMs,
    restingHeartRate: samples.restingHeartRate,
    rhrBaseline: samples.rhrBaseline,
    sleepHours: samples.sleepHours,
    sleepTargetHours: samples.sleepTargetHours ?? 7.5,
  });

  const day = samples.day instanceof Date ? samples.day : new Date(samples.day ?? Date.now());
  const dayKey = [
    day.getFullYear(),
    String(day.getMonth() + 1).padStart(2, "0"),
    String(day.getDate()).padStart(2, "0"),
  ].join("-");

  return {
    dayKey,
    generatedAt: generatedAt.toISOString(),
    sleepHours: samples.sleepHours ?? null,
    sleepScore: samples.sleepScore ?? null,
    hrvNightMs: samples.hrvNightMs ?? null,
    restingHeartRate: samples.restingHeartRate ?? null,
    readinessScore: readiness.score,
    readinessBand: readiness.band,
    stepsYesterday: samples.stepsYesterday ?? null,
    moveCaloriesYesterday: samples.moveCaloriesYesterday ?? null,
    lastWorkout: samples.lastWorkout ?? null,
    insight: insightLine({
      band: readiness.band,
      sleepHours: samples.sleepHours,
      sleepTargetHours: samples.sleepTargetHours ?? 7.5,
      cueStyle: samples.cueStyle ?? "quiet",
    }),
    sources: samples.sources ?? [],
    isDemo,
  };
}

export const SCENARIOS = {
  rested: {
    label: "Rested morning",
    samples: {
      sleepHours: 7.7,
      sleepScore: 88,
      hrvNightMs: 62,
      hrvBaselineMs: 55,
      restingHeartRate: 52,
      rhrBaseline: 56,
      stepsYesterday: 9420,
      moveCaloriesYesterday: 540,
      lastWorkout: {
        name: "Zone 2 run",
        activityType: "running",
        durationMinutes: 42,
      },
      sources: [
        { metric: "sleep", displayName: "Oura" },
        { metric: "hrv", displayName: "Apple Watch" },
        { metric: "steps", displayName: "Apple Watch" },
      ],
      cueStyle: "quiet",
    },
  },
  depleted: {
    label: "Depleted morning",
    samples: {
      sleepHours: 5.4,
      sleepScore: 61,
      hrvNightMs: 38,
      hrvBaselineMs: 55,
      restingHeartRate: 61,
      rhrBaseline: 56,
      stepsYesterday: 12800,
      moveCaloriesYesterday: 820,
      lastWorkout: {
        name: "Intervals",
        activityType: "running",
        durationMinutes: 55,
      },
      sources: [
        { metric: "sleep", displayName: "Apple Watch" },
        { metric: "hrv", displayName: "Apple Watch" },
      ],
      cueStyle: "coachy",
    },
  },
  waiting: {
    label: "Waiting on sleep",
    samples: {
      sleepHours: null,
      hrvNightMs: null,
      restingHeartRate: 54,
      rhrBaseline: 56,
      stepsYesterday: 7100,
      moveCaloriesYesterday: 410,
      sources: [{ metric: "steps", displayName: "Apple Watch" }],
      cueStyle: "quiet",
    },
  },
};
