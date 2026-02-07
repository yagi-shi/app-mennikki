# 004. 記録一覧画面（CollectionView）

## 概要
2列グリッドレイアウトのUICollectionViewで記録一覧を表示する。

## 実装内容

### 1. RecordListViewControllerの実装
- UICollectionViewをプログラマティックに追加
- Auto Layoutで画面全体に配置
- NSFetchedResultsControllerでCore Dataと連携

### 2. UICollectionViewFlowLayoutの設定
- 2列グリッド
- 列間隔: 12pt
- 行間隔: 12pt
- セクションインセット: 上下左右16pt
- セルサイズ計算: (画面幅 - 左右マージン32pt - 列間隔12pt) / 2
- アスペクト比: 幅:高さ = 1:1.3

### 3. カスタムRecordCellの作成
- 写真エリア（上部、高さ120pt、角丸12pt上部のみ）
- 店名ラベル（15pt、Semibold、2行まで）
- ラーメン種類タグ（イエロー背景、角丸8pt）
- 訪問日ラベル（12pt、グレー）
- お気に入りバッジ（右上、heart.fill）
- 白色背景、角丸12pt、軽いシャドウ

### 4. セルタップアニメーション
- タップ時に0.95倍スケールダウン（0.1秒）

### 5. 空状態の実装
- 記録が0件の場合のEmpty State表示
- ラーメンボウルアイコン（bowl.fill）
- メッセージ表示

## Todo
- [ ] RecordListViewControllerにUICollectionViewを追加
- [ ] UICollectionViewをAuto Layoutで配置
- [ ] UICollectionViewDelegateに準拠
- [ ] UICollectionViewDataSourceに準拠
- [ ] UICollectionViewDelegateFlowLayoutに準拠
- [ ] RecordCellクラスを作成
- [ ] RecordCellのレイアウトを実装
- [ ] NSFetchedResultsControllerを設定
- [ ] セルにデータをバインド
- [ ] セルタップアニメーションを実装
- [ ] 空状態の表示を実装
- [ ] 動作確認（テストデータで表示）

## 依存関係
- 001_プロジェクト初期設定
- 002_デザインシステム構築
- 003_TabBarとNavigation構築

## 完了条件
- 2列グリッドで記録が表示される
- セルがDuolingo風にデザインされている
- セルタップアニメーションが動作する
- 空状態が適切に表示される
