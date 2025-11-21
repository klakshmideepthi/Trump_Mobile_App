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

// MARK: - Device Compatibility Models

/// Response model for device compatibility check
struct DeviceCompatibilityResponse: Codable {
    let data: DeviceCompatibilityData?
    let msg: String
    let msg_code: String
    let token: String
}

/// Nested response model for get_query_device action
struct QueryDeviceResponse: Codable {
    let data: QueryDeviceData?
    let msg: String
    let msg_code: String
    let token: String
}

/// Nested data structure for get_query_device
struct QueryDeviceData: Codable {
    let DESCRIPTION: String?
    let REFRENCENO: String?
    let RESULT: QueryDeviceResult?
    let STATUSCODE: String?
}

/// Device result from get_query_device
struct QueryDeviceResult: Codable {
    let deviceInfo: [DeviceInfo]?
}

/// Device information from get_query_device
struct DeviceInfo: Codable {
    let deviceGroup: [DeviceGroup]?
    let imei: String?
    let manufacturer: String?
    let marketingName: String?
    let model: String?
    let name: String?
    let tac: String?
}

/// Device group containing specifications
struct DeviceGroup: Codable {
    let deviceGroupName: String?
    let specification: [Specification]?
}

/// Specification item
struct Specification: Codable {
    let specificationName: String?
    let specificationValue: String?
}

/// Device compatibility data from API
struct DeviceCompatibilityData: Codable {
    let BAND12COMPATIBLE: String?
    let BANDS: String?
    let CHIPSETMODEL: String?
    let CHIPSETNAME: String?
    let CHIPSETVENDOR: String?
    let COMPATIBILITY: String?
    let DESCRIPTION: String?
    let DEVICETYPE: String?
    let DUALBANDWIFI: String?
    let ESIM: String?
    let GPRS: String?
    let HDVOICE: String?
    let HSDPA: String?
    let HSPA: String?
    let IMEI: String?
    let IMS: String?
    let IPV6: String?
    let LTE: String?
    let LTEADVANCED: String?
    let LTECATEGORY: String?
    let MANUFACTURER: String?
    let MARKETINGNAME: String?
    let MODEL: String?
    let NAME: String?
    let NETWORKCOMPATIBLE: String?
    let NETWORKTECHNOLOGY: String?
    let NONSTANDALONE5G: String?
    let OSNAME: String?
    let PASSPOINT: String?
    let PRIMARYHARDWARETYPE: String?
    let REMOTESIMUNLOCK: String?
    let ROAMINGIMS: String?
    let SIMSIZE: String?
    let SIMSLOTS: String?
    let STANDALONE5G: String?
    let STATUSCODE: String?
    let TAC: String?
    let TECHNOLOGYONTHEDEVICE: String?
    let TMOBILEAPPROVED: String?
    let UMTS: String?
    let VOLTE: String?
    let VOLTECOMPATIBLE: String?
    let VOLTEEMERGENCYCALLING: String?
    let VONRCOMPATIBLE: String?
    let VOWIFI: String?
    let WIFI: String?
    let WIFICALLINGVERSION: String?
    let WIFICOMPATIBLE: String?
    let WLAN: String?
    let YEARRELEASED: String?
    
    /// Check if device is compatible based on COMPATIBILITY field
    var isCompatible: Bool {
        guard let compatibility = COMPATIBILITY?.uppercased() else { return false }
        
        // First check for "Not Compatible" - this takes precedence
        if compatibility.contains("NOT COMPATIBLE") {
            return false
        }
        
        // Then check for positive compatibility indicators
        return compatibility.contains("FULLY COMPATIBLE") || 
               compatibility.contains("COMPATIBLE") || 
               compatibility.contains("YES")
    }
    
    /// Get a user-friendly compatibility message
    var compatibilityMessage: String {
        if let compatibility = COMPATIBILITY {
            return compatibility
        }
        return "Compatibility status unknown"
    }
    
    /// Check if device supports eSIM
    var supportsESIM: Bool {
        guard let esim = ESIM?.uppercased() else { return true } // Default to true if unknown
        return esim == "YES"
    }
    
    /// Check if device supports physical SIM
    var supportsPhysicalSIM: Bool {
        // If eSIM is explicitly "No", assume physical SIM is supported
        // If eSIM is "Yes", check SIMSlots to determine if physical SIM is also supported
        if let esim = ESIM?.uppercased(), esim == "NO" {
            return true // If no eSIM, physical SIM should be available
        }
        
        // If eSIM is available, check if device also has physical SIM slots
        if let simSlots = SIMSLOTS?.uppercased() {
            return simSlots == "YES"
        }
        
        // Default to true if unknown (assume both are available)
        return true
    }
    
