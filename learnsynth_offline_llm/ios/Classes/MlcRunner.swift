import Foundation

class MlcRunner: Runner {
    func load(modelPath: String) async {
        // TODO: implement real runner
    }

    func isReady() -> Bool { return false }

    func generateStream(prompt: String, maxTokens: Int, temperature: Double, onToken: @escaping (String) -> Void) {
        // TODO
    }

    func cancel() {
        // TODO
    }
}
