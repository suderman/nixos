#!/usr/bin/env node

const assert = require("node:assert/strict");
const { setTimeout: delay } = require("node:timers/promises");

const LOCATION_ID = "235626";
const TIMEZONE = "America/Edmonton";
const CDP_URL = "http://127.0.0.1:9222";
const FRESHA_URL = "https://partners.fresha.com/calendar";
const DAYS_AHEAD = 35;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const TIME_RE = /^(?:[01]\d|2[0-3]):[0-5]\d:00$/;

async function main() {
  if (process.argv.length === 3 && process.argv[2] === "--test") {
    selfTest();
    process.stdout.write("fresha-org self-test passed\n");
    return;
  }
  if (process.argv.length !== 2) {
    throw new Error(`Unknown argument: ${process.argv[2]}`);
  }

  const schedule = await fetchSchedule(AbortSignal.timeout(30_000));
  process.stdout.write(renderOrg(schedule));
}

async function fetchSchedule(signal) {
  const dateFrom = localDate(new Date(), TIMEZONE);
  const dateTo = addDays(dateFrom, DAYS_AHEAD);
  const raw = await evaluateInFreshaPage(browserFetch, {
    locationId: LOCATION_ID,
    dateFrom,
    dateTo,
  }, signal);
  return normalize(raw, { dateFrom, dateTo });
}

function normalize(raw, range) {
  if (!raw || typeof raw !== "object") throw new Error("Invalid Fresha response");
  for (const key of ["employees", "closedDates", "scheduleDays", "timeOffOccurrences"]) {
    if (!Array.isArray(raw[key])) throw new Error(`Fresha response is missing ${key}`);
  }
  assertDate(range.dateFrom, "dateFrom");
  assertDate(range.dateTo, "dateTo");

  const employees = new Map();
  const names = new Set();
  for (const employee of raw.employees) {
    assertString(employee.id, "employee id");
    assertString(employee.firstName, "employee first name");
    if (/[\r\n]/.test(employee.firstName)) throw new Error("Employee first name contains a newline");
    if (names.has(employee.firstName)) throw new Error(`Duplicate employee first name: ${employee.firstName}`);
    names.add(employee.firstName);
    employees.set(employee.id, employee.firstName);
  }

  const closedDates = new Set();
  for (const closure of raw.closedDates) {
    assertDate(closure.start, "closed date start");
    assertDate(closure.end, "closed date end");
    if (closure.start > closure.end) throw new Error("Closed date range is reversed");
    const first = closure.start > range.dateFrom ? closure.start : range.dateFrom;
    const last = closure.end < range.dateTo ? closure.end : range.dateTo;
    for (let date = first; date <= last; date = addDays(date, 1)) closedDates.add(date);
  }

  const timeOff = new Map();
  for (const occurrence of raw.timeOffOccurrences) {
    if (typeof occurrence.approved !== "boolean") throw new Error("Invalid time-off approval state");
    if (!occurrence.approved) continue;
    assertDate(occurrence.date, "time-off date");
    if (!employees.has(occurrence.employeeId)) throw new Error("Time off references an unknown employee");

    const allDay = occurrence.startTime == null && occurrence.endTime == null;
    if (!allDay) {
      assertTime(occurrence.startTime, "time-off start");
      assertTime(occurrence.endTime, "time-off end");
    }
    const start = allDay ? null : shortTime(occurrence.startTime);
    const end = allDay ? null : shortTime(occurrence.endTime);
    if (!allDay && start > end) throw new Error("Time-off range is reversed");
    const absence = allDay || start === end ? null : [start, end];
    const key = `${occurrence.date}\0${occurrence.employeeId}`;
    const absences = timeOff.get(key) ?? [];
    absences.push(absence);
    timeOff.set(key, absences);
  }

  const shifts = [];
  for (const day of raw.scheduleDays) {
    assertDate(day.date, "schedule date");
    if (day.date < range.dateFrom || day.date > range.dateTo) {
      throw new Error(`Schedule date is outside requested range: ${day.date}`);
    }
    if (day.locationId !== LOCATION_ID) throw new Error("Schedule references another location");
    const employee = employees.get(day.employeeId);
    if (!employee) throw new Error("Schedule references an unknown employee");
    if (!Array.isArray(day.shifts)) throw new Error("Schedule day has no shifts array");
    if (closedDates.has(day.date)) continue;

    for (const shift of day.shifts) {
      assertTime(shift.startTime, "shift start");
      assertTime(shift.endTime, "shift end");
      const start = shortTime(shift.startTime);
      const end = shortTime(shift.endTime);
      if (start >= end) throw new Error("Overnight or reversed shifts are not supported");

      let segments = [[start, end]];
      for (const absence of timeOff.get(`${day.date}\0${day.employeeId}`) ?? []) {
        if (absence === null) {
          segments = [];
          break;
        }
        segments = segments.flatMap((segment) => subtractInterval(segment, absence));
      }
      for (const [segmentStart, segmentEnd] of segments) {
        shifts.push({ date: day.date, employee, startTime: segmentStart, endTime: segmentEnd });
      }
    }
  }

  shifts.sort(compareShifts);
  return shifts;
}

