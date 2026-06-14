//
//  TaskResultNG.swift
//  FFMpegGUI
//
//  Created by Kim-David Hauser on 13.06.2026.
//

import Foundation

@objc(XPCTaskResultNG)
public final class XPCTaskResultNG: NSObject, NSSecureCoding { //}, Hashable {

    public class var supportsSecureCoding: Bool { true }
//
////    public var outputPath: String?
    public let id: UUID
    public let progress: Double
    public let success: Bool

    public init(id: UUID, progress: Double, success: Bool) {
        self.id = id
        self.progress = progress
        self.success = success
    }

    public required init?(coder: NSCoder) {
        guard let id = coder.decodeObject(of: NSUUID.self, forKey: "id") as UUID?
        else { return nil }
        self.id = id
        
        guard let progress = coder.decodeDouble(forKey: "progress") as Double?
        else { return nil }
        self.progress = progress
        
        guard let success = coder.decodeBool(forKey: "success") as Bool?
        else { return nil }
        self.success = success
    }

    public func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(progress, forKey: "progress")
        coder.encode(success, forKey: "success")
    }
}
