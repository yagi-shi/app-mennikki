//
//  RecordPhotoResolver.swift
//  mennikki
//

import Foundation

/// 記録の保存時に、どの写真データを保存するかを決める
nonisolated enum RecordPhotoResolver {

    enum ResolveError: Error {
        /// 選び直した写真を、保存用のデータに変換できなかった
        case encodingFailed
    }

    /// - Parameters:
    ///   - existingPhoto: 保存済みの写真データ。新規作成や、写真のない記録では nil
    ///   - didPickNewPhoto: 利用者がこの画面で写真を選び直したかどうか
    ///   - encodeNewPhoto: 選び直した写真を保存用のデータに変換する。変換できなければ nil を返す
    /// - Returns: 保存する写真データ。選び直していなければ、保存済みのデータをそのまま返す
    static func resolve(
        existingPhoto: Data?,
        didPickNewPhoto: Bool,
        encodeNewPhoto: () -> Data?
    ) throws -> Data? {
        guard didPickNewPhoto else { return existingPhoto }
        guard let encoded = encodeNewPhoto() else { throw ResolveError.encodingFailed }
        return encoded
    }
}
