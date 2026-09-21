import Foundation

func apply(_ command: TrackerCommand, to state: inout AppState) {
    switch command {
    case .addActivity(let name, let at):
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let order = (state.activities.map(\.sortOrder).max() ?? -1) + 1
        state.activities.append(
            Activity(id: UUID(), name: trimmed, createdAt: at, deletedAt: nil, sortOrder: order)
        )

    case .renameActivity(let id, let name):
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = state.activities.firstIndex(where: { $0.id == id && $0.deletedAt == nil })
        else { return }
        state.activities[index].name = trimmed

    case .deleteActivity(let id, let at):
        guard let index = state.activities.firstIndex(where: { $0.id == id && $0.deletedAt == nil })
        else { return }
        if state.currentActivityId == id {
            apply(.stop(at: at), to: &state)
        }
        state.activities[index].deletedAt = at

    case .select(let id, let at):
        guard let activity = state.activities.first(where: { $0.id == id && $0.deletedAt == nil })
        else { return }
        if state.currentActivityId == id {
            if state.isPaused {
                apply(.resume(at: at), to: &state)
            }
            return
        }
        closeOpenSegment(in: &state, at: at)
        let sessionId = UUID()
        state.isPaused = false
        state.currentActivityId = id
        state.currentSessionId = sessionId
        state.segments.append(
            Segment(
                id: UUID(),
                activityId: id,
                sessionId: sessionId,
                name: activity.name,
                startedAt: at,
                endedAt: nil
            )
        )

    case .pause(let at):
        guard state.currentActivityId != nil, !state.isPaused else { return }
        guard closeOpenSegment(in: &state, at: at) else { return }
        state.isPaused = true

    case .resume(let at):
        guard state.isPaused,
              let activityId = state.currentActivityId,
              let sessionId = state.currentSessionId,
              state.segments.contains(where: { $0.endedAt == nil }) == false,
              let activity = state.activities.first(where: { $0.id == activityId })
        else { return }
        state.isPaused = false
        state.segments.append(
            Segment(
                id: UUID(),
                activityId: activityId,
                sessionId: sessionId,
                name: activity.name,
                startedAt: at,
                endedAt: nil
            )
        )

    case .stop(let at):
        guard state.currentActivityId != nil else { return }
        closeOpenSegment(in: &state, at: at)
        state.currentActivityId = nil
        state.currentSessionId = nil
        state.isPaused = false
    }
}

@discardableResult
func closeOpenSegment(in state: inout AppState, at date: Date) -> Bool {
    guard let index = state.segments.lastIndex(where: { $0.endedAt == nil }) else { return false }
    let start = state.segments[index].startedAt
    state.segments[index].endedAt = max(date, start)
    return true
}

func repair(_ state: inout AppState) {
    let openIndexes = state.segments.indices.filter { state.segments[$0].endedAt == nil }
    if openIndexes.count > 1 {
        for index in openIndexes.dropLast() {
            state.segments[index].endedAt = state.segments[index].startedAt
        }
    }
    if let open = state.segments.last(where: { $0.endedAt == nil }) {
        state.currentActivityId = open.activityId
        state.currentSessionId = open.sessionId
        state.isPaused = false
        return
    }
    let pausedIsValid = state.isPaused
        && state.currentActivityId != nil
        && state.currentSessionId != nil
        && state.activities.contains { $0.id == state.currentActivityId }
    if pausedIsValid { return }
    state.currentActivityId = nil
    state.currentSessionId = nil
    state.isPaused = false
}

func sessionSeconds(state: AppState, now: Date) -> Int? {
    guard let sessionId = state.currentSessionId else { return nil }
    let total = state.segments.reduce(0.0) { partial, segment in
        guard segment.sessionId == sessionId else { return partial }
        let end = segment.endedAt ?? now
        return partial + max(0, end.timeIntervalSince(segment.startedAt))
    }
    return Int(total.rounded())
}
