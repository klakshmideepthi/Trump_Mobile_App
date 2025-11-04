import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Plan Data Models

/// Represents a plan from the Telgoo5 API
struct Plan: Codable, Identifiable {
    let plan_id: Int
    let plan_name: String
    let plan_price: Int
    let total_plan_price: Int
    let plan_description: String
    let plan_code: Int
    let display_name: String?
    let display_price: String
    let display_description: String?
    let display_features_description: [String]
    let data: Int
    let talk: Int
    let text: Int
    let is_unlimited_plan: String
    let is_familyplan: String
    let is_prepaid_postpaid: String
    let plan_expiry_days: Int
    let plan_expiry_type: String
    let carrier: [String]
    let minute_unlimited: String?
    let text_unlimited: String?
    let data_unlimited: String?
    let plan_discount_details: [String]
    let autopay_discount: String
    
    var id: Int { plan_id }
    
    // Custom decoder to handle string-to-number conversions
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle plan_id - can be string or int
        if let planIdString = try? container.decode(String.self, forKey: .plan_id) {
            plan_id = Int(planIdString) ?? 0
        } else {
            plan_id = try container.decode(Int.self, forKey: .plan_id)
        }
        
        plan_name = try container.decode(String.self, forKey: .plan_name)
        
        // Handle plan_price - can be string (decimal) or number
        if let priceString = try? container.decode(String.self, forKey: .plan_price) {
            // Convert decimal string to integer (round to nearest)
            plan_price = Int(Double(priceString)?.rounded() ?? 0)
        } else if let priceDouble = try? container.decode(Double.self, forKey: .plan_price) {
            plan_price = Int(priceDouble.rounded())
        } else {
            plan_price = try container.decode(Int.self, forKey: .plan_price)
        }
        
        // Handle total_plan_price - same as plan_price
        if let totalPriceString = try? container.decode(String.self, forKey: .total_plan_price) {
            total_plan_price = Int(Double(totalPriceString)?.rounded() ?? 0)
        } else if let totalPriceDouble = try? container.decode(Double.self, forKey: .total_plan_price) {
            total_plan_price = Int(totalPriceDouble.rounded())
        } else {
            total_plan_price = try container.decode(Int.self, forKey: .total_plan_price)
        }
        
        plan_description = try container.decode(String.self, forKey: .plan_description)
        
        // Handle plan_code - can be string or int
        if let codeString = try? container.decode(String.self, forKey: .plan_code) {
            plan_code = Int(codeString) ?? 0
        } else {
            plan_code = try container.decode(Int.self, forKey: .plan_code)
        }
        
        display_name = try container.decodeIfPresent(String.self, forKey: .display_name)
        display_price = try container.decode(String.self, forKey: .display_price)
        display_description = try container.decodeIfPresent(String.self, forKey: .display_description)
        display_features_description = try container.decode([String].self, forKey: .display_features_description)
        
        // Handle data - can be string or int
        if let dataString = try? container.decode(String.self, forKey: .data) {
            data = Int(dataString) ?? 0
        } else {
            data = try container.decode(Int.self, forKey: .data)
        }
        
        // Handle talk - can be string or int
        if let talkString = try? container.decode(String.self, forKey: .talk) {
            talk = Int(talkString) ?? 0
        } else {
            talk = try container.decode(Int.self, forKey: .talk)
        }
        
        // Handle text - can be string or int
        if let textString = try? container.decode(String.self, forKey: .text) {
            text = Int(textString) ?? 0
        } else {
            text = try container.decode(Int.self, forKey: .text)
        }
        
