# mennikki - ラーメン記録アプリ

## プロジェクト概要

ラーメンの食事履歴をシンプルに記録・管理できるiOSアプリ。Duolingo風の明るく親しみやすいデザインで、記録の追加・閲覧・検索・お気に入り管理が可能。

**プラットフォーム:** iOS 17.0+
**開発言語:** Swift
**UI:** UIKit（コードベース、Storyboard不使用）
**データ永続化:** Core Data（ローカルのみ）

---

## 技術スタック

- **UI構築**: UIKit（プログラマティック、Storyboard/XIB不使用）
- **データ永続化**: Core Data
- **レイアウト**: Auto Layout（NSLayoutAnchor）
- **画像選択**: PHPickerViewController
- **アーキテクチャ**: MVC
- **デザインシステム**: Duolingo風（カラフル、丸みのあるUI）

---

## 開発ルール・規約

### 1. UI実装の原則

#### Storyboard/XIB不使用
- **全てのUIをコードで構築する**
- 初期設定でMain.storyboardを削除し、Info.plistとSceneDelegateを適切に設定
- UIViewControllerのライフサイクルメソッド内でUIを生成

#### ViewControllerの使用方針
- **全ての画面でUIViewControllerを使用する**
- UITableViewController、UICollectionViewControllerは使用しない
- UITableView、UICollectionViewは必要に応じてUIViewControllerに配置
- これにより将来的な機能拡張に柔軟に対応できる

#### Auto Layout
- `translatesAutoresizingMaskIntoConstraints = false` を設定
- **NSLayoutAnchor** を使用した制約設定を推奨
- 複雑なレイアウトには **UIStackView** を活用
- マジックナンバーを避け、定数を使用

### 2. Core Data

- Core DataスタックはAppDelegateまたはSceneDelegateで初期化
- **NSPersistentContainer** を使用
- バックグラウンドコンテキストでのデータ操作を考慮
- **NSFetchedResultsController** を使用してUIと連携
  - NSFetchedResultsControllerDelegateで変更を検知
  - controllerDidChangeContent(_:)でcollectionView.reloadData()を呼び出し
  - より詳細な制御が必要な場合は、performBatchUpdates(_:completion:)を使用

### 3. デザインシステム

- **カラー、フォント、スタイルは定義済みのデザインシステムを使用**
- 詳細は `docs/design/デザインガイドライン.md` を参照
- UIColor extension、UIFont extensionで定義されたスタイルを使用
- 再利用可能なコンポーネントを作成（ボタン、カード、タグなど）

### 4. データ管理

#### Core Dataマイグレーション
- データモデル変更時のマイグレーション戦略を事前に検討

#### メモリ管理
- 写真データ（Data型）が大きくなる可能性があるため、適切なリサイズとキャッシュ管理を行う
- 画像は表示前に適切なサイズにリサイズ（最大長辺800px、JPEG品質0.75）
- サムネイルは CGImageSourceCreateThumbnailAtIndex でダウンサンプリング（最大300px）
- 画像キャッシュは NSCache（静的共有インスタンス）を使用

### 5. アクセシビリティ

- **全てのインタラクティブな要素に適切なaccessibilityLabelを設定**
- 操作方法が明確でない要素にはaccessibilityHintを設定
- 適切なaccessibilityTraitを設定（.button、.image、.headerなど）
- Dynamic Type対応を考慮

---

## プロジェクト構成

```
mennikki/
├── Models/              # Core Dataモデル、Enum定義（RamenType, Prefecture）
├── Views/               # カスタムビュー、セル（RecordCell, StarRatingView）
├── ViewControllers/     # 画面ごとのViewController
│   ├── BaseRecordListViewController.swift   # 一覧画面の共通基底クラス
│   ├── RecordListViewController.swift       # 記録一覧（検索・フィルター付き）
│   ├── FavoriteListViewController.swift     # お気に入り一覧
│   ├── RecordDetailViewController.swift     # 記録詳細
│   └── AddRecordViewController.swift        # 新規作成・編集（共用）
├── Managers/            # CoreDataManager（シングルトン）
├── Extensions/          # UIColor, UIFont, UIView, UINavigationBar, UITabBar 拡張
└── Resources/           # Assets、Core Dataモデルファイル
```

---

## 設計書の参照

詳細な設計情報は以下のドキュメントを参照してください：

- **[データモデル設計書](docs/design/データモデル設計.md)** - Core Dataエンティティ、フィールド定義
- **[デザインガイドライン](docs/design/デザインガイドライン.md)** - カラー、フォント、UI要素のスタイル
- **[機能仕様書](docs/design/機能仕様書.md)** - 各機能の詳細仕様
- **[画面設計書](docs/design/画面設計.md)** - 画面構成、ナビゲーション構造
- **[テストケース](docs/test/test.md)** - 手動テスト結果（2026/02/23 実施）

---

## 実装ステータス

全チケット実装完了。

| チケット | 内容 | 状態 |
|---------|------|------|
| 001 | プロジェクト初期設定 | 完了 |
| 002 | デザインシステム構築 | 完了 |
| 003 | TabBarとNavigation構築 | 完了 |
| 004 | 記録一覧画面（CollectionView） | 完了 |
| 005 | 新規記録画面 | 完了 |
| 006 | 記録詳細画面 | 完了 |
| 007 | 記録編集機能 | 完了 |
| 008 | 検索機能 | 完了 |
| 009 | お気に入り機能 | 完了 |
| 010 | アクセシビリティ対応 | 完了 |
| 011 | 最終調整とテスト | 完了 |

### 既知の不具合

- **5-5**: 編集画面で写真を変更して保存しても、詳細画面・一覧画面に反映されない

---

## 今後の拡張候補（スコープ外）

- 地図上で訪問店を表示（MapKit統合）
- 複数デバイス間のデータ同期（CloudKit統合）
- 訪問日のカレンダー一覧表示
- データのエクスポート・インポート（CSV、JSON形式）
- ダークモード対応の強化
- iPad対応（UISplitViewController使用）

---

## 開発環境・注意事項

- **Xcode** を使用。`PBXFileSystemSynchronizedRootGroup` によりファイルが自動追加されるため、pbxprojの手動編集は不要
- **Deployment Target は iOS 17.0**（Swift 5.10 + Xcode 16.2 で `_swift_task_deinitOnExecutor` リンクエラーが発生するため iOS 15 から変更）
- `UIButton.contentEdgeInsets` / `titleEdgeInsets` / `imageEdgeInsets` は iOS 15 deprecated。`UIButton.Configuration` または `NSString.size(withAttributes:)` で代替
