//
//  WidgetLibrarySheet.swift  (Phase 4f — + Add Widget library)
//  simpleWeather
//
//  Bottom-sheet picker over `WidgetCatalog.all`, grouped by `group`.
//  Tapping a non-deferred row hands the WidgetKind to `onAdd` and dismisses;
//  deferred kinds (currently only `tide`, which needs NOAA CO-OPS in v3)
//  render disabled with a "Coming soon" badge so users see what's planned.
//

import SwiftUI

struct WidgetLibrarySheet: View {
    /// Called with the chosen kind. The sheet dismisses itself afterward.
    let onAdd: (WidgetKind) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(WidgetCatalog.byGroup, id: \.group) { section in
                    Section(section.group) {
                        ForEach(section.entries) { entry in
                            Button {
                                guard !entry.isDeferred else { return }
                                onAdd(entry.kind)
                                dismiss()
                            } label: {
                                LibraryRow(entry: entry)
                            }
                            .disabled(entry.isDeferred)
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Row -----------------------------------------------------------------

private struct LibraryRow: View {
    let entry: WidgetCatalogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.symbolName)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(entry.isDeferred ? Color.secondary : Color.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if entry.isDeferred {
                        Text("Coming soon")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .foregroundStyle(.secondary)
                            .background(.secondary.opacity(0.15), in: .capsule)
                    }
                }

                if !entry.summary.isEmpty {
                    Text(entry.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Allowed sizes — useful info while picking; also hints to
                // the user that some widgets resize and others don't.
                Text(entry.allowedSizes.map(\.rawValue).joined(separator: " · "))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .opacity(entry.isDeferred ? 0.6 : 1.0)
    }
}

#Preview {
    WidgetLibrarySheet(onAdd: { kind in
        print("would add \(kind.rawValue)")
    })
}
