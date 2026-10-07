# シニア向け健康増進プロジェクト「23区対抗WALK」

<div align="center">

**🚶 歩くこと を、地域を繋ぐエンターテインメントへ**

![Project Status](https://img.shields.io/badge/status-development-blue)
![Team](https://img.shields.io/badge/team-Group%209%20Team%205-green)
![License](https://img.shields.io/badge/license-MIT-blue)

</div>

---

## 📋 プロジェクト概要

### VISION
超高齢社会における**健康寿命の延伸**と**社会的孤立の解消**を目指し、シニア層が「歩くこと」を通じて地域コミュニティとつながる LINEミニアプリです。

東京都23区対抗の競技形式で、ご近所の仲間と一緒に健康増進に取り組みます。

### 🎯 主な特徴

- **📱 LINEで楽々スタート**
  - ダウンロード・登録不要、LINEミニアプリで完結
  - シニア層の利用ハードルを最小化

- **👥 ご近所チームで継続**
  - 町内会や馴染みの仲間とチーム化
  - 「みんなのために」という前向きな義務感を創出

- **⚡ 速さを測って健康に**
  - スマホセンサーで「歩く速さ」を測定
  - ロコモ予防（寝たきり予防）をサポート

---

## 👥 チーム体制

| 職務 | メンバー | 主な責務 |
|------|---------|--------|
| **PM 兼 進行管理** | 広瀬 龍征 | 全体進捗管理・意思決定 |
| **PO 兼 企画・UI/UXデザイン** | 郷原 拓海 | 機能設計・デザイン・優先度付け |
| **フロントエンド 兼 実装リード** | 西川 裕貴 | Flutter アプリ開発・UI実装 |
| **バックエンド / インフラ** | 赤塚 蔵人 | Firebase・API・データベース |

---

## 🏗 プロジェクト構成

```
team-jissyuu/
├── README.md                           # このファイル
├── docs/                               # 技術ドキュメント
│   ├── PROJECT_PLAN.md                 # プロジェクト計画書
│   ├── TECHNICAL_SPEC.md               # 技術仕様書
│   ├── API_DESIGN.md                   # API設計書
│   └── DATABASE_SCHEMA.md              # Firestore スキーマ設計
│
├── frontend/                           # Flutter アプリケーション
│   ├── lib/
│   │   ├── main.dart                   # エントリポイント
│   │   ├── screens/                    # ページ（ホーム、ランキング等）
│   │   ├── widgets/                    # 再利用可能なUIコンポーネント
│   │   ├── services/                   # API・センサー連携
│   │   ├── models/                     # データモデル
│   │   └── utils/                      # ユーティリティ関数
│   ├── pubspec.yaml                    # Flutter 依存関係
│   └── test/                           # ユニットテスト
│
├── backend/                            # Firebase + Python
│   ├── functions/                      # Cloud Functions (Node.js)
│   │   ├── index.js                    # エントリポイント
│   │   ├── auth.js                     # LINE連携・認証
│   │   ├── walking-api.js              # 歩数データ取得・保存
│   │   ├── ranking-api.js              # ランキング計算
│   │   └── package.json
│   ├── scripts/                        # Python スクリプト
│   │   ├── scoring_algorithm.py        # スコアリング数理モデル
│   │   ├── push_notification.py        # プッシュ通知（MAB）
│   │   ├── data_export.py              # 分析用データ
│   │   └── requirements.txt
│   ├── firestore.rules                 # Firestore セキュリティルール
│   ├── firebase.json                   # Firebase 設定
│   └── .env.example                    # 環境変数テンプレート
│
├── .github/
│   ├── workflows/
│   │   ├── test.yml                    # テスト実行パイプライン
│   │   └── deploy.yml                  # デプロイパイプライン
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md               # バグレポートテンプレート
│       └── feature_request.md          # 機能リクエストテンプレート
│
└── .gitignore                          # Git除外ファイル

```

---

## 🚀 クイックスタート

### 前提条件

- **Node.js**: v18.0.0 以上
- **Python**: 3.9 以上
- **Flutter**: 3.0 以上
- **Firebase CLI**: 最新版
- **Git**: v2.30 以上

### セットアップ手順

#### 1️⃣ リポジトリのクローン

```bash
git clone https://github.com/1F10240045/team-jissyuu.git
cd team-jissyuu
```

#### 2️⃣ フロントエンド（Flutter）のセットアップ

```bash
cd frontend

# 依存パッケージをインストール
flutter pub get

# iOS の依存関係を解決（Mac環境の場合）
cd ios
pod install
cd ..

# アプリを実行（エミュレータまたは実機接続時）
flutter run
```

#### 3️⃣ バックエンド（Firebase Functions）のセットアップ

```bash
cd backend/functions

# Node.js 依存関係をインストール
npm install

# ローカルで Firebase エミュレータを起動
firebase emulators:start

# 別ターミナルでテスト実行
npm test
```

#### 4️⃣ Python スクリプト環境のセットアップ

```bash
cd backend/scripts

# 仮想環境を作成
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# または
venv\Scripts\activate  # Windows

# 依存パッケージをインストール
pip install -r requirements.txt

# スコアリングアルゴリズムのテスト
python3 -m pytest ../tests/
```

#### 5️⃣ 環境変数の設定

```bash
cd backend

# .env.example をコピーして .env を作成
cp .env.example .env

# .env ファイルを編集して必要な値を設定
# - Firebase API キー
# - LINE Messaging API チャネルID・シークレット
# - その他認証情報
```

---

## 📱 主要機能

### 現在開発中の機能

- [ ] **ホーム画面** - 日次歩数表示・目標進捗
- [ ] **ランキング表示**
  - 23区対抗ランキング
  - フレンドチーム別ランキング
  - 個人の過去データ比較グラフ
- [ ] **フレンド機能** - チームメンバー管理・チャット
- [ ] **マップ表示** - 歩行ルート可視化
- [ ] **プッシュ通知** - 適応型ナッジ配信
- [ ] **LINE ミニアプリ連携** - ダウンロード不要での利用

---

## 🛠 開発ワークフロー

### ブランチ戦略

```
main (本番環境)
  ↑
  ├─ develop (開発環境)
  │   ↑
  │   ├─ feature/***  (新機能開発)
  │   ├─ bugfix/***   (バグ修正)
  │   └─ refactor/*** (リファクタリング)
```

### 新機能追加の流れ

1. **ブランチ作成**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **コード実装・テスト**
   ```bash
   # コード作成
   # テスト実行
   flutter test          # Flutter テスト
   npm test              # Firebase Functions テスト
   pytest backend/tests  # Python テスト
   ```

3. **コミット・プッシュ**
   ```bash
   git add .
   git commit -m "feat: 機能説明"
   git push origin feature/your-feature-name
   ```

4. **Pull Request 作成**
   - GitHub で PR を作成（develop へのマージを指定）
   - コードレビュー依頼（PO・リード確認）
   - レビュー対応 → マージ

5. **デプロイ**
   ```bash
   git checkout main
   git pull origin develop
   git push origin main
   # CI/CD が自動実行 → 本番環境にデプロイ
   ```

---

## 📊 プロジェクト進捗

### 実装フェーズ

- **Phase 1（Week 1-2）**: プロジェクト基盤構築 - `進行中`
- **Phase 2（Week 2-4）**: 技術基盤構築 - `計画中`
- **Phase 3（Week 4-6）**: コア機能開発 - `計画中`
- **Phase 4（Week 6-8）**: UX強化・最適化 - `計画中`
- **Phase 5（Week 8-10）**: テスト・デプロイ - `計画中`
- **Phase 6（Week 10+）**: 本格運用 - `計画中`

📌 **進捗状況は [GitHub Projects](https://github.com/1F10240045/team-jissyuu/projects) を参照してください**

---

## 🤝 コントリビューション

### やることリスト

各メンバーの初期タスクについては、以下を参照してください：

- **GitHub Issues** - 課題・タスク管理
- **GitHub Projects** - スプリント・進捗管理
- **GitHub Discussions** - チーム間の技術討論・意思決定

### コード規約

各言語のコード規約に従ってください：

- **Dart/Flutter** - [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- **JavaScript** - ESLint ルール準拠
- **Python** - PEP 8 準拠

---

## 📚 技術スタック

| レイヤー | 技術 | 役割 |
|---------|------|------|
| **フロントエンド** | Flutter | クロスプラットフォーム モバイルアプリ |
| **フロントエンド** | LINE SDK | LINEミニアプリ連携 |
| **バックエンド** | Firebase | リアルタイムDB・認証・ホスティング |
| **バックエンド** | Cloud Functions | サーバーレス API |
| **バックエンド** | Python | スコアリング・分析処理 |
| **センサー連携** | HealthKit (iOS) | iOS歩数・速度計測 |
| **センサー連携** | Google Fit (Android) | Android歩数・速度計測 |
| **データベース** | Firestore | NoSQL リアルタイムDB |
| **CI/CD** | GitHub Actions | 自動テスト・デプロイ |

---

## 📖 ドキュメント

詳細な技術仕様については、以下を参照してください：

- [📄 プロジェクト計画書](docs/PROJECT_PLAN.md)
- [🔧 技術仕様書](docs/TECHNICAL_SPEC.md)
- [📡 API 設計書](docs/API_DESIGN.md)
- [🗄️ Firestore スキーマ設計](docs/DATABASE_SCHEMA.md)

---

## 🐛 バグ報告・機能リクエスト

### バグを発見した場合

GitHub Issues から [バグレポート](https://github.com/1F10240045/team-jissyuu/issues/new?template=bug_report.md) を作成してください。

**記載項目:**
- バグの説明
- 再現手順
- 期待される動作
- 実際の動作
- スクリーンショット（必要に応じて）

### 新機能を提案したい場合

GitHub Issues から [機能リクエスト](https://github.com/1F10240045/team-jissyuu/issues/new?template=feature_request.md) を作成してください。

---

## 📞 お問い合わせ・コミュニケーション

- **技術的な質問**: GitHub Discussions
- **プロジェクト管理**: GitHub Issues・Projects
- **チーム連携**: Slack（オンサイト時）

---

## 📄 ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。

詳細は [LICENSE](LICENSE) をご覧ください。

---

## 🎓 参考資料

### 超高齢社会・健康寿命に関する論文

- 山縣 然太朗 (2018): 「閉じこもり傾向層の社会参加促進要因」
- 北島 尚志 (2018): 「男性シニアの運動習慣継続要因」
- 重松 良祐 (2011): 「運動継続のためのコミュニティ設計」

### シニアのスマートフォン利用動向

- 総務省統計局: スマートフォン普及率（60代: 95%, 70代: 86%）
- 内閣府: 「高齢者の幸福度調査」 - 健康状況が最重視される傾向

---

<div align="center">

**Last Updated**: 2026-10-07  
**Version**: 0.1.0 (Development)

Made with ❤️ by Group 9 Team 5

</div>
