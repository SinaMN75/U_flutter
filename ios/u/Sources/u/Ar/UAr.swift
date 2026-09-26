import ARKit
import AVFoundation
import Combine
import CoreLocation
import Flutter
import Metal
import QuickLook
import RealityKit
import ReplayKit
import SwiftUI
import UIKit
import Vision

#if canImport(RoomPlan)
    import RoomPlan
#endif

// =============================================================================
// UAr — ARKit + RealityKit implementation of the `u` AR / 3D plugin.
//
// Every AR session is a platform view ("u/ar_view") hosting a RealityKit
// ARView; the same view runs camera-less as the 3D viewer. USDZ / Reality files
// load natively, glTF / GLB through the small converter below. RoomPlan, Object
// Capture, Vision OCR / barcodes, AR Quick Look and ReplayKit recording are all
// system frameworks, so nothing here adds to the app beyond the OS.
// =============================================================================

enum UArConvert {
    static func float(_ value: Any?, _ fallback: Float) -> Float {
        (value as? NSNumber)?.floatValue ?? fallback
    }

    static func floats(_ value: Any?, _ count: Int, _ fallback: Float) -> [Float] {
        let list = value as? [Any] ?? []
        return (0 ..< count).map { index in index < list.count ? ((list[index] as? NSNumber)?.floatValue ?? fallback) : fallback }
    }

    static func vector(_ value: Any?, _ fallback: Float = 0) -> SIMD3<Float> {
        let v = floats(value, 3, fallback)
        return SIMD3<Float>(v[0], v[1], v[2])
    }

    static func quaternion(_ value: Any?) -> simd_quatf {
        let v = floats(value, 4, 0)
        if v.allSatisfy({ $0 == 0 }) { return simd_quatf(ix: 0, iy: 0, iz: 0, r: 1) }
        return simd_normalize(simd_quatf(ix: v[0], iy: v[1], iz: v[2], r: v[3]))
    }

    static func matrix(pose: Any?) -> simd_float4x4 {
        let v = floats(pose, 7, 0)
        var transform = Transform()
        transform.translation = SIMD3<Float>(v[0], v[1], v[2])
        transform.rotation = v[3] == 0 && v[4] == 0 && v[5] == 0 && v[6] == 0 ? simd_quatf(ix: 0, iy: 0, iz: 0, r: 1) : simd_normalize(simd_quatf(ix: v[3], iy: v[4], iz: v[5], r: v[6]))
        return transform.matrix
    }

    static func pose(_ matrix: simd_float4x4) -> [Double] {
        let transform = Transform(matrix: matrix)
        let q = transform.rotation.vector
        return [transform.translation.x, transform.translation.y, transform.translation.z, q.x, q.y, q.z, q.w].map { Double($0) }
    }

    static func color(_ value: Any?, _ fallback: UInt32) -> UIColor {
        let c = (value as? NSNumber)?.uint32Value ?? fallback
        return UIColor(
            red: CGFloat((c >> 16) & 0xFF) / 255,
            green: CGFloat((c >> 8) & 0xFF) / 255,
            blue: CGFloat(c & 0xFF) / 255,
            alpha: CGFloat((c >> 24) & 0xFF) / 255
        )
    }

    static func translation(_ m: simd_float4x4) -> SIMD3<Float> {
        SIMD3<Float>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
    }
}

// =============================================================================
// Sources
// =============================================================================

final class UArSourceLoader {
    private let lookup: (String) -> String
    private let cacheDirectory: URL

    init(lookup: @escaping (String) -> String) {
        self.lookup = lookup
        cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("u_ar", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func hash(_ value: String) -> String {
        var h: UInt64 = 1_469_598_103_934_665_603
        for byte in value.utf8 {
            h ^= UInt64(byte)
            h = h &* 1_099_511_628_211
        }
        return String(h, radix: 16)
    }

    /// Resolves a Dart `UArSource` to a local file, downloading and caching URLs.
    func file(_ source: [String: Any]?, completion: @escaping (URL?, String?) -> Void) {
        guard let source else {
            completion(nil, "Missing source")
            return
        }
        let kind = source["kind"] as? String ?? "url"
        let ext = (source["ext"] as? String).map { String($0.filter { $0.isLetter || $0.isNumber }.prefix(8)) }.flatMap { $0.isEmpty ? nil : $0 } ?? "bin"
        switch kind {
        case "file":
            completion(URL(fileURLWithPath: source["value"] as? String ?? ""), nil)
        case "asset":
            let key = lookup(source["value"] as? String ?? "")
            if let path = Bundle.main.path(forResource: key, ofType: nil) {
                completion(URL(fileURLWithPath: path), nil)
            } else {
                completion(nil, "Asset not found")
            }
        case "bytes":
            guard let typed = source["value"] as? FlutterStandardTypedData else {
                completion(nil, "Missing bytes")
                return
            }
            let target = cacheDirectory.appendingPathComponent("bytes_\(hash("\(typed.data.count)_\(typed.data.hashValue)")).\(ext)")
            do {
                if !FileManager.default.fileExists(atPath: target.path) { try typed.data.write(to: target) }
                completion(target, nil)
            } catch {
                completion(nil, error.localizedDescription)
            }
        default:
            guard let string = source["value"] as? String, let url = URL(string: string) else {
                completion(nil, "Bad url")
                return
            }
            download(url, ext: ext, completion: completion)
        }
    }

    func download(_ url: URL, ext: String, completion: @escaping (URL?, String?) -> Void) {
        let target = cacheDirectory.appendingPathComponent("\(hash(url.absoluteString)).\(ext)")
        if FileManager.default.fileExists(atPath: target.path) {
            completion(target, nil)
            return
        }
        URLSession.shared.downloadTask(with: url) { location, response, error in
            // The temporary file is deleted as soon as this handler returns, so it
            // has to be moved here, before hopping to the main queue.
            var failure: String?
            if let error {
                failure = error.localizedDescription
            } else if let http = response as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) {
                failure = "HTTP \(http.statusCode)"
            } else if let location {
                let partial = self.cacheDirectory.appendingPathComponent("\(UUID().uuidString).part")
                do {
                    try? FileManager.default.removeItem(at: partial)
                    try FileManager.default.moveItem(at: location, to: partial)
                    try? FileManager.default.removeItem(at: target)
                    try FileManager.default.moveItem(at: partial, to: target)
                } catch {
                    failure = error.localizedDescription
                }
            } else {
                failure = "Download failed"
            }
            DispatchQueue.main.async { failure == nil ? completion(target, nil) : completion(nil, failure) }
        }.resume()
    }

    func data(_ source: [String: Any]?, completion: @escaping (Data?, URL?, String?) -> Void) {
        if let typed = source?["value"] as? FlutterStandardTypedData {
            completion(typed.data, nil, nil)
            return
        }
        file(source) { url, error in
            guard let url else {
                completion(nil, nil, error)
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let data = try? Data(contentsOf: url)
                DispatchQueue.main.async { completion(data, url, data == nil ? "Unreadable file" : nil) }
            }
        }
    }
}

// =============================================================================
// glTF 2.0 → RealityKit
// =============================================================================

@available(iOS 15.0, *)
final class UGltfAsset {
    struct Primitive {
        var positions: [SIMD3<Float>]
        var normals: [SIMD3<Float>]?
        var uvs: [SIMD2<Float>]?
        var indices: [UInt32]
        var material: Int
    }

    struct Node {
        var name: String
        var children: [Int]
        var mesh: Int
        var translation: SIMD3<Float>
        var rotation: simd_quatf
        var scale: SIMD3<Float>
        var matrix: simd_float4x4?
    }

    struct Channel {
        var node: Int
        var path: String
        var times: [Float]
        var values: [Float]
        var interpolation: String
    }

    struct Animation {
        var name: String
        var channels: [Channel]
        var duration: Float
    }

    struct MaterialInfo {
        var baseColor: SIMD4<Float> = SIMD4<Float>(1, 1, 1, 1)
        var metallic: Float = 1
        var roughness: Float = 1
        var emissive: SIMD3<Float> = .zero
        var baseTexture = -1
        var normalTexture = -1
        var emissiveTexture = -1
        var alphaMode = "OPAQUE"
        var alphaCutoff: Float = 0.5
        var unlit = false
    }

    var nodes: [Node] = []
    var roots: [Int] = []
    var meshes: [[Primitive]] = []
    var materials: [MaterialInfo] = []
    var textureImages: [Int] = []
    var images: [CGImage?] = []
    var animations: [Animation] = []

    private var json: [String: Any] = [:]
    private var buffers: [Data] = []

