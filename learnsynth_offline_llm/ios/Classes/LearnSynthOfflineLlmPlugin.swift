import Flutter
import UIKit
import CommonCrypto

public class LearnSynthOfflineLlmPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var downloadSink: FlutterEventSink? { downloadHandler.sink }
  private var modelManager: ModelManager?
  private var modelId: String?
  private var manifest: Manifest?
  private var runner: Runner = StubRunner()

  private let downloadHandler = DownloadStreamHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "learnsynth_offline_llm/methods", binaryMessenger: registrar.messenger())
    let instance = LearnSynthOfflineLlmPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let events = FlutterEventChannel(name: "learnsynth_offline_llm/events", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
    let downloads = FlutterEventChannel(name: "learnsynth_offline_llm/downloads", binaryMessenger: registrar.messenger())
    downloads.setStreamHandler(instance.downloadHandler)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "init":
      if let args = call.arguments as? [String: Any], let id = args["modelId"] as? String {
        modelId = id
        modelManager = ModelManager(modelId: id)
        manifest = nil
        runner = StubRunner()
        result(true)
      } else {
        result(FlutterError(code: "ARG", message: "modelId required", details: nil))
      }
    case "getModelId":
      result(modelId ?? "")
    case "getModelDir":
      result(modelManager?.modelDir().path ?? "")
    case "isReady":
      do {
        let mf = try loadManifest()
        result(modelManager?.isReady(mf) == true)
      } catch {
        result(FlutterError(code: "READY", message: error.localizedDescription, details: nil))
      }
    case "downloadModelIfNeeded":
      do {
        let mf = try loadManifest()
        Task {
          do {
            try self.modelManager?.ensureModel(manifest: mf) { map in
              self.downloadSink?(map)
            }
            DispatchQueue.main.async { result(true) }
          } catch {
            DispatchQueue.main.async { result(FlutterError(code: "DL", message: error.localizedDescription, details: nil)) }
          }
        }
      } catch {
        result(FlutterError(code: "MANIFEST", message: error.localizedDescription, details: nil))
      }
    case "stream":
      let args = call.arguments as? [String: Any]
      let prompt = args?["prompt"] as? String ?? ""
      let maxTokens = args?["maxTokens"] as? Int ?? 256
      let temperature = args?["temperature"] as? Double ?? 0.2
      let mf = try? loadManifest()
      Task {
        if !runner.isReady() {
          if let file = mf?.files.first?.name, let dir = modelManager?.modelDir() {
            let path = dir.appendingPathComponent(file).path
            await runner.load(modelPath: path)
          }
        }
        runner.generateStream(prompt: prompt, maxTokens: maxTokens, temperature: temperature) { token in
          self.eventSink?(token)
        }
      }
      result(nil)
    case "cancel":
      runner.cancel()
      result(nil)
    case "deleteModel":
      guard let mid = self.modelId else { result(false); return }
      let appSup = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
      let dir = appSup.appendingPathComponent("models/\(mid)", isDirectory: true)
      do {
        if FileManager.default.fileExists(atPath: dir.path) {
          try FileManager.default.removeItem(at: dir)
        }
        result(true)
      } catch {
        result(FlutterError(code: "DEL", message: error.localizedDescription, details: nil))
      }
    case "verifyModel":
      guard let manifest = self.manifest ?? (try? loadManifest()),
            let dir = self.modelManager?.modelDir() else { result(false); return }
      guard let entry = manifest.files.first else { result(false); return }
      let fileUrl = dir.appendingPathComponent(entry.name, isDirectory: false)
      do {
        let expected = entry.sha256.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let actual = try sha256File(url: fileUrl)
        result(expected == actual)
      } catch {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    runner.cancel()
    eventSink = nil
    return nil
  }

  private func loadManifest() throws -> Manifest {
    if let m = manifest { return m }
    guard let id = modelId else {
      throw NSError(domain: "mm", code: 0)
    }
    let key = FlutterDartProject.lookupKey(
      forAsset: "assets/models/\(id)/manifest.json",
      fromPackage: "learnsynth_offline_llm"
    )
    guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
      throw NSError(domain: "mm", code: 404, userInfo: [NSLocalizedDescriptionKey: "manifest not found"])
    }
    let json = try String(contentsOfFile: path, encoding: .utf8)
    let data = json.data(using: .utf8)!
    let mf = try JSONDecoder().decode(Manifest.self, from: data)
    manifest = mf
    return mf
  }

  private class DownloadStreamHandler: NSObject, FlutterStreamHandler {
    var sink: FlutterEventSink?
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      sink = events
      return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
      sink = nil
      return nil
    }
  }
}

func sha256File(url: URL) throws -> String {
  let handle = try FileHandle(forReadingFrom: url)
  defer { try? handle.close() }

  var context = CC_SHA256_CTX()
  CC_SHA256_Init(&context)

  while autoreleasepool(invoking: {
    let data = handle.readData(ofLength: 1024 * 1024)
    if data.count > 0 {
      data.withUnsafeBytes { _ = CC_SHA256_Update(&context, $0.baseAddress, CC_LONG(data.count)) }
      return true
    } else { return false }
  }) {}

  var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
  CC_SHA256_Final(&digest, &context)
  return digest.map { String(format: "%02x", $0) }.joined()
}
