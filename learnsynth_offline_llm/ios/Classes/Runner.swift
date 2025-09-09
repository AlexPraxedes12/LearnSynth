import Foundation

protocol Runner {
    func load(modelPath: String) async
    func isReady() -> Bool
    func generateStream(prompt: String, maxTokens: Int, temperature: Double, onToken: @escaping (String) -> Void)
    func cancel()
}
