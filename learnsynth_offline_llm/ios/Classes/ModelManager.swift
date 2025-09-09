import Foundation
import CommonCrypto

struct ManifestFile: Codable { let name: String; let size: Int; let sha256: String; let url: String?; let asset: Bool?; let demo: Bool? }
struct Manifest: Codable { let ctxLen: Int?; let tokenizer: String?; let files: [ManifestFile] }

class ModelManager {
  let modelId: String
  let rootDir: URL
  init(modelId: String) {
    self.modelId = modelId
    let appSup = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    self.rootDir = appSup.appendingPathComponent("models/\(modelId)", isDirectory: true)
    try? FileManager.default.createDirectory(at: rootDir, withIntermediateDirectories: true)
  }

  func modelDir() -> URL { rootDir }

  func isReady(_ manifest: Manifest) -> Bool {
    for f in manifest.files {
      let path = rootDir.appendingPathComponent(f.name)
      guard FileManager.default.fileExists(atPath: path.path),
            let ok = try? verifySha256(file: path, hex: f.sha256), ok
      else { return false }
    }
    return true
  }

  func ensureModel(manifest: Manifest, progress: @escaping ([String: Any]) -> Void) throws {
    for f in manifest.files {
      let dst = rootDir.appendingPathComponent(f.name)
      if f.asset == true {
        progress(["stage":"copy-asset","file":f.name,"received":0,"total":f.size,"percent":0])
        try copyAsset(named: "assets/models/\(modelId)/\(f.name)", to: dst)
      } else if (f.demo ?? false) {
        try FileManager.default.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: dst.path, contents: Data())
        progress(["stage":"demo-generate","file":f.name,"received":f.size,"total":f.size,"percent":100])
      } else {
        if !FileManager.default.fileExists(atPath: dst.path) || !(try? verifySha256(file: dst, hex: f.sha256))! {
          guard let urlStr = f.url, let url = URL(string: urlStr) else { throw NSError(domain:"mm", code:1) }
          try download(url: url, to: dst, total: f.size) { rec, tot, pct in
            progress(["stage":"downloading","file":f.name,"received":rec,"total":tot,"percent":pct])
          }
        }
      }
      progress(["stage":"verifying","file":f.name,"received":f.size,"total":f.size,"percent":100])
      if try !verifySha256(file: dst, hex: f.sha256) { throw NSError(domain:"mm", code:2, userInfo:[NSLocalizedDescriptionKey:"SHA mismatch \(f.name)"]) }
    }
    progress(["stage":"done","file":"","received":0,"total":0,"percent":100])
  }

  private func copyAsset(named: String, to dst: URL) throws {
    let bundle = Bundle.main
    guard let src = bundle.url(forResource: named, withExtension: nil) else { throw NSError(domain:"mm", code:3) }
    try FileManager.default.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
    if FileManager.default.fileExists(atPath: dst.path) { try FileManager.default.removeItem(at: dst) }
    try FileManager.default.copyItem(at: src, to: dst)
  }

  private func verifySha256(file: URL, hex: String) throws -> Bool {
    let h = try sha256(url: file)
    let expected = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let actual = h.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return expected == actual
  }

  private func sha256(url: URL) throws -> String {
    let bufSize = 32768
    var ctx = CC_SHA256_CTX(); CC_SHA256_Init(&ctx)
    let fh = try FileHandle(forReadingFrom: url)
    while autoreleasepool(invoking: {
      let data = fh.readData(ofLength: bufSize)
      if data.count > 0 {
        data.withUnsafeBytes { _ = CC_SHA256_Update(&ctx, $0.baseAddress, CC_LONG(data.count)) }
        return true
      }
      return false
    }) {}
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    CC_SHA256_Final(&digest, &ctx)
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  private func download(url: URL, to dst: URL, total: Int, onProg: (Int, Int, Int) -> Void) throws {
    let tmp = dst.appendingPathExtension("part")
    try FileManager.default.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
    let data = try Data(contentsOf: url)
    try data.write(to: tmp, options: .atomic)
    onProg(total, total, 100)
    if FileManager.default.fileExists(atPath: dst.path) { try FileManager.default.removeItem(at: dst) }
    try FileManager.default.moveItem(at: tmp, to: dst)
  }
}