    init(data: Data, baseURL: URL?) throws {
        var bin: Data?
        if data.count >= 12, data.withUnsafeBytes({ $0.loadUnaligned(as: UInt32.self) }) == 0x4654_6C67 {
            var offset = 12
            while offset + 8 <= data.count {
                let length = Int(data.subdata(in: offset ..< offset + 4).withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) })
                let type = data.subdata(in: offset + 4 ..< offset + 8).withUnsafeBytes { $0.load(as: UInt32.self) }
                let start = offset + 8
                let chunk = data.subdata(in: start ..< min(start + length, data.count))
                if type == 0x4E4F_534A {
                    json = (try JSONSerialization.jsonObject(with: chunk) as? [String: Any]) ?? [:]
                } else if type == 0x004E_4942 {
                    bin = chunk
                }
                offset = start + length + ((4 - length % 4) % 4)
            }
        } else {
            json = (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        }
        for name in json["extensionsRequired"] as? [String] ?? [] where name == "KHR_draco_mesh_compression" || name == "EXT_meshopt_compression" {
            throw NSError(domain: "u.ar", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(name) is not supported; export the model without mesh compression"])
        }
        for buffer in json["buffers"] as? [[String: Any]] ?? [] {
            if let uri = buffer["uri"] as? String {
                buffers.append(try UGltfAsset.resolve(uri, baseURL: baseURL))
            } else {
                buffers.append(bin ?? Data())
            }
        }
        images = (json["images"] as? [[String: Any]] ?? []).map { image in
            var bytes: Data?
            if let view = image["bufferView"] as? Int {
                bytes = viewData(view)
            } else if let uri = image["uri"] as? String {
                bytes = try? UGltfAsset.resolve(uri, baseURL: baseURL)
            }
            guard let bytes, let source = CGImageSourceCreateWithData(bytes as CFData, nil) else { return nil }
            return CGImageSourceCreateImageAtIndex(source, 0, nil)
        }
        textureImages = (json["textures"] as? [[String: Any]] ?? []).map { $0["source"] as? Int ?? -1 }
        materials = (json["materials"] as? [[String: Any]] ?? []).map(UGltfAsset.material)
        meshes = (json["meshes"] as? [[String: Any]] ?? []).map(readMesh)
        nodes = (json["nodes"] as? [[String: Any]] ?? []).enumerated().map { index, node in
            let t = UArConvert.floats(node["translation"], 3, 0)
            let r = node["rotation"] == nil ? [0, 0, 0, 1] : UArConvert.floats(node["rotation"], 4, 0)
            let s = UArConvert.floats(node["scale"], 3, 1)
            var matrix: simd_float4x4?
            if let m = node["matrix"] as? [NSNumber], m.count == 16 {
                let f = m.map { $0.floatValue }
                matrix = simd_float4x4(
                    SIMD4<Float>(f[0], f[1], f[2], f[3]),
                    SIMD4<Float>(f[4], f[5], f[6], f[7]),
                    SIMD4<Float>(f[8], f[9], f[10], f[11]),
                    SIMD4<Float>(f[12], f[13], f[14], f[15])
                )
            }
            return Node(
                name: node["name"] as? String ?? "node\(index)",
                children: node["children"] as? [Int] ?? [],
                mesh: node["mesh"] as? Int ?? -1,
                translation: SIMD3<Float>(t[0], t[1], t[2]),
                rotation: simd_normalize(simd_quatf(ix: r[0], iy: r[1], iz: r[2], r: r[3])),
                scale: SIMD3<Float>(s[0], s[1], s[2]),
                matrix: matrix
            )
        }
        if let scenes = json["scenes"] as? [[String: Any]], !scenes.isEmpty {
            let index = min(max(json["scene"] as? Int ?? 0, 0), scenes.count - 1)
            roots = scenes[index]["nodes"] as? [Int] ?? []
        } else {
            let children = Set(nodes.flatMap { $0.children })
            roots = nodes.indices.filter { !children.contains($0) }
        }
        animations = (json["animations"] as? [[String: Any]] ?? []).enumerated().map { index, animation in
            let samplers = animation["samplers"] as? [[String: Any]] ?? []
            var duration: Float = 0
            let channels: [Channel] = (animation["channels"] as? [[String: Any]] ?? []).compactMap { channel in
                guard let target = channel["target"] as? [String: Any], let node = target["node"] as? Int,
                      let path = target["path"] as? String, path != "weights",
                      let samplerIndex = channel["sampler"] as? Int, samplerIndex < samplers.count
                else { return nil }
                let sampler = samplers[samplerIndex]
                let times = floats(sampler["input"] as? Int ?? -1)
                duration = max(duration, times.last ?? 0)
                return Channel(node: node, path: path, times: times, values: floats(sampler["output"] as? Int ?? -1), interpolation: sampler["interpolation"] as? String ?? "LINEAR")
            }
            return Animation(name: animation["name"] as? String ?? "animation\(index)", channels: channels, duration: duration)
        }
    }

    static func resolve(_ uri: String, baseURL: URL?) throws -> Data {
        if uri.hasPrefix("data:"), let comma = uri.firstIndex(of: ",") {
            return Data(base64Encoded: String(uri[uri.index(after: comma)...])) ?? Data()
        }
        guard let base = baseURL, let url = URL(string: uri.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? uri, relativeTo: base) else {
            throw NSError(domain: "u.ar", code: 2, userInfo: [NSLocalizedDescriptionKey: "External glTF resources need a file or url source"])
        }
        return try Data(contentsOf: url)
    }

    private static func material(_ material: [String: Any]) -> MaterialInfo {
        var info = MaterialInfo()
        let pbr = material["pbrMetallicRoughness"] as? [String: Any] ?? [:]
        let base = UArConvert.floats(pbr["baseColorFactor"], 4, 1)
        info.baseColor = SIMD4<Float>(base[0], base[1], base[2], base[3])
        info.metallic = UArConvert.float(pbr["metallicFactor"], 1)
        info.roughness = UArConvert.float(pbr["roughnessFactor"], 1)
        let emissive = UArConvert.floats(material["emissiveFactor"], 3, 0)
        let extensions = material["extensions"] as? [String: Any] ?? [:]
        let strength = UArConvert.float((extensions["KHR_materials_emissive_strength"] as? [String: Any])?["emissiveStrength"], 1)
        info.emissive = SIMD3<Float>(emissive[0], emissive[1], emissive[2]) * strength
        info.baseTexture = (pbr["baseColorTexture"] as? [String: Any])?["index"] as? Int ?? -1
        info.normalTexture = (material["normalTexture"] as? [String: Any])?["index"] as? Int ?? -1
        info.emissiveTexture = (material["emissiveTexture"] as? [String: Any])?["index"] as? Int ?? -1
        info.alphaMode = material["alphaMode"] as? String ?? "OPAQUE"
        info.alphaCutoff = UArConvert.float(material["alphaCutoff"], 0.5)
        info.unlit = extensions["KHR_materials_unlit"] != nil
        return info
    }

    private func viewData(_ index: Int) -> Data? {
        guard let views = json["bufferViews"] as? [[String: Any]], index < views.count else { return nil }
        let view = views[index]
        let buffer = view["buffer"] as? Int ?? 0
        guard buffer < buffers.count else { return nil }
        let offset = view["byteOffset"] as? Int ?? 0
        let length = view["byteLength"] as? Int ?? 0
        let data = buffers[buffer]
        guard offset + length <= data.count else { return nil }
        return data.subdata(in: data.startIndex + offset ..< data.startIndex + offset + length)
    }

    private func components(_ type: String) -> Int {
        switch type {
        case "VEC2": return 2
        case "VEC3": return 3
        case "VEC4", "MAT2": return 4
        case "MAT3": return 9
        case "MAT4": return 16
        default: return 1
        }
    }

    private func floats(_ index: Int) -> [Float] {
        guard index >= 0, let accessors = json["accessors"] as? [[String: Any]], index < accessors.count else { return [] }
        let accessor = accessors[index]
        let count = accessor["count"] as? Int ?? 0
        let comps = components(accessor["type"] as? String ?? "SCALAR")
        let type = accessor["componentType"] as? Int ?? 5126
        let normalized = accessor["normalized"] as? Bool ?? false
        var out = [Float](repeating: 0, count: count * comps)
        guard let viewIndex = accessor["bufferView"] as? Int, let views = json["bufferViews"] as? [[String: Any]], viewIndex < views.count else { return out }
        let view = views[viewIndex]
        let bufferIndex = view["buffer"] as? Int ?? 0
        guard bufferIndex < buffers.count else { return out }
        let size = type == 5120 || type == 5121 ? 1 : (type == 5122 || type == 5123 ? 2 : 4)
        let stride = (view["byteStride"] as? Int).flatMap { $0 == 0 ? nil : $0 } ?? size * comps
        let base = (view["byteOffset"] as? Int ?? 0) + (accessor["byteOffset"] as? Int ?? 0)
        buffers[bufferIndex].withUnsafeBytes { raw in
            for i in 0 ..< count {
                for c in 0 ..< comps {
                    let p = base + i * stride + c * size
                    guard p + size <= raw.count else { continue }
                    var value: Float
                    switch type {
                    case 5120:
                        let v = Float(raw.load(fromByteOffset: p, as: Int8.self))
                        value = normalized ? max(v / 127, -1) : v
                    case 5121:
                        let v = Float(raw.load(fromByteOffset: p, as: UInt8.self))
                        value = normalized ? v / 255 : v
                    case 5122:
                        let v = Float(raw.loadUnaligned(fromByteOffset: p, as: Int16.self))
                        value = normalized ? max(v / 32767, -1) : v
                    case 5123:
                        let v = Float(raw.loadUnaligned(fromByteOffset: p, as: UInt16.self))
                        value = normalized ? v / 65535 : v
                    case 5125:
                        value = Float(raw.loadUnaligned(fromByteOffset: p, as: UInt32.self))
                    default:
                        value = raw.loadUnaligned(fromByteOffset: p, as: Float.self)
                    }
                    out[i * comps + c] = value
                }
            }
        }
        return out
    }

    private func readMesh(_ mesh: [String: Any]) -> [Primitive] {
        (mesh["primitives"] as? [[String: Any]] ?? []).compactMap { primitive in
            let mode = primitive["mode"] as? Int ?? 4
            guard mode == 4 || mode == 5 || mode == 6,
                  let attributes = primitive["attributes"] as? [String: Any],
                  let positionIndex = attributes["POSITION"] as? Int
            else { return nil }
            let p = floats(positionIndex)
            let positions = stride(from: 0, to: p.count - 2, by: 3).map { SIMD3<Float>(p[$0], p[$0 + 1], p[$0 + 2]) }
            var indices: [UInt32] = (primitive["indices"] as? Int).map { floats($0).map { UInt32($0) } } ?? (0 ..< positions.count).map { UInt32($0) }
            if mode == 5 {
                var out: [UInt32] = []
                for i in 0 ..< max(indices.count - 2, 0) {
                    out += i % 2 == 0 ? [indices[i], indices[i + 1], indices[i + 2]] : [indices[i + 1], indices[i], indices[i + 2]]
                }
                indices = out
            } else if mode == 6 {
                var out: [UInt32] = []
                for i in 1 ..< max(indices.count - 1, 1) { out += [indices[0], indices[i], indices[i + 1]] }
                indices = out
            }
            var normals: [SIMD3<Float>]?
            if let normalIndex = attributes["NORMAL"] as? Int {
                let n = floats(normalIndex)
                normals = stride(from: 0, to: n.count - 2, by: 3).map { SIMD3<Float>(n[$0], n[$0 + 1], n[$0 + 2]) }
            }
            var uvs: [SIMD2<Float>]?
            if let uvIndex = attributes["TEXCOORD_0"] as? Int {
                let t = floats(uvIndex)
                uvs = stride(from: 0, to: t.count - 1, by: 2).map { SIMD2<Float>(t[$0], 1 - t[$0 + 1]) }
            }
            return Primitive(positions: positions, normals: normals, uvs: uvs, indices: indices, material: primitive["material"] as? Int ?? -1)
        }
    }

    // -------------------------------------------------------------------------
    // Entity building
    // -------------------------------------------------------------------------

    private var textureCache: [Int: TextureResource] = [:]

    private func texture(_ index: Int, normal: Bool = false) -> TextureResource? {
        guard index >= 0, index < textureImages.count else { return nil }
        let key = index * 4 + (normal ? 1 : 0)
        if let cached = textureCache[key] { return cached }
        let imageIndex = textureImages[index]
        guard imageIndex >= 0, imageIndex < images.count, let image = images[imageIndex] else { return nil }
        let resource = try? TextureResource.generate(from: image, options: .init(semantic: normal ? .normal : .color))
        textureCache[key] = resource
        return resource
    }

    private func makeMaterial(_ index: Int) -> RealityKit.Material {
        guard index >= 0, index < materials.count else {
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .white)
            material.roughness = .init(floatLiteral: 0.8)
            material.faceCulling = .none
            return material
        }
        let info = materials[index]
        let tint = UIColor(red: CGFloat(info.baseColor.x), green: CGFloat(info.baseColor.y), blue: CGFloat(info.baseColor.z), alpha: 1)
        if info.unlit {
            var material = UnlitMaterial()
            if let base = texture(info.baseTexture) {
                material.color = .init(tint: tint, texture: .init(base))
            } else {
                material.color = .init(tint: tint)
            }
            if info.alphaMode == "BLEND" || info.baseColor.w < 1 { material.blending = .transparent(opacity: .init(floatLiteral: info.baseColor.w)) }
            if info.alphaMode == "MASK" { material.opacityThreshold = info.alphaCutoff }
            if #available(iOS 18.0, *) { material.faceCulling = .none }
            return material
        }
        var material = PhysicallyBasedMaterial()
        if let base = texture(info.baseTexture) {
            material.baseColor = .init(tint: tint, texture: .init(base))
        } else {
            material.baseColor = .init(tint: tint)
        }
        material.metallic = .init(floatLiteral: info.metallic)
        material.roughness = .init(floatLiteral: info.roughness)
        if let normal = texture(info.normalTexture, normal: true) { material.normal = .init(texture: .init(normal)) }
        if info.emissive != .zero || info.emissiveTexture >= 0 {
            let emissive = UIColor(red: CGFloat(min(info.emissive.x, 1)), green: CGFloat(min(info.emissive.y, 1)), blue: CGFloat(min(info.emissive.z, 1)), alpha: 1)
            if let texture = texture(info.emissiveTexture) {
                material.emissiveColor = .init(color: emissive, texture: .init(texture))
            } else {
                material.emissiveColor = .init(color: emissive)
            }
            material.emissiveIntensity = max(max(info.emissive.x, info.emissive.y), max(info.emissive.z, 1))
        }
        if info.alphaMode == "BLEND" { material.blending = .transparent(opacity: .init(floatLiteral: info.baseColor.w)) }
        if info.alphaMode == "MASK" { material.opacityThreshold = info.alphaCutoff }
        material.faceCulling = .none
        return material
    }

    private func meshResource(_ primitives: [Primitive]) -> (MeshResource, [RealityKit.Material])? {
        var descriptors: [MeshDescriptor] = []
        var materialList: [RealityKit.Material] = []
        for (index, primitive) in primitives.enumerated() {
            var descriptor = MeshDescriptor(name: "p\(index)")
            descriptor.positions = MeshBuffers.Positions(primitive.positions)
            if let normals = primitive.normals, normals.count == primitive.positions.count { descriptor.normals = MeshBuffers.Normals(normals) }
            if let uvs = primitive.uvs, uvs.count == primitive.positions.count { descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs) }
            descriptor.primitives = .triangles(primitive.indices)
            descriptor.materials = .allFaces(UInt32(index))
            descriptors.append(descriptor)
            materialList.append(makeMaterial(primitive.material))
        }
        guard let mesh = try? MeshResource.generate(from: descriptors) else { return nil }
        return (mesh, materialList)
    }

    /// Builds the entity tree; returns the root and the entity of every glTF node.
    func build() -> (Entity, [Int: Entity]) {
        let root = Entity()
        var entities: [Int: Entity] = [:]
        var meshCache: [Int: (MeshResource, [RealityKit.Material])] = [:]
        func visit(_ index: Int, parent: Entity, depth: Int) {
            guard index >= 0, index < nodes.count, depth < 64 else { return }
            let node = nodes[index]
            let entity: Entity
            if node.mesh >= 0, node.mesh < meshes.count {
                if meshCache[node.mesh] == nil, let built = meshResource(meshes[node.mesh]) { meshCache[node.mesh] = built }
                if let built = meshCache[node.mesh] {
                    entity = ModelEntity(mesh: built.0, materials: built.1)
                } else {
                    entity = Entity()
                }
            } else {
                entity = Entity()
            }
            entity.name = node.name
            if let matrix = node.matrix {
                entity.transform = Transform(matrix: matrix)
            } else {
                entity.transform = Transform(scale: node.scale, rotation: node.rotation, translation: node.translation)
            }
            parent.addChild(entity)
            entities[index] = entity
            for child in node.children { visit(child, parent: entity, depth: depth + 1) }
        }
        for rootIndex in roots { visit(rootIndex, parent: root, depth: 0) }
        return (root, entities)
    }
}

/// Plays glTF node animations by sampling keyframes every frame.
@available(iOS 15.0, *)
final class UGltfAnimator {
    let animations: [UGltfAsset.Animation]
    let entities: [Int: Entity]
    var clips: [Int] = []
    var time: Float = 0
    var loop = true
    var speed: Float = 1
    var playing = false
    var onFinished: (() -> Void)?

    init(asset: UGltfAsset, entities: [Int: Entity]) {
        animations = asset.animations
        self.entities = entities
    }

    var names: [String] { animations.map { $0.name } }

    func play(name: String?, index: Int, loop: Bool, speed: Float) {
        if animations.isEmpty {
            clips = []
        } else if name == "*" {
            clips = Array(animations.indices)
        } else if let name {
            clips = animations.firstIndex { $0.name == name }.map { [$0] } ?? []
        } else {
            clips = [min(max(index, 0), animations.count - 1)]
        }
        self.loop = loop
        self.speed = speed
        time = 0
        playing = !clips.isEmpty
    }

    func update(_ delta: Float) {
        guard playing, !clips.isEmpty else { return }
        time += delta * speed
        let duration = clips.map { animations[$0].duration }.max() ?? 0
        if duration > 0, time > duration {
            if loop {
                time = time.truncatingRemainder(dividingBy: duration)
            } else {
                time = duration
                playing = false
                onFinished?()
            }
        }
        for clip in clips {
            for channel in animations[clip].channels { apply(channel) }
        }
    }

    private func apply(_ channel: UGltfAsset.Channel) {
        guard let entity = entities[channel.node], !channel.times.isEmpty else { return }
        let c = channel.path == "rotation" ? 4 : 3
        let cubic = channel.interpolation == "CUBICSPLINE"
        let stride = cubic ? c * 3 : c
        let times = channel.times
        var k = 0
        if time >= times[times.count - 1] {
            k = times.count - 1
        } else if time > times[0] {
            var lo = 0
            var hi = times.count - 1
            while hi - lo > 1 {
                let mid = (lo + hi) / 2
                if times[mid] <= time { lo = mid } else { hi = mid }
            }
            k = lo
        }
        let next = min(k + 1, times.count - 1)
        let span = times[next] - times[k]
        let f = span <= 0 ? 0 : min(max((time - times[k]) / span, 0), 1)
        let offset = cubic ? c : 0
        func value(_ key: Int, _ component: Int) -> Float {
            let i = key * stride + offset + component
            return i < channel.values.count ? channel.values[i] : 0
        }
        if c == 4 {
            let a = simd_quatf(ix: value(k, 0), iy: value(k, 1), iz: value(k, 2), r: value(k, 3))
            let b = simd_quatf(ix: value(next, 0), iy: value(next, 1), iz: value(next, 2), r: value(next, 3))
            entity.transform.rotation = channel.interpolation == "STEP" ? simd_normalize(a) : simd_slerp(simd_normalize(a), simd_normalize(b), f)
        } else {
            let a = SIMD3<Float>(value(k, 0), value(k, 1), value(k, 2))
            let b = SIMD3<Float>(value(next, 0), value(next, 1), value(next, 2))
            let v = channel.interpolation == "STEP" ? a : a + (b - a) * f
            if channel.path == "translation" { entity.transform.translation = v } else { entity.transform.scale = v }
        }
    }
}

// =============================================================================
// Procedural meshes and textures
// =============================================================================