function aggregate(shifts) {
  const byDate = new Map();
  for (const shift of shifts) {
    const day = byDate.get(shift.date) ?? [];
    day.push(shift);
    byDate.set(shift.date, day);
  }

  return [...byDate.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([date, day]) => {
    day.sort(compareShifts);
    return {
      date,
      startTime: day.reduce((start, shift) => shift.startTime < start ? shift.startTime : start, "23:59"),
      endTime: day.reduce((end, shift) => shift.endTime > end ? shift.endTime : end, "00:00"),
      lines: day.map((shift) => `${shift.employee} ${shift.startTime}-${shift.endTime}`),
    };
  });
}

function renderOrg(shifts) {
  const output = ["#+title: Fresha clinic schedule", "#+category: Clinic", ""];
  for (const event of aggregate(shifts)) {
    output.push(
      "* Clinic",
      `  <${event.date} ${weekday(event.date)} ${event.startTime}-${event.endTime}>`,
      ...event.lines.map((line) => `  - ${line}`),
      "",
    );
  }
  return `${output.join("\n").trimEnd()}\n`;
}

function browserFetch({ locationId, dateFrom, dateTo }) {
  const readJson = async (url, options) => {
    const response = await fetch(url, { credentials: "include", ...options });
    if (!response.ok) throw new Error(`Fresha request failed (${response.status}). Log in to Fresha and try again.`);
    try {
      return await response.json();
    } catch {
      throw new Error("Fresha returned an unexpected response. Log in to Fresha and try again.");
    }
  };
  const apiUrl = (path, params) => {
    const url = new URL(path, "https://partners-api.fresha.com");
    for (const [key, value] of Object.entries(params)) url.searchParams.set(key, value);
    return url;
  };
  const graph = async (operationName, query, variables) => {
    const body = await readJson("https://staff-working-hours-api.fresha.com/graphql", {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify({ operationName, query, variables }),
    });
    if (body.errors?.length || !body.data) throw new Error(`Fresha ${operationName} query failed`);
    return body.data;
  };

  return (async () => {
    const employeesBody = await readJson(apiUrl("/v2/employees", {
      "location-id": locationId,
      "with-deleted": "false",
    }), { headers: { Accept: "application/vnd.api+json" } });
    if (!Array.isArray(employeesBody.data)) throw new Error("Fresha employee schema changed");
    const employees = employeesBody.data
      .filter((item) => item?.attributes?.["provides-services"] === true && item?.attributes?.["deleted-at"] == null)
      .map((item) => ({ id: item.id, firstName: item.attributes["first-name"] }));
    if (!employees.length) throw new Error("Fresha returned no active service providers");
    const employeeIds = employees.map((employee) => employee.id);

    const scheduleQuery = `query employeeScheduleDays($dateFrom: Date!, $dateTo: Date!, $employeeIds: [IID!]!, $locationId: IID!) {
      employeeScheduleDays(employeeIds: $employeeIds, fromDate: $dateFrom, toDate: $dateTo, locationId: $locationId) {
        date employeeId locationId shifts { startTime endTime }
      }
    }`;
    const timeOffQuery = `query timeOffOccurrences($dateFrom: Date!, $dateTo: Date!, $employeeIds: [IID!]!) {
      timesOffOccurrences(employeeIds: $employeeIds, fromDate: $dateFrom, toDate: $dateTo) {
        approved date employeeId startTime endTime
      }
    }`;
    const variables = { dateFrom, dateTo, employeeIds, locationId };
    const [closuresBody, scheduleBody, timeOffBody] = await Promise.all([
      readJson(apiUrl("/closed-dates", {
        "location-id": locationId,
        "date-from": dateFrom,
        "date-to": dateTo,
      }), { headers: { Accept: "application/vnd.api+json" } }),
      graph("employeeScheduleDays", scheduleQuery, variables),
      graph("timeOffOccurrences", timeOffQuery, { dateFrom, dateTo, employeeIds }),
    ]);
    if (!Array.isArray(closuresBody.data)) throw new Error("Fresha closure schema changed");

    return {
      employees,
      closedDates: closuresBody.data.map((item) => ({
        start: item?.attributes?.start,
        end: item?.attributes?.end,
      })),
      scheduleDays: scheduleBody.employeeScheduleDays,
      timeOffOccurrences: timeOffBody.timesOffOccurrences,
    };
  })();
}

