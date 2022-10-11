import Foundation
import SwiftSoup

let UIS_URL = "https://uis.fudan.edu.cn"

/// Store the network API of Fudan university services.
class FDNetworks {
    static var shared = FDNetworks()
    let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
    
    // MARK: Stored Properties
    
    var loggedIn = false
    var username: String
    var password: String
    
    init() {
        loggedIn = defaults?.bool(forKey: "fdu-logged-in") ?? false
        username = defaults?.string(forKey: "fdu-username") ?? ""
        password = defaults?.string(forKey: "fdu-password") ?? ""
    }
    
    // MARK: Authentication
    
    func login(_ username: String, _ password: String) async throws {
        if try await needCaptcha(username: username) {
            print("need captcha")
            throw NetworkError.unauthorized
        }
        let authUrl = URL(string: UIS_URL + "/authserver/login")!
        var request = URLRequest(url: authUrl)
        request.allHTTPHeaderFields = ["User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"]
        let (loginFormData, _) = try await URLSession.shared.data(for: request)
        let authRequest = try prepareAuthRequest(authUrl: authUrl, formData: loginFormData,
                                                 username: username, password: password)
        print(String(data: authRequest.httpBody!, encoding: String.Encoding.utf8)!)
        let (data, response) = try await URLSession.shared.data(for: authRequest)
        if response.url?.absoluteString != "https://uis.fudan.edu.cn/authserver/index.do" {
            print(String(data: data, encoding: String.Encoding.utf8)!)
            throw NetworkError.unauthorized
        }
        persistLoginData(username, password)
    }
    
    
    private func persistLoginData(_ username: String, _ password: String) {
        loggedIn = true
        self.username = username
        self.password = password
        defaults?.set(true, forKey: "fdu-logged-in")
        defaults?.set(username, forKey: "fdu-username")
        defaults?.set(password, forKey: "fdu-password")
    }
    
    
    private func prepareAuthRequest(authUrl: URL, formData: Data,
                                    username: String?,
                                    password: String?) throws -> URLRequest {
        var loginForm = [
            URLQueryItem(name: "username", value: username ?? self.username),
            URLQueryItem(name: "password", value: password ?? self.password)
        ]
        
        guard let htmlText = String(data: formData, encoding: String.Encoding.utf8) else {
            throw NetworkError.invalidResponse
        }
        
        let doc = try SwiftSoup.parse(htmlText)
        for element in try doc.select("input") {
            if try element.attr("type") == "hidden" {
                loginForm.append(URLQueryItem(name: try element.attr("name"),
                                              value: try element.attr("value")))
            }
        }
        
        let requestHeaders = ["Content-Type" : "application/x-www-form-urlencoded",
                              "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"]
        var requestBodyComponents = URLComponents()
        requestBodyComponents.queryItems = loginForm
        var request = URLRequest(url: authUrl)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = requestHeaders
        request.httpBody = requestBodyComponents.query?.data(using: .ascii)
        
        return request
    }

    private func needCaptcha(username: String) async throws -> Bool {
        var component = URLComponents(string: UIS_URL + "/authserver/needCaptcha.html")!
        component.queryItems = [URLQueryItem(name: "username", value: username)]
        var request = URLRequest(url: component.url!)
        request.allHTTPHeaderFields = ["User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"]
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let result = String(data: data, encoding: String.Encoding.ascii) else {
            throw NetworkError.invalidResponse
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines) != "false"
    }
}