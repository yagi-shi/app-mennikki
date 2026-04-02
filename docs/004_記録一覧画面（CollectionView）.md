# 004. 記録一覧画面（CollectionView）

## 概要
2列グリッドレイアウトのUICollectionViewで記録一覧を表示する。

## 実装内容

### 1. BaseRecordListViewControllerの作成（共通基底クラス）
- RecordListViewControllerとFavoriteListViewControllerの共通処理を集約
- UICollectionViewをプログラマティックに追加（Auto Layout配置）
- NSFetchedResultsControllerでCore Dataと連携
- 空状態表示（アイコン + メッセージ + サブメッセージ）
- スタガーアニメーション（フェードイン+スライド）
- サブクラス用のカスタマイズフック（fetchPredicate, emptyState系, setupAdditionalUI等）

### 2. UICollectionViewFlowLayoutの設定
- 2列グリッド
- 列間隔: 12pt
- 行間隔: 12pt
- セクションインセット: 上下12pt、左右10pt
- セルサイズ計算: (画面幅 - 左右マージン20pt - 列間隔12pt) / 2
- アスペクト比: 幅:高さ = 1:1（正方形）

### 3. カスタムRecordCellの作成
- **上部エリア**（セル高さの60%）: 写真 or ラーメン種類カラー背景
  - 写真あり: scaleAspectFill + ダークグラデーションオーバーレイ
  - 写真なし: 種類カラー背景 + fork.knifeプレースホルダー（白60%透過）
- **お気に入りバッジ**: 右上8ptマージン、appPrimary背景円形（24x24pt）、白heart.fill
- **店名**: appStoreName（17pt bold）、2行まで
- **ラーメン種類タグ**: 種類カラー背景、白テキスト、角丸8pt
- **ミニ星評価**: 10x10ptの星5個（appSuccess / ライトグレー）、タグの横
- **セルスタイル**: 角丸16pt、ハードシャドウ（appBorder、opacity 1.0、offset 5pt）、ボーダー2pt

### 4. 3D押し込みアニメーション
- isHighlightedで5px下にずれてシャドウが消える（0.08秒）

### 5. 画像キャッシュとダウンサンプリング
- NSCache（静的共有、RecordCell内）
- CGImageSourceCreateThumbnailAtIndex（最大300px）
- バックグラウンドスレッドでデコード
- currentRecordIDによるセル再利用時の画像すり替え防止

### 6. RecordListViewControllerの実装
- BaseRecordListViewControllerを継承
- 空状態: bowl.fill アイコン、「まだラーメンの記録がありません」
- FABボタン（詳細は005で実装）

### 7. 空状態の実装
- UIStackView（アイコン + タイトル + サブタイトル）
- 画面中央に配置（Y方向-50ptオフセット）

## Todo
- [x] BaseRecordListViewControllerを作成
- [x] UICollectionViewをAuto Layoutで配置
- [x] UICollectionViewDelegateに準拠
- [x] UICollectionViewDataSourceに準拠
- [x] UICollectionViewDelegateFlowLayoutに準拠
- [x] RecordCellクラスを作成
- [x] RecordCellのレイアウトを実装（種類カラー背景、ハードシャドウ）
- [x] 画像キャッシュとダウンサンプリングを実装
- [x] NSFetchedResultsControllerを設定
- [x] セルにデータをバインド
- [x] 3D押し込みアニメーションを実装
- [x] スタガーアニメーションを実装
- [x] 空状態の表示を実装
- [x] 動作確認

## 依存関係
- 001_プロジェクト初期設定
- 002_デザインシステム構築
- 003_TabBarとNavigation構築

## 完了条件
- 2列グリッドで記録が表示される
- セルがデザインシステムに沿っている（ハードシャドウ、種類カラー背景）
- 3D押し込みアニメーションが動作する
- 画像キャッシュとダウンサンプリングが機能する
- 空状態が適切に表示される
