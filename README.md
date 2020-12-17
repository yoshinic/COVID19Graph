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

1. 検索用 URL にリクエスト

このあとは DynamoDB Stream により動きが２つに分かれる 

2. 応答が返ってきたら、検索用 URL とページ番号を取得した「 search_parameters 」テーブルに保存。

    4. 2 の保存をトリガーとして、次のページ URL にリクエスト

    5. 2, 4 を繰り返して、スクレイピング対象 URL が無ければ終了

3. 検索結果 URL を「 url_store 」に保存

    6. 3 の保存をトリガーとして、スクレイピング対象 URL にリクエスト

    7. 取得した HTML をパースして Race or Horse 構造体として 「 races 」or 「 horses 」テーブルに 保存

<br>

# 使用方法

1. Labmda 関数を AWS Lambda に設定

    - DownloadLambdaHandler：
        - グラフ表示に使用するCSVデータをDynamoDBに保存する関数
        - タイムアウトを１５分で設定
        - メモリは128M

    - MPrefectureLambdaHandler：
        - DownloadLambdaHandlerで保存したDynamoDBデータを、さらにグラフ表示用にデータを作成して、DynamoDBに保存する関数
        - Result Model に対する DynamoDB Strean Trigger として設定
        - タイムアウト３分
        - メモリは256M

    - WebsiteLambdaHandler:
        - グラフ表示API関数
        - ユーザーからのリクエストに対してグラフ表示用HTMLをレスポンスとして返す
        - タイムアウト１０秒
        - メモリは128M

2. 設定した Lambda 関数に環境変数を設定

    - ACCESS_KEY_ID：Lambda 関数、DynamoDB を使用するユーザーID

    - SECRET_ACCESS_KEY：ユーザーのパスワード

    - REGION：AWS の地域。

3. Result Table を作成する。

    DynamoDB Stream の Trigger を設定する必要があるため、手動で行う。

4. WebsiteLambdaHandler に設定したLambda関数に対して API を作成

5. DownloadLambdaHandlerに対して設定した Lambda 関数で
