import Security
import SwiftUI
import UIKit
import WidgetKit
import os

private let widgetKind = "ICourierWidget"
private let storageKey = "widget_state"
private let companyIdKey = "widget_company_id"
private let endpointKey = "widget_endpoint"
private let refreshRequestedAtKey = "widget_refresh_requested_at"

private enum WidgetDateParser {
  private static let fractionalFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let standardFormatter = ISO8601DateFormatter()

  static func parse(_ value: String) -> Date? {
    fractionalFormatter.date(from: value) ?? standardFormatter.date(from: value)
  }

  static func format(_ date: Date) -> String {
    fractionalFormatter.string(from: date)
  }
}

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
    guard let date = WidgetDateParser.parse(staleAfter) else {
      return true
    }
    return date <= Date()
  }

  var generatedAtDate: Date? {
    WidgetDateParser.parse(generatedAt)
  }
}

private enum RemotePackageStage {
  case origin
  case route
  case destination
  case available
  case delivered
}

private struct RemotePackage: Decodable {
  let estatus: String?
  let retenido: Bool?
  let disponible: Bool?
  let progreso: Int?
}

private enum WidgetRemoteRefresh {
  static let interval: TimeInterval = 30 * 60
  private static let staleInterval: TimeInterval = 4 * 60 * 60
  private static let keychainService = "com.barolit.icourier.widget-session"
  private static let keychainAccount = "current"
  private static let logger = Logger(
    subsystem: "com.barolit.icourier.widget",
    category: "remote-refresh"
  )

  private static let deliveredTerms: Set<String> = [
    "ENTREGADO AL CLIENTE", "ENTREGADO", "DELIVERED", "BILLED COUNTER",
    "FACTURADO COUNTER",
  ]
  private static let routeTerms = [
    "EMBARCADO", "SHIPMENT SENT", "IN TRANSIT", "EN RUTA",
  ]
  private static let destinationTerms = [
    "TRANSFERIDO", "EMPACADO", "ADUANA", "TRANSITO", "DISTRIBUCION",
    "RECIBIDO AILA", "ALMACEN", "WAREHOUSE", "CUSTOM",
    "DISTRIBUTION CENTER", "PACKED", "OUTGOING TRANSFER", "DESTINO",
  ]
  private static let originTerms = [
    "RECIBIDO PARA PROCESAR", "LISTO PARA EMBARCACION",
    "RECIBIDO EN ORIGEN", "RECIBIDO MIAMI", "ORIGIN", "RECEIVED",
  ]

  static func refreshIfNeeded(
    snapshot: WidgetSnapshot?,
    appGroup: String,
    now: Date
  ) async -> WidgetSnapshot? {
    guard let snapshot, snapshot.session.signedIn else {
      return snapshot
    }
    guard let defaults = UserDefaults(suiteName: appGroup) else {
      logger.error("The widget App Group is unavailable.")
      return snapshot
    }
    guard shouldRefresh(snapshot, defaults: defaults, now: now) else {
      return snapshot
    }
    guard let companyId = defaults.string(forKey: companyIdKey),
          !companyId.isEmpty,
          let endpoint = defaults.string(forKey: endpointKey),
          let sessionId = loadSessionId(),
          !sessionId.isEmpty else {
      logger.error("The shared widget session is incomplete.")
      return snapshot
    }

    do {
      let packages = try await fetchPackages(
        endpoint: endpoint,
        companyId: companyId,
        sessionId: sessionId
      )
      let refreshed = makeSnapshot(from: snapshot, packages: packages, now: now)
      let payload = try JSONEncoder().encode(refreshed)
      defaults.set(String(decoding: payload, as: UTF8.self), forKey: storageKey)
      return refreshed
    } catch {
      let nsError = error as NSError
      logger.error(
        "The remote widget refresh failed (\(nsError.domain, privacy: .public): \(nsError.code))."
      )
      return snapshot
    }
  }

  static func nextRefreshDate(snapshot: WidgetSnapshot?, now: Date) -> Date {
    guard let generatedAt = snapshot?.generatedAtDate else {
      return now.addingTimeInterval(interval)
    }
    let requested = generatedAt.addingTimeInterval(interval)
    return requested > now ? requested : now.addingTimeInterval(interval)
  }

  private static func shouldRefresh(
    _ snapshot: WidgetSnapshot,
    defaults: UserDefaults,
    now: Date
  ) -> Bool {
    guard let generatedAt = snapshot.generatedAtDate else {
      return true
    }
    let requestedAt = Date(
      timeIntervalSince1970: defaults.double(forKey: refreshRequestedAtKey)
    )
    return requestedAt > generatedAt ||
      now.timeIntervalSince(generatedAt) >= interval
  }

