import SwiftUI

struct TrackerView: View {
    @Bindable var store: Store
    @State private var newName = ""
    @State private var editingID: UUID?
    @State private var draft = ""
    @State private var pendingDelete: UUID?
    @State private var fromDate = Date()
    @State private var toDate = Date()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(now: context.date)
        }
    }

    private func content(now: Date) -> some View {
        let calendar = Calendar.current
        let today = dayRange(containing: now, calendar: calendar)
        let pieces = slices(state: store.state, range: today, now: now).filter { $0.durationSeconds > 0 }
        let sums = totals(from: pieces)

        return VStack(alignment: .leading, spacing: 12) {
            header(now: now)
            tasks
            controls
            Divider()
            log(pieces: pieces, sums: sums)
            Divider()
            editor
            Divider()
            export(calendar: calendar)
        }
        .padding(12)
        .frame(width: 340)
    }

    private func header(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            switch store.state.phase {
            case .idle:
                Text("Sin tarea")
                    .font(.headline)
            case .running, .paused:
                Text(store.state.currentActivity?.name ?? "")
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(formatDuration(sessionSeconds(state: store.state, now: now) ?? 0))
                        .font(.title2.monospacedDigit())
                    if store.state.phase == .paused {
                        Text("En pausa")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var tasks: some View {
        let activities = store.state.activeActivities
        if activities.isEmpty {
            Text("Añade un botón para empezar.")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            FlowLayout(spacing: 6) {
                ForEach(activities) { activity in
                    taskButton(activity)
                }
            }
        }
    }

    private func taskButton(_ activity: Activity) -> some View {
        let selected = store.state.currentActivityId == activity.id
        return Button {
            store.send(.select(id: activity.id, at: Date()))
        } label: {
            Text(activity.name)
                .lineLimit(1)
                .frame(maxWidth: 150)
        }
        .buttonStyle(.bordered)
        .tint(selected ? Color.accentColor : nil)
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.accentColor, lineWidth: 1.5)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button(store.state.phase == .paused ? "Seguir" : "Pausa") {
                if store.state.phase == .paused {
                    store.send(.resume(at: Date()))
                } else {
                    store.send(.pause(at: Date()))
                }
            }
            .disabled(store.state.phase == .idle)

            Button("Stop") {
                store.send(.stop(at: Date()))
            }
            .disabled(store.state.phase == .idle)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private func log(
        pieces: [TimedSlice],
        sums: [(activityId: UUID, name: String, durationSeconds: Int)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Registro")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if pieces.isEmpty {
                Text("Nada registrado hoy.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ViewThatFits(in: .vertical) {
                    logList(pieces: pieces, sums: sums)
                    ScrollView {
                        logList(pieces: pieces, sums: sums)
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private func logList(
        pieces: [TimedSlice],
        sums: [(activityId: UUID, name: String, durationSeconds: Int)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sums, id: \.activityId) { sum in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(sum.name)
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(formatDuration(sum.durationSeconds))
                            .font(.callout.monospacedDigit())
                    }
                    ForEach(pieces.filter { $0.activityId == sum.activityId }) { slice in
                        HStack {
                            Text(sliceLabel(slice))
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 8)
                            Text(formatDuration(slice.durationSeconds))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Botones")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                TextField("Nueva tarea", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addActivity)
                Button("Añadir", action: addActivity)
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ForEach(store.state.activeActivities) { activity in
                editorRow(activity)
            }
        }
    }

    @ViewBuilder
    private func editorRow(_ activity: Activity) -> some View {
        if editingID == activity.id {
            HStack(spacing: 6) {
                TextField("Nombre", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { commitRename(activity.id) }
                Button("OK") { commitRename(activity.id) }
            }
        } else {
            HStack(spacing: 6) {
                Text(activity.name)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button("Editar") {
                    editingID = activity.id
                    draft = activity.name
                    pendingDelete = nil
                }
                .buttonStyle(.borderless)
                if pendingDelete == activity.id {
                    Button("Confirmar") {
                        store.send(.deleteActivity(id: activity.id, at: Date()))
                        pendingDelete = nil
                    }
                    .buttonStyle(.borderless)
                    Button("No") { pendingDelete = nil }
                        .buttonStyle(.borderless)
                } else {
                    Button("Quitar") { pendingDelete = activity.id }
                        .buttonStyle(.borderless)
                }
            }
            .font(.callout)
        }
    }

    private func export(calendar: Calendar) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exportar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Button("Hoy") {
                    let range = dayRange(containing: Date(), calendar: calendar)
                    writeExport(range: range, name: "task-tracker-\(fileStamp(Date(), calendar: calendar)).json")
                }
                Button("Esta semana") {
                    let range = weekRange(containing: Date(), calendar: calendar)
                    writeExport(
                        range: range,
                        name: "task-tracker-semana-\(fileStamp(range.start, calendar: calendar)).json"
                    )
                }
            }
            .buttonStyle(.bordered)
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Desde")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("Desde", selection: $fromDate, displayedComponents: .date)
                        .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hasta")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("Hasta", selection: $toDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .controlSize(.small)
            Button("Intervalo") {
                let range = intervalRange(from: fromDate, to: toDate, calendar: calendar)
                let start = fileStamp(range.start, calendar: calendar)
                let endDay = calendar.date(byAdding: .day, value: -1, to: range.end) ?? range.end
                let end = fileStamp(endDay, calendar: calendar)
                writeExport(range: range, name: "task-tracker-\(start)_\(end).json")
            }
            .buttonStyle(.bordered)
        }
    }

    private func addActivity() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        store.send(.addActivity(name: name, at: Date()))
        newName = ""
    }

    private func commitRename(_ id: UUID) {
        store.send(.renameActivity(id: id, name: draft))
        editingID = nil
    }

    private func writeExport(range: DateInterval, name: String) {
        let document = makeExport(
            state: store.state,
            range: range,
            now: Date(),
            timeZone: Calendar.current.timeZone
        )
        guard let data = try? exportData(document) else { return }
        SavePanel.write(data: data, suggestedName: name)
    }

    private func sliceLabel(_ slice: TimedSlice) -> String {
        if slice.isOpen {
            return "\(formatClock(slice.startedAt)) – ahora"
        }
        return "\(formatClock(slice.startedAt)) – \(formatClock(slice.endedAt))"
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 316
        let rows = rows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        var index = 0
        for row in rows {
            var x = bounds.minX
            for size in row.sizes {
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
                index += 1
            }
            y += row.height + spacing
        }
    }

    private func rows(maxWidth: CGFloat, subviews: Subviews) -> [(sizes: [CGSize], height: CGFloat)] {
        var rows: [(sizes: [CGSize], height: CGFloat)] = []
        var sizes: [CGSize] = []
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = sizes.isEmpty ? size.width : rowWidth + spacing + size.width
            if nextWidth > maxWidth, !sizes.isEmpty {
                rows.append((sizes, rowHeight))
                sizes = [size]
                rowWidth = size.width
                rowHeight = size.height
            } else {
                sizes.append(size)
                rowWidth = nextWidth
                rowHeight = max(rowHeight, size.height)
            }
        }
        if !sizes.isEmpty {
            rows.append((sizes, rowHeight))
        }
        return rows
    }
}

private func formatDuration(_ seconds: Int) -> String {
    let value = max(0, seconds)
    let hours = value / 3600
    let minutes = (value % 3600) / 60
    let secs = value % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }
    return String(format: "%d:%02d", minutes, secs)
}

private func formatClock(_ date: Date) -> String {
    date.formatted(Date.FormatStyle(date: .omitted, time: .shortened))
}
