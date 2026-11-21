# Xcode Cloud の設定手順（PR ごとの自動テスト）

この手順書は、mennikki で Xcode Cloud を使い、PR ごとに自動テストを動かすようにしたときの記録です。2026-11-22 に、issue #68 で設定しました。

Xcode Cloud のワークフローの設定は、Xcode と App Store Connect に保存され、リポジトリのファイルには入りません。どう設定したかは、この手順書が唯一の記録です。設定を変えたら、この手順書も直してください。

## この手順でできること

- PR を作ったときと、PR にコミットを足したときに、Xcode Cloud が `mennikkiTests` を自動で動かす
- テストの結果が、GitHub の PR に「mennikki | PR Tests」という名前で表示される
- 同じ結果を、Xcode と App Store Connect でも見られる

アプリを作ってストアに送ること（アーカイブ、TestFlight への配信）は行いません。ストアに出ているアプリには影響しません。

## 目次

1. 始める前に決めたこと
2. 必要なもの
3. 準備
4. ワークフローを作る
5. GitHub と接続する
6. App Store Connect のアプリと結び付ける
7. 最初のビルド
8. PR で動くかを確かめる
9. 失敗の表示を確かめる
10. テストが通らないとマージできない設定
11. 運用のルール
12. あとで設定を変えるとき
13. つまずいたところ
14. 参考にした資料

---

## 1. 始める前に決めたこと

| 項目 | 決めたこと | 理由 |
|---|---|---|
| 動く PR | 向き先が `dev_` で始まるブランチと `main` の PR | feature → `dev_YYYYMM` の PR と、リリースの `dev_YYYYMM` → `main` の PR の両方で確かめるため |
| ドキュメントだけの PR | 動かす | 設定が簡単で、月 25 時間の無料枠に収まる見込みのため |
| 行うこと | テストだけ。アーカイブはしない | CI の目的は、PR で壊したところに気づくことだけのため |
| テストの機種 | iPhone 17（iOS 26.5）のシミュレータ 1 台 | テストは処理の結果を確かめるもので、機種では結果が変わらないため。台数を増やすと時間を多く使う |
| Xcode の版 | 26.6（手元と同じ） | 手元と版が違うと、結果が食い違うことがあるため。MVVM と SwiftUI が終わるまで 26.6 を使い、そのあと第一優先で 27 以降に上げる |
| macOS の版 | Tahoe 26.5.1（版を固定） | 自動で版が変わる選択肢だと、結果が食い違ったときに原因を探しにくいため |
| 結果の通知 | なし | 結果は PR に表示されるため |

## 2. 必要なもの

| 必要なもの | このプロジェクトでの状態 |
|---|---|
| Apple Developer Program への登録 | 登録済み。月 25 時間ぶんの Xcode Cloud の利用が含まれる |
| App Store Connect の役割（Account Holder、Admin、App Manager のどれか） | Account Holder |
| App Store Connect のアプリの記録 | あり（mennikki - シンプルなラーメン日記、`yagishi.mennikki`） |
| GitHub のリポジトリの admin の権限 | あり（個人アカウント `yagi-shi`） |
| 共有されたスキーム | あり（`mennikki.xcodeproj/xcshareddata/xcschemes/mennikki.xcscheme`） |
| テストのターゲット | あり（`mennikkiTests`。スキームのテストに入っている） |
| 手元の Xcode | Xcode 26.6（`/Applications/Xcode26.6.app`） |

## 3. 準備

### 3-1. Xcode にサインインしているか確かめる

1. Xcode を開く
2. メニューの Xcode → Settings → Accounts を開く
3. 開発者登録の Apple ID が入っていることを確かめる

### 3-2. スキームが共有されているか確かめる

ターミナルで、リポジトリのフォルダから次を実行します。

```sh
ls mennikki.xcodeproj/xcshareddata/xcschemes/
```

`mennikki.xcscheme` が表示されれば大丈夫です。表示されない場合は、Xcode の Product → Scheme → Manage Schemes で、`mennikki` の「Shared」にチェックを入れて、コミットします。

### 3-3. アプリとして認識されるか確かめる

```sh
xcodebuild -project mennikki.xcodeproj -describeAllArchivableProducts -json
```

`"productType" : "app"` と `"containingSchemes" : [ "mennikki" ]` が出れば大丈夫です。

