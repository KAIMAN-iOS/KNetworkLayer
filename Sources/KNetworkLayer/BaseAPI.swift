//
//  API.swift
//  GameOffer
//
//  Created by Jean Philippe on 10/09/2019.
//  Copyright © 2019 jps. All rights reserved.
//

import Foundation
import UIKit
import Alamofire


// MARK: Protocol API Implementation
public protocol API {
    var baseURL: URL { get }
    var commonHeaders: HTTPHeaders? { get }
    var commonParameters: Parameters? { get }
    var decoder: JSONDecoder { get }
    var sessionManager: Session { get }
}

public enum ApiError: Error {
    case mockUpNotFound
}

/**
 Comportement par défaut d'un objet API
 */
public extension API {
    var decoder: JSONDecoder { JSONDecoder() }
    var commonParameters: Parameters? { nil }
    var sessionManager: Session { Session() }
    
    func printRequest<T>(_ request: RequestObject<T>, urlRequest: URLRequest) {
        guard let url = urlRequest.url else { return }
        
        print("\n💬💬💬 Request:")
        print("• URL: \(url)")
        print("• Headers: \(urlRequest.allHTTPHeaderFields ?? [:]))")
        print("• Method: \(request.method)")
        
        if let params = request.parameters {
            print("• Parameters: \(params)")
        }
    }
    
    /**
     Log dans la console la réponse du serveur, formé de manière à ce que ça soit le plus lisible possible.
     - Parameter dataResponse: Réponse Alamofire
     */
    func printResponse(_ dataResponse: DataResponse<Any, AFError>) {
        //        #if NETWORK_LOGS
        print("\n🔵🔵🔵 Response:")
        if let data = dataResponse.data, let code = dataResponse.response?.statusCode, let str = String(data: data, encoding: .utf8), let url = dataResponse.request?.url {
            print("• URL: \(url)")
            print("• Code: \(code)")
            print("• Response: \(str)\n")
        } else if let url = dataResponse.request?.url, let code = dataResponse.response?.statusCode {
            print("• URL: \(url)")
            print("• Code: \(code)")
            print("• Response: <<Empty>>\n")
        } else if let url = dataResponse.request?.url {
            print("• URL: \(url)")
            print("• ERROR")
        }
        if let headers = dataResponse.response?.headers {
            print("• HEADERS")
            print("• \(headers)")
        }
        //        #endif
    }
    
    /**
     Traite une réponse Alamofire (DataResponse)
     - Parameter dataResponse: Objet de réponse d'une requête d'alamofire
     */
    func handleDataResponse<T: Decodable>(_ dataResponse: DataResponse<Any, AFError>) -> Swift.Result<T, AFError> {
        guard dataResponse.error == nil else {
            return Swift.Result.failure(dataResponse.response?.statusCode ?? 0 == 401 ? AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) : dataResponse.error!)
        }
        //pprint("🤢 Reponse \(dataResponse.error)\n\(dataResponse.error?.localizedDescription)")
        return handleDataResponse(dataResponse.data, statusCode: dataResponse.response?.statusCode)
    }
    
    func handleDataResponse<T: Decodable>(_ data: Data?, statusCode: Int?) -> Swift.Result<T, AFError> {
        let returnError: (_ error: AFError) -> Swift.Result<T, AFError> = { err in
            //            let error = NSError(domain: "unknown", code: 0, userInfo: nil)
            print("🆘 Request failed \(err).")
            // Retourner ou faire un print sur err fait crasher l'app ???
            // called; this results in an invalid NSError instance. It will raise an exception in a future release. Please call errorWithDomain:code:userInfo: or initWithDomain:code:userInfo:. This message shown only once.
            return Swift.Result.failure(err)
        }
        
        let returnSuccess: (_ object: T) -> Swift.Result<T, AFError> = { obj in
            print("✅ Request succeeded.")
            return Swift.Result.success(obj)
        }
        
        guard let code = statusCode else {
            return returnError(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: -1)))
        }
        
        let handling = handleResponse(data: data, code: code, expectedObject: T.self)
        switch handling {
        case .success(let object): return returnSuccess(object)
        case .failure(let error):
            if let error = error as? AFError {
                return returnError(error)
            } else {
                return returnError(AFError.responseSerializationFailed(reason: .customSerializationFailed(error: error)))
            }
        }
    }
    
    /**
     Traite une réponse du serveur de type Data
     - Parameter data: La data retournée par le serveur
     - Parameter code: Le code HTTP retourné par le serveur
     - Parameter expectedObject: Le type d'objet attendu après décodage du JSON
     
     - Returns: Objet attendu si le décodage de la réponse à réussi (objet), ou erreur s'il a échoué (error)
     */
    func handleResponse<T: Decodable>(data: Data?, code: Int, expectedObject: T.Type) -> Result<T, Error> {
        switch code {
        case 200, 204:
            do {
                let object = try decoder.decode(expectedObject, from: data == nil ? "{}".data(using: .utf8)! : data!)
                return .success(object)
            } catch {
                print("🔌 \(error)")
                return .failure(error)
            }
        default:
            return .failure(AFError.responseValidationFailed(reason: (data == nil && [401, 500].contains(code) == false) ? .dataFileNil : .unacceptableStatusCode(code: code)))
        }
    }
    
    //MARK:- Alamofire5 and Promise implementation
    func dataRequest<T: Decodable>(_ request: RequestObject<T>) -> DataRequest {
        var headers: HTTPHeaders = HTTPHeaders()
        commonHeaders?.forEach({ headers.add($0) })
        request.headers?.forEach({ headers.add($0) })
        let dataRequest: DataRequest!
        if let data = request.multipartData {
            dataRequest = sessionManager.upload(multipartFormData: data,
                                                to: baseURL.appendingPathComponent(request.endpoint ?? ""),
                                                method: request.method,
                                                headers: headers)
        } else {
            dataRequest = sessionManager.request(baseURL.appendingPathComponent(request.endpoint ?? ""),
                                                 method: request.method,
                                                 parameters: request.parameters,
                                                 encoder: request.encoder,
                                                 headers: headers,
                                                 interceptor: nil)
        }
        printDataRequest(request: dataRequest)
        return dataRequest
    }
    
    func printDataRequest(request: DataRequest) {
        //        #if NETWORK_LOGS
        print("\n💬💬💬 Request:")
        if let url = request.convertible.urlRequest?.url { print("• URL: \(url)")}
        if let headers = request.convertible.urlRequest?.headers { print("• Headers: \(headers))") }
        if let method = request.convertible.urlRequest?.method { print("• Method: \(method)") }
        if let params = request.convertible.urlRequest?.httpBody {
            print("• Parameters: \(String(data: params, encoding: .utf8) ?? "")")
        }
        //        #endif
    }
}
