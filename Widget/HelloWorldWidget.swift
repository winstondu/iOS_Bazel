import SwiftUI
import WidgetKit

struct HelloWorldEntry: TimelineEntry {
    let date: Date
}

struct HelloWorldProvider: TimelineProvider {
    func placeholder(in context: Context) -> HelloWorldEntry {
        HelloWorldEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (HelloWorldEntry) -> Void) {
        completion(HelloWorldEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HelloWorldEntry>) -> Void) {
        let entry = HelloWorldEntry(date: .now)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct HelloWorldWidgetEntryView: View {
    let entry: HelloWorldEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "hand.wave.fill")
                .font(.title2)
                .foregroundStyle(.yellow)

            Spacer(minLength: 0)

            Text("Hello, world!")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text("Have a wonderful day.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [.indigo, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

@main
struct HelloWorldWidget: Widget {
    let kind = "HelloWorldWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HelloWorldProvider()) { entry in
            HelloWorldWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hello World")
        .description("A friendly hello for your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