---

## 4. ワークフローを作る

### 4-1. Xcode Cloud の画面を開く

1. Xcode で `mennikki.xcodeproj` を開く
2. 左のナビゲーターで、Report navigator を開く。いちばん右のアイコン（紙に横線が並んだ形）。キーボードなら `⌘` + `9`
3. 上の切り替えで「Cloud」を選ぶ
4. 「Get Started」を押す

### 4-2. 製品を選ぶ（Select a Product）

1. 「mennikki（yagishi.mennikki）」の行を選ぶ。Platform が iOS、Team が開発者登録のチームであることを確かめる
2. 「Next」を押す

### 4-3. ワークフローの案（Review Workflow）

最初は、次のような案が出ます。このままでは使わないので、直します。

| 項目 | 最初の案 |
|---|---|
| Name | Default |
| Start Condition | Branch Changes (main) |
| Environment | Latest Release（その時点の最新の Xcode） |
| Actions | Archive (iOS) |
| Post-Actions | No TestFlight Deployments or Notifications |

「Edit Workflow…」を押します。左に一覧、右に設定の画面が出ます。

### 4-4. General

| 項目 | 設定 |
|---|---|
| Name | `PR Tests` |
| Description | `PR ごとに mennikkiTests を iPhone シミュレータ 1 台で動かす。対象は、向き先が "dev_" で始まるブランチと main の PR。Xcode は手元と同じ 26.6。詳細は GitHub の issue#68。` |
| Restrict Editing | オン。Account Holder、Admin、App Manager しか変えられなくなる。将来チームに人を入れたときに、勝手に変えられないようにするため |
| Primary Repository | `git@github.com:yagi-shi/app-mennikki.git`（自動で入る。確かめるだけ） |
| Project or Workspace | `mennikki.xcodeproj`（自動で入る。確かめるだけ） |

### 4-5. Environment

1. **Xcode Version** の選択欄を開き、「Release Versions」の中から **Xcode 26.6 (17F113)** を選ぶ
   - 括弧の中のビルド番号が、手元の Xcode と同じであることを確かめる。手元の番号は、ターミナルで `xcodebuild -version` を実行すると分かる
   - 「Latest Release」「Latest Beta or Release」は選ばない。版が自動で変わるため
   - 「Beta Versions」（試用版）は選ばない
2. **macOS Version** の選択欄を開き、「Release Versions」の中から **macOS Tahoe 26.5.1 (25F80)** を選ぶ
   - Xcode を選んだあとは、その Xcode に合う macOS だけが一覧に残る
   - **注意:** Xcode を変えたあとも、チェックは前の値（例: macOS Golden Gate 27.2.1）のまま残っていることがある。必ず選び直す
   - 「Latest Release (Currently macOS Tahoe …)」も選べるが、版が自動で変わるので、版を固定したほうを選ぶ
3. **Environment Variables** は空のままにする。ここに秘密の情報（鍵など）は入れない

### 4-6. Start Conditions（動く条件）

消す前に足します。ワークフローには、動く条件が最低 1 つ要る場合があるためです。

1. 左の「Start Conditions」の右の「+」（丸に十字）を押し、「Pull Request Changes」を選ぶ
2. 開いた画面を、次のようにする

| 項目 | 設定 |
|---|---|
| Source Branch | Any Branch |
| Target Branch | Custom Branches。下の 2 つを足す |
| Files and Folders | Start a Build If Any File Changes |
| Auto-cancel Builds | オン。同じ PR に新しいコミットを足したとき、古いほうのビルドを止めて、時間を節約する |

3. Target Branch の 2 つは、次のように足す
   - 「+」を押して `dev_` と入力し、候補から **branches beginning with "dev_"** を選ぶ
   - 「+」を押して `main` と入力し、候補から **main**（「beginning with」が付かないほう）を選ぶ
   - **注意:** 入力しただけだと、「ちょうどその名前のブランチ」になることがある。`dev_` がちょうどの名前になると、`dev_202611` などは対象にならない。一覧の表示が次のとおりになっていることを確かめる

| 一覧の表示 | 意味 |
|---|---|
| branches beginning with "dev_" | `dev_` で始まるブランチ（`dev_202611` など） |
| main | 名前がちょうど `main` のブランチ |

4. 左の「Branch Changes」（最初からあった条件）を選び、右上のごみ箱のアイコンで消す

