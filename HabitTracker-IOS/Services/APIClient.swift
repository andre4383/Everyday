import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case http(status: Int, message: String)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .invalidResponse: return "Resposta inválida do servidor"
        case .http(_, let message): return message
        case .decoding(let err): return "Erro ao decodificar: \(err.localizedDescription)"
        case .transport(let err): return err.localizedDescription
        }
    }
}

struct EmptyResponse: Decodable {}

@Observable
final class APIClient {
    static let shared = APIClient()

    var baseURL = URL(string: "http://localhost:3000")!

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        self.session = URLSession(configuration: .default)

        self.encoder = JSONEncoder()
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(iso.string(from: date))
        }

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let withFrac = ISO8601DateFormatter()
            withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = withFrac.date(from: str) { return d }
            let noFrac = ISO8601DateFormatter()
            noFrac.formatOptions = [.withInternetDateTime]
            if let d = noFrac.date(from: str) { return d }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Data ISO 8601 inválida: \(str)"
            )
        }
    }

    // MARK: - Public API

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(path: path, method: "GET", body: Optional<String>.none)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path: path, method: "POST", body: body)
    }

    func postEmpty<T: Decodable>(_ path: String) async throws -> T {
        try await request(path: path, method: "POST", body: Optional<String>.none)
    }

    func patch<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path: path, method: "PATCH", body: body)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        try await request(path: path, method: "DELETE", body: Optional<String>.none)
    }

    // MARK: - Core

    private func request<T: Decodable, B: Encodable>(
        path: String,
        method: String,
        body: B?
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = KeychainHelper.read() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = Self.extractErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
            throw APIError.http(status: http.statusCode, message: message)
        }

        if data.isEmpty, T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private static func extractErrorMessage(from data: Data) -> String? {
        struct ErrorBody: Decodable {
            let message: StringOrArray?
        }
        enum StringOrArray: Decodable {
            case single(String)
            case list([String])
            init(from decoder: Decoder) throws {
                let c = try decoder.singleValueContainer()
                if let s = try? c.decode(String.self) { self = .single(s); return }
                let arr = try c.decode([String].self)
                self = .list(arr)
            }
            var text: String {
                switch self {
                case .single(let s): return s
                case .list(let arr): return arr.joined(separator: ", ")
                }
            }
        }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.message?.text
    }
}
