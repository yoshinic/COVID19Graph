import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import NIO

typealias PrefectureID = Int
typealias ItemID = Int

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
    
    private let prefectureMaster: [String] = [
        "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県", "茨城県",
        "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県", "新潟県", "富山県",
        "石川県", "福井県", "山梨県", "長野県", "岐阜県", "静岡県", "愛知県", "三重県",
        "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県", "鳥取県", "島根県",
        "岡山県", "広島県", "山口県", "徳島県", "香川県", "愛媛県", "高知県", "福岡県",
        "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
    ]
    
    private let itemMaster: [String] = [
        "検査陽性者数", "PCR検査人数", "入院治療等を要する者", "重症者数",
        "退院・療養解除", "死亡者数", //"実効再生産数",
    ]
    
    let startYear: Int = 2020
    let startMonth: Int = 1
    
    init(context: Lambda.InitializationContext) {
        let db = Self.createDynamoDBClient(on: context.eventLoop)
        self.mprefectureController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        mprefectureController
            .all()
            .map {
                $0.reduce(into: [[[Int]]]()) { (_a, d) in
                    let year = Int(d.ym.prefix(4)) ?? 0
                    let month = Int(d.ym.suffix(2)) ?? 0
                    let ym = (year - startYear) * 12 + month - startMonth
                    guard ym > 0 else { return }
                    
                    if _a.count <= ym {
                        let x = ym - _a.count + 1
                        (0..<x).forEach { _ in _a.append([]) }
                        (0..<x).forEach { i in
                            if _a[i].count == 0 {
                                (0..<prefectureMaster.count).forEach { _ in _a[i].append([]) }
                            }
                        }
                        (0..<x).forEach { i in
                            (0..<prefectureMaster.count).forEach { j in
                                if _a[i][j].count == 0 {
                                    (0..<itemMaster.count).forEach { _ in _a[i][j].append(0) }
                                }
                            }
                        }
                    }
                    
                    let prefectureID = prefectureMaster.firstIndex(of: d.prefectureName) ?? 0
                    _a[ym][prefectureID][0] = Int(d.positive) ?? 0
                    _a[ym][prefectureID][1] = Int(d.peopleTested) ?? 0
                    _a[ym][prefectureID][2] = Int(d.hospitalized) ?? 0
                    _a[ym][prefectureID][3] = Int(d.serious) ?? 0
                    _a[ym][prefectureID][4] = Int(d.discharged) ?? 0
                    _a[ym][prefectureID][5] = Int(d.deaths) ?? 0
//                    _a[ym][prefectureID][6] = Int(d.effectiveReproductionNumber) ?? 0
                }
            }
            .map { WebsiteData(prefectureMaster: prefectureMaster, itemMaster: itemMaster, data: $0) }
            .map { (data: WebsiteData) -> WebsiteOutput in
                .init(
                    statusCode: .ok,
                    headers: [
                        "Content-Type": "text/html",
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Methods": "GET",
                        "Access-Control-Allow-Credentials": "true",
                    ],
                    body: html(data)
                )
            }
    }
}

struct WebsiteData: Codable {
    let prefectureMaster: [String]
    let itemMaster: [String]
    let data: [[[Int]]]   // 年月別、都道府県別、アイテム別
}
