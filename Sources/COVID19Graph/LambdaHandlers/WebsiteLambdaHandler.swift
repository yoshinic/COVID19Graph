import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import NIO

typealias PrefectureID = Int

struct WebsiteInput: Codable {
    
}

struct WebsiteOutput: Codable {
    let statusCode: HTTPResponseStatus
    let headers: HTTPHeaders?
    let body: String?
}

struct WebsiteLambdaHandler: DynamoDBLambdaHandler {
    typealias In = WebsiteInput
    typealias Out = WebsiteOutput
    
    let deathController: DeathController
    let prefectureController: PrefectureController
    
    let prefectureMaster: [PrefectureID: String] = [
        0: "北海道", 1: "青森県", 2: "岩手県", 3: "宮城県", 4: "秋田県", 5: "山形県", 6: "福島県", 7: "茨城県",
        8: "栃木県", 9: "群馬県", 10: "埼玉県", 11: "千葉県", 12: "東京都", 13: "神奈川県", 14: "新潟県", 15: "富山県",
        16: "石川県", 17: "福井県", 18: "山梨県", 19: "長野県", 20: "岐阜県", 21: "静岡県", 22: "愛知県", 23: "三重県",
        24: "滋賀県", 25: "京都府", 26: "大阪府", 27: "兵庫県", 28: "奈良県", 29: "和歌山県", 30: "鳥取県", 31: "島根県",
        32: "岡山県", 33: "広島県", 34: "山口県", 35: "徳島県", 36: "香川県", 37: "愛媛県", 38: "高知県", 39: "福岡県",
        40: "佐賀県", 41: "長崎県", 42: "熊本県", 43: "大分県", 44: "宮崎県", 45: "鹿児島県", 46: "沖縄県", 47: "全国"
    ]
    
    init(context: Lambda.InitializationContext) {
        let db = Self.createDynamoDBClient(on: context.eventLoop)
        self.deathController = .init(db: db)
        self.prefectureController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        prefectureController
            .db
            .scan(.init(tableName: Prefecture.tableName))
            .map { $0.items ?? [] }
            .flatMapEachThrowing { try Prefecture(dic: $0) }
            .mapEach { (d: Prefecture) -> PrefectureData in
                PrefectureData(
                    date: d.date.filledDateString,
                    prefectureID: prefectureMaster.first { $0.value == d.prefectureNameJ }?.key ?? -1,
                    positive: Int(d.positive) ?? -1,
                    peopleTested: Int(d.peopleTested) ?? -1,
                    hospitalized: Int(d.hospitalized) ?? -1,
                    serious: Int(d.serious) ?? -1,
                    discharged: Int(d.discharged) ?? -1,
                    deaths: Int(d.deaths) ?? -1,
                    effectiveReproductionNumber: Int(d.effectiveReproductionNumber) ?? -1
                )
            }
            .map { $0.sorted { $0.date < $1.date } }
            .map {
                .init(
                    statusCode: .ok,
                    headers: [
                        "Content-Type": "text/html",
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Methods": "GET",
                        "Access-Control-Allow-Credentials": "true",
                    ],
                    body: "\($0)"
                )
            }
        
        
        
        //        deathController
        //            .db
        //            .scan(.init(tableName: Death.tableName))
        //            .map { $0.items ?? [] }
        //            .flatMapEachThrowing { try Death(dic: $0) }
        //            .mapEach { (date: $0.date.filledDateString, number: $0.number) }
        //            .map { $0.sorted { $0.date < $1.date } }
//            .map { script($0) }
//            .map {
//                .init(
//                    statusCode: .ok,
//                    headers: [
//                        "Content-Type": "text/html",
//                        "Access-Control-Allow-Origin": "*",
//                        "Access-Control-Allow-Methods": "GET",
//                        "Access-Control-Allow-Credentials": "true",
//                    ],
//                    body: html($0)
//                )
//            }
    }
}

extension WebsiteLambdaHandler {
    private var myChartID: String { "myChart" }
    
    private func script(_ data: [(date: String, number: String)]) -> String {
        """
        var ctx = document.getElementById('\(myChartID)').getContext('2d');
        var chart = new Chart(ctx, {
            // The type of chart we want to create
            type: 'line',

            // The data for our dataset
            data: {
                labels: [\(data.map { "'\($0.date)'" }.joined(separator: ", "))],
                datasets: [
                    {
                        label: '新型コロナウイルスによる死亡者数',
                        pointRadius: 0,
                        fill: false,
                        borderColor: 'rgb(255, 99, 132)',
                        data: [\(data.map { $0.number }.joined(separator: ", "))]
                    }
                ]
            },

            // Configuration options go here
            options: {
                scales: {
                    xAxes: [
                        {
                            ticks: {
                                autoSkip: true,
                                // autoSkipPadding: 40,
                                maxTicksLimit: 20,
                            },
                        },
                    ],
                    yAxes: [

                    ]
                }
            }
        });
        """
    }
    
    private func html(_ script: String) -> String {
        """
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>タイトル</title>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/chart.js@2.9.4/dist/Chart.min.css">
          </head>
          <body>
            <canvas id="\(myChartID)"></canvas>
            <script src="https://cdn.jsdelivr.net/npm/chart.js@2.9.4/dist/Chart.min.js"></script>
            <script type="text/javascript">\(script)</script>
          </body>
        </html>
        """
    }
}

struct WebsiteContext: Codable {
    let prefectureMaster: [PrefectureID: String]
    let data: PrefectureData
}

struct PrefectureData: Codable {
    let date: String
    let prefectureID: PrefectureID
    let positive: Int
    let peopleTested: Int
    let hospitalized: Int
    let serious: Int
    let discharged: Int
    let deaths: Int
    let effectiveReproductionNumber: Int
}
