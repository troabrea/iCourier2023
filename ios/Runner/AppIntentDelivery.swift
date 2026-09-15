import Foundation

/// Keeps Siri requests until the UI isolate is ready and acknowledges each one.
/// Only one request is presented at a time, including during a cold launch.
@MainActor
final class AppIntentDelivery {
  static let shared = AppIntentDelivery(defaults: .standard)
  typealias Sender = (String, @escaping (Bool) -> Void) -> Void

  private let defaults: UserDefaults
  private let storageKey = "icourier.pendingPickupIntents"
  private var pending: [String]
  private var sender: Sender?
  private var ready = false
  private var inFlight: String?
  private var generation = 0

  init(defaults: UserDefaults) {
    self.defaults = defaults
    pending = defaults.stringArray(forKey: storageKey) ?? []
  }

  func enqueue() {
    pending.append(UUID().uuidString)
    defaults.set(pending, forKey: storageKey)
    drain()
  }

  func bind(sender: @escaping Sender) {
    generation += 1
    self.sender = sender
    ready = false
    inFlight = nil
  }

  func markReady() {
    ready = true
    drain()
  }

  private func drain() {
    guard ready, inFlight == nil, let id = pending.first, let sender else { return }
    inFlight = id
    let sentGeneration = generation
    sender(id) { [weak self] accepted in
      guard let self, self.generation == sentGeneration, self.inFlight == id else { return }
      self.inFlight = nil
      guard accepted else {
        // Wait for the next readiness handshake instead of retrying in a loop.
        self.ready = false
        return
      }
      self.pending.removeFirst()
      self.defaults.set(self.pending, forKey: self.storageKey)
      self.drain()
    }
  }
}
