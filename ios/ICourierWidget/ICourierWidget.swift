import SwiftUI
import WidgetKit

private let widgetKind = "ICourierWidget"
private let storageKey = "widget_state"

private struct WidgetBrand: Codable {
  let slug: String
  let primary: String
  let onPrimary: String
  let surface: String
  let text: String
  let muted: String
  let logoAsset: String
}

private struct WidgetSession: Codable {
  let signedIn: Bool
  let accountCode: String
  let accountName: String
}

private struct WidgetCounts: Codable {
  let disponible: Int
  let retenido: Int
  let enRuta: Int
  let enProceso: Int
  let total: Int
}

private struct WidgetFeatured: Codable {
  let id: String
  let contenido: String
  let macro: String
  let estadoLabel: String
  let stageIndex: Int
  let stageCount: Int
  let retenido: Bool
  let montoUsd: Double
  let sucursal: String?
  let ultimoEvento: String?
}

private struct WidgetSnapshot: Codable {
  let schema: Int
  let brand: WidgetBrand
  let session: WidgetSession
  let counts: WidgetCounts
  let featured: WidgetFeatured?
  let deepLink: String
  let generatedAt: String
  let staleAfter: String

  var isStale: Bool {
    guard let date = ISO8601DateFormatter().date(from: staleAfter) else {
      return true
    }
    return date <= Date()
  }
}

private struct WidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot?
}

private struct WidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> WidgetEntry {
    WidgetEntry(date: Date(), snapshot: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
    completion(WidgetEntry(date: Date(), snapshot: loadSnapshot()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
    let now = Date()
    let entry = WidgetEntry(date: now, snapshot: loadSnapshot())
    completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60 * 60))))
  }

  private func loadSnapshot() -> WidgetSnapshot? {
    guard let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
          let payload = UserDefaults(suiteName: appGroup)?.string(forKey: storageKey),
          let data = payload.data(using: .utf8) else {
      return nil
    }
    return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
  }
}

private struct ICourierWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: WidgetEntry

  var body: some View {
    Group {
      if let snapshot = entry.snapshot, snapshot.session.signedIn {
        signedIn(snapshot)
      } else {
        signedOut
      }
    }
    .widgetURL(entry.snapshot.flatMap { URL(string: $0.deepLink) })
    .icourierWidgetBackground(Color(hex: entry.snapshot?.brand.surface ?? "#FFFFFF"))
  }

  @ViewBuilder
  private func signedIn(_ snapshot: WidgetSnapshot) -> some View {
    if snapshot.isStale {
      VStack(alignment: .leading, spacing: 6) {
        Image(systemName: "arrow.clockwise.circle.fill")
          .foregroundStyle(Color(hex: snapshot.brand.primary))
        Text("Abre la app para actualizar")
          .font(.system(.caption, design: .rounded, weight: .semibold))
          .foregroundStyle(Color(hex: snapshot.brand.text))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    } else if family == .systemSmall {
      small(snapshot)
    } else {
      package(snapshot)
    }
  }

  private func small(_ snapshot: WidgetSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Image(systemName: "shippingbox.fill")
        .foregroundStyle(Color(hex: snapshot.brand.primary))
      Spacer()
      Text("\(snapshot.counts.disponible)")
        .font(.system(size: 38, weight: .bold, design: .rounded))
        .foregroundStyle(Color(hex: snapshot.brand.text))
        .minimumScaleFactor(0.65)
      Text("Disponibles")
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .foregroundStyle(Color(hex: snapshot.brand.muted))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func package(_ snapshot: WidgetSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 7) {
      if let featured = snapshot.featured {
        HStack {
          Text(featured.estadoLabel)
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundStyle(Color(hex: snapshot.brand.primary))
          Spacer()
          if featured.retenido {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
          }
        }
        Text(featured.contenido.isEmpty ? featured.id : featured.contenido)
          .font(.system(.headline, design: .rounded, weight: .semibold))
          .foregroundStyle(Color(hex: snapshot.brand.text))
          .lineLimit(1)
        HStack(spacing: 4) {
          ForEach(0..<max(featured.stageCount, 1), id: \.self) { index in
            Capsule()
              .fill(index <= featured.stageIndex
                ? Color(hex: snapshot.brand.primary)
                : Color(hex: snapshot.brand.muted).opacity(0.25))
              .frame(height: 5)
          }
        }
        Text(featured.sucursal ?? snapshot.session.accountCode)
          .font(.system(.caption2, design: .rounded))
          .foregroundStyle(Color(hex: snapshot.brand.muted))
          .lineLimit(1)
      } else {
        Text("No hay paquetes activos")
          .font(.system(.caption, design: .rounded, weight: .semibold))
          .foregroundStyle(Color(hex: snapshot.brand.text))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private var signedOut: some View {
    VStack(alignment: .leading, spacing: 6) {
      Image(systemName: "shippingbox")
        .font(.title2)
      Text("Inicia sesión")
        .font(.system(.caption, design: .rounded, weight: .semibold))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

private extension Color {
  init(hex: String) {
    let normalized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    let value = UInt64(normalized, radix: 16) ?? 0
    let red = Double((value >> 16) & 0xff) / 255
    let green = Double((value >> 8) & 0xff) / 255
    let blue = Double(value & 0xff) / 255
    self.init(red: red, green: green, blue: blue)
  }
}

private extension View {
  @ViewBuilder
  func icourierWidgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { color }
    } else {
      background(color)
    }
  }
}

@main
struct ICourierWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: widgetKind, provider: WidgetProvider()) { entry in
      ICourierWidgetView(entry: entry)
    }
    .configurationDisplayName("iCourier")
    .description("Estado de tus paquetes")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}
