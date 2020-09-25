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
    
    func retrievePost(nb: Int) -> Promise<[Post]> {
        return api.perform(RetrievePost())
    }
}

private class DailySpecialApi: API {
    // Singleton
    static let shared: DailySpecialApi = DailySpecialApi()
    
    /// URL de base de l'api Transport.
    var baseURL: URL {
        URL(string: "http://jsonplaceholder.typicode.com")!
    }
    
    /// Headers communs à tous les appels (aucun pour cette api)/
    var commonHeaders: HTTPHeaders? {
//        let header = HTTPHeaders.init([HTTPHeader.contentType("application/json")])
//        return header
        return nil
    }
    
    var decoder: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }
}

//MARK:- Common parameters Encodable base class
// make all routes pamraetrs inherit from this class to allow common parameters...
class AppApiCommonParameters: RequestParameters {
}

struct Post: Decodable {
    var userId: Int
    var id: Int
    var title: String
    var body: String
}
// MARK: - Code example on how to use RequestObject to retrieve a User with parameters
/**
 Obtenir les arrêts d’une ligne.
 - Returns: les arrêts dans l’ordre pour une ligne et une destination
 */
class RetrievePost: RequestObject<[Post]> {
    // MARK: - RequestObject Protocol
    
    override var method: HTTPMethod {
        .get
    }
    
    override var endpoint: String? {
        "/posts"
        // "/posts/\(numberOfPosts)" for REST APIs
    }
    
    override var encoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    override var parameters: RequestParameters? {
        return nil
    }
}

// used for POST PAERAMETERS
class PostParameter: AppApiCommonParameters {
    let numberOfPost: Int
    
    init(numberOfPost: Int) {
        self.numberOfPost = numberOfPost
        super.init()
    }
}

//MARK:- Examples of a authen fails and retry code
//private extension AppAPI {
//    func perform<T>(route: RequestObject<T>, showMessageOnFail: Bool = true) -> Promise<T> {
//        return Promise<T>.init { resolver in
//            performAndRetry(route: route)
//                .done { object in
//                    resolver.fulfill(object)
//            }
//            .catch { error in
//                if showMessageOnFail {
////                    MessageManager.show(.request(.serverError))
//                }
//                resolver.reject(error)
//            }
//        }
//    }
//
//    func performAndRetry<T>(route: RequestObject<T>) -> Promise<T> {
//        func refresh() -> Promise<T> {
//            self.performAndRetry(route: route)
//        }
//
//        var hasRefreshed: Bool = false
//        return
//            api
//            .perform(route)
//            .recover { error -> Promise<T> in
//                switch error {
//                case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) where hasRefreshed == false:
//                    // only once
//                    hasRefreshed = true
//                    print("🐞 refresh token try....")
//                    return refresh()
//
//                default: return Promise<T>.init(error: error)
//                }
//
//        }
//    }
//}

