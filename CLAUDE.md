# mennikki - ラーメン記録アプリ

## プロジェクト概要

ラーメンの食事履歴をシンプルに記録・管理できるiOSアプリ。Duolingo風の明るく親しみやすいデザインで、記録の追加・閲覧・検索・お気に入り管理が可能。

**プラットフォーム:** iOS 15+
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
- 画像は表示前に適切なサイズにリサイズ
- 不要になった画像データは適切に解放

### 5. アクセシビリティ

- **全てのインタラクティブな要素に適切なaccessibilityLabelを設定**
- 操作方法が明確でない要素にはaccessibilityHintを設定
- 適切なaccessibilityTraitを設定（.button、.image、.headerなど）
- Dynamic Type対応を考慮

---

## プロジェクト構成

```
mennikki/
├── Models/              # Core Dataモデル、Enum定義
├── Views/               # カスタムビュー、セル
├── ViewControllers/     # 画面ごとのViewController
├── Managers/            # Core Dataマネージャーなど
├── Extensions/          # UIColor、UIFont、UIViewなどの拡張
├── Resources/           # Assets、Core Dataモデルファイル
└── Utils/               # ユーティリティクラス
```

---

## 設計書の参照

詳細な設計情報は以下のドキュメントを参照してください：

- **[データモデル設計書](docs/design/データモデル設計.md)** - Core Dataエンティティ、フィールド定義
- **[デザインガイドライン](docs/design/デザインガイドライン.md)** - カラー、フォント、UI要素のスタイル
- **[機能仕様書](docs/design/機能仕様書.md)** - 各機能の詳細仕様
- **[画面設計書](docs/design/画面設計.md)** - 画面構成、ナビゲーション構造

---

## 実装タスク

実装タスクは `/docs` 配下のチケットファイルで管理しています：

- **001_プロジェクト初期設定.md** - Storyboard削除、Core Dataセットアップ
- **002_デザインシステム構築.md** - カラー・フォント・スタイル定義
- **003_TabBarとNavigation構築.md** - TabBar、NavigationController
- **004_記録一覧画面（CollectionView）.md** - 2列グリッドレイアウト
- **005_新規記録画面.md** - 記録作成フォーム
- **006_記録詳細画面.md** - 詳細情報表示
- **007_記録編集機能.md** - 編集・削除
- **008_検索機能.md** - 店名検索、種類フィルター
- **009_お気に入り機能.md** - お気に入り登録・一覧
- **010_アクセシビリティ対応.md** - VoiceOver、Dynamic Type
- **011_最終調整とテスト.md** - エラーハンドリング、最適化

---

## 今後の拡張候補（スコープ外）

- 地図上で訪問店を表示（MapKit統合）
- 複数デバイス間のデータ同期（CloudKit統合）
- 訪問日のカレンダー一覧表示
- データのエクスポート・インポート（CSV、JSON形式）
- ダークモード対応の強化
- iPad対応（UISplitViewController使用）

---

## 開発のヒント

1. まず `docs/design/` 配下の設計書を確認し、全体像を把握する
2. `/docs` 配下のチケットファイルを順番に実装する
3. デザインシステムを活用し、統一感のあるUIを構築する
4. 各機能実装後、VoiceOverでアクセシビリティを確認する
5. 定期的にメモリリークをチェックする