async function evaluateInFreshaPage(fn, args, signal) {
  let targets = await cdpTargets(signal);
  let target = targets.find(isFreshaPage);
  let targetId = target?.id;
  if (!target) {
    const version = await cdpJson("/json/version", signal);
    if (typeof version.webSocketDebuggerUrl !== "string") {
      throw new Error("Chromium CDP did not provide a browser WebSocket URL");
    }
    const created = await cdpCall(version.webSocketDebuggerUrl, "Target.createTarget", {
      url: FRESHA_URL,
      background: true,
    }, signal);
    if (typeof created?.targetId !== "string") throw new Error("Chromium did not create a Fresha tab");
    targetId = created.targetId;
  }

  target = await waitForFreshaPage(targetId, signal);
  if (!target) {
    throw new Error("Fresha did not open. Log in to partners.fresha.com in chromium-agent, then try again");
  }

  const expression = `(async () => {
    try {
      return { ok: true, value: await (${fn.toString()})(${JSON.stringify(args)}) };
    } catch (error) {
      return { ok: false, error: error instanceof Error ? error.message : String(error) };
    }
  })()`;
  const result = await cdpCall(target.webSocketDebuggerUrl, "Runtime.evaluate", {
    expression,
    awaitPromise: true,
    returnByValue: true,
  }, signal);
  const envelope = result?.result?.value;
  if (!envelope?.ok) throw new Error(envelope?.error ?? "Fresha page request failed");
  return envelope.value;
}

async function waitForFreshaPage(targetId, signal) {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    const targets = await cdpTargets(signal);
    const target = targets.find((item) => item.id === targetId && isFreshaPage(item));
    if (target?.webSocketDebuggerUrl) {
      try {
        const result = await cdpCall(target.webSocketDebuggerUrl, "Runtime.evaluate", {
          expression: "({ origin: location.origin, readyState: document.readyState })",
          returnByValue: true,
        }, signal);
        const state = result?.result?.value;
        if (state?.origin === "https://partners.fresha.com" && state.readyState === "complete") return target;
      } catch (error) {
        if (signal.aborted) throw error;
      }
    }
    await delay(250, undefined, { signal });
  }
  return null;
}

async function cdpTargets(signal) {
  const targets = await cdpJson("/json/list", signal);
  if (!Array.isArray(targets)) throw new Error("Chromium CDP returned an invalid target list");
  return targets;
}

async function cdpJson(path, signal) {
  const response = await fetch(new URL(path, CDP_URL), { signal });
  if (!response.ok) throw new Error(`Cannot reach Chromium CDP (${response.status})`);
  return response.json();
}

function isFreshaPage(item) {
  return item.type === "page" && item.url?.startsWith("https://partners.fresha.com/");
}

function cdpCall(webSocketUrl, method, params, signal) {
  signal.throwIfAborted();
  const socket = new WebSocket(webSocketUrl);
  return new Promise((resolve, reject) => {
    const id = 1;
    let settled = false;
    const finish = (callback, value) => {
      if (settled) return;
      settled = true;
      signal.removeEventListener("abort", stop);
      if (socket.readyState === WebSocket.OPEN) socket.close();
      callback(value);
    };
    const stop = () => finish(reject, signal.reason ?? new Error("CDP request aborted"));
    signal.addEventListener("abort", stop, { once: true });
    socket.addEventListener("error", () => finish(reject, new Error("Cannot connect to Chromium CDP")), { once: true });
    socket.addEventListener("close", () => finish(reject, new Error("Chromium closed the CDP connection")), { once: true });
    socket.addEventListener("open", () => {
      if (settled) return socket.close();
      socket.send(JSON.stringify({ id, method, params }));
    }, { once: true });
    socket.addEventListener("message", (event) => {
      let message;
      try {
        message = JSON.parse(event.data);
      } catch {
        return finish(reject, new Error("Chromium returned an invalid CDP response"));
      }
      if (message.id !== id) return;
      if (message.error) finish(reject, new Error(`CDP ${method} failed: ${message.error.message}`));
      else finish(resolve, message.result);
    });
  });
}