@available(iOS 15.0, *)
enum UArMeshes {
    static func cylinder(radius: Float, height: Float, cone: Bool, segments: Int = 32) -> MeshResource? {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        let half = height / 2
        let top: Float = cone ? 0 : radius
        let slope = (radius - top) / height
        let l = sqrt(1 + slope * slope)
        for s in 0 ... segments {
            let u = Float(s) / Float(segments)
            let theta = u * 2 * .pi
            let x = sin(theta)
            let z = cos(theta)
            positions.append(SIMD3<Float>(x * top, half, z * top))
            normals.append(SIMD3<Float>(x / l, slope / l, z / l))
            uvs.append(SIMD2<Float>(u, 1))
            positions.append(SIMD3<Float>(x * radius, -half, z * radius))
            normals.append(SIMD3<Float>(x / l, slope / l, z / l))
            uvs.append(SIMD2<Float>(u, 0))
        }
        for s in 0 ..< segments {
            let a = UInt32(s * 2)
            indices += [a, a + 1, a + 2, a + 1, a + 3, a + 2]
        }
        for y in cone ? [-half] : [half, -half] {
            let center = UInt32(positions.count)
            let ny: Float = y > 0 ? 1 : -1
            let r = y > 0 ? top : radius
            positions.append(SIMD3<Float>(0, y, 0))
            normals.append(SIMD3<Float>(0, ny, 0))
            uvs.append(SIMD2<Float>(0.5, 0.5))
            for s in 0 ... segments {
                let theta = Float(s) / Float(segments) * 2 * .pi
                positions.append(SIMD3<Float>(sin(theta) * r, y, cos(theta) * r))
                normals.append(SIMD3<Float>(0, ny, 0))
                uvs.append(SIMD2<Float>(0.5 + sin(theta) / 2, 0.5 + cos(theta) / 2))
            }
            for s in 0 ..< segments {
                let a = center + 1 + UInt32(s)
                indices += ny > 0 ? [center, a, a + 1] : [center, a + 1, a]
            }
        }
        var descriptor = MeshDescriptor(name: cone ? "cone" : "cylinder")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)
        return try? MeshResource.generate(from: [descriptor])
    }

    /// Flat polygon in the X/Z plane from ARKit boundary vertices, fan-triangulated.
    static func polygon(_ vertices: [SIMD3<Float>], tile: Float) -> MeshResource? {
        guard vertices.count >= 3 else { return nil }
        var indices: [UInt32] = []
        for i in 1 ..< vertices.count - 1 { indices += [0, UInt32(i + 1), UInt32(i)] }
        var descriptor = MeshDescriptor(name: "plane")
        descriptor.positions = MeshBuffers.Positions(vertices.map { SIMD3<Float>($0.x, 0, $0.z) })
        descriptor.normals = MeshBuffers.Normals(vertices.map { _ in SIMD3<Float>(0, 1, 0) })
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(vertices.map { SIMD2<Float>($0.x * tile, $0.z * tile) })
        descriptor.primitives = .triangles(indices + indices.reversed())
        return try? MeshResource.generate(from: [descriptor])
    }

    static func texture(size: Int, draw: (CGContext, CGFloat) -> Void) -> TextureResource? {
        let s = CGFloat(size)
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.clear(CGRect(x: 0, y: 0, width: s, height: s))
        draw(context, s)
        guard let image = context.makeImage() else { return nil }
        return try? TextureResource.generate(from: image, options: .init(semantic: .color))
    }

    static func planeTexture(style: String, color: UIColor) -> TextureResource? {
        texture(size: 128) { context, s in
            switch style {
            case "dots":
                context.setFillColor(color.cgColor)
                context.fillEllipse(in: CGRect(x: s * 0.4, y: s * 0.4, width: s * 0.2, height: s * 0.2))
            case "solid", "outline":
                context.setFillColor(color.withAlphaComponent(color.cgColor.alpha * 0.45).cgColor)
                context.fill(CGRect(x: 0, y: 0, width: s, height: s))
            default:
                context.setFillColor(color.withAlphaComponent(color.cgColor.alpha * 0.12).cgColor)
                context.fill(CGRect(x: 0, y: 0, width: s, height: s))
                context.setStrokeColor(color.cgColor)
                context.setLineWidth(3)
                context.stroke(CGRect(x: 1.5, y: 1.5, width: s - 3, height: s - 3))
            }
        }
    }

    static func ringTexture(color: UIColor) -> TextureResource? {
        texture(size: 256) { context, s in
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(s * 0.07)
            context.strokeEllipse(in: CGRect(x: s * 0.12, y: s * 0.12, width: s * 0.76, height: s * 0.76))
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: CGRect(x: s * 0.46, y: s * 0.46, width: s * 0.08, height: s * 0.08))
        }
    }

    static func sampler() -> MaterialParameters.Texture.Sampler {
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.mipFilter = .linear
        return MaterialParameters.Texture.Sampler(descriptor)
    }
}

// =============================================================================
// Session (one platform view)
// =============================================================================

@available(iOS 15.0, *)
final class UArNodeRecord {
    let id: String
    var map: [String: Any] = [:]
    let wrapper = Entity()
    var content: Entity?
    var animator: UGltfAnimator?
    var animationNames: [String] = []
    var player: AVPlayer?
    var endObserver: NSObjectProtocol?
    var sourceKey = ""
    var loaded = false
    var loadToken = 0

    init(id: String) {
        self.id = id
        wrapper.name = "u-node:\(id)"
    }

    var type: String { map["type"] as? String ?? "group" }
    var anchorId: String? { map["anchorId"] as? String }
    var parentId: String? { map["parentId"] as? String }
    var billboard: String { map["billboard"] as? String ?? "none" }
    var visible: Bool { map["visible"] as? Bool ?? true }
    var hittable: Bool { map["hittable"] as? Bool ?? true }

    func release() {
        player?.pause()
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        player = nil
        content?.removeFromParent()
        content = nil
        animator = nil
    }
}

@available(iOS 15.0, *)
final class UArAnchorRecord {
    let id: String
    var arAnchor: ARAnchor?
    var entity: AnchorEntity
    let root = Entity()
    var type: String
    var cloudId: String?
    var lastSent: SIMD3<Float>?
    var lastState = ""

    init(id: String, arAnchor: ARAnchor?, entity: AnchorEntity, type: String) {
        self.id = id
        self.arAnchor = arAnchor
        self.entity = entity
        self.type = type
        entity.addChild(root)
    }
}

@available(iOS 15.0, *)
final class UArSession: NSObject, FlutterPlatformView, FlutterStreamHandler, ARSessionDelegate {
    let sessionId: Int64
    private let container = UIView()
    private var arView: ARView?
    private var config: [String: Any]
    private let loader: UArSourceLoader
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    private var started = false
    private var disposed = false
    private var worldAnchor: AnchorEntity?
    private var nodes: [String: UArNodeRecord] = [:]
    private var anchors: [String: UArAnchorRecord] = [:]
    private var specialAnchors: [String: AnchorEntity] = [:]
    private var planeVisuals: [UUID: (AnchorEntity, ModelEntity, TimeInterval)] = [:]
    private var planeIds: [UUID: String] = [:]
    private var pendingPlanes: [UUID: ARPlaneAnchor] = [:]
    private var removedPlanes: [String] = []
    private var faceIds: [UUID: String] = [:]
    private var faceMeshes: [UUID: (ModelEntity, TimeInterval)] = [:]
    private var tracks: [[String: Any]] = []
    private var sceneSubscription: Cancellable?
    private var loads = Set<AnyCancellable>()
    private var coaching: ARCoachingOverlayView?
    private var reticleAnchor: AnchorEntity?
    private var reticleEntity: ModelEntity?
    private var centerHit: [String: Any]?
    private var viewerCamera: PerspectiveCamera?
    private var viewerLight: DirectionalLight?
    private var lastEvent: TimeInterval = 0
    private var lastPlaneEmit: TimeInterval = 0
    private var lastFaceEmit: TimeInterval = 0
    private var lastBodyEmit: TimeInterval = 0
    private var lastAnchorEmit: TimeInterval = 0
    private var lastGeoQuery: TimeInterval = 0
    private var lastTracking = ""
    private var geo: [String: Any]?
    private var geoStatus = "notAvailable"
    private var recordingStart = Date()
    private var nextId = 1
    private var configuration: ARConfiguration?
    private var vpsAvailable: Bool?
    private var degraded = false
    private var planeTextureCache: TextureResource?

