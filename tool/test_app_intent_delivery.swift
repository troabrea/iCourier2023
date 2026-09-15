import Foundation

@main
struct AppIntentDeliveryTests {
  @MainActor
  static func main() {
    let suite = "icourier.intent-test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let queue = AppIntentDelivery(defaults: defaults)
    var sent: [String] = []
    var replies: [(Bool) -> Void] = []
    queue.enqueue()
    queue.enqueue()
    queue.bind { id, reply in sent.append(id); replies.append(reply) }
    assert(sent.isEmpty, "Cold launch must wait for Dart")
    queue.markReady()
    assert(sent.count == 1)
    queue.markReady()
    assert(sent.count == 1, "Repeated readiness must not duplicate in-flight work")
    replies[0](true)
    assert(sent.count == 2 && sent[0] != sent[1], "Drain in order after acknowledgment")
    replies[0](true)
    assert(sent.count == 2, "Duplicate acknowledgments cannot consume another request")
    replies[1](false)
    assert(sent.count == 2, "Failure must not spin")
    queue.markReady()
    assert(sent.count == 3 && sent[1] == sent[2], "Retry retains identity")
    let oldReply = replies[2]
    queue.bind { id, reply in sent.append(id); replies.append(reply) }
    oldReply(true)
    queue.markReady()
    assert(sent.count == 4 && sent[3] == sent[2], "Ignore callbacks from replaced engines")
    replies[3](true)
    let restored = AppIntentDelivery(defaults: defaults)
    var restoredCount = 0
    restored.bind { _, _ in restoredCount += 1 }
    restored.markReady()
    assert(restoredCount == 0, "Acknowledged requests must not survive restart")
    queue.enqueue()
    let restarted = AppIntentDelivery(defaults: defaults)
    restarted.bind { id, reply in
      assert(id == sent.last, "Unacknowledged requests retain identity across restart")
      restoredCount += 1
      reply(true)
    }
    restarted.markReady()
    assert(restoredCount == 1)
    print("AppIntentDelivery: cold start, FIFO, retry, rebind and persistence passed")
  }
}