### 4-7. Actions（行うこと）

1. 左の「Actions」の右の「+」を押し、「Test」を選ぶ
2. 開いた画面（Test - iOS）を、次のようにする

| 項目 | 設定 |
|---|---|
| Platform | iOS |
| Scheme | mennikki |
| Requirement | Required To Pass。テストが通らないと、ビルド全体を失敗にする |
| Test | Use Scheme Settings。スキームの設定どおり、`mennikkiTests` を動かす |
| Destination | **iPhone 17**。最初は「Recommended iPhones」（Apple が勧める何台かの iPhone）になっているので、選択欄を開いて 1 台に変える |
| OS Version | Latest from Selected Xcode (iOS 26.5)。Xcode を固定しているので、iOS も 26.5 から動かない。Xcode を上げたときは、一緒に新しい iOS に変わる |

3. 左の「Archive - iOS」（最初からあった行うこと）を選び、右上のごみ箱で消す

補足: 選んでいる行の右に赤い ✕ が出ることがありますが、その行を消すためのボタンです。設定の誤りの印ではありません。

### 4-8. Post-Actions

何も足さない（最初のまま、なし）。

### 4-9. 確かめて保存する

1. 左の一覧が、次の形になっていることを確かめる
   - Start Conditions: Pull Request Changes だけ
   - Actions: Test - iOS だけ
   - Post-Actions: なし
2. 左上の「PR Tests」の横のトグルがオンであることを確かめる。オフにすると、設定は残ったまま動かなくなる
3. 右下の「Save」を押す
4. 要約の画面（Review Workflow）で、次のとおりになっていることを確かめて、「Next」を押す
   - Start Condition: Pull Request Changes (Any Branch)。「Any Branch」は元のブランチ（Source Branch）のこと。向き先は要約には出ない
   - Environment: Xcode 26.6 (17F113)
   - Actions: Test (iOS)
   - Post-Actions: No TestFlight Deployments or Notifications

---

## 5. GitHub と接続する

### 5-1. Xcode の画面（Grant Access to Your Source Code）

- `yagi-shi` の下に `yagi-shi/app-mennikki` が表示される。接続する前は、左上が「Unknown github.com」になっている
- 「Grant Access…」を押す。ブラウザが開く

### 5-2. Apple の説明の画面（Xcode Cloud を GitHub に接続する）

これから GitHub で行う 2 つの手順の説明です。

1. Xcode Cloud が、Apple ID と GitHub のアカウントを結び付けることを許可する
2. GitHub に Apple のアプリを入れ、入れる先に `yagi-shi/app-mennikki` を選ぶ

「GitHub でステップ 1 を完了」を押す。このボタンは GitHub の画面を開くだけで、まだ何も許可しない。

### 5-3. GitHub の許可の画面（Xcode Cloud by Apple wants access to your GitHub account）

押す前に、次のことを確かめる。

- 相手が「Xcode Cloud by Apple」であること
- 許可したあとに移る先が `https://appstoreconnect.apple.com` であること（偽物の画面でないことの確認）

求められる中身は次の 3 つ。

| 項目 | 意味 |
|---|---|
| Verify your GitHub identity | GitHub のアカウント（`yagi-shi`）を確かめる |
| Know which resources you can access | 使えるリポジトリなどを知る |
| Act on your behalf | 代わりに操作する。ただし、5-4 で入れるアプリの権限の範囲で、アプリを入れたリポジトリの中だけ |

「Authorize」を押す。

### 5-4. GitHub のアプリを入れる画面（Install Xcode Cloud）

1. 「Install on your personal account yagishi」と出る。「yagishi」はアカウント `yagi-shi` の表示名
2. 入れる先は、最初は「All repositories」になっている。**Only select repositories** に変える
3. 「Select repositories」を押し、`yagi-shi/app-mennikki` だけを選ぶ。「Selected 1 repository.」と出ることを確かめる
4. 権限が次の 2 つだけであることを確かめる

| 権限 | 使い道 |
|---|---|
| Read access to code, metadata, and pull requests | PR を見つけて、コードを取り込み、テストする |
| Read and write access to checks and commit statuses | テストの結果を PR に表示する |

   コードの書き込みの権限はないので、このアプリがブランチを書き換えることはできない
5. 「Install」を押す