    init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger, loader: UArSourceLoader) {
        sessionId = viewId
        config = ((arguments as? [String: Any])?["config"] as? [String: Any]) ?? [:]
        self.loader = loader
        eventChannel = FlutterEventChannel(name: "u/ar/events/\(viewId)", binaryMessenger: messenger)
        super.init()
        container.frame = frame
        container.backgroundColor = .black
        eventChannel.setStreamHandler(self)
        let viewer = isViewer
        let view = ARView(frame: frame, cameraMode: viewer ? .nonAR : .ar, automaticallyConfigureSession: false)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isUserInteractionEnabled = false
        container.addSubview(view)
        arView = view
        applyViewOptions()
        UArSession.live.add(self)
        UArSession.arbitrateRendering()
    }

    // RealityKit stops drawing a camera ARView while another, camera-less ARView
    // (a 3D viewer on the page underneath) is still rendering: the AR view goes
    // black. Viewers therefore leave the window while any AR session is alive.
    private static let live = NSHashTable<UArSession>.weakObjects()

    private static func arbitrateRendering() {
        let sessions = live.allObjects.filter { !$0.disposed }
        let arActive = sessions.contains { !$0.isViewer }
        for session in sessions where session.isViewer {
            session.setRendering(!arActive)
        }
    }

    private var parkedAnchors: [HasAnchoring]?

    /// Destroys this viewer's ARView while an AR session runs (hiding it is not
    /// enough) and rebuilds it with the same scene content afterwards.
    private func setRendering(_ enabled: Bool) {
        if enabled {
            guard let anchors = parkedAnchors, arView == nil, !disposed else { return }
            parkedAnchors = nil
            let view = ARView(frame: container.bounds, cameraMode: .nonAR, automaticallyConfigureSession: false)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.isUserInteractionEnabled = false
            container.insertSubview(view, at: 0)
            arView = view
            applyViewOptions()
            for anchor in anchors { view.scene.addAnchor(anchor) }
            if started {
                sceneSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                    self?.onSceneUpdate(Float(event.deltaTime))
                }
            }
        } else {
            guard let view = arView, parkedAnchors == nil else { return }
            sceneSubscription?.cancel()
            sceneSubscription = nil
            let anchors = Array(view.scene.anchors)
            view.scene.anchors.removeAll()
            parkedAnchors = anchors
            view.removeFromSuperview()
            arView = nil
        }
    }

    func view() -> UIView { container }

    private var isViewer: Bool { config["mode"] as? String == "viewer" }

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func emit(_ payload: [String: Any?]) {
        guard !disposed else { return }
        var clean: [String: Any] = [:]
        for (key, value) in payload { if let value { clean[key] = value } }
        eventSink?(clean)
    }

    private func newId(_ prefix: String) -> String {
        defer { nextId += 1 }
        return "\(prefix)\(nextId)"
    }

    // -------------------------------------------------------------------------
    // Configuration
    // -------------------------------------------------------------------------

    static func capabilities() -> [String: Any] {
        var caps: [String: Any] = [
            "platform": "ios",
            "worldTracking": ARWorldTrackingConfiguration.isSupported,
            "planeHorizontal": ARWorldTrackingConfiguration.isSupported,
            "planeVertical": ARWorldTrackingConfiguration.isSupported,
            "planeClassification": ARPlaneAnchor.isClassificationSupported,
            "depth": ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth),
            "peopleOcclusion": ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth),
            "sceneReconstruction": ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh),
            "lidar": ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh),
            "imageTracking": ARImageTrackingConfiguration.isSupported,
            "objectTracking": ARWorldTrackingConfiguration.isSupported,
            "faceTracking": ARFaceTrackingConfiguration.isSupported,
            "bodyTracking": ARBodyTrackingConfiguration.isSupported,
            "geospatial": ARGeoTrackingConfiguration.isSupported,
            "gpsGeo": ARWorldTrackingConfiguration.isSupported,
            "cloudAnchors": false,
            "worldMap": ARWorldTrackingConfiguration.isSupported,
            "collaboration": ARWorldTrackingConfiguration.isSupported,
            "lightEstimation": true,
            "environmentHdr": true,
            "instantPlacement": true,
            "semantics": false,
            "recording": RPScreenRecorder.shared().isAvailable,
            "snapshot": true,
            "roomPlan": false,
            "objectCapture": false,
            "textRecognition": true,
            "barcodeDetection": true,
            "cameraImage": true,
            "nativeViewer": true,
            "viewer": true,
            "webXr": false,
            "sensorAr": false,
            "formats": ["usdz", "reality", "glb", "gltf"],
        ]
        #if canImport(RoomPlan)
            if #available(iOS 16.0, *) { caps["roomPlan"] = RoomCaptureSession.isSupported }
        #endif
        // Always reached from Flutter method-channel / platform-view callbacks, which run on the main thread.
        if #available(iOS 17.0, *) { caps["objectCapture"] = MainActor.assumeIsolated { ObjectCaptureSession.isSupported } }
        return caps
    }

    private func applyViewOptions() {
        guard let arView else { return }
        var debug: ARView.DebugOptions = []
        if config["showFeaturePoints"] as? Bool == true { debug.insert(.showFeaturePoints) }
        if config["showWorldOrigin"] as? Bool == true { debug.insert(.showWorldOrigin) }
        if config["showAnchors"] as? Bool == true { debug.insert(.showAnchorOrigins) }
        if config["showSceneMesh"] as? Bool == true { debug.insert(.showSceneUnderstanding) }
        arView.debugOptions = debug
        var render: ARView.RenderOptions = []
        if config["shadows"] as? Bool == false { render.insert(.disableGroundingShadows) }
        if config["peopleOcclusion"] as? Bool == false { render.insert(.disablePersonOcclusion) }
        arView.renderOptions = render
        let exposure = max(UArConvert.float(config["exposure"], 1) * UArConvert.float(config["environmentIntensity"], 1), 0.01)
        arView.environment.lighting.intensityExponent = log2(exposure)
        if isViewer {
            if config["transparentBackground"] as? Bool == true {
                arView.environment.background = .color(.clear)
                arView.backgroundColor = .clear
                arView.isOpaque = false
                container.backgroundColor = .clear
            } else {
                let color = UArConvert.color(config["background"], 0xFFF2_F2F2)
                arView.environment.background = .color(color)
                container.backgroundColor = color
            }
        } else {
            var understanding: ARView.Environment.SceneUnderstanding.Options = []
            if config["occlusion"] as? Bool != false, ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) { understanding.insert(.occlusion) }
            understanding.insert(.receivesLighting)
            arView.environment.sceneUnderstanding.options = understanding
        }
    }

    private func makeConfiguration(images: Set<ARReferenceImage>, objects: Set<ARReferenceObject>, worldMap: ARWorldMap?) -> ARConfiguration? {
        let mode = config["mode"] as? String ?? "world"
        let lightEstimation = config["lightEstimation"] as? String != "disabled"
        let planes: ARWorldTrackingConfiguration.PlaneDetection = {
            switch config["planeDetection"] as? String {
            case "none": return []
            case "horizontal": return [.horizontal]
            case "vertical": return [.vertical]
            default: return [.horizontal, .vertical]
            }
        }()
        switch mode {
        case "face":
            guard ARFaceTrackingConfiguration.isSupported else { return nil }
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = lightEstimation
            configuration.maximumNumberOfTrackedFaces = min(ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces, 3)
            return configuration
        case "image":
            let configuration = ARImageTrackingConfiguration()
            configuration.trackingImages = images
            configuration.maximumNumberOfTrackedImages = max(1, config["maxTrackedImages"] as? Int ?? 4)
            configuration.isAutoFocusEnabled = config["focusMode"] as? String != "fixed"
            return configuration
        case "body":
            guard ARBodyTrackingConfiguration.isSupported else { return nil }
            let configuration = ARBodyTrackingConfiguration()
            configuration.planeDetection = planes
            configuration.automaticSkeletonScaleEstimationEnabled = true
            configuration.environmentTexturing = .automatic
            return configuration
        case "orientation":
            return AROrientationTrackingConfiguration()
        case "geo" where config["geoMode"] as? String != "gps" && ARGeoTrackingConfiguration.isSupported && vpsAvailable == true:
            let configuration = ARGeoTrackingConfiguration()
            configuration.planeDetection = planes
            configuration.environmentTexturing = .automatic
            configuration.detectionImages = images
            configuration.maximumNumberOfTrackedImages = max(1, config["maxTrackedImages"] as? Int ?? 4)
            return configuration
        default:
            guard ARWorldTrackingConfiguration.isSupported else { return nil }
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = planes
            configuration.environmentTexturing = .automatic
            configuration.isLightEstimationEnabled = lightEstimation
            configuration.isAutoFocusEnabled = config["focusMode"] as? String != "fixed"
            configuration.detectionImages = images
            configuration.maximumNumberOfTrackedImages = images.isEmpty ? 0 : max(1, config["maxTrackedImages"] as? Int ?? 4)
            configuration.detectionObjects = objects
            configuration.isCollaborationEnabled = config["collaboration"] as? Bool == true
            configuration.initialWorldMap = worldMap
            let alignment = config["worldAlignment"] as? String
            configuration.worldAlignment = mode == "geo" || alignment == "gravityAndHeading" ? .gravityAndHeading : (alignment == "camera" ? .camera : .gravity)
            let occlusion = config["occlusion"] as? Bool != false
            if config["peopleOcclusion"] as? Bool != false, ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
                configuration.frameSemantics.insert(.personSegmentationWithDepth)
            }
            if occlusion, ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) { configuration.frameSemantics.insert(.sceneDepth) }
            let reconstruction = config["sceneReconstruction"] as? String
            if reconstruction == "meshWithClassification", ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
                configuration.sceneReconstruction = .meshWithClassification
            } else if (reconstruction == "mesh" || occlusion || config["showSceneMesh"] as? Bool == true), ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                configuration.sceneReconstruction = .mesh
            }
            if config["highFps"] as? Bool == true, let format = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { $0.framesPerSecond >= 60 }) {
                configuration.videoFormat = format
            }
            return configuration
        }
    }

    private func loadReferences(completion: @escaping (Set<ARReferenceImage>, Set<ARReferenceObject>, ARWorldMap?) -> Void) {
        let images = (config["images"] as? [[String: Any]]) ?? []
        let objects = (config["objects"] as? [[String: Any]]) ?? []
        var loadedImages = Set<ARReferenceImage>()
        var loadedObjects = Set<ARReferenceObject>()
        let group = DispatchGroup()
        for image in images {
            group.enter()
            loader.data(image["source"] as? [String: Any]) { data, _, _ in
                if let data, let source = CGImageSourceCreateWithData(data as CFData, nil), let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                    let reference = ARReferenceImage(cgImage, orientation: .up, physicalWidth: CGFloat(UArConvert.float(image["width"], 0.2)))
                    reference.name = image["name"] as? String
                    loadedImages.insert(reference)
                }
                group.leave()
            }
        }
        for object in objects {
            group.enter()
            loader.file(object["source"] as? [String: Any]) { url, _ in
                if let url, let reference = try? ARReferenceObject(archiveURL: url) {
                    reference.name = object["name"] as? String
                    loadedObjects.insert(reference)
                }
                group.leave()
            }
        }
        var worldMap: ARWorldMap?
        if let typed = config["worldMap"] as? FlutterStandardTypedData {
            worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: typed.data)
        }
        group.notify(queue: .main) { completion(loadedImages, loadedObjects, worldMap) }
    }

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    func start(result: @escaping FlutterResult) {
        guard let arView, !started else {
            result(["capabilities": UArSession.capabilities()])
            return
        }
        started = true
        let world = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
        arView.scene.addAnchor(world)
        worldAnchor = world
        sceneSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.onSceneUpdate(Float(event.deltaTime))
        }
        if isViewer {
            let camera = PerspectiveCamera()
            let cameraAnchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
            cameraAnchor.addChild(camera)
            arView.scene.addAnchor(cameraAnchor)
            viewerCamera = camera
            let light = DirectionalLight()
            light.light.intensity = 2500 * UArConvert.float(config["environmentIntensity"], 1)
            light.look(at: .zero, from: SIMD3<Float>(0.6, 1.6, 1.0), relativeTo: nil)
            if config["shadows"] as? Bool != false {
                light.shadow = DirectionalLightComponent.Shadow(maximumDistance: 10, depthBias: 2)
            }
            world.addChild(light)
            viewerLight = light
            updateOrbit()
            result(["capabilities": UArSession.capabilities()])
            emit(["type": "state", "session": "running", "tracking": "normal", "reason": "none"])
            return
        }
        checkGeoAvailability { [weak self] in
            self?.loadReferences { [weak self] images, objects, worldMap in
                guard let self, !self.disposed, let arView = self.arView else {
                    result(FlutterError(code: "cancelled", message: "The AR view was disposed", details: nil))
                    return
                }
                guard let configuration = self.makeConfiguration(images: images, objects: objects, worldMap: worldMap) else {
                    result(FlutterError(code: "unsupported", message: "This AR mode is not supported on this device", details: nil))
                    return
                }
                self.configuration = configuration
                arView.session.delegate = self
                arView.session.run(configuration, options: [])
                if self.config["coaching"] as? Bool != false { self.addCoaching() }
                result(["capabilities": self.sessionCapabilities()])
                self.emit(["type": "state", "session": "running", "tracking": "notAvailable", "reason": "initializing"])
            }
        }
    }

    /// Apple's visual positioning only covers some cities; the device check alone
    /// is not enough. Where it is missing, geo mode runs world tracking aligned to
    /// north and content is placed by GPS + compass instead.
    private func checkGeoAvailability(_ done: @escaping () -> Void) {
        guard config["mode"] as? String == "geo", config["geoMode"] as? String != "gps", ARGeoTrackingConfiguration.isSupported else {
            done()
            return
        }
        ARGeoTrackingConfiguration.checkAvailability { [weak self] available, _ in
            DispatchQueue.main.async {
                self?.vpsAvailable = available
                done()
            }
        }
    }

    private func sessionCapabilities() -> [String: Any] {
        var caps = UArSession.capabilities()
        if config["mode"] as? String == "geo" { caps["geospatial"] = configuration is ARGeoTrackingConfiguration }
        return caps
    }

    private func addCoaching() {
        guard let arView else { return }
        let overlay = ARCoachingOverlayView(frame: container.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.session = arView.session
        switch config["coachingGoal"] as? String {
        case "tracking": overlay.goal = .tracking
        case "horizontalPlane": overlay.goal = .horizontalPlane
        case "verticalPlane": overlay.goal = .verticalPlane
        case "geoTracking": overlay.goal = .geoTracking
        default: overlay.goal = .anyPlane
        }
        overlay.activatesAutomatically = true
        container.addSubview(overlay)
        coaching = overlay
    }

    func pause() {
        arView?.session.pause()
        emit(["type": "state", "session": "paused", "tracking": "paused", "reason": "none"])
    }

    func resume() {
        if let configuration { arView?.session.run(configuration, options: []) }
        emit(["type": "state", "session": "running", "tracking": "limited", "reason": "initializing"])
    }

    func reset(keepNodes: Bool) {
        for record in anchors.values {
            if let anchor = record.arAnchor { arView?.session.remove(anchor: anchor) }
            if keepNodes {
                for child in record.root.children { worldAnchor?.addChild(child) }
            }
            record.entity.removeFromParent()
        }
        anchors.removeAll()
        for visual in planeVisuals.values { visual.0.removeFromParent() }
        planeVisuals.removeAll()
        planeIds.removeAll()
        if !keepNodes {
            nodes.values.forEach { $0.release(); $0.wrapper.removeFromParent() }
            nodes.removeAll()
        }
        if let configuration { arView?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors]) }
    }

    func updateConfig(_ next: [String: Any], result: @escaping FlutterResult) {
        if next["mode"] as? String != config["mode"] as? String {
            result(FlutterError(code: "unsupported", message: "Changing the mode needs a new session", details: nil))
            return
        }
        config = next
        applyViewOptions()
        planeTextureCache = nil
        if isViewer {
            updateOrbit()
            result(nil)
            return
        }
        loadReferences { [weak self] images, objects, _ in
            guard let self, let arView = self.arView, let configuration = self.makeConfiguration(images: images, objects: objects, worldMap: nil) else {
                result(nil)
                return
            }
            self.configuration = configuration
            arView.session.run(configuration, options: [])
            result(nil)
        }
    }

    func dispose() {
        guard !disposed else { return }
        disposed = true
        eventChannel.setStreamHandler(nil)
        sceneSubscription?.cancel()
        loads.removeAll()
        nodes.values.forEach { $0.release() }
        nodes.removeAll()
        arView?.session.pause()
        arView?.session.delegate = nil
        arView?.scene.anchors.removeAll()
        coaching?.removeFromSuperview()
        arView?.removeFromSuperview()
        arView = nil
        if RPScreenRecorder.shared().isRecording { RPScreenRecorder.shared().stopRecording(handler: nil) }
        UArSession.live.remove(self)
        UArSession.arbitrateRendering()
    }

    // -------------------------------------------------------------------------
    // Per-frame work
    // -------------------------------------------------------------------------

    private var cameraMatrix: simd_float4x4 {
        if let viewerCamera { return viewerCamera.transformMatrix(relativeTo: nil) }
        return arView?.cameraTransform.matrix ?? matrix_identity_float4x4
    }

    private func onSceneUpdate(_ delta: Float) {
        guard !disposed, let arView else { return }
        let camera = UArConvert.translation(cameraMatrix)
        for record in nodes.values {
            record.animator?.update(delta)
            guard record.billboard != "none", record.wrapper.parent != nil else { continue }
            let position = record.wrapper.position(relativeTo: nil)
            var toCamera = camera - position
            if record.billboard == "yAxis" { toCamera.y = 0 }
            guard simd_length(toCamera) > 0.0001 else { continue }
            let direction = simd_normalize(toCamera)
            let orientation = record.billboard == "yAxis"
                ? simd_quatf(angle: atan2(direction.x, direction.z), axis: SIMD3<Float>(0, 1, 0))
                : simd_quatf(from: SIMD3<Float>(0, 0, 1), to: direction)
            record.wrapper.setOrientation(orientation, relativeTo: nil)
        }
        if !isViewer, config["reticle"] as? Bool == true { updateReticle(arView) }
        if isViewer {
            let now = CACurrentMediaTime()
            let rate = Double(max(1, min(60, config["eventRate"] as? Int ?? 30)))
            if now - lastEvent >= 1 / rate {
                lastEvent = now
                emitFrame(nil)
            }
        }
    }

    private func updateReticle(_ arView: ARView) {
        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        let hits = arView.raycast(from: center, allowing: .existingPlaneGeometry, alignment: .any) + arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any)
        if reticleAnchor == nil {
            let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
            var material = UnlitMaterial()
            if let texture = UArMeshes.ringTexture(color: UArConvert.color(config["reticleColor"], 0xFFFF_FFFF)) {
                material.color = .init(tint: .white, texture: .init(texture))
            }
            material.blending = .transparent(opacity: .init(floatLiteral: 1))
            let entity = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [material])
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            reticleAnchor = anchor
            reticleEntity = entity
        }
        guard let hit = hits.first else {
            reticleEntity?.isEnabled = false
            centerHit = nil
            return
        }
        let distance = simd_distance(UArConvert.translation(hit.worldTransform), UArConvert.translation(cameraMatrix))
        let size = min(max(0.05 + distance * 0.035, 0.04), 0.3)
        reticleAnchor?.setTransformMatrix(hit.worldTransform, relativeTo: nil)
        reticleEntity?.transform = Transform(scale: SIMD3<Float>(size * 2, 1, size * 2), rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1), translation: SIMD3<Float>(0, 0.002, 0))
        reticleEntity?.isEnabled = true
        centerHit = hitMap(hit)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let now = CACurrentMediaTime()
        let rate = Double(max(1, min(60, config["eventRate"] as? Int ?? 30)))
        if now - lastEvent >= 1 / rate {
            lastEvent = now
            emitFrame(frame)
        }
        if now - lastPlaneEmit > 0.2, !pendingPlanes.isEmpty || !removedPlanes.isEmpty {
            lastPlaneEmit = now
            let updated = pendingPlanes.values.map(planeMap)
            emit(["type": "planes", "updated": updated, "removed": removedPlanes])
            pendingPlanes.removeAll()
            removedPlanes.removeAll()
        }
        if now - lastAnchorEmit > 0.1 {
            lastAnchorEmit = now
            emitAnchors()
        }
        let alignedToNorth = config["mode"] as? String == "geo" || config["worldAlignment"] as? String == "gravityAndHeading"
        if alignedToNorth, now - lastGeoQuery > 1, configuration is ARGeoTrackingConfiguration {
            lastGeoQuery = now
            let position = UArConvert.translation(frame.camera.transform)
            session.getGeoLocation(forPoint: position) { [weak self] coordinate, altitude, error in
                guard let self, error == nil else { return }
                self.geo = [
                    "state": self.geoStatus,
                    "tracking": self.geoStatus == "localized" ? "normal" : "limited",
                    "latitude": coordinate.latitude,
                    "longitude": coordinate.longitude,
                    "altitude": altitude,
                    "source": "geoTracking",
                ]
            }
        }
    }

    private func emitFrame(_ frame: ARFrame?) {
        let camera = cameraMatrix
        var payload: [String: Any?] = [
            "type": "frame",
            "t": CACurrentMediaTime() * 1000,
            "camera": UArConvert.pose(camera),
        ]
        if let viewerCamera {
            payload["fov"] = Double(viewerCamera.camera.fieldOfViewInDegrees)
        } else if let frame, let arView {
            let projection = frame.camera.projectionMatrix(for: interfaceOrientation(), viewportSize: arView.bounds.size, zNear: 0.01, zFar: 100)
            payload["fov"] = Double(2 * atan(1 / projection.columns.1.y) * 180 / .pi)
            if let estimate = frame.lightEstimate {
                payload["light"] = ["intensity": Double(estimate.ambientIntensity / 1000), "colorTemperature": Double(estimate.ambientColorTemperature)]
            }
        }
        if !isViewer {
            payload["center"] = centerHit
            if config["mode"] as? String == "geo" || config["worldAlignment"] as? String == "gravityAndHeading" {
                let forward = -SIMD3<Float>(camera.columns.2.x, camera.columns.2.y, camera.columns.2.z)
                let heading = (Double(atan2(forward.x, -forward.z)) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
                payload["northYaw"] = 0.0
                payload["heading"] = heading
                var geoMap = geo ?? ["state": geoStatus, "tracking": "notAvailable", "source": "gps"]
                geoMap["heading"] = heading
                payload["geo"] = geo == nil ? nil : geoMap
            }
        }
        if !tracks.isEmpty { payload["projections"] = projections(camera) }
        emit(payload)
    }

    private func interfaceOrientation() -> UIInterfaceOrientation {
        container.window?.windowScene?.interfaceOrientation ?? .portrait
    }

    private func projections(_ camera: simd_float4x4) -> [[Any]] {
        guard let arView else { return [] }
        let inverse = camera.inverse
        let size = arView.bounds.size
        var out: [[Any]] = []
        for track in tracks {
            guard let id = track["id"] as? String else { continue }
            let offset = UArConvert.vector(track["offset"])
            var point: SIMD3<Float>?
            if let nodeId = track["nodeId"] as? String, let record = nodes[nodeId], record.wrapper.parent != nil {
                point = record.wrapper.convert(position: offset, to: nil)
            } else if let anchorId = track["anchorId"] as? String, let entity = anchorEntity(anchorId) {
                point = entity.convert(position: offset, to: nil)
            } else if track["nodeId"] == nil, track["anchorId"] == nil {
                point = offset
            }
            guard let world = point else {
                out.append([id, 0.5, 0.5, 0.0, -1])
                continue
            }
            let local = inverse * SIMD4<Float>(world.x, world.y, world.z, 1)
            let distance = Double(simd_distance(world, UArConvert.translation(camera)))
            if local.z >= 0 {
                out.append([id, local.x >= 0 ? 1.0 : 0.0, 0.5, distance, -1])
                continue
            }
            guard let projected = arView.project(world), size.width > 0, size.height > 0 else {
                out.append([id, 0.5, 0.5, distance, -1])
                continue
            }
            let x = Double(projected.x / size.width)
            let y = Double(projected.y / size.height)
            out.append([id, x, y, distance, (0 ... 1).contains(x) && (0 ... 1).contains(y) ? 1 : 0])
        }
        return out
    }

    func session(_: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var tracking = "normal"
        var reason = "none"
        switch camera.trackingState {
        case .notAvailable:
            tracking = "notAvailable"
            reason = "initializing"
        case let .limited(limited):
            tracking = "limited"
            switch limited {
            case .initializing: reason = "initializing"
            case .excessiveMotion: reason = "excessiveMotion"
            case .insufficientFeatures: reason = "insufficientFeatures"
            case .relocalizing: reason = "relocalizing"
            @unknown default: reason = "unknown"
            }
        case .normal:
            break
        }
        let key = tracking + reason
        if key != lastTracking {
            lastTracking = key
            emit(["type": "state", "tracking": tracking, "reason": reason, "session": "running"])
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        let arCode = (error as? ARError)?.code
        // Occlusion extras are the usual reason a configuration is refused; retry
        // once without them rather than leaving a frozen, black view.
        if arCode == .unsupportedConfiguration, !degraded, let world = configuration as? ARWorldTrackingConfiguration {
            degraded = true
            world.frameSemantics = []
            world.sceneReconstruction = []
            arView?.environment.sceneUnderstanding.options = []
            session.run(world, options: [.resetTracking, .removeExistingAnchors])
            return
        }
        let code = arCode == .cameraUnauthorized ? "permission" : "sessionFailed"
        emit(["type": "error", "code": code, "message": error.localizedDescription])
    }

    func session(_: ARSession, didChange status: ARGeoTrackingStatus) {
        switch status.state {
        case .localized: geoStatus = "localized"
        case .localizing: geoStatus = "localizing"
        case .initializing: geoStatus = "initializing"
        default: geoStatus = "notAvailable"
        }
    }

    func session(_: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let encoded = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true) else { return }
        emit(["type": "collaboration", "data": FlutterStandardTypedData(bytes: encoded)])
    }

    // -------------------------------------------------------------------------
    // Trackables
    // -------------------------------------------------------------------------

    func session(_: ARSession, didAdd added: [ARAnchor]) {
        handleAnchors(added, removed: false)
    }

    func session(_: ARSession, didUpdate updated: [ARAnchor]) {
        handleAnchors(updated, removed: false)
    }

    func session(_: ARSession, didRemove removed: [ARAnchor]) {
        handleAnchors(removed, removed: true)
    }

    private func handleAnchors(_ list: [ARAnchor], removed: Bool) {
        var images: [[String: Any]] = []
        var faces: [[String: Any]] = []
        var goneFaces: [String] = []
        for anchor in list {
            if let plane = anchor as? ARPlaneAnchor {
                if removed {
                    if let id = planeIds.removeValue(forKey: plane.identifier) { removedPlanes.append(id) }
                    planeVisuals.removeValue(forKey: plane.identifier)?.0.removeFromParent()
                } else {
                    pendingPlanes[plane.identifier] = plane
                    updatePlaneVisual(plane)
                }
            } else if let image = anchor as? ARImageAnchor, let name = image.referenceImage.name {
                if !removed { attachSpecial("image:\(name)", anchor: image) }
                images.append([
                    "name": name,
                    "pose": UArConvert.pose(image.transform),
                    "width": Double(image.referenceImage.physicalSize.width * image.estimatedScaleFactor),
                    "height": Double(image.referenceImage.physicalSize.height * image.estimatedScaleFactor),
                    "tracking": removed ? "notAvailable" : (image.isTracked ? "normal" : "limited"),
                ])
            } else if let object = anchor as? ARObjectAnchor, let name = object.referenceObject.name {
                if !removed { attachSpecial("image:\(name)", anchor: object) }
                images.append([
                    "name": name,
                    "pose": UArConvert.pose(object.transform),
                    "width": Double(object.referenceObject.extent.x),
                    "height": Double(object.referenceObject.extent.z),
                    "tracking": removed ? "notAvailable" : "normal",
                ])
            } else if let face = anchor as? ARFaceAnchor {
                let id = faceIds[face.identifier] ?? newId("f")
                faceIds[face.identifier] = id
                if removed {
                    faceIds.removeValue(forKey: face.identifier)
                    specialAnchors.removeValue(forKey: "face:\(id)")?.removeFromParent()
                    goneFaces.append(id)
                    continue
                }
                attachSpecial("face:\(id)", anchor: face)
                if specialAnchors["face"] == nil || faceIds.count == 1 { specialAnchors["face"] = specialAnchors["face:\(id)"] }
                faces.append(faceMap(face, id: id))
                if config["showFaceMesh"] as? Bool == true { updateFaceMesh(face, id: id) }
            } else if let body = anchor as? ARBodyAnchor {
                let now = CACurrentMediaTime()
                if removed {
                    emit(["type": "body", "body": nil])
                } else if now - lastBodyEmit > 1.0 / 30 {
                    lastBodyEmit = now
                    emit(["type": "body", "body": bodyMap(body)])
                }
            }
        }
        if !images.isEmpty { emit(["type": "images", "updated": images]) }
        let now = CACurrentMediaTime()
        if !goneFaces.isEmpty || (!faces.isEmpty && now - lastFaceEmit > 1.0 / 30) {
            lastFaceEmit = now
            emit(["type": "faces", "updated": faces, "removed": goneFaces])
        }
    }

    private func attachSpecial(_ key: String, anchor: ARAnchor) {
        guard let arView, specialAnchors[key] == nil else { return }
        let entity = AnchorEntity(anchor: anchor)
        arView.scene.addAnchor(entity)
        specialAnchors[key] = entity
        for record in nodes.values where record.anchorId == key || (key.hasPrefix("face:") && record.anchorId == "face") {
            attach(record)
        }
    }

    private func planeId(_ plane: ARPlaneAnchor) -> String {
        if let id = planeIds[plane.identifier] { return id }
        let id = newId("p")
        planeIds[plane.identifier] = id
        return id
    }

    private func classification(_ plane: ARPlaneAnchor) -> String {
        guard ARPlaneAnchor.isClassificationSupported else { return plane.alignment == .vertical ? "wall" : "none" }
        switch plane.classification {
        case .wall: return "wall"
        case .floor: return "floor"
        case .ceiling: return "ceiling"
        case .table: return "table"
        case .seat: return "seat"
        case .door: return "door"
        case .window: return "window"
        default: return "none"
        }
    }

    private func planeType(_ plane: ARPlaneAnchor) -> String {
        if plane.alignment == .vertical { return "vertical" }
        return classification(plane) == "ceiling" ? "horizontalDown" : "horizontalUp"
    }

    private func planeMap(_ plane: ARPlaneAnchor) -> [String: Any] {
        var center = plane.transform
        center.columns.3 = plane.transform * SIMD4<Float>(plane.center.x, plane.center.y, plane.center.z, 1)
        let polygon = plane.geometry.boundaryVertices.flatMap { [Double($0.x - plane.center.x), Double($0.z - plane.center.z)] }
        return [
            "id": planeId(plane),
            "type": planeType(plane),
            "classification": classification(plane),
            "pose": UArConvert.pose(center),
            "extent": [Double(plane.extent.x), Double(plane.extent.z)],
            "polygon": polygon,
            "tracking": "normal",
        ]
    }

    private func updatePlaneVisual(_ plane: ARPlaneAnchor) {
        guard let arView else { return }
        let style = config["planeStyle"] as? String ?? "grid"
        guard style != "hidden" else { return }
        let now = CACurrentMediaTime()
        if let visual = planeVisuals[plane.identifier], now - visual.2 < 0.25 { return }
        guard let mesh = UArMeshes.polygon(plane.geometry.boundaryVertices, tile: style == "dots" ? 10 : 8) else { return }
        if let visual = planeVisuals[plane.identifier] {
            visual.1.model?.mesh = mesh
            planeVisuals[plane.identifier] = (visual.0, visual.1, now)
            return
        }
        if planeTextureCache == nil { planeTextureCache = UArMeshes.planeTexture(style: style, color: UArConvert.color(config["planeColor"], 0x80FF_FFFF)) }
        var material = UnlitMaterial()
        if let texture = planeTextureCache {
            material.color = .init(tint: .white, texture: .init(texture, sampler: UArMeshes.sampler()))
        } else {
            material.color = .init(tint: UArConvert.color(config["planeColor"], 0x80FF_FFFF))
        }
        material.blending = .transparent(opacity: .init(floatLiteral: 1))
        let entity = ModelEntity(mesh: mesh, materials: [material])
        let anchor = AnchorEntity(anchor: plane)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        planeVisuals[plane.identifier] = (anchor, entity, now)
    }

    private func faceMap(_ face: ARFaceAnchor, id: String) -> [String: Any] {
        var shapes: [String: Double] = [:]
        for (key, value) in face.blendShapes { shapes[key.rawValue] = value.doubleValue }
        let look = face.transform * SIMD4<Float>(face.lookAtPoint.x, face.lookAtPoint.y, face.lookAtPoint.z, 1)
        return [
            "id": id,
            "pose": UArConvert.pose(face.transform),
            "regions": [
                "leftEye": UArConvert.pose(face.transform * face.leftEyeTransform),
                "rightEye": UArConvert.pose(face.transform * face.rightEyeTransform),
            ],
            "blendShapes": shapes,
            "lookAt": [Double(look.x), Double(look.y), Double(look.z)],
        ]
    }

    private func updateFaceMesh(_ face: ARFaceAnchor, id: String) {
        let now = CACurrentMediaTime()
        if let existing = faceMeshes[face.identifier], now - existing.1 < 1.0 / 15 { return }
        let geometry = face.geometry
        var descriptor = MeshDescriptor(name: "face")
        descriptor.positions = MeshBuffers.Positions(geometry.vertices)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(geometry.textureCoordinates)
        descriptor.primitives = .triangles(geometry.triangleIndices.map { UInt32($0) })
        guard let mesh = try? MeshResource.generate(from: [descriptor]) else { return }
        if let existing = faceMeshes[face.identifier] {
            existing.0.model?.mesh = mesh
            faceMeshes[face.identifier] = (existing.0, now)
            return
        }
        var material = UnlitMaterial(color: UArConvert.color(config["faceMeshColor"], 0x55FF_FFFF))
        material.blending = .transparent(opacity: .init(floatLiteral: Float(UArConvert.color(config["faceMeshColor"], 0x55FF_FFFF).cgColor.alpha)))
        let entity = ModelEntity(mesh: mesh, materials: [material])
        specialAnchors["face:\(id)"]?.addChild(entity)
        faceMeshes[face.identifier] = (entity, now)
    }

    private func bodyMap(_ body: ARBodyAnchor) -> [String: Any] {
        var joints: [String: [Double]] = [:]
        var screen: [String: [Double]] = [:]
        let names = body.skeleton.definition.jointNames
        let transforms = body.skeleton.jointModelTransforms
        let size = arView?.bounds.size ?? .zero
        for (index, name) in names.enumerated() where index < transforms.count {
            let world = body.transform * transforms[index]
            let p = UArConvert.translation(world)
            joints[name] = [Double(p.x), Double(p.y), Double(p.z)]
            if let projected = arView?.project(p), size.width > 0 {
                screen[name] = [Double(projected.x / size.width), Double(projected.y / size.height)]
            }
        }
        return ["pose": UArConvert.pose(body.transform), "joints": joints, "screen": screen]
    }

    // -------------------------------------------------------------------------
    // Anchors
    // -------------------------------------------------------------------------

    private func anchorEntity(_ id: String) -> Entity? {
        if id == "camera" {
            if specialAnchors["camera"] == nil, let arView {
                let camera = AnchorEntity(.camera)
                arView.scene.addAnchor(camera)
                specialAnchors["camera"] = camera
            }
            return specialAnchors["camera"]
        }
        if let special = specialAnchors[id] { return special }
        return anchors[id]?.root
    }

    private func anchorMap(_ record: UArAnchorRecord) -> [String: Any] {
        let matrix = record.arAnchor?.transform ?? record.entity.transformMatrix(relativeTo: nil)
        return [
            "id": record.id,
            "pose": UArConvert.pose(matrix),
            "type": record.type,
            "tracking": "normal",
            "cloudId": record.cloudId as Any,
        ]
    }

    private func emitAnchors() {
        var updated: [[String: Any]] = []
        for record in anchors.values {
            let matrix = record.arAnchor?.transform ?? record.entity.transformMatrix(relativeTo: nil)
            let position = UArConvert.translation(matrix)
            let state = record.entity.isAnchored ? "normal" : "limited"
            if record.lastSent == nil || simd_distance(record.lastSent!, position) > 0.002 || record.lastState != state {
                record.lastSent = position
                record.lastState = state
                var map = anchorMap(record)
                map["tracking"] = state
                updated.append(map)
            }
        }
        if !updated.isEmpty { emit(["type": "anchors", "updated": updated, "removed": [String]()]) }
    }

    func addAnchor(id: String, pose: Any?, type: String = "world") -> [String: Any] {
        let matrix = UArConvert.matrix(pose: pose)
        if let old = anchors.removeValue(forKey: id) { removeAnchorRecord(old) }
        let record: UArAnchorRecord
        if isViewer || arView == nil {
            let entity = AnchorEntity(world: matrix)
            arView?.scene.addAnchor(entity)
            record = UArAnchorRecord(id: id, arAnchor: nil, entity: entity, type: type)
        } else {
            let anchor = ARAnchor(name: "u:\(id)", transform: matrix)
            arView?.session.add(anchor: anchor)
            let entity = AnchorEntity(anchor: anchor)
            arView?.scene.addAnchor(entity)
            record = UArAnchorRecord(id: id, arAnchor: anchor, entity: entity, type: type)
        }
        anchors[id] = record
        for node in nodes.values where node.anchorId == id { attach(node) }
        return anchorMap(record)
    }

    func updateAnchor(id: String, pose: Any?) {
        guard let record = anchors[id] else { return }
        let matrix = UArConvert.matrix(pose: pose)
        let children = Array(record.root.children)
        if let old = record.arAnchor, let arView {
            arView.session.remove(anchor: old)
            let anchor = ARAnchor(name: "u:\(id)", transform: matrix)
            arView.session.add(anchor: anchor)
            let entity = AnchorEntity(anchor: anchor)
            arView.scene.addAnchor(entity)
            record.entity.removeFromParent()
            let next = UArAnchorRecord(id: id, arAnchor: anchor, entity: entity, type: record.type)
            next.root.transform = record.root.transform
            for child in children { next.root.addChild(child) }
            anchors[id] = next
        } else {
            record.entity.setTransformMatrix(matrix, relativeTo: nil)
        }
    }

    private func removeAnchorRecord(_ record: UArAnchorRecord) {
        if let anchor = record.arAnchor { arView?.session.remove(anchor: anchor) }
        record.entity.removeFromParent()
    }

    func removeAnchor(id: String, removeNodes: Bool) {
        guard let record = anchors.removeValue(forKey: id) else { return }
        if removeNodes {
            for node in nodes.values where node.anchorId == id { removeNode(node.id) }
        }
        removeAnchorRecord(record)
        emit(["type": "anchors", "updated": [[String: Any]](), "removed": [id]])
    }

    func addGeoAnchor(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let arView, configuration is ARGeoTrackingConfiguration else {
            result(FlutterError(code: "unsupported", message: "Location anchors need geo tracking", details: nil))
            return
        }
        let id = args["id"] as? String ?? newId("g")
        let coordinate = CLLocationCoordinate2D(latitude: (args["latitude"] as? NSNumber)?.doubleValue ?? 0, longitude: (args["longitude"] as? NSNumber)?.doubleValue ?? 0)
        let mode = args["altitudeMode"] as? String ?? "terrain"
        let anchor = mode == "absolute"
            ? ARGeoAnchor(name: "u:\(id)", coordinate: coordinate, altitude: (args["altitude"] as? NSNumber)?.doubleValue ?? 0)
            : ARGeoAnchor(name: "u:\(id)", coordinate: coordinate)
        arView.session.add(anchor: anchor)
        let entity = AnchorEntity(anchor: anchor)
        arView.scene.addAnchor(entity)
        let record = UArAnchorRecord(id: id, arAnchor: anchor, entity: entity, type: mode == "absolute" ? "geo" : "terrain")
        let heading = Float((args["heading"] as? NSNumber)?.doubleValue ?? 0) * .pi / 180
        record.root.orientation = simd_quatf(angle: -heading, axis: SIMD3<Float>(0, 1, 0))
        if mode != "absolute" { record.root.position = SIMD3<Float>(0, UArConvert.float(args["altitude"], 0), 0) }
        anchors[id] = record
        for node in nodes.values where node.anchorId == id { attach(node) }
        result(anchorMap(record))
    }

    func checkVps(latitude: Double, longitude: Double, result: @escaping FlutterResult) {
        guard ARGeoTrackingConfiguration.isSupported else {
            result("unavailable")
            return
        }
        ARGeoTrackingConfiguration.checkAvailability(at: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) { available, _ in
            DispatchQueue.main.async { result(available ? "available" : "unavailable") }
        }
    }

    // -------------------------------------------------------------------------
    // Hit testing
    // -------------------------------------------------------------------------

    private func hitMap(_ hit: ARRaycastResult) -> [String: Any] {
        let distance = simd_distance(UArConvert.translation(hit.worldTransform), UArConvert.translation(cameraMatrix))
        var map: [String: Any] = [
            "pose": UArConvert.pose(hit.worldTransform),
            "distance": Double(distance),
            "type": hit.target == .estimatedPlane ? "estimated" : "plane",
            "classification": "none",
        ]
        if let plane = hit.anchor as? ARPlaneAnchor {
            map["trackableId"] = planeId(plane)
            map["planeType"] = planeType(plane)
            map["classification"] = classification(plane)
        } else if hit.targetAlignment == .vertical {
            map["planeType"] = "vertical"
        } else if hit.targetAlignment == .horizontal {
            map["planeType"] = "horizontalUp"
        }
        return map
    }

    func hitTest(x: CGFloat, y: CGFloat, types: [String]) -> [[String: Any]] {
        guard let arView, !isViewer else { return [] }
        let point = CGPoint(x: x * arView.bounds.width, y: y * arView.bounds.height)
        var results: [ARRaycastResult] = []
        if types.contains("plane") { results += arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .any) }
        if types.contains(where: { ["estimated", "point", "depth", "instant", "mesh"].contains($0) }) {
            results += arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any)
        }
        return results.map(hitMap).sorted { ($0["distance"] as? Double ?? 0) < ($1["distance"] as? Double ?? 0) }
    }

    func hitTestNodes(x: CGFloat, y: CGFloat) -> [String: Any]? {
        guard let arView else { return nil }
        let point = CGPoint(x: x * arView.bounds.width, y: y * arView.bounds.height)
        for hit in arView.hitTest(point, query: .nearest, mask: .all) {
            var entity: Entity? = hit.entity
            while let current = entity {
                if current.name.hasPrefix("u-node:") {
                    let id = String(current.name.dropFirst(7))
                    if nodes[id]?.hittable == false { break }
                    let camera = UArConvert.translation(cameraMatrix)
                    return ["id": id, "position": [Double(hit.position.x), Double(hit.position.y), Double(hit.position.z)], "distance": Double(simd_distance(hit.position, camera))]
                }
                entity = current.parent
            }
        }
        return nil
    }

    // -------------------------------------------------------------------------
    // Nodes
    // -------------------------------------------------------------------------

    private func attach(_ record: UArNodeRecord) {
        var parent: Entity?
        if let parentId = record.parentId {
            parent = nodes[parentId]?.wrapper
        } else if let anchorId = record.anchorId {
            parent = anchorEntity(anchorId)
        } else {
            parent = worldAnchor
        }
        if let parent {
            if record.wrapper.parent !== parent { parent.addChild(record.wrapper) }
        } else {
            record.wrapper.removeFromParent()
        }
        for child in nodes.values where child.parentId == record.id { attach(child) }
    }

    private func applyTransform(_ record: UArNodeRecord) {
        let map = record.map
        record.wrapper.transform = Transform(scale: UArConvert.vector(map["scale"], 1), rotation: UArConvert.quaternion(map["rotation"]), translation: UArConvert.vector(map["position"]))
        record.wrapper.isEnabled = record.visible
    }

    private func material(_ map: [String: Any]?, texture: TextureResource? = nil) -> RealityKit.Material {
        let map = map ?? [:]
        if map["occluder"] as? Bool == true { return OcclusionMaterial() }
        let color = UArConvert.color(map["color"], 0xFFFF_FFFF)
        let opacity = UArConvert.float(map["opacity"], 1) * Float(color.cgColor.alpha)
        if map["unlit"] as? Bool == true || texture != nil {
            var material = UnlitMaterial()
            if let texture {
                material.color = .init(tint: color.withAlphaComponent(1), texture: .init(texture))
                material.blending = .transparent(opacity: .init(floatLiteral: opacity))
            } else {
                material.color = .init(tint: color.withAlphaComponent(1))
                if opacity < 1 { material.blending = .transparent(opacity: .init(floatLiteral: opacity)) }
            }
            if #available(iOS 18.0, *), map["doubleSided"] as? Bool == true { material.faceCulling = .none }
            return material
        }
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color.withAlphaComponent(1))
        material.metallic = .init(floatLiteral: UArConvert.float(map["metallic"], 0))
        material.roughness = .init(floatLiteral: UArConvert.float(map["roughness"], 0.6))
        if map["emissive"] != nil { material.emissiveColor = .init(color: UArConvert.color(map["emissive"], 0)) }
        if opacity < 1 { material.blending = .transparent(opacity: .init(floatLiteral: opacity)) }
        if map["doubleSided"] as? Bool == true { material.faceCulling = .none }
        return material
    }

    private func sourceKey(_ map: [String: Any]) -> String {
        let source = map["source"] as? [String: Any]
        let ios = map["iosSource"] as? [String: Any]
        func describe(_ s: [String: Any]?) -> String {
            if let typed = s?["value"] as? FlutterStandardTypedData { return "bytes:\(typed.data.count):\(typed.data.hashValue)" }
            return "\(s?["kind"] ?? ""):\(s?["value"] ?? "")"
        }
        return "\(map["type"] ?? "")|\(describe(ios ?? source))|\(map["width"] ?? "")|\(map["height"] ?? "")|\(map["depth"] ?? "")|\(map["radius"] ?? "")|\(map["material"] ?? "")"
    }

    private func info(_ record: UArNodeRecord) -> [String: Any] {
        let bounds = record.wrapper.visualBounds(relativeTo: nil)
        let empty = bounds.isEmpty
        return [
            "id": record.id,
            "loaded": record.loaded,
            "min": empty ? [0.0, 0.0, 0.0] : [Double(bounds.min.x), Double(bounds.min.y), Double(bounds.min.z)],
            "max": empty ? [0.0, 0.0, 0.0] : [Double(bounds.max.x), Double(bounds.max.y), Double(bounds.max.z)],
            "animations": record.animationNames,
        ]
    }

    private func finish(_ record: UArNodeRecord, content: Entity, emitEvent: Bool) {
        record.content?.removeFromParent()
        record.content = content
        record.wrapper.addChild(content)
        normalize(record)
        if record.hittable { content.generateCollisionShapes(recursive: true) }
        if #available(iOS 18.0, *) {
            let casts = record.map["castShadow"] as? Bool != false && config["shadows"] as? Bool != false
            content.components.set(GroundingShadowComponent(castsShadow: casts))
        }
        record.loaded = true
        playConfiguredAnimation(record)
        if emitEvent {
            var event = info(record)
            event["type"] = "node"
            event["event"] = "loaded"
            emit(event)
        }
    }

    private func normalize(_ record: UArNodeRecord) {
        guard let content = record.content, record.type == "model" else { return }
        content.transform = Transform()
        let bounds = content.visualBounds(relativeTo: content)
        guard !bounds.isEmpty else { return }
        let size = bounds.extents
        let largest = max(size.x, max(size.y, size.z))
        var scale: Float = 1
        if let fit = (record.map["fitSize"] as? NSNumber)?.floatValue, largest > 0 {
            scale = fit / largest
        } else if largest > 20 {
            // Older USDZ exports are in centimetres without metersPerUnit, which
            // RealityKit reads as metres: a 1.9 m figure arrives 190 m tall.
            scale = 0.01
        }
        var offset = SIMD3<Float>(0, 0, 0)
        switch record.map["pivot"] as? String {
        case "bottom": offset = SIMD3<Float>(-bounds.center.x, -bounds.min.y, -bounds.center.z)
        case "center": offset = -bounds.center
        default: break
        }
        content.transform = Transform(scale: SIMD3<Float>(repeating: scale), rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1), translation: offset * scale)
    }

    private func playConfiguredAnimation(_ record: UArNodeRecord) {
        guard let animation = record.map["animation"] as? [String: Any], animation["autoplay"] as? Bool != false else { return }
        playAnimation(record, name: animation["name"] as? String, index: animation["index"] as? Int ?? 0, loop: animation["loop"] as? Bool != false, speed: UArConvert.float(animation["speed"], 1))
    }

    func playAnimation(_ record: UArNodeRecord, name: String?, index: Int, loop: Bool, speed: Float) {
        if let animator = record.animator {
            animator.play(name: name, index: index, loop: loop, speed: speed)
            return
        }
        guard let content = record.content else { return }
        let available = content.availableAnimations
        guard !available.isEmpty else { return }
        let selected: [AnimationResource] = name == "*" ? available : [available[min(max(index, 0), available.count - 1)]]
        for animation in selected {
            let controller = content.playAnimation(loop ? animation.repeat() : animation, transitionDuration: 0, startsPaused: false)
            controller.speed = speed
        }
    }

    func addNode(_ map: [String: Any], result: @escaping FlutterResult) {
        guard let id = map["id"] as? String else {
            result(FlutterError(code: "notFound", message: "Node id missing", details: nil))
            return
        }
        let record = nodes[id] ?? UArNodeRecord(id: id)
        let key = sourceKey(map)
        let reuse = nodes[id] != nil && record.sourceKey == key && record.loaded
        record.map = map
        nodes[id] = record
        applyTransform(record)
        attach(record)
        if reuse {
            normalize(record)
            result(info(record))
            return
        }
        record.release()
        record.loaded = false
        record.sourceKey = key
        record.loadToken += 1
        let token = record.loadToken
        let materialMap = map["material"] as? [String: Any]
        let width = UArConvert.float(map["width"], 0.1)
        let height = UArConvert.float(map["height"], 0.1)
        let depth = UArConvert.float(map["depth"], 0.1)
        let radius = UArConvert.float(map["radius"], 0.05)
        switch record.type {
        case "box":
            finish(record, content: ModelEntity(mesh: .generateBox(size: SIMD3<Float>(width, height, depth)), materials: [material(materialMap)]), emitEvent: false)
            result(info(record))
        case "sphere":
            finish(record, content: ModelEntity(mesh: .generateSphere(radius: radius), materials: [material(materialMap)]), emitEvent: false)
            result(info(record))
        case "plane":
            finish(record, content: ModelEntity(mesh: .generatePlane(width: width, height: height), materials: [material(materialMap)]), emitEvent: false)
            result(info(record))
        case "cylinder", "cone":
            if let mesh = UArMeshes.cylinder(radius: radius, height: height, cone: record.type == "cone") {
                finish(record, content: ModelEntity(mesh: mesh, materials: [material(materialMap)]), emitEvent: false)
            }
            result(info(record))
        case "group":
            record.loaded = true
            result(info(record))
        case "image":
            result(["id": id, "loaded": false])
            loader.data(map["source"] as? [String: Any]) { [weak self] data, _, error in
                guard let self, record.loadToken == token else { return }
                guard let data, let source = CGImageSourceCreateWithData(data as CFData, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
                      let texture = try? TextureResource.generate(from: image, options: .init(semantic: .color))
                else {
                    self.emit(["type": "node", "id": id, "event": "error", "message": error ?? "Unreadable image"])
                    return
                }
                let aspect = Float(image.height) / Float(max(image.width, 1))
                let h = height > 0 ? height : width * aspect
                let entity = ModelEntity(mesh: .generatePlane(width: width, height: h), materials: [self.material(materialMap, texture: texture)])
                self.finish(record, content: entity, emitEvent: true)
            }
        case "video":
            result(["id": id, "loaded": false])
            loader.file(map["source"] as? [String: Any]) { [weak self] url, error in
                guard let self, record.loadToken == token else { return }
                guard let url else {
                    self.emit(["type": "node", "id": id, "event": "error", "message": error ?? "Video not found"])
                    return
                }
                let options = map["video"] as? [String: Any] ?? [:]
                let player = AVPlayer(url: url)
                player.isMuted = options["muted"] as? Bool != false
                player.volume = UArConvert.float(options["volume"], 1)
                record.player = player
                let loop = options["loop"] as? Bool != false
                record.endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self, weak player] _ in
                    self?.emit(["type": "node", "id": id, "event": "videoEnded"])
                    if loop {
                        player?.seek(to: .zero)
                        player?.play()
                    }
                }
                let entity = ModelEntity(mesh: .generatePlane(width: width, height: height), materials: [VideoMaterial(avPlayer: player)])
                self.finish(record, content: entity, emitEvent: true)
                if options["autoplay"] as? Bool != false { player.play() }
            }
        case "model":
            result(["id": id, "loaded": false])
            let source = (map["iosSource"] as? [String: Any]) ?? (map["source"] as? [String: Any])
            loadModel(record, source: source, token: token)
        default:
            result(FlutterError(code: "unsupported", message: "Unknown node type", details: nil))
        }
    }

    private func loadModel(_ record: UArNodeRecord, source: [String: Any]?, token: Int) {
        let ext = (source?["ext"] as? String ?? "").lowercased()
        let id = record.id
        loader.file(source) { [weak self] url, error in
            guard let self, record.loadToken == token else { return }
            guard let url else {
                self.emit(["type": "node", "id": id, "event": "error", "message": error ?? "Model not found"])
                return
            }
            if ext == "glb" || ext == "gltf" {
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let data = try Data(contentsOf: url)
                        let asset = try UGltfAsset(data: data, baseURL: url.deletingLastPathComponent())
                        DispatchQueue.main.async {
                            guard record.loadToken == token else { return }
                            let (root, entities) = asset.build()
                            let animator = UGltfAnimator(asset: asset, entities: entities)
                            animator.onFinished = { [weak self] in self?.emit(["type": "node", "id": id, "event": "animationEnded"]) }
                            record.animator = animator
                            record.animationNames = animator.names
                            self.finish(record, content: root, emitEvent: true)
                        }
                    } catch {
                        DispatchQueue.main.async { self.emit(["type": "node", "id": id, "event": "error", "message": error.localizedDescription]) }
                    }
                }
                return
            }
            Entity.loadAsync(contentsOf: url).sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(failure) = completion {
                        self?.emit(["type": "node", "id": id, "event": "error", "message": failure.localizedDescription])
                    }
                },
                receiveValue: { [weak self] entity in
                    guard let self, record.loadToken == token else { return }
                    record.animationNames = entity.availableAnimations.indices.map { "animation\($0)" }
                    self.finish(record, content: entity, emitEvent: true)
                }
            ).store(in: &self.loads)
        }
    }

    func transformNode(_ args: [String: Any]) {
        guard let id = args["id"] as? String, let record = nodes[id] else { return }
        var map = record.map
        if args["world"] as? Bool == true {
            if let position = args["position"] as? [Any] { record.wrapper.setPosition(UArConvert.vector(position), relativeTo: nil) }
            if let rotation = args["rotation"] as? [Any] { record.wrapper.setOrientation(UArConvert.quaternion(rotation), relativeTo: nil) }
            let local = record.wrapper.transform
            map["position"] = [Double(local.translation.x), Double(local.translation.y), Double(local.translation.z)]
            map["rotation"] = [Double(local.rotation.vector.x), Double(local.rotation.vector.y), Double(local.rotation.vector.z), Double(local.rotation.vector.w)]
        } else {
            if let position = args["position"] as? [Any] { map["position"] = position }
            if let rotation = args["rotation"] as? [Any] { map["rotation"] = rotation }
        }
        if let scale = args["scale"] as? [Any] { map["scale"] = scale }
        record.map = map
        applyTransform(record)
    }

    func removeNode(_ id: String) {
        guard let record = nodes.removeValue(forKey: id) else { return }
        record.release()
        record.wrapper.removeFromParent()
        for child in nodes.values where child.parentId == id { removeNode(child.id) }
    }

    func clearNodes() {
        nodes.values.forEach { $0.release(); $0.wrapper.removeFromParent() }
        nodes.removeAll()
    }

    func nodePose(_ id: String) -> [Double]? {
        guard let record = nodes[id], record.wrapper.parent != nil else { return nil }
        return UArConvert.pose(record.wrapper.transformMatrix(relativeTo: nil))
    }

    func node(_ id: String) -> UArNodeRecord? { nodes[id] }

    func setTracks(_ list: [[String: Any]]) {
        tracks = list
    }

    // -------------------------------------------------------------------------
    // Viewer camera
    // -------------------------------------------------------------------------

    func setOrbit(_ orbit: [String: Any]?) {
        config["orbit"] = orbit
        updateOrbit()
    }

    private func updateOrbit() {
        guard let camera = viewerCamera else { return }
        let orbit = config["orbit"] as? [String: Any] ?? [:]
        let yaw = UArConvert.float(orbit["yaw"], 30) * .pi / 180
        let pitch = UArConvert.float(orbit["pitch"], 15) * .pi / 180
        let distance = UArConvert.float(orbit["distance"], 1.5)
        let target = UArConvert.vector(orbit["target"])
        let eye = target + SIMD3<Float>(distance * cos(pitch) * sin(yaw), distance * sin(pitch), distance * cos(pitch) * cos(yaw))
        camera.look(at: target, from: eye, relativeTo: nil)
        camera.camera.fieldOfViewInDegrees = UArConvert.float(orbit["fov"], 45)
        camera.camera.near = max(0.005, distance * 0.01)
        camera.camera.far = distance * 50 + 50
    }

    // -------------------------------------------------------------------------
    // Capture
    // -------------------------------------------------------------------------

    func snapshot(format: String, quality: Int, result: @escaping FlutterResult) {
        guard let arView else {
            result(nil)
            return
        }
        arView.snapshot(saveToHDR: false) { image in
            guard let image else {
                result(nil)
                return
            }
            let data = format == "png" ? image.pngData() : image.jpegData(compressionQuality: CGFloat(quality) / 100)
            result(data.map { FlutterStandardTypedData(bytes: $0) })
        }
    }

    func startRecording(audio: Bool, result: @escaping FlutterResult) {
        let recorder = RPScreenRecorder.shared()
        recorder.isMicrophoneEnabled = audio
        recorder.startRecording { error in
            DispatchQueue.main.async {
                if let error {
                    result(FlutterError(code: "unknown", message: error.localizedDescription, details: nil))
                } else {
                    self.recordingStart = Date()
                    result(nil)
                }
            }
        }
    }

    func stopRecording(result: @escaping FlutterResult) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("u_ar_\(Int(Date().timeIntervalSince1970 * 1000)).mp4")
        RPScreenRecorder.shared().stopRecording(withOutput: url) { error in
            DispatchQueue.main.async {
                if let error {
                    result(FlutterError(code: "unknown", message: error.localizedDescription, details: nil))
                } else {
                    result(["path": url.path, "mime": "video/mp4", "duration": Int(Date().timeIntervalSince(self.recordingStart) * 1000)])
                }
            }
        }
    }

    /// Normalised captured-image → normalised-view transform for the current orientation.
    private func displayTransform(_ frame: ARFrame) -> CGAffineTransform {
        frame.displayTransform(for: interfaceOrientation(), viewportSize: arView?.bounds.size ?? .zero)
    }

    func cameraImage(maxSize: Int) -> [String: Any]? {
        guard let frame = arView?.session.currentFrame else { return nil }
        let buffer = frame.capturedImage
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) else { return nil }
        let width = CVPixelBufferGetWidthOfPlane(buffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(buffer, 0)
        let rowStride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
        var step = 1
        while width / step > maxSize || height / step > maxSize { step += 1 }
        let outW = width / step
        let outH = height / step
        var out = [UInt8](repeating: 0, count: outW * outH)
        let pointer = base.assumingMemoryBound(to: UInt8.self)
        for y in 0 ..< outH {
            let row = y * step * rowStride
            for x in 0 ..< outW { out[y * outW + x] = pointer[row + x * step] }
        }
        let t = displayTransform(frame)
        let s = CGFloat(step)
        let transform: [Double] = [
            Double(t.a * s / CGFloat(width)), Double(t.c * s / CGFloat(height)), Double(t.tx),
            Double(t.b * s / CGFloat(width)), Double(t.d * s / CGFloat(height)), Double(t.ty),
        ]
        return ["bytes": FlutterStandardTypedData(bytes: Data(out)), "width": outW, "height": outH, "stride": outW, "transform": transform]
    }

    private func viewCorners(_ observation: VNRectangleObservation, transform t: CGAffineTransform, orientation: CGImagePropertyOrientation) -> [Double] {
        return [observation.topLeft, observation.topRight, observation.bottomRight, observation.bottomLeft].flatMap { point -> [Double] in
            let u = point.x
            let v = 1 - point.y
            var raw = CGPoint(x: u, y: v)
            switch orientation {
            case .right: raw = CGPoint(x: v, y: 1 - u)
            case .left: raw = CGPoint(x: 1 - v, y: u)
            case .down: raw = CGPoint(x: 1 - u, y: 1 - v)
            default: break
            }
            let view = raw.applying(t)
            return [Double(view.x), Double(view.y)]
        }
    }

    private func visionOrientation() -> CGImagePropertyOrientation {
        switch interfaceOrientation() {
        case .portrait: return .right
        case .portraitUpsideDown: return .left
        case .landscapeLeft: return .down
        default: return .up
        }
    }

    func detectBarcodes(result: @escaping FlutterResult) {
        guard let frame = arView?.session.currentFrame else {
            result([Any]())
            return
        }
        let request = VNDetectBarcodesRequest()
        let transform = displayTransform(frame)
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .up)
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
            let codes: [[String: Any]] = (request.results ?? []).compactMap { observation in
                guard let text = observation.payloadStringValue else { return nil }
                return ["text": text, "format": observation.symbology.rawValue, "corners": self.viewCorners(observation, transform: transform, orientation: .up)]
            }
            DispatchQueue.main.async { result(codes) }
        }
    }

    func recognizeText(languages: [String], accurate: Bool, result: @escaping FlutterResult) {
        guard let frame = arView?.session.currentFrame else {
            result([Any]())
            return
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = accurate ? .accurate : .fast
        request.usesLanguageCorrection = true
        if !languages.isEmpty { request.recognitionLanguages = languages }
        let orientation = visionOrientation()
        let transform = displayTransform(frame)
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: orientation)
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
            let lines: [[String: Any]] = (request.results ?? []).compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return ["text": candidate.string, "confidence": Double(candidate.confidence), "corners": self.viewCorners(observation, transform: transform, orientation: orientation)]
            }
            DispatchQueue.main.async { result(lines) }
        }
    }

    func worldMap(result: @escaping FlutterResult) {
        guard let arView, !isViewer else {
            result(nil)
            return
        }
        arView.session.getCurrentWorldMap { map, error in
            DispatchQueue.main.async {
                guard let map, let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true) else {
                    result(FlutterError(code: "notFound", message: error?.localizedDescription ?? "World map not available yet", details: nil))
                    return
                }
                result(FlutterStandardTypedData(bytes: data))
            }
        }
    }

    func receiveCollaboration(_ data: Data) {
        guard let collaboration = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) else { return }
        arView?.session.update(with: collaboration)
    }
}

