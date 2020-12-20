# COVID19Graph
 
新型コロナウイルスについてのデータをグラフ化します。

<br>

データは下記のものを利用させて頂いています。
 
- 東洋経済オンライン「新型コロナウイルス 国内感染の状況」制作：荻原和樹

- [GitHubのソースコード](https://github.com/kaz-ogiwara/covid19/)

<br>

# 主な機能

>#### 必須
>- AWS Lambda へ関数登録する必要があります。
>
>- DynamoDB の設定の仕方で、うまく動作しない場合があります。

- 新型コロナに関する各CSVファイルのデータを上記サイトからダウンロードし、Amazon DynamoDB へ保存します。

- 保存したDynamoDBデータを、さらにグラフ表示用データに変換して保存します。

- グラフ表示用APIの作成

    - 月別・都道府県別・項目別のデータをグラフとして表示します。

# 環境
 
- Swift 5.3 以上

- Amazon DynamoDB

- AWS Lambda 

<br>

# ツリーマップ

├── Sources
<br>
│   └── COVID19Graph
<br>
│       ├── Controllers
<br>
&emsp;&emsp;&emsp;&ensp;
（ModelのDynamoDBに対する操作）
<br>
│       ├── LambdaHandlers
<br>
&emsp;&emsp;&emsp;&ensp;
（AWS Lamda関数群）
<br>
│       │   ├── DownloadLambdaHandler.swift
<br>
&emsp;&emsp;&emsp;&emsp;&ensp;
（上記サイトのCSVファイルをDynamoDBへ保存）
<br>
│       │   ├── DynamoDBLambdaHandler.swift
<br>
&emsp;&emsp;&emsp;&emsp;&ensp;
（各LambdaHandler用のprotocol）
<br>
│       │   ├── MPrefectureLambdaHandler.swift
<br>
&emsp;&emsp;&emsp;&emsp;&ensp;
（グラフ表示用のDynamoDBデータを保存）
<br>
│       │   ├── WebsiteLambdaHandler.swift
<br>
&emsp;&emsp;&emsp;&emsp;&ensp;
（グラフ表示API用関数）
<br>
│       │   └── WebsiteLambdaHandler+HTML.swift
<br>
&emsp;&emsp;&emsp;&emsp;&ensp;
（グラフ表示API用のHTML作成箇所）
<br>
│       ├── Models
<br>
&emsp;&emsp;&emsp;&ensp;
（各CSVデータをDynamoDB用に定義しモデル化）
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
└── package.sh
<br>
&emsp;&emsp;&emsp;&ensp;
（AWS LambdaでSwiftを動作させるためのスクリプト）

<br>

# 使用方法

### # ローカルPCでの作業

#### ・ AWS Lambda用の zip ファイルを作成

1. このプロジェクトをローカルPCにクローン

    git clone https://github.com/yoshiswift/COVID19Graph.git

2. cd COVID19Graph

3. AWS Lambda 用にコンパイル

    - docker run --rm --volume "$(pwd)/:/src" --workdir "/src/" swift-lambda-builder swift build --product COVID19Graph -c release

4. Swift ファイル群の zip を作成

    - docker run --rm --volume "$(pwd)/:/src" --workdir "/src/" swift-lambda-builder scripts/package.sh COVID19Graph

<br>

### # AWS コンソール上での操作

#### ・ グラフ表示のためのデータを作成

5. AWS Lambda関数を作成

    - 必要な関数は４つ

    - それぞれの関数に

        - タイムアウト
        
        - 使用メモリ量
        
        - 環境変数

        を設定

    - 環境変数は次の４つを設定

        - ACCESS_KEY_ID：Lambda 関数、DynamoDB を使用するユーザーID

        - SECRET_ACCESS_KEY：ユーザーのパスワード

        - REGION：AWS の地域

        - TYPE: 実行する関数を決定

        <br>

    - TableLambdaHandler に対応する関数：

        - データ作成、グラフ表示に必要な DynamoDB テーブルを作成する関数

        - タイムアウト：10秒

        - メモリ：128M

        - TYPE = table

    - DownloadLambdaHandler に対応する関数：

        - グラフ表示に使用するCSVデータをDynamoDBに保存する関数

        - タイムアウト：１５分

        - メモリ：128M

        - TYPE = download

        - CSV ファイルの URL をリクエストパラメータで設定

    - MPrefectureLambdaHandler に対応する関数：

        - DownloadLambdaHandler で保存したDynamoDB データを、さらにグラフ表示用にデータを作成して、DynamoDBに保存する関数

        - results テーブルに対する DynamoDB Stream Trigger として設定

        - タイムアウト：３分

        - メモリ：256M

        - TYPE = prefecture

    - WebsiteLambdaHandler に対応する関数:

        - グラフ表示API関数

        - ユーザーからのリクエストに対してグラフ表示用HTMLをレスポンスとして返す

        - タイムアウト：１０秒

        - メモリ：128M

        - TYPE = website

6. 作成した zip ファイルを AWS にアップロード

7. results テーブルに mprefecture 関数をトリガーとして設定

8. Lambda 関数の table 関数を実行

9. テーブルが作成されたのを確認して Lambda 関数のdownload 関数を実行

10. API を作成