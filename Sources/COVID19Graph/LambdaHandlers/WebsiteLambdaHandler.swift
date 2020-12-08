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
    
    let mprefectureController: MPrefectureController
    
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
        self.mprefectureController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        mprefectureController
            .db
            .scan(.init(tableName: MPrefecture.tableName))
            .map { $0.items ?? [] }
            .flatMapEachThrowing { try MPrefecture(dic: $0) }
            .map {
                var a: [[MPrefectureData]] = []
                (0..<12).forEach { _ in a.append([]) }
                (0..<prefectureMaster.count).forEach { _ in
                    (0..<12).forEach {
                        a[$0].append(MPrefectureData(0, 0, 0, 0, 0, 0, 0))
                    }
                }
                
                return $0.reduce(into: a) { (_a, d) in
                    let month = Int(d.month) ?? 0
                    let prefectureID = prefectureMaster.first { $0.value == d.prefectureName }?.key ?? 0
                    _a[month][prefectureID].positive = Int(d.positive) ?? 0
                    _a[month][prefectureID].peopleTested = Int(d.peopleTested) ?? 0
                    _a[month][prefectureID].hospitalized = Int(d.hospitalized) ?? 0
                    _a[month][prefectureID].serious = Int(d.serious) ?? 0
                    _a[month][prefectureID].discharged = Int(d.discharged) ?? 0
                    _a[month][prefectureID].deaths = Int(d.deaths) ?? 0
                    _a[month][prefectureID].effectiveReproductionNumber = Int(d.effectiveReproductionNumber) ?? 0
                }
            }
            .map { WebsiteData(prefectureMaster: prefectureMaster, data: $0) }
            .map { (a: WebsiteData) -> WebsiteOutput in
                .init(
                    statusCode: .ok,
                    headers: [
                        "Content-Type": "text/html",
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Methods": "GET",
                        "Access-Control-Allow-Credentials": "true",
                    ],
                    body: "\(a)"
                )
            }
    }
}

extension WebsiteLambdaHandler {
    private var myChartID: String { "myChart" }
    
    private func script(_ d: WebsiteData) -> String {
        """
        const data = \(d.data)

        const ctx = document.getElementById('\(myChartID)').getContext('2d');
        const chart = new Chart(ctx, {
            // The type of chart we want to create
            type: 'line',

            // The data for our dataset
            data: {
                labels: [],
                datasets: [
                    {
                        label: '新型コロナウイルスによる死亡者数',
                        pointRadius: 0,
                        fill: false,
                        borderColor: 'rgb(255, 99, 132)',
                        data: []
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

struct WebsiteData: Codable {
    let prefectureMaster: [PrefectureID: String]
    let data: [[MPrefectureData]]   // 月別、都道府県別
}

struct MPrefectureData: Codable {
    var positive: Int
    var peopleTested: Int
    var hospitalized: Int
    var serious: Int
    var discharged: Int
    var deaths: Int
    var effectiveReproductionNumber: Int
    
    init(
        _ positive: Int,
        _ peopleTested: Int,
        _ hospitalized: Int,
        _ serious: Int,
        _ discharged: Int,
        _ deaths: Int,
        _ effectiveReproductionNumber: Int
    ) {
        self.positive = positive
        self.peopleTested = peopleTested
        self.hospitalized = hospitalized
        self.serious = serious
        self.discharged = discharged
        self.deaths = deaths
        self.effectiveReproductionNumber = effectiveReproductionNumber
    }
}