  private static func loadSessionId() -> String? {
    guard let accessGroup = Bundle.main.object(
      forInfoDictionaryKey: "KeychainAccessGroup"
    ) as? String else {
      return nil
    }
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainAccount,
      kSecAttrAccessGroup as String: accessGroup,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
          let data = result as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  private static func fetchPackages(
    endpoint: String,
    companyId: String,
    sessionId: String
  ) async throws -> [RemotePackage] {
    guard let url = URL(string: endpoint),
          url.scheme == "https",
          url.host == "icourierfunctions2023.azurewebsites.net" else {
      throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 15
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: [
      "empresaId": companyId,
      "sessionId": sessionId,
    ])
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 15
    let (data, response) = try await URLSession(configuration: configuration)
      .data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          200..<300 ~= httpResponse.statusCode else {
      throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode([RemotePackage].self, from: data)
  }

  private static func makeSnapshot(
    from snapshot: WidgetSnapshot,
    packages: [RemotePackage],
    now: Date
  ) -> WidgetSnapshot {
    let counts = summarize(packages)
    return WidgetSnapshot(
      schema: snapshot.schema,
      brand: snapshot.brand,
      session: snapshot.session,
      counts: counts,
      featured: snapshot.featured,
      deepLink: snapshot.deepLink,
      generatedAt: WidgetDateParser.format(now),
      staleAfter: WidgetDateParser.format(now.addingTimeInterval(staleInterval))
    )
  }

  private static func summarize(_ packages: [RemotePackage]) -> WidgetCounts {
    var available = 0
    var retained = 0
    var inRoute = 0
    var inProcess = 0
    for package in packages {
      let stage = stage(for: package)
      if stage == .available {
        available += 1
      } else if package.retenido == true {
        retained += 1
      } else if stage == .route || stage == .destination {
        inRoute += 1
      } else if stage == .origin {
        inProcess += 1
      }
    }
    return WidgetCounts(
      disponible: available,
      retenido: retained,
      enRuta: inRoute,
      enProceso: inProcess,
      total: packages.count
    )
  }

  private static func stage(for package: RemotePackage) -> RemotePackageStage {
    let status = normalize(package.estatus ?? "")
    if deliveredTerms.contains(status) {
      return .delivered
    }
    if package.disponible == true || status.contains("DISPONIBLE") {
      return .available
    }
    if destinationTerms.contains(where: status.contains) {
      return .destination
    }
    if routeTerms.contains(where: status.contains) {
      return .route
    }
    if originTerms.contains(where: status.contains) {
      return .origin
    }
    switch package.progreso ?? 0 {
    case ...1:
      return .origin
    case 2:
      return .route
    case 3:
      return .destination
    case 4:
      return .available
    default:
      return .delivered
    }
  }

  private static func normalize(_ value: String) -> String {
    let folded = value.folding(
      options: [.diacriticInsensitive, .caseInsensitive],
      locale: Locale(identifier: "es")
    ).uppercased()
    return folded
      .components(separatedBy: CharacterSet.alphanumerics.inverted)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
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
    Task {
      let now = Date()
      let appGroup = Bundle.main.object(
        forInfoDictionaryKey: "AppGroupIdentifier"
      ) as? String
      let current = loadSnapshot()
      let snapshot: WidgetSnapshot?
      if let appGroup {
        snapshot = await WidgetRemoteRefresh.refreshIfNeeded(
          snapshot: current,
          appGroup: appGroup,
          now: now
        )
      } else {
        snapshot = current
      }
      let entry = WidgetEntry(date: now, snapshot: snapshot)
      let nextRefresh = WidgetRemoteRefresh.nextRefreshDate(
        snapshot: snapshot,
        now: now
      )
      completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
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
        signedOut(entry.snapshot)
      }
    }
    .widgetURL(entry.snapshot.flatMap { URL(string: $0.deepLink) })
    .icourierWidgetBackground(Color(hex: entry.snapshot?.brand.surface ?? "#FFFFFF"))
  }

  @ViewBuilder
  private func signedIn(_ snapshot: WidgetSnapshot) -> some View {
    Group {
      if family == .systemSmall {
        small(snapshot)
      } else if family == .systemMedium {
        summary(snapshot)
      } else {
        accessorySummary(snapshot)
      }
    }
    .opacity(snapshot.isStale ? 0.55 : 1)
    .overlay(alignment: .bottomTrailing) {
      if snapshot.isStale {
        staleTimestamp(snapshot)
      }
    }
  }

  private func staleTimestamp(_ snapshot: WidgetSnapshot) -> some View {
    HStack(spacing: 3) {
      Image(systemName: "clock")
      if let date = snapshot.generatedAtDate {
        Text(date, style: .time)
      }
    }
    .font(.system(size: 9, weight: .semibold, design: .rounded))
    .foregroundStyle(Color(hex: snapshot.brand.text))
    .padding(.horizontal, 5)
    .padding(.vertical, 3)
    .background(Color(hex: snapshot.brand.surface).opacity(0.94), in: Capsule())
    .accessibilityLabel("Actualizado")
  }

  private func small(_ snapshot: WidgetSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top) {
        Image(systemName: "shippingbox.fill")
          .foregroundStyle(Color(hex: snapshot.brand.primary))
        Spacer()
        brandIcon(snapshot, size: 30)
      }
      Spacer(minLength: 0)
      HStack(alignment: .bottom, spacing: 10) {
        smallMetric(
          "Total",
          value: snapshot.counts.total,
          color: Color(hex: snapshot.brand.text)
        )
        Rectangle()
          .fill(Color(hex: snapshot.brand.muted).opacity(0.22))
          .frame(width: 1, height: 38)
        smallMetric(
          "Disponibles",
          value: snapshot.counts.disponible,
          color: Color(hex: snapshot.brand.primary)
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func smallMetric(_ title: String, value: Int, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(title)
        .font(.system(.caption2, design: .rounded, weight: .semibold))
        .foregroundStyle(color.opacity(0.72))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
      Text("\(value)")
        .font(.system(.title, design: .rounded, weight: .bold))
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.65)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }

  private func summary(_ snapshot: WidgetSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 9) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 1) {
          Text("\(snapshot.counts.total) paquetes")
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(Color(hex: snapshot.brand.text))
          Text("Resumen por estatus")
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(Color(hex: snapshot.brand.muted))
        }
        Spacer()
        brandIcon(snapshot, size: 30)
      }
      Divider()
        .overlay(Color(hex: snapshot.brand.muted).opacity(0.2))
      HStack(alignment: .top, spacing: 8) {
        statusMetric("Disponibles", value: snapshot.counts.disponible, snapshot: snapshot)
        statusMetric("En proceso", value: snapshot.counts.enProceso, snapshot: snapshot)
        statusMetric("En ruta", value: snapshot.counts.enRuta, snapshot: snapshot)
        statusMetric("Retenidos", value: snapshot.counts.retenido, snapshot: snapshot)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func statusMetric(
    _ title: String,
    value: Int,
    snapshot: WidgetSnapshot
  ) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title)
        .font(.system(.caption2, design: .rounded, weight: .medium))
        .foregroundStyle(Color(hex: snapshot.brand.muted))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
      Text("\(value)")
        .font(.system(.title3, design: .rounded, weight: .bold))
        .foregroundStyle(Color(hex: snapshot.brand.primary))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }

  private func accessorySummary(_ snapshot: WidgetSnapshot) -> some View {
    HStack(spacing: 6) {
      Image(systemName: "shippingbox.fill")
        .foregroundStyle(Color(hex: snapshot.brand.primary))
      Text("\(snapshot.counts.total) paquetes · \(snapshot.counts.disponible) disponibles")
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .foregroundStyle(Color(hex: snapshot.brand.text))
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func signedOut(_ snapshot: WidgetSnapshot?) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .top) {
        Image(systemName: "shippingbox")
          .font(.title2)
        Spacer()
        if let snapshot {
          brandIcon(snapshot, size: 30)
        }
      }
      Text("Inicia sesión")
        .font(.system(.caption, design: .rounded, weight: .semibold))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func brandIcon(_ snapshot: WidgetSnapshot, size: CGFloat) -> some View {
    if let image = loadBrandIcon(snapshot) {
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityLabel("Icono de la aplicación")
    }
  }

  private func loadBrandIcon(_ snapshot: WidgetSnapshot) -> UIImage? {
    guard let appGroup = Bundle.main.object(
      forInfoDictionaryKey: "AppGroupIdentifier"
    ) as? String,
          let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
          ) else {
      return nil
    }
    return UIImage(
      contentsOfFile: containerURL
        .appendingPathComponent(snapshot.brand.logoAsset)
        .path
    )
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
