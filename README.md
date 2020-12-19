# COVID19Graph
 
 新型コロナウイルスについてのデータをグラフ化します。

 データは下記のものを利用させて頂いています。
 
 - 東洋経済オンライン「新型コロナウイルス 国内感染の状況」制作：荻原和樹

 - [GitHubのソースコード](https://github.com/kaz-ogiwara/covid19/)

<br>

# 主な機能

>#### 事前設定
>- AWS Lambda へ関数登録する必要があります。
>
>- DynamoDB の設定によってはうまく動作しません。

- 上記サイトから、新型コロナに関する各CSVファイルのデータをAmazon DynamoDBへ保存する。

- 保存したDynamoDBデータを、さらにグラフ表示用データに変換して保存する。

- グラフ表示用APIの作成

    - 月別・都道府県別・項目別のデータをグラフとして表示できます。

# 環境
 
- Swift 5.2 以上

- Amazon DynamoDB

- AWS Lambda 

<br>

# ツリーマップ

├── Sources
<br>
│   └── COVID19Graph
<br>
│       ├── Controllers（ModelをDynamoDBに対して操作）
<br>
│       ├── LambdaHandlers（AWS Lamda関数群）
<br>
│       │   ├── DownloadLambdaHandler.swift（上記サイトのCSVファイルをDynamoDBへ保存）
<br>
│       │   ├── DynamoDBLambdaHandler.swift（各LambdaHandler用のprotocol）
<br>
│       │   ├── MPrefectureLambdaHandler.swift（グラフ表示用のDynamoDBデータを保存）
<br>
│       │   ├── WebsiteLambdaHandler.swift（グラフ表示API用関数）
<br>
│       │   └── WebsiteLambdaHandler+HTML.swift（グラフ表示API用のHTML作成箇所）
<br>
│       ├── Models（各CSVデータをDynamoDB用に定義しモデル化）
<br>
│       ├── Utilities
<br>
│       └── main.swift
<br>
├── Tests
<br>
└── scripts
<br>
&nbsp;&nbsp;&nbsp;&nbsp;
└── package.sh（AWS LambdaでSwiftを動作させるためのスクリプト）

<br>

# 全体の動き

<br>

# 使用方法

## ローカルPCでの作業

### AWS Lambda用の zip ファイルを作成する

1. このプロジェクトをクローン

2. cd （プロジェクトディレクトリに移動）

3. AWS Lambda 用にコンパイル

    - docker run --rm --volume "$(pwd)/:/src" --workdir "/src/" swift-lambda-builder swift build --product COVID19Graph -c release

    - プロジェクト名は任意

4. zip ファイルの作成

    - docker run --rm --volume "$(pwd)/:/src" --workdir "/src/" swift-lambda-builder scripts/package.sh COVID19Graph

    - プロジェクト名は 3 に合わせる

<br>

## AWS コンソール上での操作

### グラフ表示のためのデータを作成

5. Lambda関数を作成

    - 必要な関数は４つ

    - TableLambdaHandler に対応：

        - データ作成、グラフ表示に必要な DynamoDB テーブルを作成する関数

        - TYPE = table

    - DownloadLambdaHandler に対応：

        - グラフ表示に使用するCSVデータをDynamoDBに保存する関数

        - タイムアウトを１５分で設定

        - メモリは128M

        - TYPE = download

        - リクエストパラメータの設定

    - MPrefectureLambdaHandler に対応：

        - DownloadLambdaHandlerで保存したDynamoDBデータを、さらにグラフ表示用にデータを作成して、DynamoDBに保存する関数

        - Result Model に対する DynamoDB Strean Trigger として設定

        - タイムアウト３分

        - メモリは256M

        - TYPE = prefecture

    - WebsiteLambdaHandler に対応:

        - グラフ表示API関数

        - ユーザーからのリクエストに対してグラフ表示用HTMLをレスポンスとして返す

        - タイムアウト１０秒

        - メモリは128M

        - TYPE = website

    - 全ての Lambda 関数共通で、環境変数を４つ設定

        - ACCESS_KEY_ID：Lambda 関数、DynamoDB を使用するユーザーID

        - SECRET_ACCESS_KEY：ユーザーのパスワード

        - REGION：AWS の地域。

        - TYPE: （上記の値）

6. 作成した zip ファイルを AWS にアップロード

7. results テーブルに mprefecture 関数をトリガーとして設定

8. Lambda 関数の table 関数を実行

9. テーブルが作成されたのを確認して Lambda 関数のdownload 関数を実行