    /// Convert QueryDeviceData to DeviceCompatibilityData
    static func fromQueryDeviceData(_ queryData: QueryDeviceData) -> DeviceCompatibilityData? {
        guard let deviceInfo = queryData.RESULT?.deviceInfo?.first else { return nil }
        
        // Extract values from nested structure
        var esim: String? = nil
        var simSlots: String? = nil
        var compatibility: String? = nil
        var manufacturer: String? = deviceInfo.manufacturer
        var marketingName: String? = deviceInfo.marketingName
        var model: String? = deviceInfo.model
        var imei: String? = deviceInfo.imei
        var networkTechnology: String? = nil
        var band12Compatible: String? = nil
        var volteCompatible: String? = nil
        var wifiCompatible: String? = nil
        
        // Extract values from device groups
        if let deviceGroups = deviceInfo.deviceGroup {
            for group in deviceGroups {
                guard let groupName = group.deviceGroupName,
                      let specifications = group.specification else { continue }
                
                switch groupName {
                case "SimSpecifications":
                    for spec in specifications {
                        if let name = spec.specificationName, let value = spec.specificationValue {
                            if name == "eSIM" {
                                esim = value
                            } else if name == "SIMSlots" {
                                simSlots = value
                            }
                        }
                    }
                    
                case "NetworkCompatibility":
                    for spec in specifications {
                        if let name = spec.specificationName, let value = spec.specificationValue {
                            if name == "compatibility" {
                                compatibility = value
                            } else if name == "NetworkTechnology" {
                                networkTechnology = value
                            } else if name == "Band12Compatible" {
                                band12Compatible = value
                            } else if name == "VoLTECompatible" {
                                volteCompatible = value
                            } else if name == "WiFiCompatible" {
                                wifiCompatible = value
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
        
        return DeviceCompatibilityData(
            BAND12COMPATIBLE: band12Compatible,
            BANDS: nil,
            CHIPSETMODEL: nil,
            CHIPSETNAME: nil,
            CHIPSETVENDOR: nil,
            COMPATIBILITY: compatibility,
            DESCRIPTION: queryData.DESCRIPTION,
            DEVICETYPE: nil,
            DUALBANDWIFI: nil,
            ESIM: esim,
            GPRS: nil,
            HDVOICE: nil,
            HSDPA: nil,
            HSPA: nil,
            IMEI: imei,
            IMS: nil,
            IPV6: nil,
            LTE: nil,
            LTEADVANCED: nil,
            LTECATEGORY: nil,
            MANUFACTURER: manufacturer,
            MARKETINGNAME: marketingName,
            MODEL: model,
            NAME: deviceInfo.name,
            NETWORKCOMPATIBLE: nil,
            NETWORKTECHNOLOGY: networkTechnology,
            NONSTANDALONE5G: nil,
            OSNAME: nil,
            PASSPOINT: nil,
            PRIMARYHARDWARETYPE: nil,
            REMOTESIMUNLOCK: nil,
            ROAMINGIMS: nil,
            SIMSIZE: nil,
            SIMSLOTS: simSlots,
            STANDALONE5G: nil,
            STATUSCODE: queryData.STATUSCODE,
            TAC: deviceInfo.tac,
            TECHNOLOGYONTHEDEVICE: nil,
            TMOBILEAPPROVED: nil,
            UMTS: nil,
            VOLTE: nil,
            VOLTECOMPATIBLE: volteCompatible,
            VOLTEEMERGENCYCALLING: nil,
            VONRCOMPATIBLE: nil,
            VOWIFI: nil,
            WIFI: nil,
            WIFICALLINGVERSION: nil,
            WIFICOMPATIBLE: wifiCompatible,
            WLAN: nil,
            YEARRELEASED: nil
        )
    }
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
    
    // MARK: - Transaction ID Generation
    
    /// Generate a unique external transaction ID for API calls
    /// Format: {OrderID}{Action}{Timestamp}
    /// - Parameters:
    ///   - orderId: The system order ID
    ///   - action: The API action name (e.g., "CHECK", "PAY", "CREATE")
    /// - Returns: A unique transaction ID string
    static func generateTransactionId(orderId: String, action: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(orderId)\(action)\(timestamp)"
    }
    
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
        source: String = "WEBSITE",
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
    
    // MARK: - Get City State API
    
    /// Get city and state from ZIP code
    /// - Parameters:
    ///   - zipCode: 5-digit ZIP code
    ///   - agentId: User login ID created in Telgoo5
    ///   - source: "API" or "WEBSITE"
    ///   - completion: Returns city and state or error
    func getCityState(
        zipCode: String,
        agentId: String,
        source: String = "API",
        completion: @escaping (Result<(city: String, state: String), Error>) -> Void
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
        let parameters: [String: Any] = [
            "action": "get_city_state",
            "zip_code": zipCode,
            "agent_id": agentId,
            "source": source
        ]
        
        // Make authenticated request
        post(endpoint: "/address", parameters: parameters) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let data):
                // Print raw API response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📡 City/State API Raw Response:")
                    print(responseString)
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
                
                // Parse response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let msgCode = json["msg_code"] as? String,
                       msgCode == "RESTAPI000",
                       let dataDict = json["data"] as? [String: Any],
                       let city = dataDict["city"] as? String,
                       let state = dataDict["state"] as? String {
                        print("✅ City/State API Success:")
                        print("   city: \(city)")
                        print("   state: \(state)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        completion(.success((city: city, state: state)))
                    } else {
                        let msg = json["msg"] as? String ?? "Failed to get city and state"
                        print("❌ City/State API Error: \(msg)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: msg]
                        )
                        completion(.failure(error))
                    }
                } else {
                    let error = NSError(
                        domain: "VCareAPIManager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"]
                    )
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Device Compatibility Check API
    
    /// Check device compatibility by IMEI
    /// - Parameters:
    ///   - imei: 15-digit IMEI number
    ///   - carrier: Carrier name (e.g., "TMB", "PLUM", "VER", "BLUECONNECTSATT")
    ///   - agentId: User login ID created in Telgoo5
    ///   - source: "API" or "WEBSITE" (default: "API")
    ///   - externalTransactionId: Optional transaction ID
    ///   - completion: Returns device compatibility data or error
    func checkDeviceCompatibility(
        imei: String,
        carrier: String,
        agentId: String,
        source: String = "API",
        externalTransactionId: String? = nil,
        completion: @escaping (Result<DeviceCompatibilityData, Error>) -> Void
    ) {
        // Validate IMEI (should be 15 digits)
        let digitsOnly = imei.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard digitsOnly.count == 15 else {
            let error = NSError(
                domain: "VCareAPIManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid IMEI. Must be exactly 15 digits."]
            )
            completion(.failure(error))
            return
        }
        
        // Determine action based on carrier
        // For TMB, use "get_query_device", otherwise use "check_device_compatibility"
        let action = carrier.uppercased() == "TMB" ? "get_query_device" : "check_device_compatibility"
        
        // Prepare parameters
        var parameters: [String: Any] = [
            "action": action,
            "agent_id": agentId,
            "source": source,
            "carrier": carrier,
            "imei": digitsOnly
        ]
        
        if let externalTransactionId = externalTransactionId {
            parameters["external_transaction_id"] = externalTransactionId
        }
        
        // Make authenticated request
        post(endpoint: "/inventory", parameters: parameters) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let data):
                // Print raw API response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📡 Device Compatibility API Raw Response:")
                    print(responseString)
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
                
                // Parse response
                do {
                    let decoder = JSONDecoder()
                    var compatibilityData: DeviceCompatibilityData?
                    
                    // Always try nested structure first (API may return nested format regardless of action)
                    do {
                        let queryResponse = try decoder.decode(QueryDeviceResponse.self, from: data)
                        print("✅ Query Device API Response:")
                        print("   msg_code: \(queryResponse.msg_code)")
                        print("   msg: \(queryResponse.msg)")
                        
                        if queryResponse.msg_code == "RESTAPI000", let queryData = queryResponse.data {
                            compatibilityData = DeviceCompatibilityData.fromQueryDeviceData(queryData)
                        }
                    } catch {
                        // Fall back to flat structure if nested fails
                        print("⚠️ Failed to decode as nested structure, trying flat structure...")
                        do {
                            let response = try decoder.decode(DeviceCompatibilityResponse.self, from: data)
                            print("✅ Device Compatibility API Response:")
                            print("   msg_code: \(response.msg_code)")
                            print("   msg: \(response.msg)")
                            
                            if response.msg_code == "RESTAPI000" {
                                compatibilityData = response.data
                            }
                        } catch {
                            print("❌ Failed to decode as both nested and flat structure: \(error)")
                            throw error
                        }
                    }
                    
                    // Process the compatibility data
                    if let data = compatibilityData {
                        print("   Device: \(data.MARKETINGNAME ?? data.MODEL ?? "Unknown")")
                        print("   Manufacturer: \(data.MANUFACTURER ?? "Unknown")")
                        print("   Compatibility: \(data.COMPATIBILITY ?? "Unknown")")
                        print("   Is Compatible: \(data.isCompatible)")
                        print("   Supports eSIM: \(data.supportsESIM)")
                        print("   Supports Physical SIM: \(data.supportsPhysicalSIM)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        completion(.success(data))
                    } else {
                        let errorMessage = "Failed to parse device compatibility data"
                        print("❌ Device Compatibility API Error: \(errorMessage)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )
                        completion(.failure(error))
                    }
                } catch {
                    print("❌ Failed to decode device compatibility response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Port-In Validation Models
    
    /// Response model for validate_portin API
    struct PortInValidationResponse: Codable {
        let data: PortInValidationData?
        let msg: String
        let msg_code: String
        let token: String
    }
    
    /// Port-in validation data
    struct PortInValidationData: Codable {
        let DESCRIPTION: String?
        let PORTINSTATUS: String?
        let STATUSCODE: Int?
        let description: String?
        let mdn: String?
        let old_service_provider: String?
        let msg: String?
        let msg_code: String?
        
        // Custom decoder to handle STATUSCODE as string or int
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            DESCRIPTION = try container.decodeIfPresent(String.self, forKey: .DESCRIPTION)
            PORTINSTATUS = try container.decodeIfPresent(String.self, forKey: .PORTINSTATUS)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            mdn = try container.decodeIfPresent(String.self, forKey: .mdn)
            old_service_provider = try container.decodeIfPresent(String.self, forKey: .old_service_provider)
            msg = try container.decodeIfPresent(String.self, forKey: .msg)
            msg_code = try container.decodeIfPresent(String.self, forKey: .msg_code)
            
            // Handle STATUSCODE - can be string or int
            if let statusCodeString = try? container.decode(String.self, forKey: .STATUSCODE) {
                STATUSCODE = Int(statusCodeString)
            } else {
                STATUSCODE = try container.decodeIfPresent(Int.self, forKey: .STATUSCODE)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case DESCRIPTION
            case PORTINSTATUS
            case STATUSCODE
            case description
            case mdn
            case old_service_provider
            case msg
            case msg_code
        }
    }
    
    // MARK: - Port-In Validation API
    
    /// Validate port-in eligibility for a phone number
    /// - Parameters:
    ///   - mdn: Phone number to port in (10 digits)
    ///   - carrier: Carrier abbreviation (e.g., "TMB", "ATT", "VER")
    ///   - zipCode: Optional zip code (required for AT&T)
    ///   - agentId: User login ID created in Telgoo5
    ///   - source: "API" or "WEBSITE" (default: "WEBSITE")
    ///   - externalTransactionId: Optional transaction ID
    ///   - completion: Returns port-in validation data or error
    func validatePortIn(
        mdn: String,
        carrier: String,
        zipCode: String? = nil,
        agentId: String,
        source: String = "API",
        externalTransactionId: String? = nil,
        completion: @escaping (Result<PortInValidationData, Error>) -> Void
    ) {
        // Validate MDN (should be 10 digits, remove formatting)
        let digitsOnly = mdn.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard digitsOnly.count == 10 else {
            let error = NSError(
                domain: "VCareAPIManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid phone number. Must be exactly 10 digits."]
            )
            completion(.failure(error))
            return
        }
        
        // Prepare parameters
        var parameters: [String: Any] = [
            "action": "validate_portin",
            "mdn": digitsOnly,
            "carrier": carrier,
            "agent_id": agentId,
            "source": source
        ]
        
        // Add zip code if provided (required for AT&T)
        if let zipCode = zipCode, !zipCode.isEmpty {
            parameters["zip_code"] = zipCode
        }
        
        if let externalTransactionId = externalTransactionId {
            parameters["external_transaction_id"] = externalTransactionId
        }
        
        // Make authenticated request
        post(endpoint: "/inventory", parameters: parameters) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let data):
                // Print raw API response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📡 Port-In Validation API Raw Response:")
                    print(responseString)
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
                
                // Parse response
                do {
                    // First, try to parse as JSON to see the structure
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("📋 Port-In Validation API JSON Structure:")
                        print(json)
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    }
                    
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PortInValidationResponse.self, from: data)
                    
                    print("✅ Port-In Validation API Response:")
                    print("   msg_code: \(response.msg_code)")
                    print("   msg: \(response.msg)")
                    
                    if response.msg_code == "RESTAPI000", let validationData = response.data {
                        print("   PORTINSTATUS: \(validationData.PORTINSTATUS ?? "nil")")
                        print("   DESCRIPTION: \(validationData.DESCRIPTION ?? "nil")")
                        print("   STATUSCODE: \(validationData.STATUSCODE ?? -1)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        completion(.success(validationData))
                    } else {
                        // Try to extract detailed error message from errors array
                        var errorMessage = response.msg
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errors = json["errors"] as? [String],
                           let firstError = errors.first {
                            // Extract the user-friendly part of the error (before the pipe)
                            let errorParts = firstError.components(separatedBy: "|")
                            if let userFriendlyError = errorParts.first {
                                errorMessage = userFriendlyError.trimmingCharacters(in: .whitespaces)
                            } else {
                                errorMessage = firstError
                            }
                        }
                        
                        print("❌ Port-In Validation API Error: \(errorMessage)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )
                        completion(.failure(error))
                    }
                } catch {
                    print("❌ Failed to decode port-in validation response: \(error)")
                    print("   Error details: \(error.localizedDescription)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("   Raw Response: \(responseString)")
                    }
                    
                    // Try to extract error message from JSON if possible
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        var errorMessage = "Validation failed"
                        
                        // Try to get error from errors array first
                        if let errors = json["errors"] as? [String],
                           let firstError = errors.first {
                            let errorParts = firstError.components(separatedBy: "|")
                            if let userFriendlyError = errorParts.first {
                                errorMessage = userFriendlyError.trimmingCharacters(in: .whitespaces)
                            } else {
                                errorMessage = firstError
                            }
                        } else if let msg = json["msg"] as? String {
                            errorMessage = msg
                        }
                        
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )
                        completion(.failure(error))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // MARK: - Service Availability Check API
    
    /// Response model for check_service_availability API
    struct ServiceAvailabilityResponse: Codable {
        let data: ServiceAvailabilityData?
        let msg: String
        let msg_code: String
        let token: String
    }
    
    /// Service availability data
    struct ServiceAvailabilityData: Codable {
        let enrollment_id: String?
        let zip_code: String?  // Changed to String to handle API response
        let city: String?
        let state: String?
        let external_transaction_id: String?
        // Add other fields as needed from the API response
        
        // Custom decoder to handle zip_code as either string or int
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            enrollment_id = try container.decodeIfPresent(String.self, forKey: .enrollment_id)
            city = try container.decodeIfPresent(String.self, forKey: .city)
            state = try container.decodeIfPresent(String.self, forKey: .state)
            external_transaction_id = try container.decodeIfPresent(String.self, forKey: .external_transaction_id)
            
            // Handle zip_code - can be string or int
            if let zipCodeString = try? container.decode(String.self, forKey: .zip_code) {
                zip_code = zipCodeString
            } else if let zipCodeInt = try? container.decode(Int.self, forKey: .zip_code) {
                zip_code = String(zipCodeInt)
            } else {
                zip_code = nil
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case enrollment_id
            case zip_code
            case city
            case state
            case external_transaction_id
        }
    }
    
    /// Check service availability for a zip code
    /// - Parameters:
    ///   - zipCode: 5-digit zip code
    ///   - enrollmentType: "NON_LIFELINE" for prepaid/postpaid, "LIFELINE" for ACP/Lifeline
    ///   - isEnrollment: "Y" to create enrollment_id, "N" to just check availability
    ///   - agentId: User login ID created in Telgoo5
    ///   - source: "API" or "WEBSITE"
    ///   - externalTransactionId: Optional transaction ID (order ID)
    ///   - completion: Returns service availability data with enrollment_id or error
    func checkServiceAvailability(
        zipCode: String,
        enrollmentType: String = "NON_LIFELINE",
        isEnrollment: String = "Y",
        agentId: String,
        source: String = "WEBSITE",
        externalTransactionId: String? = nil,
        completion: @escaping (Result<ServiceAvailabilityData, Error>) -> Void
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
            "action": "check_service_availability",
            "zip_code": zipCode,
            "enrollment_type": enrollmentType,
            "is_enrollment": isEnrollment,
            "agent_id": agentId,
            "source": source
        ]
        
        if let externalTransactionId = externalTransactionId {
            parameters["external_transaction_id"] = externalTransactionId
        }
        
        // Make authenticated request
        post(endpoint: "/enrollment", parameters: parameters) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let data):
                // Print raw API response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📡 Service Availability API Raw Response:")
                    print(responseString)
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
                
                // Parse response
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ServiceAvailabilityResponse.self, from: data)
                    
                    print("✅ Service Availability API Response:")
                    print("   msg_code: \(response.msg_code)")
                    print("   msg: \(response.msg)")
                    
                    if response.msg_code == "RESTAPI000", let availabilityData = response.data {
                        if let enrollmentId = availabilityData.enrollment_id {
                            print("   enrollment_id: \(enrollmentId)")
                        }
                        print("   city: \(availabilityData.city ?? "nil")")
                        print("   state: \(availabilityData.state ?? "nil")")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        completion(.success(availabilityData))
                    } else {
                        // Check for specific error messages
                        var errorMessage = response.msg
                        if response.msg_code != "RESTAPI000" {
                            // Handle specific error cases
                            if response.msg.contains("We do not provide services") {
                                errorMessage = "Services are not available for this zip code."
                            } else if response.msg.contains("Invalid zip code") {
                                errorMessage = "Invalid zip code. Please enter a valid 5-digit zip code."
                            }
                        }
                        
                        print("❌ Service Availability API Error: \(errorMessage)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )
                        completion(.failure(error))
                    }
                } catch {
                    print("❌ Failed to decode service availability response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("   Raw Response: \(responseString)")
                    }
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Create Customer Prepaid Multiline API
    
    /// Response model for create_customer_prepaid_multiline API
    struct CreateCustomerResponse: Codable {
        let data: [CreateCustomerLineResponse]?
        let msg: String
        let msg_code: String
        let external_transaction_id: String?
        let token: String
    }
    
    /// Response for each line in create_customer_prepaid_multiline
    struct CreateCustomerLineResponse: Codable {
        let data: CreateCustomerLineData?
        let msg: String
        let msg_code: String
    }
    
    /// Data for each line in create_customer_prepaid_multiline
    struct CreateCustomerLineData: Codable {
        let cust_id: Int?
        let customer_id: Int?
        let enrollment_id: String?
        let enrollment_type: String?
        let invoice_number: String?
        let mdn: String?
        let msid: String?
        let msl: String?
    }
    
    /// Create customer prepaid multiline order
    /// - Parameters:
    ///   - enrollmentId: Enrollment ID from check_service_availability
    ///   - orderId: Order ID from make_payment (optional)
    ///   - planId: Plan ID from plan_list
    ///   - customerInfo: Customer information dictionary
    ///   - agentId: User login ID created in Telgoo5
    ///   - source: "API" or "WEBSITE" (default: "API")
    ///   - externalTransactionId: Optional transaction ID
    ///   - completion: Returns create customer response or error
    func createCustomerPrepaidMultiline(
        enrollmentId: String,
        orderId: Int? = nil,
        planId: Int,
        customerInfo: [String: Any],
        agentId: String,
        source: String = "API",
        externalTransactionId: String? = nil,
        completion: @escaping (Result<CreateCustomerResponse, Error>) -> Void
    ) {
        // Build the lines array - for now, single line order
        var line: [String: Any] = [
            "enrollment_id": enrollmentId,
            "plan_id": planId,
            "activation_type": customerInfo["activation_type"] as? String ?? "NEWACTIVATION",
            "enrollment_type": customerInfo["enrollment_type"] as? String ?? "SHIPMENT",
            "carrier": customerInfo["carrier"] as? String ?? "TMBRLY",
            "email": customerInfo["email"] as? String ?? "",
            "first_name": customerInfo["first_name"] as? String ?? "",
            "last_name": customerInfo["last_name"] as? String ?? "",
            "service_address_one": customerInfo["service_address_one"] as? String ?? "",
            "service_city": customerInfo["service_city"] as? String ?? "",
            "service_state": customerInfo["service_state"] as? String ?? "",
            "service_zip": customerInfo["service_zip"] as? String ?? "",
            "billing_address_one": customerInfo["billing_address_one"] as? String ?? "",
            "billing_city": customerInfo["billing_city"] as? String ?? "",
            "billing_state": customerInfo["billing_state"] as? String ?? "",
            "billing_zip": customerInfo["billing_zip"] as? String ?? "",
            "notify_bill_via_text": customerInfo["notify_bill_via_text"] as? String ?? "Y",
            "notify_bill_via_email": customerInfo["notify_bill_via_email"] as? String ?? "Y"
        ]
        
        // Add optional fields
        if let orderId = orderId {
            line["order_id"] = orderId
        }
        
        if let password = customerInfo["password"] as? String, !password.isEmpty {
            line["password"] = password
        }
        
        if let middleInitial = customerInfo["middle_initial"] as? String, !middleInitial.isEmpty {
            line["middle_initial"] = middleInitial
        }
        
        if let alternatePhoneNumber = customerInfo["alternate_phone_number"] as? String, !alternatePhoneNumber.isEmpty {
            line["alternate_phone_number"] = alternatePhoneNumber
        }
        
        if let serviceAddressTwo = customerInfo["service_address_two"] as? String, !serviceAddressTwo.isEmpty {
            line["service_address_two"] = serviceAddressTwo
        }
        
        if let billingAddressTwo = customerInfo["billing_address_two"] as? String, !billingAddressTwo.isEmpty {
            line["billing_address_two"] = billingAddressTwo
        }
        
        // SIM type
        if let isEsim = customerInfo["is_esim"] as? String {
            line["is_esim"] = isEsim
        }
        
        // Port-in information (if activation_type is PORTIN)
        if let activationType = line["activation_type"] as? String, activationType == "PORTIN" {
            if let portCurrentCarrier = customerInfo["port_current_carrier"] as? String {
                line["port_current_carrier"] = portCurrentCarrier
            }
            if let portFirstName = customerInfo["port_first_name"] as? String {
                line["port_first_name"] = portFirstName
            }
            if let portLastName = customerInfo["port_last_name"] as? String {
                line["port_last_name"] = portLastName
            }
            if let portAddressOne = customerInfo["port_address_one"] as? String {
                line["port_address_one"] = portAddressOne
            }
            if let portAddressTwo = customerInfo["port_address_two"] as? String {
                line["port_address_two"] = portAddressTwo
            }
            if let portCity = customerInfo["port_city"] as? String {
                line["port_city"] = portCity
            }
            if let portState = customerInfo["port_state"] as? String {
                line["port_state"] = portState
            }
            if let portZipCode = customerInfo["port_zip_code"] as? String {
                line["port_zip_code"] = portZipCode
            }
            if let portAccountNumber = customerInfo["port_account_number"] as? String {
                line["port_account_number"] = portAccountNumber
            }
            if let portAccountPassword = customerInfo["port_account_password"] as? String {
                line["port_account_password"] = portAccountPassword
            }
            if let portNumber = customerInfo["port_number"] as? String {
                line["port_number"] = portNumber
            }
            if let portSsn = customerInfo["port_ssn"] as? String {
                line["port_ssn"] = portSsn
            }
        }
        
        // Shipping ID (if available)
        if let shippingId = customerInfo["shipping_id"] as? String {
            line["shipping_id"] = shippingId
        }
        
        // Security questions (if available)
        if let securityQuestions = customerInfo["security_questions_answers"] as? [[String: String]] {
            line["security_questions_answers"] = securityQuestions
        }
        
        // Build request parameters
        var parameters: [String: Any] = [
            "lines": [line],
            "parent_enrollment_id": enrollmentId,
            "action": "create_customer_prepaid_multiline",
            "source": source,
            "sub_source": "plans",
            "request_name": "customer",
            "agent_id": agentId
        ]
        
        if let externalTransactionId = externalTransactionId {
            parameters["external_transaction_id"] = externalTransactionId
        }
        
        if let couponCode = customerInfo["coupon_code"] as? String, !couponCode.isEmpty {
            parameters["coupon_code"] = couponCode
        }
        
        // Make authenticated request with 50 second timeout (as per API documentation)
        guard let body = try? JSONSerialization.data(withJSONObject: parameters) else {
            let error = NSError(
                domain: "VCareAPIManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"]
            )
            completion(.failure(error))
            return
        }
        
        // Create request with 50 second timeout
        authenticate { [weak self] authResult in
            guard let self = self else { return }
            
            switch authResult {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let token):
                guard let url = URL(string: "\(self.baseURL)/customer") else {
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
                request.addValue(token, forHTTPHeaderField: "token")
                request.httpBody = body
                request.timeoutInterval = 50  // 50 seconds as per API documentation
                
                // Print request for debugging
                if let requestString = String(data: body, encoding: .utf8) {
                    print("📡 Create Customer API Request:")
                    print(requestString)
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
                
                // Make request
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("❌ Create Customer API Error: \(error.localizedDescription)")
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
                    
                    // Print raw response
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📡 Create Customer API Raw Response:")
                        print(responseString)
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    }
                    
                    // Parse response
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(CreateCustomerResponse.self, from: data)
                        
                        print("✅ Create Customer API Response:")
                        print("   msg_code: \(response.msg_code)")
                        print("   msg: \(response.msg)")
                        
                        if response.msg_code == "RESTAPI000" {
                            if let lines = response.data {
                                for (index, lineResponse) in lines.enumerated() {
                                    if let lineData = lineResponse.data {
                                        print("   Line \(index + 1):")
                                        print("      cust_id: \(lineData.cust_id ?? -1)")
                                        print("      enrollment_id: \(lineData.enrollment_id ?? "nil")")
                                        print("      mdn: \(lineData.mdn ?? "nil")")
                                    }
                                }
                            }
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            completion(.success(response))
                        } else {
                            print("❌ Create Customer API Error: \(response.msg)")
                            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            let error = NSError(
                                domain: "VCareAPIManager",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: response.msg]
                            )
                            completion(.failure(error))
                        }
                    } catch {
                        print("❌ Failed to decode create customer response: \(error)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("   Raw Response: \(responseString)")
                        }
                        completion(.failure(error))
                    }
                }
                
                task.resume()
            }
        }
    }
    
    // MARK: - USPS Address Validation Models
    
    /// Response model for address_validation_usps API
    struct USPSAddressValidationResponse: Codable {
        let data: USPSAddressData?
        let msg: String
        let msg_code: String
        let token: String
        let errors: [String]?
    }
    
    /// USPS address validation data
    struct USPSAddressData: Codable {
        let attributes: Attributes?
        let Address1: String?
        let Address2: String?
        let CarrierRoute: String?
        let CentralDeliveryPoint: String?
        let City: String?
        let DPVConfirmation: String?
        let DPVFalse: String?
        let DPVFootnotes: String?
        let Footnotes: String?
        let State: String?
        let Zip4: String?
        let Zip5: String?
        
        enum CodingKeys: String, CodingKey {
            case Address1, Address2, CarrierRoute, CentralDeliveryPoint, City
            case DPVConfirmation, DPVFalse, DPVFootnotes, Footnotes
            case State, Zip4, Zip5
            case attributes = "@attributes"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            Address1 = try container.decodeIfPresent(String.self, forKey: .Address1)
            Address2 = try container.decodeIfPresent(String.self, forKey: .Address2)
            CarrierRoute = try container.decodeIfPresent(String.self, forKey: .CarrierRoute)
            CentralDeliveryPoint = try container.decodeIfPresent(String.self, forKey: .CentralDeliveryPoint)
            City = try container.decodeIfPresent(String.self, forKey: .City)
            DPVConfirmation = try container.decodeIfPresent(String.self, forKey: .DPVConfirmation)
            DPVFalse = try container.decodeIfPresent(String.self, forKey: .DPVFalse)
            DPVFootnotes = try container.decodeIfPresent(String.self, forKey: .DPVFootnotes)
            Footnotes = try container.decodeIfPresent(String.self, forKey: .Footnotes)
            State = try container.decodeIfPresent(String.self, forKey: .State)
            Zip4 = try container.decodeIfPresent(String.self, forKey: .Zip4)
            Zip5 = try container.decodeIfPresent(String.self, forKey: .Zip5)
            attributes = try container.decodeIfPresent(Attributes.self, forKey: .attributes)
        }
    }
    
    struct Attributes: Codable {
        let ID: String?
    }
    
    // MARK: - USPS Address Validation API
    
    /// Validate address with USPS
    /// - Parameters:
    ///   - enrollmentId: Enrollment ID (optional, reuse existing if available)
    ///   - addressOne: Street address
    ///   - addressTwo: Apartment number or house number (optional)
    ///   - city: City
    ///   - state: State (2-letter code)
    ///   - zipCode: 5-digit ZIP code
    ///   - agentId: User login ID created in Telgoo5
    ///   - source: "API" or "WEBSITE" (default: "WEBSITE")
    ///   - completion: Returns validated address data or error
    func validateAddressUSPS(
        enrollmentId: String? = nil,
        addressOne: String,
        addressTwo: String = "",
        city: String,
        state: String,
        zipCode: String,
        agentId: String,
        source: String = "WEBSITE",
        completion: @escaping (Result<USPSAddressData, Error>) -> Void
    ) {
        // Validate required fields
        guard !addressOne.isEmpty, !city.isEmpty, !state.isEmpty else {
            let error = NSError(
                domain: "VCareAPIManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Address, city, and state are required."]
            )
            completion(.failure(error))
            return
        }
        
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
            "address_one": addressOne,
            "address_two": addressTwo,
            "city": city.uppercased(),
            "state": state.uppercased(),
            "zip_code": zipCode,
            "action": "address_validation_usps",
            "agent_id": agentId,
            "source": source
        ]
        
        // Add enrollment_id if provided
        if let enrollmentId = enrollmentId, !enrollmentId.isEmpty {
            parameters["enrollment_id"] = enrollmentId
        }
        
        // Make authenticated request
        post(endpoint: "/address", parameters: parameters) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let data):
                // Print raw API response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📡 USPS Address Validation API Raw Response:")
                    print(responseString)
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }
                