### 5-5. 接続できた画面（Xcode Cloud は正常に接続されました）

1. 「Xcode で続ける」を押す
2. ブラウザに「このWebページで "Xcode26.6.app" を開くことを許可しますか?」と出たら、「許可」を押す。「常に許可」ではなく、今回だけの「許可」でよい
3. Xcode が前に出てこないことがある。その場合は、Dock の Xcode か `⌘` + `Tab` で、手で Xcode に切り替える

### 5-6. Xcode に戻ったあと

- 「Grant Access to Your Source Code」の画面で、左上が「GitHub github.com」に変わり、`yagi-shi/app-mennikki` に緑のチェックが付いていることを確かめる
- 「Next」を押す

## 6. App Store Connect のアプリと結び付ける

- 「Confirm App on App Store Connect」の画面に、今あるアプリ（mennikki - シンプルなラーメン日記、`yagishi.mennikki`）が出ることを確かめる
- 「Next」を押す
- ビルドがこのアプリに結び付けられるが、テストだけでアップロードはしないので、ストアのアプリや TestFlight には影響しない

## 7. 最初のビルド

- 「"mennikki" is now configured for Xcode Cloud」と出れば、設定は保存されている
- 「Choose a branch to start your first build.」でブランチを選び「Start Build」を押すと、「Cannot start build for mennikki … the branch is not associated with the workflow」と断られる
  - 手でビルドを始めるには、そのブランチがワークフローのブランチの条件に入っている必要がある。このワークフローは PR でだけ動く設定なので、断られるのは想定どおり
- 「OK」→「Close」で閉じる。最初のビルドは、次の 8 で PR を作って動かす

---

## 8. PR で動くかを確かめる

1. `dev_` で始まるブランチに向けた PR を作る（今回は PR #69。CLAUDE.md と README の変更）
2. PR の下のほうのチェックの欄に、「mennikki | PR Tests」が出ることを確かめる
   - 出てすぐは「queued」（待ち行列）
   - 動き始めると「Waiting for status to be reported — in progress」
   - 終わると、緑のチェック（成功）か赤のバツ（失敗）に変わる
3. Xcode でも確かめられる。Report navigator（`⌘` + `9`）→「Cloud」→「mennikki」→「PR Tests」で、ビルドの一覧が出る

| 一覧の表示 | 意味 |
|---|---|
| 見出し（例: Xcode Cloud で、PR ごとに自動テストを動かす） | PR のタイトル |
| Created from PR Tests | ワークフロー「PR Tests」で動いた |
| Build | このワークフローの何回目のビルドか |
| Status | くるくるは実行中。緑のチェックは成功、赤のバツは失敗 |
| 4 つのアイコンの列 | 左から、警告、解析で見つかった問題、ビルドのエラー、テストの失敗の数 |
| Last Commit | テストしたコミット |

4. ターミナルからは、次のコマンドで確かめられる

```sh
gh pr checks <PR の番号>
```

結果（PR #69、2026-11-22）:

- 成功した。PR には、次の 2 つの結果が表示された

| 名前 | 中身 |
|---|---|
| mennikki \| PR Tests | ワークフロー全体の結果 |
| mennikki \| PR Tests \| Test - iOS | Test の結果。エラー 0、テストの失敗 0、解析の問題 0、警告 0 |

- Test にかかった時間は 3 分 44 秒。PR を作ってから結果が出るまでは、待ち時間を含めて 5 分ほど

## 9. 失敗の表示を確かめる

1. `dev_` で始まるブランチから、確認用のブランチを作る（今回は `feature/68-ci-failure-check`）
2. わざと落ちるテストを 1 つ足す（今回は `mennikkiTests/CIFailureCheckTests.swift` に `#expect(Bool(false))` だけのテスト）
3. タイトルに「マージしない」と書いて、`dev_` で始まるブランチに向けた PR を作る（今回は PR #70）
4. PR の「mennikki | PR Tests」が赤のバツになることを確かめる
5. その PR はマージせずに閉じ、ブランチを手元と GitHub から消す

結果（PR #70、2026-11-22）:

- 失敗が表示された

| 名前 | 中身 |
|---|---|
| mennikki \| PR Tests | 失敗（failed） |
| mennikki \| PR Tests \| Test - iOS | テストの失敗 1、エラー 0、解析の問題 0、警告 0。かかった時間は 3 分 35 秒 |