// =============================================================================
// Platform view factory
// =============================================================================

final class UArUnsupportedView: NSObject, FlutterPlatformView {
    private let placeholder = UIView()

    func view() -> UIView { placeholder }
}

final class UArViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private weak var handler: UArHandler?

    init(messenger: FlutterBinaryMessenger, handler: UArHandler) {
        self.messenger = messenger
        self.handler = handler
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        guard #available(iOS 15.0, *), let handler else { return UArUnsupportedView() }
        let session = UArSession(frame: frame, viewId: viewId, arguments: args, messenger: messenger, loader: handler.loader)
        handler.register(session, id: viewId)
        return session
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

// =============================================================================
// RoomPlan
// =============================================================================

#if canImport(RoomPlan)
    @available(iOS 16.0, *)
    final class UArRoomScanController: UIViewController, RoomCaptureViewDelegate {
        private var captureView: RoomCaptureView?
        private let options: [String: Any]
        private let completion: ([String: Any]?, String?) -> Void
        private var stopped = false
        private var finished = false

        init(options: [String: Any], completion: @escaping ([String: Any]?, String?) -> Void) {
            self.options = options
            self.completion = completion
            super.init(nibName: nil, bundle: nil)
            modalPresentationStyle = .fullScreen
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            let capture = RoomCaptureView(frame: view.bounds)
            capture.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            capture.delegate = self
            view.addSubview(capture)
            captureView = capture
            let done = button(options["done"] as? String ?? "Done", action: #selector(donePressed))
            let cancel = button(options["cancel"] as? String ?? "Cancel", action: #selector(cancelPressed))
            let stack = UIStackView(arrangedSubviews: [cancel, UIView(), done])
            stack.axis = .horizontal
            stack.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            ])
        }

        private func button(_ title: String, action: Selector) -> UIButton {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .boldSystemFont(ofSize: 17)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor.black.withAlphaComponent(0.55)
            button.layer.cornerRadius = 22
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 22, bottom: 12, right: 22)
            button.addTarget(self, action: action, for: .touchUpInside)
            return button
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            captureView?.captureSession.run(configuration: RoomCaptureSession.Configuration())
        }

        @objc private func donePressed() {
            if !stopped {
                stopped = true
                captureView?.captureSession.stop()
            }
        }

        @objc private func cancelPressed() {
            captureView?.captureSession.stop()
            complete(nil, "cancelled")
        }

        func captureView(shouldPresent _: CapturedRoomData, error _: Error?) -> Bool { true }

        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            if let error {
                complete(nil, error.localizedDescription)
                return
            }
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("u_ar_room_\(Int(Date().timeIntervalSince1970))", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var result: [String: Any] = [
                "walls": processedResult.walls.map { surface($0) },
                "doors": processedResult.doors.map { surface($0) },
                "windows": processedResult.windows.map { surface($0) },
                "openings": processedResult.openings.map { surface($0) },
                "objects": processedResult.objects.map { object in
                    [
                        "category": "\(object.category)",
                        "dimensions": [Double(object.dimensions.x), Double(object.dimensions.y), Double(object.dimensions.z)],
                        "pose": UArConvert.pose(object.transform),
                        "confidence": "\(object.confidence)",
                    ] as [String: Any]
                },
            ]
            if #available(iOS 17.0, *) { result["floors"] = processedResult.floors.map { surface($0) } }
            if options["exportModel"] as? Bool != false {
                let usdz = directory.appendingPathComponent("room.usdz")
                if (try? processedResult.export(to: usdz, exportOptions: options["parametric"] as? Bool == false ? .mesh : .parametric)) != nil {
                    result["usdz"] = usdz.path
                }
            }
            let json = directory.appendingPathComponent("room.json")
            if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted]), (try? data.write(to: json)) != nil {
                result["json"] = json.path
            }
            complete(result, nil)
        }

        private func surface(_ surface: CapturedRoom.Surface) -> [String: Any] {
            [
                "category": "\(surface.category)",
                "dimensions": [Double(surface.dimensions.x), Double(surface.dimensions.y), Double(surface.dimensions.z)],
                "pose": UArConvert.pose(surface.transform),
                "confidence": "\(surface.confidence)",
            ]
        }

        private func complete(_ result: [String: Any]?, _ error: String?) {
            guard !finished else { return }
            finished = true
            dismiss(animated: true) { self.completion(result, error) }
        }
    }
