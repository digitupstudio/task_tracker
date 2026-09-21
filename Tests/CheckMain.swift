import Foundation

@main
enum CheckMain {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 2 * 3600)!
        calendar.locale = Locale(identifier: "es_ES")
        var failed = 0

        func expect(_ condition: Bool, _ message: String) {
            if !condition {
                failed += 1
                fputs("FAIL \(message)\n", stderr)
            }
        }

        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
            var parts = DateComponents()
            parts.year = year
            parts.month = month
            parts.day = day
            parts.hour = hour
            parts.minute = minute
            parts.second = 0
            return calendar.date(from: parts)!
        }

        do {
            var state = AppState()
            let t0 = date(2026, 9, 22, 10, 0)
            let t1 = date(2026, 9, 22, 10, 30)
            let t2 = date(2026, 9, 22, 10, 45)
            let t3 = date(2026, 9, 22, 11, 0)
            apply(.addActivity(name: "  Proyecto X  ", at: t0), to: &state)
            let id = state.activities[0].id
            apply(.select(id: id, at: t0), to: &state)
            let session = state.currentSessionId
            apply(.pause(at: t1), to: &state)
            expect(state.phase == .paused, "pause phase")
            expect(state.currentActivityId == id, "pause keeps activity")
            expect(state.segments[0].endedAt == t1, "pause closes segment")
            apply(.resume(at: t2), to: &state)
            expect(state.phase == .running, "resume runs")
            expect(state.currentSessionId == session, "resume keeps session")
            expect(state.segments.count == 2, "resume adds segment")
            expect(state.segments[1].sessionId == session, "same session id")
            expect(sessionSeconds(state: state, now: t3) == 45 * 60, "gap excluded")
            let report = makeExport(
                state: state,
                range: dayRange(containing: t0, calendar: calendar),
                now: t3,
                timeZone: calendar.timeZone
            )
            expect(report.totals == [.init(name: "Proyecto X", durationSeconds: 45 * 60)], "pause total")
            expect(report.entries.map(\.durationSeconds) == [30 * 60, 15 * 60], "pause entries")
        }

        do {
            var state = AppState()
            let t0 = date(2026, 9, 22, 10, 0)
            apply(.addActivity(name: "Comer", at: t0), to: &state)
            let id = state.activities[0].id
            apply(.select(id: id, at: t0), to: &state)
            apply(.pause(at: date(2026, 9, 22, 10, 10)), to: &state)
            apply(.stop(at: date(2026, 9, 22, 10, 40)), to: &state)
            expect(state.phase == .idle, "stop from pause is idle")
            expect(state.segments.count == 1, "stop does not add time")
            expect(sessionSeconds(state: state, now: date(2026, 9, 22, 10, 40)) == nil, "no session after stop")
            let report = makeExport(
                state: state,
                range: dayRange(containing: t0, calendar: calendar),
                now: date(2026, 9, 22, 12, 0),
                timeZone: calendar.timeZone
            )
            expect(report.totals.first?.durationSeconds == 10 * 60, "paused stop total")
        }

        do {
            var state = AppState()
            let t0 = date(2026, 9, 22, 10, 0)
            apply(.addActivity(name: "Proyecto X", at: t0), to: &state)
            apply(.addActivity(name: "Proyecto Y", at: t0), to: &state)
            let first = state.activities[0].id
            let second = state.activities[1].id
            apply(.select(id: first, at: t0), to: &state)
            apply(.select(id: second, at: date(2026, 9, 22, 10, 20)), to: &state)
            let now = date(2026, 9, 22, 10, 30)
            expect(state.currentActivityId == second, "switch current")
            expect(state.segments[0].endedAt == date(2026, 9, 22, 10, 20), "switch closes")
            expect(state.segments[1].endedAt == nil, "second stays open")
            let report = makeExport(
                state: state,
                range: dayRange(containing: t0, calendar: calendar),
                now: now,
                timeZone: calendar.timeZone
            )
            expect(report.totals.map(\.name) == ["Proyecto X", "Proyecto Y"], "switch names")
            expect(report.totals.map(\.durationSeconds) == [20 * 60, 10 * 60], "switch totals")
        }

        do {
            var state = AppState()
            let t0 = date(2026, 9, 22, 9, 0)
            apply(.addActivity(name: "Leer", at: t0), to: &state)
            let id = state.activities[0].id
            apply(.select(id: id, at: t0), to: &state)
            apply(.select(id: id, at: date(2026, 9, 22, 9, 30)), to: &state)
            expect(state.segments.count == 1, "reselect is a no-op")
            expect(state.segments[0].endedAt == nil, "reselect stays open")
        }

        do {
            var state = AppState()
            let t0 = date(2026, 9, 22, 8, 0)
            apply(.addActivity(name: "Descanso", at: t0), to: &state)
            let id = state.activities[0].id
            apply(.select(id: id, at: t0), to: &state)
            apply(.deleteActivity(id: id, at: date(2026, 9, 22, 8, 25)), to: &state)
            expect(state.activeActivities.isEmpty, "soft delete hides button")
            expect(state.phase == .idle, "delete stops")
            expect(state.activities[0].deletedAt != nil, "deletedAt set")
            let report = makeExport(
                state: state,
                range: dayRange(containing: t0, calendar: calendar),
                now: date(2026, 9, 22, 9, 0),
                timeZone: calendar.timeZone
            )
            expect(report.entries.first?.name == "Descanso", "deleted name remains")
            expect(report.totals.first?.durationSeconds == 25 * 60, "deleted total remains")
        }

        do {
            var state = AppState()
            let t0 = date(2026, 9, 22, 8, 0)
            apply(.addActivity(name: "Viejo", at: t0), to: &state)
            let id = state.activities[0].id
            apply(.select(id: id, at: t0), to: &state)
            apply(.stop(at: date(2026, 9, 22, 8, 5)), to: &state)
            apply(.renameActivity(id: id, name: " Nuevo "), to: &state)
            let report = makeExport(
                state: state,
                range: dayRange(containing: t0, calendar: calendar),
                now: t0,
                timeZone: calendar.timeZone
            )
            expect(report.entries.first?.name == "Nuevo", "rename updates export")
        }

        do {
            var state = AppState()
            apply(.addActivity(name: "   ", at: date(2026, 9, 22, 8, 0)), to: &state)
            expect(state.activities.isEmpty, "blank name ignored")
        }

        do {
            var state = AppState()
            let start = date(2026, 9, 22, 23, 0)
            let end = date(2026, 9, 23, 1, 0)
            apply(.addActivity(name: "Noche", at: start), to: &state)
            apply(.select(id: state.activities[0].id, at: start), to: &state)
            apply(.stop(at: end), to: &state)
            let report = makeExport(
                state: state,
                range: dayRange(containing: date(2026, 9, 23, 12, 0), calendar: calendar),
                now: end,
                timeZone: calendar.timeZone
            )
            expect(report.entries.count == 1, "clip count")
            expect(report.entries.first?.durationSeconds == 60 * 60, "clip duration")
            expect(report.range.from == "2026-09-23T00:00:00+02:00", "range from")
            expect(report.range.to == "2026-09-24T00:00:00+02:00", "range to")
            expect(report.entries.first?.startedAt == "2026-09-23T00:00:00+02:00", "clip start")
            expect(report.entries.first?.endedAt == "2026-09-23T01:00:00+02:00", "clip end")
        }

        do {
            let sunday = date(2026, 9, 27, 15, 0)
            let range = weekRange(containing: sunday, calendar: calendar)
            expect(range.start == date(2026, 9, 21, 0, 0), "week starts monday")
            expect(range.end == date(2026, 9, 28, 0, 0), "week ends next monday")
            let mondayRange = weekRange(containing: date(2026, 9, 21, 0, 30), calendar: calendar)
            expect(mondayRange.start == date(2026, 9, 21, 0, 0), "monday stays")
        }

        do {
            let range = intervalRange(
                from: date(2026, 9, 23, 18, 0),
                to: date(2026, 9, 22, 1, 0),
                calendar: calendar
            )
            expect(range.start == date(2026, 9, 22, 0, 0), "interval swap start")
            expect(range.end == date(2026, 9, 24, 0, 0), "interval inclusive end")
        }

        do {
            var state = AppState()
            let id = UUID()
            let session = UUID()
            state.activities = [
                Activity(id: id, name: "X", createdAt: date(2026, 9, 22, 1, 0), deletedAt: nil, sortOrder: 0)
            ]
            state.segments = [
                Segment(
                    id: UUID(),
                    activityId: id,
                    sessionId: session,
                    name: "X",
                    startedAt: date(2026, 9, 22, 1, 0),
                    endedAt: nil
                )
            ]
            state.isPaused = true
            repair(&state)
            expect(state.phase == .running, "repair open segment")
            expect(state.currentActivityId == id, "repair activity")
            expect(state.currentSessionId == session, "repair session")
        }

        do {
            var state = AppState()
            let t0 = date(2026, 9, 22, 10, 0)
            apply(.addActivity(name: "Proyecto X", at: t0), to: &state)
            apply(.select(id: state.activities[0].id, at: t0), to: &state)
            apply(.stop(at: date(2026, 9, 22, 11, 0)), to: &state)
            let document = makeExport(
                state: state,
                range: dayRange(containing: t0, calendar: calendar),
                now: t0,
                timeZone: calendar.timeZone
            )
            let json = String(decoding: (try? exportData(document)) ?? Data(), as: UTF8.self)
            expect(json.contains("\"entries\""), "json entries")
            expect(json.contains("\"totals\""), "json totals")
            expect(json.contains("\"name\""), "json name")
            expect(json.contains("\"startedAt\""), "json start")
            expect(json.contains("\"endedAt\""), "json end")
            expect(json.contains("\"durationSeconds\" : 3600"), "json duration")
        }

        if failed > 0 {
            fputs("\(failed) failed\n", stderr)
            Darwin.exit(1)
        }
        print("ok")
    }
}