- ビルドのエラーではなく、テストの失敗として数えられた（ねらいどおり）

## 10. テストが通らないとマージできない設定

GitHub のルールセット「require-pr-tests」で、「mennikki | PR Tests」が成功しないと PR をマージできないようにしました（2026-11-22）。ルールセットは、リポジトリの Settings → Rules → Rulesets で見られます。`main` の削除と強制 push を禁止している「protect-main」とは別のルールセットです。

ルールセットがないと、テストが失敗していても、マージのボタンが押せてしまいます（PR #70 で、実際に押せる状態でした）。

### 中身

| 項目 | 設定 | 理由 |
|---|---|---|
| 名前 | require-pr-tests | |
| 対象のブランチ | 既定のブランチ（`main`）と、`dev_` で始まるブランチ | Xcode Cloud が動く PR と同じにする |
| 必要な結果 | mennikki \| PR Tests（ワークフロー全体の結果） | Test だけの結果より、行うことを増やしても名前が変わらないため |
| 結果を出せる相手 | Xcode Cloud のアプリ（番号 117084）だけ | ほかから同じ名前で「成功」を送られても、通らないようにする |
| 向き先の最新に追いついている必要 | なし | feature は 1 つずつマージしているので、困らないため |
| ブランチを作るとき | この条件を当てはめない | リリースのたびの `dev_YYYYMM` の作成が止まらないようにする |
| 例外にできる人 | リポジトリの管理者。PR をマージするときに限る | Xcode Cloud が止まったときや、月 25 時間を使い切ったときに、管理者がはっきり選べばマージできるようにする。PR を通さない直接の push は例外にしない |

### 作り方

結果の名前（`mennikki | PR Tests`）とアプリの番号は、ワークフローが一度 PR で動いたあとでないと分かりません。先に 8 を行います。

1. アプリの番号を調べる。8 の PR のコミットの結果から、次のコマンドで分かる

```sh
gh api repos/yagi-shi/app-mennikki/commits/<コミットの SHA>/check-runs -q '.check_runs[] | "\(.name) \(.app.slug) \(.app.id)"'
```

   `xcode-cloud 117084` のように出る

2. 次の中身のファイル（例: `ruleset.json`）を作る

```json
{
  "name": "require-pr-tests",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["~DEFAULT_BRANCH", "refs/heads/dev_*"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "do_not_enforce_on_create": true,
        "required_status_checks": [
          { "context": "mennikki | PR Tests", "integration_id": 117084 }
        ]
      }
    }
  ],
  "bypass_actors": [
    { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "pull_request" }
  ]
}
```

3. 次のコマンドで作る

```sh
gh api -X POST repos/yagi-shi/app-mennikki/rulesets --input ruleset.json
```

GitHub の画面（Settings → Rules → Rulesets → New ruleset → New branch ruleset）でも、同じ中身で作れます。

### 確かめ方

1. 例外にできる人が、管理者（admin）になっているかを確かめる。`actor_id: 5` が管理者を表すことは、GitHub の資料に書かれていないため、作ったあとで確かめる

```sh
gh api graphql -f query='query { repository(owner:"yagi-shi", name:"app-mennikki") { rulesets(first: 10) { nodes { name enforcement bypassActors(first: 5) { nodes { bypassMode repositoryRoleName } } } } } }'
```

   `require-pr-tests` の `repositoryRoleName` が `admin`、`bypassMode` が `PULL_REQUEST` なら大丈夫

2. テストが失敗している PR と、成功している PR で、マージできるかを確かめる

```sh
gh pr view <PR の番号> --json mergeStateStatus
```

   失敗している PR は `BLOCKED`（マージできない）、成功している PR は `CLEAN`（マージできる）になる

結果（2026-11-22）:

- 例外にできる人は `admin`、`PULL_REQUEST` だった
- テストが失敗している PR #70 は `BLOCKED`、成功している PR #69 は `CLEAN` だった

### 例外としてマージするとき

Xcode Cloud が止まっているときなど、テストの結果が出ないのにマージが必要なときは、管理者が PR の画面で、例外としてマージするためのチェック（bypass）を入れてマージします。ふだんは使いません。

### 注意