#endif

// =============================================================================
// Object Capture
// =============================================================================

@available(iOS 17.0, *)
@MainActor
final class UArObjectCaptureModel: ObservableObject {
    @Published var state = "initializing"
    @Published var progress: Double = 0
    let session = ObjectCaptureSession()
    private let root: URL
    private let images: URL
    private let detail: String
    private let completion: ([String: Any]?, String?) -> Void
    private var done = false
    var dismiss: (() -> Void)?

    init(detail: String, completion: @escaping ([String: Any]?, String?) -> Void) {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("u_ar_capture_\(Int(Date().timeIntervalSince1970))", isDirectory: true)
        images = root.appendingPathComponent("Images", isDirectory: true)
        self.detail = detail
        self.completion = completion
        try? FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)
        let checkpoint = root.appendingPathComponent("Checkpoint", isDirectory: true)
        try? FileManager.default.createDirectory(at: checkpoint, withIntermediateDirectories: true)
        var configuration = ObjectCaptureSession.Configuration()
        configuration.checkpointDirectory = checkpoint
        session.start(imagesDirectory: images, configuration: configuration)
        Task { @MainActor [weak self] in
            guard let self else { return }
            for await state in self.session.stateUpdates { self.handle(state) }
        }
    }

    private func handle(_ state: ObjectCaptureSession.CaptureState) {
        switch state {
        case .ready: self.state = "ready"
        case .detecting: self.state = "detecting"
        case .capturing: self.state = "capturing"
        case .finishing: self.state = "finishing"
        case .completed:
            self.state = "processing"
            reconstruct()
        case let .failed(error): finish(nil, error.localizedDescription)
        default: break
        }
    }

    func primary() {
        switch state {
        case "ready": _ = session.startDetecting()
        case "detecting": session.startCapturing()
        case "capturing": session.finish()
        default: break
        }
    }

    func cancel() {
        session.cancel()
        finish(nil, "cancelled")
    }

    private func reconstruct() {
        let output = root.appendingPathComponent("model.usdz")
        // iOS only supports `.reduced`; higher detail levels are macOS-only.
        let level: PhotogrammetrySession.Request.Detail = .reduced
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let photogrammetry = try PhotogrammetrySession(input: self.images, configuration: PhotogrammetrySession.Configuration())
                try photogrammetry.process(requests: [.modelFile(url: output, detail: level)])
                for try await event in photogrammetry.outputs {
                    switch event {
                    case let .requestProgress(_, fractionComplete):
                        self.progress = fractionComplete
                    case let .requestError(_, error):
                        self.finish(nil, error.localizedDescription)
                        return
                    case .processingComplete:
                        self.finish(["model": output.path, "images": self.images.path], nil)
                        return
                    default:
                        break
                    }
                }
            } catch {
                self.finish(nil, error.localizedDescription)
            }
        }
    }

    private func finish(_ result: [String: Any]?, _ error: String?) {
        guard !done else { return }
        done = true
        let completion = completion
        if let dismiss {
            dismiss()
            completion(result, error)
        } else {
            completion(result, error)
        }
    }
}

