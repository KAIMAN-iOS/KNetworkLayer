//
//  Api.swift
//  iOS Example
//
//  Created by GG on 24/09/2020.
//

import KNetworkLayer
import UIKit
import PromiseKit
import Alamofire


//MARK:- Example of an Internal class for API
// MARK: - AppAPI
// -
struct AppAPI {
    private let api = DailySpecialApi.shared
    static let shared: AppAPI = AppAPI()
    private init() {}
    
    enum ApiError: Error {
        case noEmail
        case refreshTokenFailed
    }
    
    func updateUser(name: String, firstname: String, dob: Date) -> Promise<User> {
        let route = UpdateUserRoute(name: name, firstname: firstname, dob: dob)
        return perform(route: route).get { user in
            DataManager.instance.store(user.currentUser)
        }
    }
}

private class DailySpecialApi: API {
    // Singleton
    static let shared: DailySpecialApi = DailySpecialApi()
    
    /// URL de base de l'api Transport.
    var baseURL: URL {
        URL(string: Constants.network.rootUrl)!
    }
    
    /// Headers communs à tous les appels (aucun pour cette api)/
    var commonHeaders: HTTPHeaders? {
        let header = HTTPHeaders.init([HTTPHeader.contentType("application/json")])
        return header
    }
    
    var decoder: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }
}

//MARK:- Common parameters Encodable base class
// make all routes pamraetrs inherit from this class to allow common parameters...
class CovidAppApiCommonParameters: RequestParameters {
}

//MARK:- Examples of a authen fails and retry code
private extension AppAPI {
    func perform<T>(route: RequestObject<T>, showMessageOnFail: Bool = true) -> Promise<T> {
        return Promise<T>.init { resolver in
            performAndRetry(route: route)
                .done { object in
                    resolver.fulfill(object)
            }
            .catch { error in
                if showMessageOnFail {
//                    MessageManager.show(.request(.serverError))
                }
                resolver.reject(error)
            }
        }
    }
    
    func performAndRetry<T>(route: RequestObject<T>) -> Promise<T> {
        func refresh() -> Promise<T> {
            self.performAndRetry(route: route)
        }
        
        var hasRefreshed: Bool = false
        return
            api
            .perform(route)
            .recover { error -> Promise<T> in
                switch error {
                case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) where hasRefreshed == false:
                    // only once
                    hasRefreshed = true
                    print("🐞 refresh token try....")
                    return refresh()
                    
                default: return Promise<T>.init(error: error)
                }
    
        }
    }
}

// MARK: - Code example on how to use RequestObject to retrieve a User with parameters
/**
 Obtenir les arrêts d’une ligne.
 - Returns: les arrêts dans l’ordre pour une ligne et une destination
 */
class UpdateUserRoute: RequestObject<User> {
    // MARK: - RequestObject Protocol
    
    override var method: HTTPMethod {
        .post
    }
    
    override var endpoint: String? {
        "user/post"
    }
    
    override var encoding: ParameterEncoding {
        return JSONEncoding.default
    }
    
    override var parameters: RequestParameters? {
        return UpdateUserParameter(name: name, firstname: firstname, dob: dob)
        //        ["username" :  email! as Any]
    }
    // MARK: Initializers
    let name: String
    let firstname: String
    let dob: String
    
    init(name: String, firstname: String, dob: Date) {
        self.name = name
        self.firstname = firstname
        self.dob = Date.apiDateFormatter.string(from: dob)
    }
}

class UpdateUserParameter: CovidAppApiCommonParameters {
    let name: String
    let firstname: String
    let dob: String
    
    init(name: String, firstname: String, dob: String) {
        self.name = name
        self.firstname = firstname
        self.dob = dob
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case firstname = "firstname"
        case dob = "dob"
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(firstname, forKey: .firstname)
        try container.encode(dob, forKey: .dob)
    }
}
