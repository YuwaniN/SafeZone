import MapKit
import PhotosUI
import SwiftUI
import UIKit

struct CreateReportView: View {
    let container: AppContainer
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: CreateReportViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case details
        case address
    }

    init(container: AppContainer, appState: AppState) {
        self.container = container
        _appState = ObservedObject(wrappedValue: appState)
        _viewModel = StateObject(wrappedValue: CreateReportViewModel(container: container, appState: appState))
    }

    var body: some View {
        NavigationStack {
            ScreenBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        categorySection
                        detailsSection
                        locationSection
                        photoSection

                        if let errorMessage = viewModel.errorMessage {
                            InlineMessage(style: .error, message: errorMessage)
                        }

                        submitButton

                        Text("Reports are shared with the SafeZone community. Only post hazards you have personally observed.")
                            .font(.szScaled(11))
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.prepare()
            }
            .onChange(of: photoItem) { _, newItem in
                Task { await loadPhoto(newItem) }
            }
            .onChange(of: viewModel.details) { _, newValue in
                if newValue.count > 500 {
                    viewModel.details = String(newValue.prefix(500))
                }
            }
            .interactiveDismissDisabled(viewModel.isSubmitting)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "What's happening?", subtitle: "Choose the hazard type")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                ForEach(IncidentCategory.allCases) { category in
                    let isSelected = viewModel.category == category
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.category = category
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.szScaled(18, weight: .semibold))
                            Text(category.title)
                                .font(.szScaled(11, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(isSelected ? .white : category.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(isSelected ? category.color : category.color.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(category.color.opacity(isSelected ? 0 : 0.18), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .cardStyle()
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Report details", subtitle: "Give neighbours enough context")

            TextField("Short title, e.g. Galle Road flooded near Kollupitiya", text: $viewModel.title)
                .font(.szScaled(15, weight: .medium))
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .details
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Theme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.8)
                )

            ZStack(alignment: .topLeading) {
                if viewModel.details.isEmpty {
                    Text("What did you see? Include water depth, blocked lanes, and direction of travel.")
                        .font(.szScaled(14))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.details)
                    .font(.szScaled(14))
                    .focused($focusedField, equals: .details)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(8)
            }
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.8)
            )

            HStack {
                Text("At least 10 characters")
                    .font(.szScaled(10))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                Text("\(viewModel.details.count) / 500")
                    .font(.szScaled(10, weight: .medium))
                    .foregroundStyle(viewModel.details.count >= 500 ? Theme.warning : Theme.textTertiary)
            }
        }
        .cardStyle()
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Location")
                        .font(.szHeadline(19))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Attach the report to a place")
                        .font(.szScaled(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button {
                    focusedField = nil
                    Task { await viewModel.useCurrentLocation() }
                } label: {
                    HStack(spacing: 5) {
                        if viewModel.isResolvingLocation {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(viewModel.isResolvingLocation ? "Locating…" : "Use Current")
                    }
                    .font(.szScaled(12, weight: .semibold))
                    .foregroundStyle(Theme.brandTeal)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.brandTeal.opacity(0.1)))
                }
                .disabled(viewModel.isResolvingLocation)
            }

            if let coordinate = viewModel.coordinate {
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                        )
                    )
                ) {
                    Marker("Report location", coordinate: coordinate)
                        .tint(viewModel.category.color)
                }
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .id("\(coordinate.latitude),\(coordinate.longitude)")
                .accessibilityLabel("Map showing the report location")
            } else {
                HStack(spacing: 9) {
                    if viewModel.isResolvingLocation {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "mappin.slash")
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Text(viewModel.isResolvingLocation ? "Finding your location…" : "No location selected yet.")
                        .font(.szScaled(12))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Theme.surfaceElevated)
                )
            }

            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.szScaled(13, weight: .semibold))
                    .foregroundStyle(Theme.brandTeal)
                TextField("Street, area, or landmark", text: $viewModel.address)
                    .font(.szScaled(13))
                    .focused($focusedField, equals: .address)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )

            if viewModel.usingFallbackLocation {
                InlineMessage(
                    style: .info,
                    message: "Using your saved Home location. Tap Use Current to attach the exact spot."
                )
            }

            if viewModel.isLocationDenied {
                InlineMessage(
                    style: .warning,
                    message: "Location access is off. You can still submit using your saved Home location.",
                    actionTitle: "Settings"
                ) {
                    viewModel.openSettings()
                }
            }
        }
        .cardStyle()
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Photo", subtitle: "Optional, but helps others verify the report")

            if let photoData = viewModel.photoData, let image = UIImage(data: photoData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        viewModel.photoData = nil
                        photoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.szScaled(22))
                            .foregroundStyle(.white, .black.opacity(0.45))
                    }
                    .padding(8)
                    .accessibilityLabel("Remove photo")
                }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Add a Photo")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .cardStyle()
    }

    private var submitButton: some View {
        VStack(spacing: 8) {
            Button {
                focusedField = nil
                Task {
                    if await viewModel.submit() {
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(viewModel.isSubmitting ? "Submitting…" : "Submit Report")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canSubmit)
            .opacity(viewModel.canSubmit ? 1 : 0.55)

            Text("Your name and report location will be visible to other SafeZone users.")
                .font(.szScaled(10))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let compressed = ImageProcessor.compressedJPEG(from: data) else {
                viewModel.errorMessage = "The selected photo could not be processed."
                return
            }
            viewModel.photoData = compressed
            viewModel.errorMessage = nil
        } catch {
            viewModel.errorMessage = "The selected photo could not be loaded."
        }
    }
}
