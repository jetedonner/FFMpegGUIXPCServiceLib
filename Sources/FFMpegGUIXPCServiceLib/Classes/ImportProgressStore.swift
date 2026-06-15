//
//  ImportProgressStore.swift
//  FFMpegGUIXPCServiceLib
//
//  Created by Kim-David Hauser on 14.06.2026.
//

import Foundation

public final class ImportProgressStore: @unchecked Sendable {
    static let shared = ImportProgressStore()

    private var values: [UUID: (progress: Double, done: Bool)] = [:]
    private let queue = DispatchQueue(label: "ImportProgressStore")

    func setProgress(_ progress: Double, for id: UUID, done: Bool) {
        queue.async {
            self.values[id] = (progress, done)
        }
    }

    func withProgress(for id: UUID, _ block: @escaping (Double, Bool) -> Void) {
        queue.async {
            let value = self.values[id] ?? (0.0, false)
            block(value.progress, value.done)
        }
    }
}

final class CheckIntegrityProgressStore: @unchecked Sendable {
    static let shared = CheckIntegrityProgressStore()

    private var values: [UUID: (progress: Double, done: Bool)] = [:]
    private let queue = DispatchQueue(label: "CheckIntegrityProgressStore")

    func setProgress(_ progress: Double, for id: UUID, done: Bool) {
        queue.async {
            self.values[id] = (progress, done)
        }
    }

    func withProgress(for id: UUID, _ block: @escaping (Double, Bool) -> Void) {
        queue.async {
            let value = self.values[id] ?? (0.0, false)
            block(value.progress, value.done)
        }
    }
}
