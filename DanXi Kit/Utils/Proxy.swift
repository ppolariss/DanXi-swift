import Foundation
import KeychainAccess
import FudanKit

class Proxy {
    static let shared = Proxy()
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard ProxySettings.shared.enableProxy,
              FudanKit.CredentialStore.shared.credentialPresent else {
            return try await tryDirectRequest(request: request)
        }
        
        let proxiedRequest = createProxiedRequest(request: request)
        let (data, response) = try await FudanKit.Authenticator.shared.authenticateWithResponse(proxiedRequest, manualLoginURL: URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!)
        if let responseURL = response.url,
              !responseURL.absoluteString.hasPrefix("https://webvpn.fudan.edu.cn/login") {
            return (data, response)
        }
        
        _ = try await FudanKit.Authenticator.shared.authenticate(URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!)
        return try await FudanKit.Authenticator.shared.authenticateWithResponse(proxiedRequest, manualLoginURL: URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!)
    }
    
    /// Try direct connection to the server
    /// Enable proxy if timeout
    private func tryDirectRequest(request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            // Create a URLSession with short timeout for connection test
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 2.0
            let session = URLSession(configuration: config)
            return try await session.data(for: request)
        } catch URLError.timedOut where !ProxySettings.shared.enableProxy {
            ProxySettings.shared.enableProxy = true
            print("WebVPN enabled.")
            return try await data(for: request)
        }
    }
    
    private func createProxiedRequest(request: URLRequest) -> URLRequest {
        guard let url = request.url, let host = url.host else {
            return request
        }

        let proxiedURLString: String
        switch host {
        case "www.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://www.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421e7e056d221347d5871048ce29b5a2e" + path
        case "fduhole-admin.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://fduhole-admin.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/http/77726476706e69737468656265737421f6f35494283c6d1d7f0c84a5961b2531922257750cb3fc25b0" + path
        case "auth.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://auth.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f1e2559469366c45760785a9d6562c38" + path
        case "danke.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://danke.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f4f64f97227e6e546b0086a09d1b203a73" + path
        default:
            return request
        }

        guard let proxiedURL = URL(string: proxiedURLString) else {
            return request
        }

        var proxiedRequest = URLRequest(url: proxiedURL)
        proxiedRequest.allHTTPHeaderFields = request.allHTTPHeaderFields
        proxiedRequest.httpMethod = request.httpMethod
        proxiedRequest.httpBody = request.httpBody
        return proxiedRequest
    }
}

public class ProxySettings: ObservableObject {
    public static let shared = ProxySettings()
    
    @Published public var enableProxy = false
}