//
//  RecordPhotoResolverTests.swift
//  mennikkiTests
//

import Testing
import Foundation
@testable import mennikki

/// RecordPhotoResolver のテスト。保存時にどの写真データを保存するかを、インメモリのストアで確かめる
@MainActor
struct RecordPhotoResolverTests {

    private let originalPhoto = Data([0x01, 0x02, 0x03, 0x04])
    private let newPhoto = Data([0x0A, 0x0B, 0x0C])

    @Test("写真を選び直さずに保存すると、保存される写真のデータが、元と完全に同じである")
    func keepsExistingPhotoWhenNotPicked() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager, photo: originalPhoto)
        var didEncode = false

        let resolved = try RecordPhotoResolver.resolve(
            existingPhoto: record.photo,
            didPickNewPhoto: false,
            encodeNewPhoto: {
                didEncode = true
                return newPhoto
            }
        )
        update(record, in: manager, storeName: "テスト軒 本店", photo: resolved)

        let saved = try #require(manager.fetchAllRecords().first)
        #expect(didEncode == false)
        #expect(saved.photo == originalPhoto)
        #expect(saved.storeName == "テスト軒 本店")
    }

    @Test("写真を選び直して保存すると、保存される写真が、新しい写真になる")
    func replacesPhotoWhenPicked() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager, photo: originalPhoto)

        let resolved = try RecordPhotoResolver.resolve(
            existingPhoto: record.photo,
            didPickNewPhoto: true,
            encodeNewPhoto: { newPhoto }
        )
        update(record, in: manager, storeName: "テスト軒", photo: resolved)

        let saved = try #require(manager.fetchAllRecords().first)
        #expect(saved.photo == newPhoto)
    }

    @Test("新しい写真の変換に失敗した場合は保存されず、元の写真が残る")
    func throwsWhenEncodingFails() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager, photo: originalPhoto)

        #expect(throws: RecordPhotoResolver.ResolveError.encodingFailed) {
            try RecordPhotoResolver.resolve(
                existingPhoto: record.photo,
                didPickNewPhoto: true,
                encodeNewPhoto: { nil }
            )
        }

        // 保存する写真データが決まらないので、更新は行われない
        let saved = try #require(manager.fetchAllRecords().first)
        #expect(saved.photo == originalPhoto)
    }

    @Test("写真のない記録で写真を選ばなければ、写真なしのままである")
    func keepsNoPhotoWhenNothingPicked() throws {
        let resolved = try RecordPhotoResolver.resolve(
            existingPhoto: nil,
            didPickNewPhoto: false,
            encodeNewPhoto: { newPhoto }
        )

        #expect(resolved == nil)
    }

    // MARK: - Helper Methods

    private func makeRecord(in manager: CoreDataManager, photo: Data?) throws -> Record {
        try #require(manager.createRecord(
            storeName: "テスト軒",
            ramenType: .shoyu,
            visitDate: Date(timeIntervalSince1970: 1_700_000_000),
            photo: photo
        ))
    }

    private func update(_ record: Record, in manager: CoreDataManager, storeName: String, photo: Data?) {
        manager.updateRecord(
            record,
            storeName: storeName,
            ramenType: .shoyu,
            visitDate: Date(timeIntervalSince1970: 1_700_000_000),
            cost: 0,
            rating: 0,
            comment: nil,
            photo: photo,
            isFavorite: false
        )
    }
}