ワークフローの名前（`PR Tests`）を変えると、結果の名前（`mennikki | PR Tests`）も変わります。そのままだと、必要な結果がいつまでも届かず、どの PR もマージできなくなります。名前を変えるときは、このルールセットの `context` も同時に直します。

---

## 11. 運用のルール

CLAUDE.md の「テストのルール」に書いてあります。要点は次のとおりです。

- PR は、Xcode Cloud のテストが成功してからマージする。失敗したら、原因を直してから push し直す
- `main` と `dev_` で始まるブランチでは、テストが成功しないと PR をマージできない（ルールセット require-pr-tests。10 を参照）
- Xcode の版は、手元と Xcode Cloud で同じにする

## 12. あとで設定を変えるとき

### ワークフローを開く

- Xcode の Report navigator（`⌘` + `9`）→「Cloud」で、「mennikki」を Control + クリック →「Manage Workflows」→「PR Tests」をダブルクリック

### Xcode を上げるとき

次の 3 つを、同じ作業でそろえて上げます。

1. 手元の Xcode。前の版は消さずに、別の名前で並べて入れる（例: `/Applications/Xcode26.6.app` と並べる）
2. このワークフローの Environment の Xcode Version と macOS Version（4-5 と同じ手順）
3. CLAUDE.md のテストのコマンドのシミュレータの版（`OS=26.5` の部分）

あわせて、Actions の Destination の機種と OS Version が、新しい Xcode でも選べるかを確かめます。この手順書の版の番号も直します。

### 一時的に止めるとき

ワークフローの編集画面の左上のトグルをオフにします。設定は残ります。

止めている間は、テストの結果が届かないので、ルールセット require-pr-tests により、PR をマージできません。マージが必要なら、管理者が例外としてマージします（10 を参照）。

### ワークフローの名前を変えるとき

ルールセット require-pr-tests の `context`（`mennikki | PR Tests`）も、同時に直します（10 の注意を参照）。

### GitHub のアプリの範囲を確かめる、変える、取り消すとき

GitHub の Settings → Applications → Installed GitHub Apps → Xcode Cloud の「Configure」を開きます。入れる先のリポジトリの確認と変更、アプリの取り外しができます。

## 13. つまずいたところ

| 起きたこと | 原因 | 対処 |
|---|---|---|
| Xcode を 26.6 にしたあとも、macOS が 27 のままだった | 前に選んでいた値が残る | macOS を選び直す（4-5） |
| Target Branch の `dev_` が、ちょうどの名前になった | 入力しただけだと、ちょうどの名前になることがある | 候補から「branches beginning with "dev_"」を選ぶ（4-6） |
| `main` が「branches beginning with "main"」になった | 同上 | 候補から、「beginning with」が付かない「main」を選ぶ（4-6） |
| テストの機種が「Recommended iPhones」になっていた | 最初の設定が、何台かの iPhone で動かす設定 | iPhone 17 の 1 台に変える（4-7） |
| 結果のメールが来ると思っていたが、Post-Actions は最初から「通知なし」だった | 最初の設定が通知なし | 結果は PR に出るので、そのままにした |
| 「許可」を押しても Xcode に戻らなかった | ブラウザから Xcode に切り替わらなかった | 手で Xcode に切り替える。接続は済んでいた（5-5） |
| 最初のビルドを手で始められなかった | PR でだけ動く設定のため | 想定どおり。PR を作って動かす（7） |
| テストが失敗している PR でも、マージのボタンが押せた | ルールセットを作る前だったため | ルールセット require-pr-tests を作る（10） |

## 14. 参考にした資料

- [Configuring your first Xcode Cloud workflow](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow)
- [Configuring start conditions](https://developer.apple.com/documentation/xcode/configuring-start-conditions)
- [Connecting Xcode Cloud to GitHub](https://developer.apple.com/documentation/xcode/connecting-xcode-cloud-to-github)
- [Configuring requirements for merging a pull request](https://developer.apple.com/documentation/xcode/configuring-requirements-for-merging-a-pull-request)
- [Setting the next build number for Xcode Cloud builds](https://developer.apple.com/documentation/xcode/setting-the-next-build-number-for-xcode-cloud-builds)（TestFlight への配信を始めるときに読む）
- [REST API endpoints for rules（GitHub Docs）](https://docs.github.com/en/rest/repos/rules)
- GitHub の issue #68（決めたことの経緯）
