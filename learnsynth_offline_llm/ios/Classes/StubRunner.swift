import Foundation

class StubRunner: Runner {
    private var ready = false
    private var task: Task<Void, Never>? = nil

    func load(modelPath: String) async {
        ready = true
    }

    func isReady() -> Bool { return ready }

    func generateStream(prompt: String, maxTokens: Int, temperature: Double, onToken: @escaping (String) -> Void) {
        task?.cancel()
        task = Task {
            let text = "iOS stub: \(prompt)"
            for ch in text {
                onToken(String(ch))
                try? await Task.sleep(nanoseconds: 40_000_000)
            }
        }
    }

    func cancel() {
        task?.cancel()
    }
}