                // Parse response
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(USPSAddressValidationResponse.self, from: data)
                    
                    print("✅ USPS Address Validation API Response:")
                    print("   msg_code: \(response.msg_code)")
                    print("   msg: \(response.msg)")
                    
                    if response.msg_code == "RESTAPI000", let addressData = response.data {
                        print("   Validated Address:")
                        print("      Address1: \(addressData.Address1 ?? "nil")")
                        print("      Address2: \(addressData.Address2 ?? "nil")")
                        print("      City: \(addressData.City ?? "nil")")
                        print("      State: \(addressData.State ?? "nil")")
                        print("      Zip5: \(addressData.Zip5 ?? "nil")")
                        print("      Zip4: \(addressData.Zip4 ?? "nil")")
                        print("      DPVConfirmation: \(addressData.DPVConfirmation ?? "nil")")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        completion(.success(addressData))
                    } else {
                        // Extract detailed error message from errors array if available
                        var errorMessage = response.msg
                        if let errors = response.errors, let firstError = errors.first {
                            // Use the first error from the errors array as it's more descriptive
                            errorMessage = firstError
                            print("   Detailed error from errors array: \(firstError)")
                        }
                        
                        print("❌ USPS Address Validation API Error:")
                        print("   msg_code: \(response.msg_code)")
                        print("   msg: \(response.msg)")
                        if let errors = response.errors {
                            print("   errors: \(errors)")
                        }
                        print("   Final error message: \(errorMessage)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        
                        let error = NSError(
                            domain: "VCareAPIManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )
                        completion(.failure(error))
                    }
                } catch {
                    print("❌ Failed to decode USPS address validation response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("   Raw Response: \(responseString)")
                    }
                    completion(.failure(error))
                }
            }
        }
    }
}

