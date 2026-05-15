# PriorityUpdater

リマインダーの期限日に基づいて、自動的に優先度を設定する Swift パッケージです。

| 期限まで | 優先度 |
|---|---|
| 0〜3日 | 高（1） |
| 4〜7日 | 中（5） |
| 8〜14日 | 低（9） |
| 15日以上 | なし（0） |

---

## パッケージ構成

```
PriorityUpdater/
├── Package.swift
└── Sources/
    ├── PriorityUpdaterCore/          # iOS / macOS 共通ライブラリ
    │   └── ReminderPriorityUpdater.swift
    └── PriorityUpdaterCLI/           # macOS 専用 CLI ツール
        └── main.swift
```

- **`PriorityUpdaterCore`** — `EventKit` を使ったリマインダー更新ロジック。iOS・macOS の両方で利用可能。
- **`PriorityUpdaterCLI`** — macOS のターミナルから実行する CLI アダプター。iPhone では動作しません。

---

## iPhone (iOS) で動かす手順

iPhone のリマインダーは直接コマンドラインで操作できないため、**iOS アプリに組み込む**形で実行します。以下の手順に従ってください。

### 前提条件

- Xcode 15 以上（Apple Silicon Mac を推奨）
- iPhone: iOS 17 以上
- Apple Developer アカウント（実機テスト用。無料アカウントでも可）

---

### ステップ 1: Xcode プロジェクトを作成する

1. Xcode を起動し、**Create New Project** を選択。
2. **iOS > App** テンプレートを選び、**Next**。
3. 以下を入力して **Next**:
   - **Product Name**: `PriorityUpdaterApp`（任意）
   - **Interface**: SwiftUI
   - **Language**: Swift
4. 保存先フォルダを選択して **Create**。

---

### ステップ 2: PriorityUpdaterCore を Swift Package として追加する

1. メニューバーから **File > Add Package Dependencies...** を選択。
2. 検索フィールドにこのリポジトリの URL を入力:
   ```
   https://github.com/beso1225/priority-updater
   ```
3. バージョンルールを選択（`Up to Next Major Version` を推奨）し、**Add Package**。
4. ライブラリ選択画面で **`PriorityUpdaterCore`** にチェックを入れ、ターゲットをアプリに設定して **Add Package**。

---

### ステップ 3: リマインダーのアクセス許可を設定する

1. Xcode でアプリのターゲットを選択し、**Info** タブを開く。
2. **Custom iOS Target Properties** に以下のキーを追加:

   | Key | Value |
   |---|---|
   | `Privacy - Reminders Usage Description` | 例: `リマインダーの優先度を期限に合わせて自動更新します。` |

   > このキーがない場合、アプリが iOS 17 のリマインダー権限をリクエストできず、クラッシュします。

---

### ステップ 4: アプリのコードに組み込む

`ContentView.swift` を以下のように書き換えます:

```swift
import SwiftUI
import PriorityUpdaterCore

struct ContentView: View {
    @State private var statusMessage = "タップして優先度を更新"

    var body: some View {
        VStack(spacing: 24) {
            Text(statusMessage)
                .multilineTextAlignment(.center)
                .padding()

            Button("リマインダーの優先度を更新") {
                updatePriorities()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func updatePriorities() {
        statusMessage = "更新中..."
        let updater = ReminderPriorityUpdater()
        updater.updateReminderPriorities { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let summary):
                    statusMessage = """
                    完了！
                    スキャン: \(summary.totalReminders) 件
                    更新済み: \(summary.updatedReminders) 件
                    失敗: \(summary.failedReminders) 件
                    """
                case .failure(let error):
                    statusMessage = "エラー: \(error.localizedDescription)"
                }
            }
        }
    }
}
```

---

### ステップ 5: iPhone 実機で実行する

1. iPhone を Mac に USB ケーブルで接続する（または Wi-Fi 経由のデバイスリンクを使用）。
2. Xcode のツールバーで実行先を自分の iPhone に切り替える。
3. **Product > Run**（または `⌘R`）を押してビルド・インストール。
4. 初回起動時にリマインダーのアクセス許可ダイアログが表示されるので **「すべてのリマインダーへのアクセスを許可」** を選択。
5. ボタンをタップして優先度の自動更新を実行。

> **初回実機テストの場合**: iPhone で **設定 > 一般 > VPN とデバイス管理** を開き、開発元（自分の Apple ID）を「信頼」に設定する必要があります。

---

### 優先度のマッピング

`EKReminder.priority` は CalDAV 標準に準拠した整数値です:

| `priority` 値 | リマインダー表示 |
|---|---|
| `1` | 高 |
| `5` | 中 |
| `9` | 低 |
| `0` | なし |

---

## macOS CLI での実行（参考）

macOS のターミナルから直接実行する場合はリポジトリを clone してビルドします:

```bash
git clone https://github.com/beso1225/priority-updater.git
cd priority-updater
swift run priority-updater
```

> macOS 14 (Sonoma) 以上が必要です。初回実行時に「コンピューターのリマインダーを変更しようとしています」という確認ダイアログが表示されます。

---

## 動作要件まとめ

| 実行環境 | 最低バージョン | 備考 |
|---|---|---|
| iPhone (iOS) | iOS 17 | Xcode アプリに組み込んで実行 |
| Mac (CLI) | macOS 14 | `swift run priority-updater` |
| Xcode | 15 以上 | iOS アプリビルド用 |