@available(iOS 17.0, *)
struct UArObjectCaptureScreen: View {
    @ObservedObject var model: UArObjectCaptureModel
    let labels: [String: String]

    private var primaryLabel: String {
        switch model.state {
        case "ready": return labels["continue"] ?? "Continue"
        case "detecting": return labels["start"] ?? "Start capture"
        case "capturing": return labels["finish"] ?? "Finish"
        default: return labels["processing"] ?? "Processing"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if model.state == "processing" || model.state == "finishing" {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView(value: model.progress)
                        .progressViewStyle(.linear)
                        .tint(.white)
                    Text(labels["processing"] ?? "Processing")
                        .foregroundColor(.white)
                }
                .padding(32)
                .frame(maxHeight: .infinity)
            } else {
                ObjectCaptureView(session: model.session)
                    .ignoresSafeArea()
            }
            HStack {
                Button(labels["cancel"] ?? "Cancel") { model.cancel() }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.55))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                Spacer()
                if ["ready", "detecting", "capturing"].contains(model.state) {
                    Button(primaryLabel) { model.primary() }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
            .padding(20)
        }
    }
}

// =============================================================================
// Method channel front end
// =============================================================================

public final class UArHandler: NSObject, CLLocationManagerDelegate, QLPreviewControllerDataSource {
    private let channel: FlutterMethodChannel
    let loader: UArSourceLoader
    private var sessions: [Int64: AnyObject] = [:]
    private let locationManager = CLLocationManager()
    private var locationWaiters: [() -> Void] = []
    private var previewItem: QLPreviewItem?
    private var activeController: AnyObject?

