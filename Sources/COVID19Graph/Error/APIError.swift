enum APIError: Error {
    case notFound
    case decoding
    case request
    case description(String)
}
