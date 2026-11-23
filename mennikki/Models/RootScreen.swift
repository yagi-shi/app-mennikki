//
//  RootScreen.swift
//  mennikki
//

import Foundation

/// アプリを開いたときに、最初に出す画面
enum RootScreen: Equatable {
    /// 記録一覧とお気に入りのタブの画面
    case recordTabs
    /// 保存したデータを開けなかったことを知らせる画面。
    /// 記録が 0 件の画面を出すと、利用者が「消えた」と思ってアプリを削除し、本当にデータが消えるおそれがあるため
    case storeLoadError

    /// - Parameter isStoreAvailable: 保存したデータを開けたかどうか（`CoreDataManager.isStoreAvailable`）
    init(isStoreAvailable: Bool) {
        self = isStoreAvailable ? .recordTabs : .storeLoadError
    }
}
