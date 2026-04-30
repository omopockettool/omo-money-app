import SwiftUI
import UIKit

struct AboutOMOView: View {
    private let appInfo = AppInfo.current
    private let donationsURL = URL(string: "https://buymeacoffee.com/omopockettool")!
    @State private var copiedFieldTitle: String?

    var body: some View {
        List {
            heroSection

            Section(LocalizationKey.About.application.localized) {
                infoRow(
                    icon: "app.badge.fill",
                    color: .red,
                    title: LocalizationKey.About.currentVersion.localized,
                    value: appInfo.fullVersionLabel
                )

                NavigationLink {
                    AppReleaseNotesView(installedVersion: appInfo.version)
                } label: {
                    infoRow(
                        icon: "clock.arrow.circlepath",
                        color: .orange,
                        title: LocalizationKey.About.whatsNew.localized,
                        value: LocalizationKey.About.viewHistory.localized
                    )
                }
            }

            Section("OMONI") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizationKey.About.descriptionLabel.localized)
                        .font(.headline)
                    Text(LocalizationKey.About.tagline.localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)

                copyableLinkRow(
                    icon: "globe",
                    color: .indigo,
                    title: LocalizationKey.About.officialWeb.localized,
                    value: "omopockettool.com",
                    destination: URL(string: "https://omopockettool.com/")!
                )

                copyableLinkRow(
                    icon: "envelope.fill",
                    color: .green,
                    title: LocalizationKey.About.contact.localized,
                    value: "omopockettool@gmail.com",
                    destination: URL(string: "mailto:omopockettool@gmail.com")!
                )
            }

            Section(LocalizationKey.About.support.localized) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizationKey.About.supportQuestion.localized)
                        .font(.headline)
                    Text(LocalizationKey.About.supportDescription.localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)

                Link(destination: donationsURL) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.brown)
                                .frame(width: 36, height: 36)

                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizationKey.About.donate.localized)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text("buymeacoffee.com/omopockettool")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
            }

            Section(LocalizationKey.About.developedBy.localized) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizationKey.About.team.localized)
                        .font(.headline)
                    Text(LocalizationKey.About.motto.localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizationKey.About.title.localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroSection: some View {
        Section {
            VStack(spacing: 14) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 68))
                    .foregroundStyle(.red)

                VStack(spacing: 4) {
                    Text("OMONI")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(LocalizationKey.About.heroTagline.localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }

    private func infoRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
        }
    }

    private func copyableLinkRow(
        icon: String,
        color: Color,
        title: String,
        value: String,
        destination: URL
    ) -> some View {
        HStack(spacing: 12) {
            Link(destination: destination) {
                infoRow(icon: icon, color: color, title: title, value: value)
            }
            .buttonStyle(.plain)

            Button {
                UIPasteboard.general.string = value
                copiedFieldTitle = title
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    if copiedFieldTitle == title {
                        copiedFieldTitle = nil
                    }
                }
            } label: {
                Image(systemName: copiedFieldTitle == title ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(copiedFieldTitle == title ? .green : .secondary)
                    .frame(width: 30, height: 30)
                    .background(
                        (copiedFieldTitle == title ? Color.green.opacity(0.14) : Color(.tertiarySystemGroupedBackground))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copiar \(title)")
        }
    }
}

struct AppReleaseNotesView: View {
    let installedVersion: String
    private let entries = AppReleaseNotesCatalog.entries

    var body: some View {
        List {
            Section(LocalizationKey.About.changelog.localized) {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(entry.version)
                                .font(.headline)

                            if entry.version == installedVersion {
                                Text(LocalizationKey.About.installed.localized)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            Text(entry.date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(entry.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        ForEach(entry.highlights, id: \.self) { highlight in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.secondary.opacity(0.6))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 6)
                                Text(highlight)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizationKey.About.news.localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AppInfo {
    let version: String
    let build: String

    var fullVersionLabel: String {
        "v\(version)"
    }

    static var current: AppInfo {
        let version = "1.8.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return AppInfo(version: version, build: build)
    }
}

private struct AppReleaseNoteEntry: Identifiable {
    let version: String
    let date: String
    let title: String
    let highlights: [String]

    var id: String { version }
}

private enum AppReleaseNotesCatalog {
    static let entries: [AppReleaseNoteEntry] = [
        AppReleaseNoteEntry(
            version: "1.5.4",
            date: "2026-04-29",
            title: "Visual polish and smoother detail flow",
            highlights: [
                "Dashboard and item-detail rows were refined to feel cleaner and easier to scan.",
                "Pending items now stay visible at the top of the item-list detail, while completed ones move to the end.",
                "Row separators were polished to give list content a calmer reading rhythm."
            ]
        ),
        AppReleaseNoteEntry(
            version: "1.5.3",
            date: "2026-04-29",
            title: "More stable dashboard refresh",
            highlights: [
                "Pull-to-refresh no longer shifts dashboard rows up and down during the refresh gesture."
            ]
        ),
        AppReleaseNoteEntry(
            version: "1.5.0",
            date: "2026-04-29",
            title: "Clearer monthly overview",
            highlights: [
                "Monthly day groups can now collapse to make long periods easier to browse.",
                "Collapsed state is remembered while moving between Today and This Month."
            ]
        ),
        AppReleaseNoteEntry(
            version: "1.4.0",
            date: "2026-04-29",
            title: "Group settings improvements",
            highlights: [
                "Group details, categories, and payment methods were reorganized into a cleaner settings flow."
            ]
        ),
        AppReleaseNoteEntry(
            version: "1.0",
            date: "2025-11-08",
            title: "Initial release",
            highlights: [
                "First public version of OMO Money focused on personal expense tracking and group organization."
            ]
        )
    ]
}
