# FocusQuest パーティーサーバーを Render に公開

Render の無料Web Serviceを1インスタンスだけ作成する設定です。専用ドメインやデータベースは不要です。設定元はリポジトリ直下の `render.yaml`、実行プログラムは `server/party_server.dart` です。

1. https://dashboard.render.com/ で GitHub アカウントを使って登録／ログイン。
2. GitHub連携で `eido0916/focusquest` を選択できる状態にする。
3. New → Blueprint を選び、`codex/party-hosting` ブランチから `render.yaml` を読み込む。
4. 作成内容が `focusquest-party` / Docker / Free / Singapore / 1 instance であることを確認して適用。
5. デプロイが Live になったら、サービス画面の実際のURLをコピーする。サービス名が競合している場合はURLに識別子が付くため、URLを推測しない。
6. `https://発行されたホスト/health` が `ok` を返すことを確認する。
7. アプリの接続先は `wss://発行されたホスト/party`。このURLをCodexに伝えると、接続テストと接続先を組み込んだAPKの作成を続けられる。

無料枠は通信のない状態が15分続くと休止し、再接続での起動に約1分かかります。最初の接続ではしばらく待ってください。アプリの接続タイムアウトは90秒へ延長しています。公開前に作成した旧APKは10秒でタイムアウトするため、起動後に再試行するか、新しいAPKを使用します。

無料枠には利用時間・通信量・ビルド時間の上限があります。上限に達すると停止する場合があります。個人での初期動作確認用です。自動デプロイは無効にしているため、更新は手動で行います。再デプロイやサーバー再起動では待機室が消えますが、開始済みの集中は各端末で継続します。

サーバー単体の確認（Flutter不要）:

```text
dart analyze server/party_server.dart server/smoke_test.dart
dart run server/smoke_test.dart
```

ヘルスチェック・4クライアントのコード参加・5人目拒否・未準備拒否・共通開始時刻を検証します。

公式情報:
- https://render.com/docs/free
- https://render.com/docs/websocket
- https://render.com/docs/blueprint-spec
