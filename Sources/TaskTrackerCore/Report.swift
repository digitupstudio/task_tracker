import Foundation

struct TimedSlice: Equatable, Identifiable, Sendable {
    var id: UUID
    var activityId: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date
    var durationSeconds: Int
    var isOpen: Bool
}

struct ExportDocument: Codable, Equatable, Sendable {
    struct Range: Codable, Equatable, Sendable {
        var from: String
        var to: String
    }

    struct Entry: Codable, Equatable, Sendable {
        var name: String
        var startedAt: String
        var endedAt: String
        var durationSeconds: Int
    }

    struct Total: Codable, Equatable, Sendable {
        var name: String
        var durationSeconds: Int
    }

    var range: Range
    var entries: [Entry]
    var totals: [Total]
}

func dayRange(containing date: Date, calendar: Calendar) -> DateInterval {
    let start = calendar.startOfDay(for: date)
    let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
    return DateInterval(start: start, end: end)
}

func weekRange(containing date: Date, calendar: Calendar) -> DateInterval {
    let startOfDay = calendar.startOfDay(for: date)
    let weekday = calendar.component(.weekday, from: startOfDay)
    let daysFromMonday = (weekday + 5) % 7
    let start = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
    let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
    return DateInterval(start: start, end: end)
}

func intervalRange(from: Date, to: Date, calendar: Calendar) -> DateInterval {
    var startDay = calendar.startOfDay(for: from)
    var endDay = calendar.startOfDay(for: to)
    if endDay < startDay {
        swap(&startDay, &endDay)
    }
    let end = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
    return DateInterval(start: startDay, end: end)
}

func slices(state: AppState, range: DateInterval, now: Date) -> [TimedSlice] {
    state.segments.compactMap { segment in
        let rawEnd = segment.endedAt ?? now
        let start = max(segment.startedAt, range.start)
        let end = min(rawEnd, range.end)
        guard end > start else { return nil }
        let name = state.activities.first { $0.id == segment.activityId }?.name ?? segment.name
        let isOpen = segment.endedAt == nil && now > range.start && now < range.end
        return TimedSlice(
            id: segment.id,
            activityId: segment.activityId,
            name: name,
            startedAt: start,
            endedAt: end,
            durationSeconds: Int(end.timeIntervalSince(start).rounded()),
            isOpen: isOpen
        )
    }
}

func totals(from slices: [TimedSlice]) -> [(activityId: UUID, name: String, durationSeconds: Int)] {
    var order: [UUID] = []
    var sums: [UUID: (name: String, seconds: Int)] = [:]
    for slice in slices where slice.durationSeconds > 0 {
        if sums[slice.activityId] == nil {
            order.append(slice.activityId)
        }
        let current = sums[slice.activityId] ?? (slice.name, 0)
        sums[slice.activityId] = (slice.name, current.seconds + slice.durationSeconds)
    }
    return order
        .compactMap { id -> (UUID, String, Int)? in
            guard let item = sums[id] else { return nil }
            return (id, item.name, item.seconds)
        }
        .sorted { lhs, rhs in
            if lhs.2 != rhs.2 { return lhs.2 > rhs.2 }
            return lhs.1.localizedStandardCompare(rhs.1) == .orderedAscending
        }
}

func makeExport(state: AppState, range: DateInterval, now: Date, timeZone: TimeZone) -> ExportDocument {
    let pieces = slices(state: state, range: range, now: now).filter { $0.durationSeconds > 0 }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = timeZone
    return ExportDocument(
        range: .init(from: formatter.string(from: range.start), to: formatter.string(from: range.end)),
        entries: pieces.map {
            .init(
                name: $0.name,
                startedAt: formatter.string(from: $0.startedAt),
                endedAt: formatter.string(from: $0.endedAt),
                durationSeconds: $0.durationSeconds
            )
        },
        totals: totals(from: pieces).map {
            .init(name: $0.name, durationSeconds: $0.durationSeconds)
        }
    )
}

func exportData(_ document: ExportDocument) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    var data = try encoder.encode(document)
    data.append(0x0A)
    return data
}

func fileStamp(_ date: Date, calendar: Calendar) -> String {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    let year = parts.year ?? 0
    let month = parts.month ?? 0
    let day = parts.day ?? 0
    return String(format: "%04d-%02d-%02d", year, month, day)
}
