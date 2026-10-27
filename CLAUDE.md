# mennikki - ラーメン記録アプリ

## プロジェクト概要

ラーメンの食事履歴をシンプルに記録・管理できるiOSアプリ。明るく親しみやすいポップなデザインで、記録の追加・閲覧・検索・お気に入り管理が可能。

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
- **デザインシステム**: カラフル、丸みのあるポップなUI

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
- 詳細は `docs/10_design/04_デザインガイドライン.md` を参照
- UIColor extension、UIFont extensionで定義されたスタイルを使用
- フォントは `UIFont+App.swift` の定義を使い、その場でサイズを書かない（`UIFont.rounded(ofSize:weight:)` や `UIFont.systemFont(ofSize:)` を画面のコードで直接使わない）。新しい用途のフォントが必要なときは、先に定義を追加する
- フォントの定義は、iOS の標準の文字サイズの段階（テキストスタイル）から `UIFont.rounded(_:weight:)` で作り、独自のサイズは作らない（例外はタブバーのみ）
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

- **[機能仕様書](docs/10_design/01_機能仕様書.md)** - 各機能の詳細仕様
- **[画面設計書](docs/10_design/02_画面設計.md)** - 画面構成、ナビゲーション構造
- **[データモデル設計書](docs/10_design/03_データモデル設計.md)** - Core Dataエンティティ、フィールド定義
- **[デザインガイドライン](docs/10_design/04_デザインガイドライン.md)** - カラー、フォント、UI要素のスタイル
- **[テストケース](docs/30_test/test.md)** - 手動テスト結果（2026/02/23 実施）

---

## 実装ステータス

全チケット実装完了。

| チケット | 内容                           | 状態 |
| -------- | ------------------------------ | ---- |
| 001      | プロジェクト初期設定           | 完了 |
| 002      | デザインシステム構築           | 完了 |
| 003      | TabBarとNavigation構築         | 完了 |
| 004      | 記録一覧画面（CollectionView） | 完了 |
| 005      | 新規記録画面                   | 完了 |
| 006      | 記録詳細画面                   | 完了 |
| 007      | 記録編集機能                   | 完了 |
| 008      | 検索機能                       | 完了 |
| 009      | お気に入り機能                 | 完了 |
| 010      | アクセシビリティ対応           | 完了 |
| 011      | 最終調整とテスト               | 完了 |

### 既知の不具合

なし


---

## 開発環境・注意事項

- **Xcode** を使用。`PBXFileSystemSynchronizedRootGroup` によりファイルが自動追加されるため、pbxprojの手動編集は不要
- **Deployment Target は iOS 17.0**（Swift 5.10 + Xcode 16.2 で `_swift_task_deinitOnExecutor` リンクエラーが発生するため iOS 15 から変更）
- `UIButton.contentEdgeInsets` / `titleEdgeInsets` / `imageEdgeInsets` は iOS 15 deprecated。`UIButton.Configuration` または `NSString.size(withAttributes:)` で代替

## 開発フロー（必ずこの順で行う）
1. 作業前に対応するissueを確認する（なければ作る）
2. issueに受け入れ条件が「issueの書き方」の形式で書かれていることを確認する。
   無い・曖昧な場合は実装前に指示者へ確認する
3. 「自動テストで確認する」の条件ごとにテストを書き、失敗することを確認して
   `test: <内容> refs #<issue番号>` でコミットする
4. 実装してテストを通し、`feat: <内容> refs #<issue番号>` などでコミットする
   （接頭辞は「命名・紐付けのルール」から選ぶ）
5. 「手動で確認する」の条件と、自動テストで担保できない項目は、
   作業完了時に指示者へ明示的に伝える（確認済みとして扱わない）
6. 挙動の仕様が変わる場合は、同じPRで `docs/10_design/` の該当する設計書を更新する
7. PR本文は .github/pull_request_template.md に従い、
   受け入れ条件とテストの対応表、手動確認項目を埋める

## issueの書き方
- issue本文は .github/issue_template.md の書式に従う
- issueには、今回の変更分の仕様と受け入れ条件を書く
- アプリ全体の仕様の正は `docs/10_design/` の設計書とし、マージ時に変更分を反映する
- 受け入れ条件は「自動テストで確認する」「手動で確認する」の見出しに分けたチェックリストで書く
- 該当する条件がない見出しには「なし」と理由を書く

## 命名・紐付けのルール
- ブランチ名は `feature/<issue番号>-<英語の短い説明>`（例: `feature/12-add-rating`）
- コミットメッセージは `<接頭辞>: <内容> refs #<issue番号>` の形式にする
- 接頭辞は次のいずれかを使う
  - `test`: テストの追加・修正
  - `feat`: 機能の追加・変更
  - `fix`: 不具合の修正
  - `refactor`: 挙動を変えないコードの整理
  - `docs`: ドキュメントのみの変更
  - `chore`: ビルド設定やプロジェクト構成などの変更
- PR本文に `Closes #<issue番号>` を含める

## テストのルール
- Model / ViewModel / ロジック層は、受け入れ条件に対応するテストを先に書いてから実装する
- テストは Swift Testing（`import Testing`）で書く
- テストは `mennikkiTests` ターゲットに、`<対象クラス名>Tests.swift` の名前で作る
- ViewControllerにロジックを追加しない。UIKit非依存のクラスに切り出してテストする
- UIのみの変更は自動テスト不要（代わりに手動確認項目を挙げる）
- テストでは `CoreDataManager(inMemory: true)` でインメモリのストアを作って使い、`CoreDataManager.shared` には書き込まない
- テストは次のコマンドで実行する（シミュレータは手元にあるものを指定する）

```sh
xcodebuild test -project mennikki.xcodeproj -scheme mennikki -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

## 実機での手動確認が必要なもの
以下に該当する変更は、自動テストだけで完了扱いにしない
- レイアウト・見た目（画面サイズ差、ダークモード、Dynamic Type）
- アニメーション、ジェスチャー、スクロールの操作感
- カメラ、写真、位置情報、通知などの権限・デバイス機能
- バックグラウンド復帰、アプリ再起動後のデータ保持
- パフォーマンス（体感速度、メモリ）

VoiceOver の読み上げは、実機での確認の対象外とする（読み上げのラベルは「5. アクセシビリティ」のとおりコードで設定する）

伝える際は「何を・どの手順で・何が期待結果か」を箇条書きで示す

## 指示者への質問
- 指示者への質問は番号付きで、選択肢があれば明示し、推奨があれば示す