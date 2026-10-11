# 003. TabBarとNavigation構築

## 概要
UITabBarControllerとUINavigationControllerを使用した基本的な画面構成を構築する。

## 実装内容

### 1. UITabBarControllerの設定
- SceneDelegateでrootViewControllerとして設定
- `applyAppStyle()` によるカスタマイズ
  - 背景色: 白（opaque）
  - 選択時tintColor: appPrimary
  - 未選択時tintColor: appSecondaryText
  - 上部にappBorder色のボーダー
  - フォント: rounded 10pt（通常: semibold、選択時: bold）

### 2. タブ構成
- 記録一覧タブ
  - RecordListViewController
  - アイコン: fork.knife
  - タイトル: "記録"
- お気に入りタブ
  - FavoriteListViewController
  - アイコン: heart.fill
  - タイトル: "お気に入り"

### 3. UINavigationControllerのカスタマイズ
- `applyAppStyle()` による設定
  - 背景色: 白（opaque）
  - タイトルフォント: appNavigationTitle（20pt bold rounded）
  - ラージタイトルフォント: appLargeTitle（28pt heavy rounded）
  - shadowColor: appBorder
  - tintColor: appPrimary
  - prefersLargeTitles: true

### 4. ViewControllerの作成
- RecordListViewController（BaseRecordListViewController継承）
- FavoriteListViewController（BaseRecordListViewController継承）

### 5. アプリライフサイクル
- sceneDidEnterBackground: CoreDataManager.shared.saveIfNeeded()

## Todo
- [x] SceneDelegateでUITabBarControllerを設定
- [x] UITabBar+App.swiftの `applyAppStyle()` を実装
- [x] RecordListViewControllerを作成
- [x] FavoriteListViewControllerを作成
- [x] 各ViewControllerをUINavigationControllerでラップ
- [x] タブアイテムの設定（アイコン・タイトル）
- [x] UINavigationBar+App.swiftの `applyAppStyle()` を実装
- [x] sceneDidEnterBackgroundでCore Data保存
- [x] 動作確認（タブ切り替え）

## 依存関係
- 001_プロジェクト初期設定
- 002_デザインシステム構築

## 完了条件
- タブバーとナビゲーションバーがアプリのデザインシステムに沿ってカスタマイズされている
- 2つのタブ間で切り替えができる
- 各タブにナビゲーションバーが表示されている