        is_unlimited_plan = try container.decode(String.self, forKey: .is_unlimited_plan)
        is_familyplan = try container.decode(String.self, forKey: .is_familyplan)
        is_prepaid_postpaid = try container.decode(String.self, forKey: .is_prepaid_postpaid)
        plan_expiry_days = try container.decode(Int.self, forKey: .plan_expiry_days)
        plan_expiry_type = try container.decode(String.self, forKey: .plan_expiry_type)
        carrier = try container.decode([String].self, forKey: .carrier)
        minute_unlimited = try container.decodeIfPresent(String.self, forKey: .minute_unlimited)
        text_unlimited = try container.decodeIfPresent(String.self, forKey: .text_unlimited)
        data_unlimited = try container.decodeIfPresent(String.self, forKey: .data_unlimited)
        plan_discount_details = try container.decode([String].self, forKey: .plan_discount_details)
        autopay_discount = try container.decode(String.self, forKey: .autopay_discount)
    }
    
    enum CodingKeys: String, CodingKey {
        case plan_id
        case plan_name
        case plan_price
        case total_plan_price
        case plan_description
        case plan_code
        case display_name
        case display_price
        case display_description
        case display_features_description
        case data
        case talk
        case text
        case is_unlimited_plan
        case is_familyplan
        case is_prepaid_postpaid
        case plan_expiry_days
        case plan_expiry_type
        case carrier
        case minute_unlimited
        case text_unlimited
        case data_unlimited
        case plan_discount_details
        case autopay_discount
    }
}

/// Response model for plan_list API
struct PlanListResponse: Codable {
    let data: [Plan]?  // Optional to handle error responses without data field
    let msg: String
    let msg_code: String
    let token: String
}

/// Manager for handling authentication and API calls to vcareapi.com
class VCareAPIManager {
    static let shared = VCareAPIManager()
    
    // API Credentials
    private let vendorId = "Demo-TrumpMobileDeepthi"
    private let username = "Demo-TrumpMobileDeepthiUser"
    private let password = "Demo-TrumpMob573hqfpc8fhm"
    private let pin = "Demo-807677255158"
    private let baseURL = "https://www.vcareapi.com:8080"
    
    // Token storage keys
    private let tokenKey = "VCareAPIToken"
    private let tokenExpiryKey = "VCareAPITokenExpiry"
    
    private init() {}
    
    // MARK: - Token Management
    
    /// Get the stored authentication token (if valid)
    var currentToken: String? {
        guard let token = UserDefaults.standard.string(forKey: tokenKey) else {
            return nil
        }
        
        // Check if token is expired
        if let expiryDate = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date,
           expiryDate > Date() {
            return token
        }
        
        // Token expired or no expiry date, clear it
        clearToken()
        return nil
    }
    
