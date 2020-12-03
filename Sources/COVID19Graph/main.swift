import AWSLambdaRuntime

struct LambdaHandler {
    static func run() {
        guard let type = Lambda.env("TYPE") else { return }
        switch type.lowercased() {
        case "download":
            Lambda.run(DownloadLambdaHandler.init)
        case "prefecture":
            Lambda.run(MPrefectureLambdaHandler.init)
        case "website":
            Lambda.run(WebsiteLambdaHandler.init)
        default: break
        }
    }
}

LambdaHandler.run()
