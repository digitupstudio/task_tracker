import Foundation

struct Activity: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var createdAt: Date
    var deletedAt: Date?
    var sortOrder: Int
}

struct Segment: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var activityId: UUID
    var sessionId: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date?
}

struct AppState: Codable, Equatable, Sendable {
    var activities: [Activity] = []
    var segments: [Segment] = []
    var currentActivityId: UUID?
    var currentSessionId: UUID?
    var isPaused: Bool = false

    var activeActivities: [Activity] {
        activities
            .filter { $0.deletedAt == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var currentActivity: Activity? {
        guard let currentActivityId else { return nil }
        return activities.first { $0.id == currentActivityId }
    }

    enum Phase: Equatable, Sendable {
        case idle
        case running
        case paused
    }

    var phase: Phase {
        guard currentActivityId != nil else { return .idle }
        return isPaused ? .paused : .running
    }
}

enum TrackerCommand: Equatable, Sendable {
    case addActivity(name: String, at: Date)
    case renameActivity(id: UUID, name: String)
    case deleteActivity(id: UUID, at: Date)
    case select(id: UUID, at: Date)
    case pause(at: Date)
    case resume(at: Date)
    case stop(at: Date)
}
