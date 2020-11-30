import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import NIO

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
    
    init(context: Lambda.InitializationContext) {
        let db = Self.createDynamoDBClient(on: context.eventLoop)
        self.deathController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        deathController
            .db
            .scan(.init(tableName: Death.tableName))
            .map { $0.items ?? [] }
            .flatMapEachThrowing { try Death(dic: $0) }
            .mapEach { (date: $0.date, number: $0.number) }
            .map { $0.sorted { $0.date < $1.date } }
            .map { script($0) }
            .map {
                .init(
                    statusCode: .ok,
                    headers: [
                        "Content-Type": "text/html",
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Methods": "GET",
                        "Access-Control-Allow-Credentials": "true",
                    ],
                    body: html($0)
                )
            }
    }
}

extension WebsiteLambdaHandler {
    func script(_ data: [(date: String, number: String)]) -> String {
        """
        var ctx = document.getElementById('myChart').getContext('2d');
        var chart = new Chart(ctx, {
            // The type of chart we want to create
            type: 'line',

            // The data for our dataset
            data: {
                labels: [\(data.map { "'\($0.date)'" }.joined(separator: ", "))],
                datasets: [{
                    label: 'My First dataset',
                    backgroundColor: 'rgb(255, 99, 132)',
                    borderColor: 'rgb(255, 99, 132)',
                    data: [\(data.map { $0.number }.joined(separator: ", "))]
                }]
            },

            // Configuration options go here
            options: {}
        });
        """
    }
    
    func html(_ script: String) -> String {
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
            <canvas id="myChart"></canvas>
            <script src="https://cdn.jsdelivr.net/npm/chart.js@2.9.4/dist/Chart.min.js"></script>
            <script type="text/javascript">\(script)</script>
          </body>
        </html>
        """
    }
}
