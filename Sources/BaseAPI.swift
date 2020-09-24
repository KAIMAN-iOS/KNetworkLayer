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
import PromiseKit


// MARK: Protocol API Implementation
public protocol API {
    var baseURL: URL { get }
    var commonHeaders: HTTPHeaders? { get }
    var commonParameters: Parameters? { get }
    var decoder: JSONDecoder { get }
    func perform<T: Decodable>(_ request: RequestObject<T>) -> Promise<T>
}

public enum ApiError: Error {
    case mockUpNotFound
}

/**
 Comportement par défaut d'un objet API
 */
public extension API {
    
    var decoder: JSONDecoder {
        return JSONDecoder()
    }
    
    var commonParameters: Parameters? {
        return nil
    }
    
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
    }
    
    /**
    Traite une réponse Alamofire (DataResponse)
     - Parameter dataResponse: Objet de réponse d'une requête d'alamofire
     */
    func handleDataResponse<T: Decodable>(_ dataResponse: DataResponse<Any, AFError>) -> Swift.Result<T, AFError> {
        
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
        
        guard let code = dataResponse.response?.statusCode else {
            return returnError(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: -1)))
        }

        let handling = handleResponse(data: dataResponse.data, code: code, expectedObject: T.self)
        
        if let error = handling.error as? AFError {
            return returnError(error)
        } else if let error = handling.error {
            return returnError(AFError.responseSerializationFailed(reason: .customSerializationFailed(error: error)))
        } else if let object = handling.object {
            return returnSuccess(object)
        } else {
            return returnError(AFError.responseSerializationFailed(reason: .customSerializationFailed(error: NSError())))
        }
    }
    
    /**
     Traite une réponse du serveur de type Data
     - Parameter data: La data retournée par le serveur
     - Parameter code: Le code HTTP retourné par le serveur
     - Parameter expectedObject: Le type d'objet attendu après décodage du JSON
     
     - Returns: Objet attendu si le décodage de la réponse à réussi (objet), ou erreur s'il a échoué (error)
     */
    private func handleResponse<T: Decodable>(data: Data?, code: Int, expectedObject: T.Type) -> (object: T?, error: Error?) {

        guard let data = data else {
            return (nil, AFError.responseValidationFailed(reason: .dataFileNil))
        }
                
        switch code {
        case 200:
            do {
                let object = try decoder.decode(expectedObject, from: data)
                return (object,nil)
            } catch {
                return (nil, error)
            }
//        case 500: return (nil, AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 500))))
        default: return (nil, AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: code)))
        }
    }
    
    //MARK:- Alamofire5 and Promise implementation
    func dataRequest<T: Decodable>(_ request: RequestObject<T>) -> DataRequest {
        var headers: HTTPHeaders = HTTPHeaders()
        commonHeaders?.forEach({ headers.add($0) })
        request.headers?.forEach({ headers.add($0) })
        let dataRequest = AF.request(baseURL.appendingPathComponent(request.endpoint ?? ""), method: request.method, parameters: request.parameters, encoder: JSONParameterEncoder.default, headers: headers, interceptor: nil)
        printDataRequest(request: dataRequest)
        return dataRequest
    }
    
    func perform<T: Decodable>(_ request: RequestObject<T>) -> Promise<T> {
        // MOCK UP HANDLE
        guard request.mockResponse == false else {
            return Promise<T>.init { resolver in
                guard let jsonName = request.mockJsonName,
                    let url = Bundle.main.url(forResource: jsonName, withExtension: "json"),
                    let data =  try? Data(contentsOf: url) else {
                    resolver.reject(ApiError.mockUpNotFound)
                    return
                }
                let object = self.handleResponse(data: data, code: 200, expectedObject: T.self)
                if let response = object.object {
                    resolver.fulfill(response)
                } else if let error = object.error {
                    resolver.reject(error)
                } else {
                    resolver.reject(ApiError.mockUpNotFound)
                }
            }
        }
        
        return Promise<T>.init { resolver in
            self.dataRequest(request)
                .responseJSON { (dataResponse) in
                    self.printResponse(dataResponse)
                    let result: Swift.Result<T, AFError> = self.handleDataResponse(dataResponse)
                    switch result {
                    case .success(let data): resolver.fulfill(data)
                    case .failure(let error): resolver.reject(error)
                    }
            }
        }
    }
    
    private func printDataRequest(request: DataRequest) {
        print("\n💬💬💬 Request:")
        if let url = request.convertible.urlRequest?.url { print("• URL: \(url)")}
        if let headers = request.convertible.urlRequest?.allHTTPHeaderFields { print("• Headers: \(headers))") }
        if let method = request.convertible.urlRequest?.method { print("• Method: \(method)") }
        
        if let params = request.convertible.urlRequest?.httpBody {
            print("• Parameters: \(String(data: params, encoding: .utf8) ?? "")")
        }
    }
}
