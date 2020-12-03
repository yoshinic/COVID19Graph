import Foundation
import NIO
import SotoDynamoDB

protocol DownloadController: DynamoDBController {
    func add(_ a: [String]) -> EventLoopFuture<Model>
    func batch(_ a: [[String]]) -> EventLoopFuture<[DynamoDB.BatchWriteItemOutput]>
}
