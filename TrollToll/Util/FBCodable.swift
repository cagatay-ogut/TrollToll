// swiftlint:disable:this file_name
//
//  FBCodable.swift
//  TrollToll
//
//  Created by Cagatay on 4.01.2026.
//

import FirebaseDatabase
import OSLog

enum FBDecoder {
    static func decode<T>(_ type: T.Type, from snapshot: DataSnapshot) throws -> T where T: Decodable {
        guard snapshot.exists(), let snapshotValue = snapshot.value as? [String: Any] else {
            throw ServerError.unexpectedDataFormat
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: snapshotValue)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ServerError.failedToDecode(underlyingError: error)
        }
    }

    static func decodeArray<T>(_ type: [T].Type, from snapshot: DataSnapshot) throws -> [T] where T: Decodable {
        guard snapshot.exists(), let snapshotValue = snapshot.value as? [[String: Any]] else {
            return []
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: snapshotValue)
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            throw ServerError.failedToDecode(underlyingError: error)
        }
    }
}

enum FBEncoder {
    static func encode<T>(_ value: T) throws -> [String: Any] where T: Encodable {
        do {
            let data = try JSONEncoder().encode(value)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ServerError.unexpectedDataFormat
            }
            return dict
        } catch {
            throw ServerError.failedToEncode(underlyingError: error)
        }
    }

    static func encodeArray<T>(_ value: [T]) throws -> [[String: Any]] where T: Encodable {
        do {
            let data = try JSONEncoder().encode(value)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw ServerError.unexpectedDataFormat
            }
            return dict
        } catch {
            throw ServerError.failedToEncode(underlyingError: error)
        }
    }
}