function subtractInterval([start, end], [absenceStart, absenceEnd]) {
  if (absenceEnd <= start || absenceStart >= end) return [[start, end]];
  const result = [];
  if (absenceStart > start) result.push([start, absenceStart < end ? absenceStart : end]);
  if (absenceEnd < end) result.push([absenceEnd > start ? absenceEnd : start, end]);
  return result.filter(([segmentStart, segmentEnd]) => segmentStart < segmentEnd);
}

function compareShifts(a, b) {
  return a.date.localeCompare(b.date)
    || a.startTime.localeCompare(b.startTime)
    || a.employee.localeCompare(b.employee)
    || a.endTime.localeCompare(b.endTime);
}

function localDate(date, timezone) {
  const parts = Object.fromEntries(new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date).filter((part) => part.type !== "literal").map((part) => [part.type, part.value]));
  return `${parts.year}-${parts.month}-${parts.day}`;
}

function weekday(date) {
  return new Intl.DateTimeFormat("en-US", { timeZone: "UTC", weekday: "short" })
    .format(new Date(`${date}T00:00:00Z`));
}

function addDays(date, count) {
  assertDate(date, "date");
  const value = new Date(`${date}T00:00:00Z`);
  value.setUTCDate(value.getUTCDate() + count);
  return value.toISOString().slice(0, 10);
}

function assertString(value, name) {
  if (typeof value !== "string" || !value.trim()) throw new Error(`${name} must be a non-empty string`);
}

function assertDate(value, name) {
  if (typeof value !== "string" || !DATE_RE.test(value)) throw new Error(`${name} must be YYYY-MM-DD`);
  const parsed = new Date(`${value}T00:00:00Z`);
  if (Number.isNaN(parsed.valueOf()) || parsed.toISOString().slice(0, 10) !== value) {
    throw new Error(`${name} must be a real date`);
  }
}

function assertTime(value, name) {
  if (typeof value !== "string" || !TIME_RE.test(value)) throw new Error(`${name} must use HH:MM:00`);
}

function shortTime(value) {
  return value.slice(0, 5);
}

function selfTest() {
  const shifts = normalize({
    employees: [{ id: "a", firstName: "Ada" }, { id: "b", firstName: "Bea" }],
    closedDates: [{ start: "2026-07-04", end: "2026-07-04" }],
    scheduleDays: [
      {
        date: "2026-07-02",
        employeeId: "a",
        locationId: LOCATION_ID,
        shifts: [{ startTime: "09:00:00", endTime: "17:00:00" }],
      },
      {
        date: "2026-07-02",
        employeeId: "b",
        locationId: LOCATION_ID,
        shifts: [{ startTime: "08:30:00", endTime: "18:00:00" }],
      },
      {
        date: "2026-07-04",
        employeeId: "a",
        locationId: LOCATION_ID,
        shifts: [{ startTime: "10:00:00", endTime: "16:00:00" }],
      },
    ],
    timeOffOccurrences: [{
      approved: true,
      date: "2026-07-02",
      employeeId: "a",
      startTime: "12:00:00",
      endTime: "13:00:00",
    }],
  }, { dateFrom: "2026-07-01", dateTo: "2026-07-07" });

  assert.deepEqual(shifts, [
    { date: "2026-07-02", employee: "Bea", startTime: "08:30", endTime: "18:00" },
    { date: "2026-07-02", employee: "Ada", startTime: "09:00", endTime: "12:00" },
    { date: "2026-07-02", employee: "Ada", startTime: "13:00", endTime: "17:00" },
  ]);
  assert.equal(renderOrg(shifts), `#+title: Fresha clinic schedule
#+category: Clinic

* Clinic
  <2026-07-02 Thu 08:30-18:00>
  - Bea 08:30-18:00
  - Ada 09:00-12:00
  - Ada 13:00-17:00
`);
  assert.throws(() => assertDate("2026-02-31", "date"), /real date/);
}

main().catch((error) => {
  process.stderr.write(`fresha-org: ${error.message}\n`);
  process.exitCode = 1;
});
