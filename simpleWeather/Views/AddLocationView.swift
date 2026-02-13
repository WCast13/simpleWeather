//
//  AddLocationView.swift
//  simpleWeather
//
//  Created by William Castellano on 2/3/25.
//

import SwiftUI
import SwiftData

struct AddLocationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: LocationViewModel?
    @State private var locationInput = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Search Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search for a Location")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TextField("City name or ZIP code", text: $locationInput)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isTextFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await addLocation()
                            }
                        }

                    Text("Examples: San Francisco, CA or 94102")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)

                // Status Section
                if let viewModel = viewModel, viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Searching...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else if let viewModel = viewModel, let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(errorMessage)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Add Button
                Button {
                    Task {
                        await addLocation()
                    }
                } label: {
                    Label("Add Location", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (viewModel?.isLoading ?? false))
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    let repository = LocationRepository(modelContext: modelContext)
                    viewModel = LocationViewModel(repository: repository)
                }
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Private Methods

    private func addLocation() async {
        guard let viewModel = viewModel else { return }

        let trimmedInput = locationInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedInput.isEmpty else {
            return
        }

        let success = await viewModel.addLocation(query: trimmedInput)

        if success {
            // Small delay for better UX feedback
            do {
                try await Task.sleep(for: .milliseconds(200))
            } catch {
                // Sleep interrupted, just continue
            }
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    AddLocationView()
        .modelContainer(for: WeatherLocation.self, inMemory: true)
}