    /// Store the authentication token
    private func storeToken(_ token: String, expiresIn: TimeInterval? = nil) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        if let expiresIn = expiresIn {
            let expiryDate = Date().addingTimeInterval(expiresIn)
            UserDefaults.standard.set(expiryDate, forKey: tokenExpiryKey)
        }
    }
    
    /// Clear the stored token
    private func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
    }
    
    // MARK: - Authentication
    
    /// Authenticate and get access token
    /// Always generates a fresh token for each API call
    /// - Parameter completion: Returns the token on success, or error on failure
    func authenticate(completion: @escaping (Result<String, Error>) -> Void) {
        // Always generate a fresh token - clear any existing token first
        clearToken()
        
        // Prepare request body
        let parameters: [String: String] = [
            "vendor_id": vendorId,
            "username": username,
            "password": password,
            "pin": pin
        ]
        
        guard let postData = try? JSONSerialization.data(withJSONObject: parameters) else {
            let error = NSError(
                domain: "VCareAPIManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"]
            )
            completion(.failure(error))
            return
        }
        
        // Create request
        guard let url = URL(string: "\(baseURL)/authenticate") else {
            let error = NSError(
                domain: "VCareAPIManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData
        request.timeoutInterval = 30
        
        // Make request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(
                    domain: "VCareAPIManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
                )
                completion(.failure(error))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let error = NSError(
                    domain: "VCareAPIManager",
                    code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Authentication failed with status code: \(httpResponse.statusCode)"
                    ]
                )
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(
                    domain: "VCareAPIManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No data received"]
                )
                completion(.failure(error))
                return
            }
            
            // Parse response
            if let responseString = String(data: data, encoding: .utf8) {
                print("✅ VCare API Authentication Response: \(responseString)")
            }
            
            // Try to parse JSON response to extract token
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["token"] as? String {
                // Don't store token - we generate fresh tokens for each API call
                completion(.success(token))
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let token = json["access_token"] as? String {
                // Try alternate token key
                completion(.success(token))
            } else if let responseString = String(data: data, encoding: .utf8),
                      !responseString.isEmpty {
                // If token is in plain text or different format
                completion(.success(responseString))
            } else {
                let error = NSError(
                    domain: "VCareAPIManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to parse token from response"]
                )
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - API Request Helpers
    
    /// Make an authenticated API request
    /// - Parameters:
    ///   - endpoint: API endpoint (e.g., "/api/orders")
    ///   - method: HTTP method (default: GET)
    ///   - body: Request body data (optional)
    ///   - completion: Returns the response data or error
    func makeAuthenticatedRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        // Ensure we have a valid token
        authenticate { [weak self] authResult in
            guard let self = self else { return }
            
            switch authResult {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let token):
                // Build URL
                let fullEndpoint = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
                guard let url = URL(string: "\(self.baseURL)\(fullEndpoint)") else {
                    let error = NSError(
                        domain: "VCareAPIManager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint URL"]
                    )
                    completion(.failure(error))
                    return
                }
                
                // Create request
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                // Use "token" header as per API documentation (not Authorization: Bearer)
                request.addValue(token, forHTTPHeaderField: "token")
                
                if let body = body {
                    request.httpBody = body
                }
                
                request.timeoutInterval = 30
                
                // Make request
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
                        )
                        completion(.failure(error))
                        return
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        // If unauthorized, clear token and try again once
                        if httpResponse.statusCode == 401 {
                            self.clearToken()
                            // Retry authentication and request
                            self.makeAuthenticatedRequest(
                                endpoint: endpoint,
                                method: method,
                                body: body,
                                completion: completion
                            )
                            return
                        }
                        
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: httpResponse.statusCode,
                            userInfo: [
                                NSLocalizedDescriptionKey: "API request failed with status code: \(httpResponse.statusCode)"
                            ]
                        )
                        completion(.failure(error))
                        return
                    }
                    
                    guard let data = data else {
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "No data received"]
                        )
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(data))
                }
                
                task.resume()
            }
        }
    }
    
    /// Make an authenticated POST request with JSON body
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - parameters: Dictionary to be encoded as JSON
    ///   - completion: Returns the response data or error
    func post(
        endpoint: String,
        parameters: [String: Any],
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let body = try? JSONSerialization.data(withJSONObject: parameters) else {
            let error = NSError(
                domain: "VCareAPIManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"]
            )
            completion(.failure(error))
            return
        }
        
        makeAuthenticatedRequest(endpoint: endpoint, method: "POST", body: body, completion: completion)
    }
    
    /// Make an authenticated GET request
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - completion: Returns the response data or error
    func get(
        endpoint: String,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        makeAuthenticatedRequest(endpoint: endpoint, method: "GET", completion: completion)
    }
    
    // MARK: - Plan List API
    
    /// Get list of available plans
    /// - Parameters:
    ///   - zipCode: 5-digit zip code for service address
    ///   - enrollmentType: "NON_LIFELINE" for prepaid/postpaid, "LIFELINE" for ACP/Lifeline
    ///   - isFamilyPlan: "Y" for family plan, "N" for individual
    ///   - planId: Optional specific plan ID to filter
    ///   - agentId: User login ID created in Telgoo5
    ///   - externalTransactionId: Optional transaction ID
    ///   - source: "API" or "WEBSITE"
    ///   - completion: Returns array of plans or error
    func getPlanList(
        zipCode: String,
        enrollmentType: String = "NON_LIFELINE",
        isFamilyPlan: String = "N",
        planId: String? = nil,
        agentId: String,
        externalTransactionId: String? = nil,
        source: String = "API",
        completion: @escaping (Result<[Plan], Error>) -> Void
    ) {
        // Validate zip code (must be 5 digits)
        guard zipCode.count == 5, zipCode.allSatisfy({ $0.isNumber }) else {
            let error = NSError(
                domain: "VCareAPIManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid zip code. Must be exactly 5 digits."]
            )
            completion(.failure(error))
            return
        }
        
        // Prepare parameters
        var parameters: [String: Any] = [
            "action": "plan_list",
            "zip_code": zipCode,
            "enrollment_type": enrollmentType,
            "is_family_plan": isFamilyPlan,
            "agent_id": agentId,
            "source": source
        ]
        
        if let planId = planId, !planId.isEmpty {
            parameters["plan_id"] = planId
        } else {
            parameters["plan_id"] = ""
        }
        
        if let externalTransactionId = externalTransactionId {
            parameters["external_transaction_id"] = externalTransactionId
        }
        
        // Make authenticated request
        makeAuthenticatedRequest(endpoint: "/plan", method: "POST", body: try? JSONSerialization.data(withJSONObject: parameters)) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let data):
                // Print raw API response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📡 Plans API Raw Response:")
                    print(responseString)
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
                
                // First check if this is an error response (no data field)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msgCode = json["msg_code"] as? String,
                   msgCode != "RESTAPI000" {
                    // This is an error response without data field
                    let msg = json["msg"] as? String ?? "Unknown error"
                    let token = json["token"] as? String ?? ""
                    
                    print("❌ Plans API Error Response:")
                    print("   msg_code: \(msgCode)")
                    print("   msg: \(msg)")
                    print("   token: \(token)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    
                    // Don't store token - we generate fresh tokens each time
                    
                    let error = NSError(
                        domain: "VCareAPIManager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: msg]
                    )
                    completion(.failure(error))
                    return
                }
                
                // Try to decode as normal response
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlanListResponse.self, from: data)
                    
                    print("✅ Plans API Decoded Response:")
                    print("   msg_code: \(response.msg_code)")
                    print("   msg: \(response.msg)")
                    print("   token: \(response.token)")
                    print("   plans count: \(response.data?.count ?? 0)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    
                    // Don't store token - we generate fresh tokens each time
                    
                    // Check if successful
                    if response.msg_code == "RESTAPI000" {
                        // Print each plan's details
                        if let plans = response.data, !plans.isEmpty {
                            print("📋 Plans Details:")
                            for (index, plan) in plans.enumerated() {
                                print("   Plan \(index + 1):")
                                print("      plan_id: \(plan.plan_id)")
                                print("      plan_name: \(plan.plan_name)")
                                print("      plan_price: \(plan.plan_price)")
                                print("      total_plan_price: \(plan.total_plan_price)")
                                print("      plan_description: \(plan.plan_description)")
                                print("      plan_code: \(plan.plan_code)")
                                print("      display_name: \(plan.display_name ?? "nil")")
                                print("      display_price: \(plan.display_price)")
                                print("      display_description: \(plan.display_description ?? "nil")")
                                print("      display_features_description: \(plan.display_features_description)")
                                print("      data: \(plan.data)")
                                print("      talk: \(plan.talk)")
                                print("      text: \(plan.text)")
                                print("      is_unlimited_plan: \(plan.is_unlimited_plan)")
                                print("      is_familyplan: \(plan.is_familyplan)")
                                print("      is_prepaid_postpaid: \(plan.is_prepaid_postpaid)")
                                print("      plan_expiry_days: \(plan.plan_expiry_days)")
                                print("      plan_expiry_type: \(plan.plan_expiry_type)")
                                print("      carrier: \(plan.carrier)")
                                print("      minute_unlimited: \(plan.minute_unlimited ?? "nil")")
                                print("      text_unlimited: \(plan.text_unlimited ?? "nil")")
                                print("      data_unlimited: \(plan.data_unlimited ?? "nil")")
                                print("      plan_discount_details: \(plan.plan_discount_details)")
                                print("      autopay_discount: \(plan.autopay_discount)")
                                print("      ──────────────────────────────────────────────")
                            }
                        } else {
                            print("⚠️ No plans found in response")
                        }
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        // Provide empty array if data is nil (shouldn't happen for success, but safety check)
                        completion(.success(response.data ?? []))
                    } else {
                        print("❌ Plans API returned error:")
                        print("   msg_code: \(response.msg_code)")
                        print("   msg: \(response.msg)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: response.msg]
                        )
                        completion(.failure(error))
                    }
                } catch {
                    print("❌ Failed to decode plan list response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                    completion(.failure(error))
                }
            }
        }
    }
}

