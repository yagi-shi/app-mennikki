# 003. TabBarとNavigation構築

## 概要
UITabBarControllerとUINavigationControllerを使用した基本的な画面構成を構築する。

## 実装内容

### 1. UITabBarControllerの設定
- SceneDelegateでrootViewControllerとして設定
- Duolingo風のカスタマイズ
  - 背景色: 白
  - 選択時tintColor: プライマリカラー
  - 未選択時tintColor: 薄いグレー
  - 上部に薄いシャドウ

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
- 背景色: 白
- タイトルフォント: 20pt Bold
- tintColor: プライマリカラー
- 薄いシャドウ

### 4. 空のViewControllerの作成
- RecordListViewController（UIViewController）
- FavoriteListViewController（UIViewController）

## Todo
- [ ] SceneDelegateでUITabBarControllerを設定
- [ ] UITabBarControllerのカスタマイズを実装
- [ ] RecordListViewControllerを作成（空実装）
- [ ] FavoriteListViewControllerを作成（空実装）
- [ ] 各ViewControllerをUINavigationControllerでラップ
- [ ] タブアイテムの設定（アイコン・タイトル）
- [ ] UINavigationBarのカスタマイズを実装
- [ ] 動作確認（タブ切り替え）

## 依存関係
- 001_プロジェクト初期設定
- 002_デザインシステム構築

## 完了条件
- タブバーとナビゲーションバーがDuolingo風にカスタマイズされている
- 2つのタブ間で切り替えができる
- 各タブにナビゲーションバーが表示されている
