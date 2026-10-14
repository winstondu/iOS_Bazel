import NukeUI
import SwiftUI
import SwiftMacros

@MainActor
struct ContentView: View {
    private static let buildVariant = #buildConfig(
        debug: "Debug build",
        release: "Release build"
    )
    private static let obfuscatedPreview = #Obfuscate("Macro expansion preview")
    private let landscapeURL = URL(string: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=900&q=80")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    welcomeHeader
                    landscapeCard
                    messageCard
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Hello World")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hello, world.")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Text("A small SwiftUI sample with a view to the outdoors.")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var landscapeCard: some View {
        Rectangle()
            .fill(.clear)
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .overlay {
                LazyImage(url: landscapeURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .overlay(alignment: .bottomLeading) {
                            Text("Take the scenic route")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                                .padding(16)
                        }
                } else if state.isLoading {
                    placeholder(
                        systemImage: "mountain.2",
                        title: "Finding the view…",
                        message: "Loading a little inspiration"
                    )
                } else {
                    placeholder(
                        systemImage: "wifi.exclamationmark",
                        title: "The view is taking a break",
                        message: "Check your connection and try again"
                    )
                }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }

    private var messageCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.indigo)
                .frame(width: 44, height: 44)
                .background(.indigo.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Built for a bright start · \(Self.buildVariant)")
                    .font(.headline)
                Text(Self.obfuscatedPreview)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("Explore the widget for a hello from your Home Screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func placeholder(systemImage: String, title: String, message: String) -> some View {
        ZStack {
            LinearGradient(
                colors: [.indigo.opacity(0.8), .cyan.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 10) {
                if systemImage == "mountain.2" {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.15)
                } else {
                    Image(systemName: systemImage)
                        .font(.title)
                        .foregroundStyle(.white)
                }

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .multilineTextAlignment(.center)
            .padding()
        }
    }
}
