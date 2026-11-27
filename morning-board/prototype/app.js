import { buildSnapshot, SCENARIOS } from "./snapshot.js";

const storeKey = "morning-board.snapshot";
const scenarioKey = "morning-board.scenario";

const phoneStatus = document.getElementById("phone-status");
const scenariosEl = document.getElementById("scenarios");
const publishBtn = document.getElementById("publish");
const clearBtn = document.getElementById("clear");
const emptyState = document.getElementById("empty-state");
const board = document.getElementById("board");
const footer = document.getElementById("footer");

let selected = localStorage.getItem(scenarioKey) || "rested";

function sourceFor(snapshot, metric) {
  return snapshot.sources.find((s) => s.metric === metric)?.displayName || "";
}

function renderScenarios() {
  scenariosEl.innerHTML = "";
  for (const [id, scenario] of Object.entries(SCENARIOS)) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.role = "option";
    btn.textContent = scenario.label;
    btn.classList.toggle("active", id === selected);
    btn.addEventListener("click", () => {
      selected = id;
      localStorage.setItem(scenarioKey, id);
      phoneStatus.textContent = `Scenario set to “${scenario.label}”. Publish to update the TV.`;
      renderScenarios();
    });
    scenariosEl.appendChild(btn);
  }
}

function renderBoard(snapshot) {
  if (!snapshot) {
    emptyState.hidden = false;
    board.hidden = true;
    return;
  }

  emptyState.hidden = true;
  board.hidden = false;

  const bandLabel = snapshot.readinessBand[0].toUpperCase() + snapshot.readinessBand.slice(1);
  document.getElementById("greeting").textContent = `Good morning · ${snapshot.dayKey}`;
  document.getElementById("band").textContent = bandLabel;
  document.getElementById("insight").textContent = snapshot.insight;
  document.getElementById("score").textContent = String(snapshot.readinessScore);

  document.getElementById("sleep-value").textContent =
    snapshot.sleepHours == null ? "—" : `${snapshot.sleepHours.toFixed(1)}h`;
  document.getElementById("sleep-detail").textContent =
    snapshot.sleepScore != null ? `Score ${snapshot.sleepScore}` : snapshot.sleepHours == null ? "Waiting on sync" : "Last night";
  document.getElementById("sleep-source").textContent = sourceFor(snapshot, "sleep");

  document.getElementById("load-value").textContent =
    snapshot.stepsYesterday == null ? "—" : snapshot.stepsYesterday.toLocaleString();
  document.getElementById("load-detail").textContent =
    snapshot.moveCaloriesYesterday != null
      ? `${Math.round(snapshot.moveCaloriesYesterday)} move cal yesterday`
      : "Steps yesterday";
  document.getElementById("load-source").textContent = sourceFor(snapshot, "steps");

  document.getElementById("workout-value").textContent = snapshot.lastWorkout?.name || "—";
  document.getElementById("workout-detail").textContent = snapshot.lastWorkout
    ? `${snapshot.lastWorkout.durationMinutes} min · ${snapshot.lastWorkout.activityType}`
    : "No workout logged";
  document.getElementById("workout-source").textContent = "";

  const generatedAt = new Date(snapshot.generatedAt);
  const ageHours = (Date.now() - generatedAt.getTime()) / (1000 * 60 * 60);
  const stale = ageHours > 18;
  footer.classList.toggle("stale", stale);
  document.getElementById("tv-status").textContent = stale
    ? "Board looks stale. Open iPhone Morning Board to refresh Health."
    : snapshot.isDemo
      ? `Demo snapshot · ${generatedAt.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}`
      : `Updated ${generatedAt.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}`;
}

function loadStore() {
  const raw = localStorage.getItem(storeKey);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function publish() {
  const scenario = SCENARIOS[selected];
  const snapshot = buildSnapshot(scenario.samples, { isDemo: true });
  localStorage.setItem(storeKey, JSON.stringify(snapshot));
  phoneStatus.textContent = `Published ${snapshot.dayKey} · ${snapshot.readinessBand} ${snapshot.readinessScore}`;
  renderBoard(snapshot);
}

function clearBoard() {
  localStorage.removeItem(storeKey);
  phoneStatus.textContent = "TV board cleared. Publish again when ready.";
  renderBoard(null);
}

document.querySelectorAll(".tile").forEach((tile) => {
  tile.addEventListener("focus", () => {
    document.querySelectorAll(".tile").forEach((t) => t.classList.remove("active"));
    tile.classList.add("active");
  });
  tile.addEventListener("click", () => {
    document.querySelectorAll(".tile").forEach((t) => t.classList.remove("active"));
    tile.classList.add("active");
  });
});

// Don't keep Sleep permanently highlighted after publish — only the focused/clicked tile.
function clearTileFocus() {
  document.querySelectorAll(".tile").forEach((t) => t.classList.remove("active"));
}
publishBtn.addEventListener("click", clearTileFocus, true);

publishBtn.addEventListener("click", publish);
clearBtn.addEventListener("click", clearBoard);
document.getElementById("refresh").addEventListener("click", () => renderBoard(loadStore()));

renderScenarios();
renderBoard(loadStore());