    public init(registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "u/ar", binaryMessenger: registrar.messenger())
        loader = UArSourceLoader(lookup: { registrar.lookupKey(forAsset: $0) })
        super.init()
        locationManager.delegate = self
        registrar.register(UArViewFactory(messenger: registrar.messenger(), handler: self), withId: "u/ar_view")
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    func register(_ session: AnyObject, id: Int64) {
        sessions[id] = session
    }

    public func dispose() {
        if #available(iOS 15.0, *) { sessions.values.compactMap { $0 as? UArSession }.forEach { $0.dispose() } }
        sessions.removeAll()
        channel.setMethodCallHandler(nil)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = (call.arguments as? [String: Any]) ?? [:]
        switch call.method {
        case "availability", "requestInstall":
            result(availability())
        case "permissionStatus":
            result(permissionMap())
        case "requestPermission":
            requestPermission(location: args["location"] as? Bool == true, microphone: args["microphone"] as? Bool == true, result: result)
        case "openSettings":
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                result(false)
                return
            }
            UIApplication.shared.open(url)
            result(true)
        case "openNativeViewer":
            openQuickLook(args, result: result)
        case "scanRoom":
            scanRoom(args, result: result)
        case "captureObject":
            captureObject(args, result: result)
        case "create":
            result(FlutterError(code: "unsupported", message: "iOS sessions are created by UArView", details: nil))
        default:
            guard #available(iOS 15.0, *) else {
                result(FlutterError(code: "unsupported", message: "AR needs iOS 15 or newer", details: nil))
                return
            }
            handleSession(call.method, args: args, result: result)
        }
    }

    @available(iOS 15.0, *)
    private func handleSession(_ method: String, args: [String: Any], result: @escaping FlutterResult) {
        let id = Int64((args["sessionId"] as? NSNumber)?.intValue ?? -1)
        if method == "dispose" {
            (sessions.removeValue(forKey: id) as? UArSession)?.dispose()
            result(nil)
            return
        }
        guard let session = sessions[id] as? UArSession else {
            if method == "checkVps" {
                ARGeoTrackingConfiguration.checkAvailability(at: CLLocationCoordinate2D(latitude: (args["latitude"] as? NSNumber)?.doubleValue ?? 0, longitude: (args["longitude"] as? NSNumber)?.doubleValue ?? 0)) { available, _ in
                    DispatchQueue.main.async { result(available ? "available" : "unavailable") }
                }
                return
            }
            result(FlutterError(code: "notFound", message: "AR session not found", details: nil))
            return
        }
        let x = CGFloat((args["x"] as? NSNumber)?.doubleValue ?? 0.5)
        let y = CGFloat((args["y"] as? NSNumber)?.doubleValue ?? 0.5)
        switch method {
        case "start":
            session.start(result: result)
        case "resize":
            result(nil)
        case "pause":
            session.pause()
            result(nil)
        case "resume":
            session.resume()
            result(nil)
        case "reset":
            session.reset(keepNodes: args["keepNodes"] as? Bool == true)
            result(nil)
        case "updateConfig":
            session.updateConfig(args["config"] as? [String: Any] ?? [:], result: result)
        case "hitTest":
            result(session.hitTest(x: x, y: y, types: args["types"] as? [String] ?? ["plane", "estimated"]))
        case "hitTestNodes":
            result(session.hitTestNodes(x: x, y: y))
        case "addAnchor":
            result(session.addAnchor(id: args["id"] as? String ?? UUID().uuidString, pose: args["pose"], type: args["name"] as? String == "geo" ? "geo" : "world"))
        case "updateAnchor":
            session.updateAnchor(id: args["id"] as? String ?? "", pose: args["pose"])
            result(nil)
        case "removeAnchor":
            session.removeAnchor(id: args["id"] as? String ?? "", removeNodes: args["removeNodes"] as? Bool != false)
            result(nil)
        case "addNode", "updateNode":
            session.addNode(args["node"] as? [String: Any] ?? [:], result: result)
        case "transformNode":
            session.transformNode(args)
            result(nil)
        case "removeNode":
            session.removeNode(args["id"] as? String ?? "")
            result(nil)
        case "clearNodes":
            session.clearNodes()
            result(nil)
        case "nodePose":
            result(session.nodePose(args["id"] as? String ?? ""))
        case "playAnimation":
            if let record = session.node(args["id"] as? String ?? "") {
                session.playAnimation(record, name: args["name"] as? String, index: args["index"] as? Int ?? 0, loop: args["loop"] as? Bool != false, speed: UArConvert.float(args["speed"], 1))
            }
            result(nil)
        case "stopAnimation":
            if let record = session.node(args["id"] as? String ?? "") {
                record.animator?.playing = false
                record.content?.stopAllAnimations()
            }
            result(nil)
        case "controlVideo":
            if let player = session.node(args["id"] as? String ?? "")?.player {
                if let seek = args["seek"] as? NSNumber { player.seek(to: CMTime(value: seek.int64Value, timescale: 1000)) }
                if let volume = args["volume"] as? NSNumber { player.volume = volume.floatValue }
                if let play = args["play"] as? Bool { play ? player.play() : player.pause() }
            }
            result(nil)
        case "setTracks":
            session.setTracks(args["tracks"] as? [[String: Any]] ?? [])
            result(nil)
        case "setOrbit":
            session.setOrbit(args["orbit"] as? [String: Any])
            result(nil)
        case "snapshot":
            session.snapshot(format: args["format"] as? String ?? "jpeg", quality: args["quality"] as? Int ?? 92, result: result)
        case "startRecording":
            session.startRecording(audio: args["audio"] as? Bool == true, result: result)
        case "stopRecording":
            session.stopRecording(result: result)
        case "cameraImage":
            result(session.cameraImage(maxSize: args["maxSize"] as? Int ?? 1024))
        case "detectBarcodes":
            session.detectBarcodes(result: result)
        case "recognizeText":
            session.recognizeText(languages: args["languages"] as? [String] ?? [], accurate: args["accurate"] as? Bool != false, result: result)
        case "addGeoAnchor":
            session.addGeoAnchor(args, result: result)
        case "checkVps":
            session.checkVps(latitude: (args["latitude"] as? NSNumber)?.doubleValue ?? 0, longitude: (args["longitude"] as? NSNumber)?.doubleValue ?? 0, result: result)
        case "getWorldMap":
            session.worldMap(result: result)
        case "collaborationData":
            if let typed = args["data"] as? FlutterStandardTypedData { session.receiveCollaboration(typed.data) }
            result(nil)
        case "updateLocation":
            result(nil)
        case "hostCloudAnchor", "resolveCloudAnchor", "enterXr", "exitXr":
            result(FlutterError(code: "unsupported", message: "\(method) is not available on iOS", details: nil))
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func availability() -> [String: Any] {
        guard #available(iOS 15.0, *) else {
            return ["status": "unsupported", "message": "AR needs iOS 15 or newer", "capabilities": ["platform": "ios"]]
        }
        let caps = UArSession.capabilities()
        return ["status": ARWorldTrackingConfiguration.isSupported ? "supported" : "unsupported", "capabilities": caps]
    }

    // -------------------------------------------------------------------------
    // Permissions
    // -------------------------------------------------------------------------

    private func cameraPermission() -> String {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return "granted"
        case .denied: return "permanentlyDenied"
        case .restricted: return "restricted"
        default: return "denied"
        }
    }

    private func locationPermission() -> String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return "granted"
        case .denied: return "permanentlyDenied"
        case .restricted: return "restricted"
        default: return "denied"
        }
    }

    private func microphonePermission() -> String {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return "granted"
        case .denied: return "permanentlyDenied"
        default: return "denied"
        }
    }

    private func permissionMap() -> [String: Any] {
        ["camera": cameraPermission(), "location": locationPermission(), "microphone": microphonePermission()]
    }

    private func requestPermission(location: Bool, microphone: Bool, result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async {
                let finish = {
                    if microphone {
                        AVAudioSession.sharedInstance().requestRecordPermission { _ in
                            DispatchQueue.main.async { result(self.permissionMap()) }
                        }
                    } else {
                        result(self.permissionMap())
                    }
                }
                // Without the usage string iOS ignores the request and never calls back.
                let declared = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
                if !declared, location {
                    NSLog("[u/ar] NSLocationWhenInUseUsageDescription is missing from Info.plist; location permission cannot be requested")
                }
                if location, declared, self.locationManager.authorizationStatus == .notDetermined {
                    self.locationWaiters.append(finish)
                    self.locationManager.requestWhenInUseAuthorization()
                } else {
                    finish()
                }
            }
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        let waiters = locationWaiters
        locationWaiters.removeAll()
        waiters.forEach { $0() }
    }

    // -------------------------------------------------------------------------
    // One-shot native experiences
    // -------------------------------------------------------------------------

    private func topController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }

    private func openQuickLook(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let source = (args["iosSource"] as? [String: Any]) ?? (args["source"] as? [String: Any]) else {
            result(false)
            return
        }
        let ext = (source["ext"] as? String ?? "").lowercased()
        guard ext == "usdz" || ext == "reality" else {
            result(false)
            return
        }
        loader.file(source) { [weak self] url, _ in
            guard let self, let url, let top = self.topController() else {
                result(false)
                return
            }
            let item = ARQuickLookPreviewItem(fileAt: url)
            if let link = args["link"] as? String { item.canonicalWebPageURL = URL(string: link) }
            item.allowsContentScaling = args["resizable"] as? Bool != false
            self.previewItem = item
            let preview = QLPreviewController()
            preview.dataSource = self
            top.present(preview, animated: true)
            result(true)
        }
    }

    public func numberOfPreviewItems(in _: QLPreviewController) -> Int {
        previewItem == nil ? 0 : 1
    }

    public func previewController(_: QLPreviewController, previewItemAt _: Int) -> QLPreviewItem {
        previewItem ?? (NSURL(fileURLWithPath: "") as QLPreviewItem)
    }

    private func scanRoom(_ args: [String: Any], result: @escaping FlutterResult) {
        #if canImport(RoomPlan)
            if #available(iOS 16.0, *), RoomCaptureSession.isSupported, let top = topController() {
                let controller = UArRoomScanController(options: args) { [weak self] map, error in
                    self?.activeController = nil
                    if let map {
                        result(map)
                    } else if error == "cancelled" {
                        result(nil)
                    } else {
                        result(FlutterError(code: "unknown", message: error, details: nil))
                    }
                }
                activeController = controller
                top.present(controller, animated: true)
                return
            }
        #endif
        result(FlutterError(code: "unsupported", message: "Room scanning needs iOS 16 and a LiDAR device", details: nil))
    }

    private func captureObject(_ args: [String: Any], result: @escaping FlutterResult) {
        guard #available(iOS 17.0, *), ObjectCaptureSession.isSupported, let top = topController() else {
            result(FlutterError(code: "unsupported", message: "Object capture needs iOS 17 and a LiDAR device", details: nil))
            return
        }
        let labels = (args["labels"] as? [String: String]) ?? [:]
        let detail = args["detail"] as? String ?? "reduced"
        Task { @MainActor [weak self] in
            let model = UArObjectCaptureModel(detail: detail) { map, error in
                self?.activeController = nil
                if let map {
                    result(map)
                } else if error == "cancelled" {
                    result(nil)
                } else {
                    result(FlutterError(code: "unknown", message: error, details: nil))
                }
            }
            let host = UIHostingController(rootView: UArObjectCaptureScreen(model: model, labels: labels))
            host.modalPresentationStyle = .fullScreen
            model.dismiss = { [weak host] in host?.dismiss(animated: true) }
            self?.activeController = host
            top.present(host, animated: true)
        }
    }
}
