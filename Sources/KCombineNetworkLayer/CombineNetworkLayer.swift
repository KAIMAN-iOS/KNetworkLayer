//
//  File.swift
//  
//
//  Created by GG on 19/05/2021.
//

import Foundation
import KNetworkLayer
import Alamofire
import Combine

@available(iOS 13.0, *)
public extension API {
    func publishDataRequest<T: Decodable>(_ request: RequestObject<T>, verbose: Bool = false) -> AnyPublisher<T, Error> {
        var headers: HTTPHeaders = HTTPHeaders()
        commonHeaders?.forEach({ headers.add($0) })
        request.headers?.forEach({ headers.add($0) })
        let dataRequest: DataRequest!
        if let data = request.multipartData {
            dataRequest = AF.upload(multipartFormData: data,
                                        to: baseURL.appendingPathComponent(request.endpoint ?? ""),
                                        method: request.method,
                                        headers: headers)
        } else {
            dataRequest = AF.request(baseURL.appendingPathComponent(request.endpoint ?? ""),
                                     method: request.method,
                                     parameters: request.parameters,
                                     encoder: request.encoder,
                                     headers: headers,
                                     interceptor: nil)
        }
        printDataRequest(request: dataRequest)
        return dataRequest
            .publishResponse(using: DataResponseSerializer())
            .retry(1)
            .map(\.data, \.response?.statusCode)
            .tryMap({ data, code -> T in
                let res: Swift.Result<T, AFError> = self.handleDataResponse(data, statusCode: code)
                switch res {
                case .success(let object): return object
                case .failure(let error): throw error
                }
            })
            .eraseToAnyPublisher()
    }
    
    func performPublisher<T: Decodable>(_ request: RequestObject<T>, verbose: Bool = false) -> AnyPublisher<T, Error> {
        // MOCK UP HANDLE
        guard request.mockResponse == false else {
            guard let jsonName = request.mockJsonName,
                let url = Bundle.main.url(forResource: jsonName, withExtension: "json"),
                let data =  try? Data(contentsOf: url) else {
                return Fail<T, Error>(error: ApiError.mockUpNotFound).eraseToAnyPublisher()
            }
            let response = self.handleResponse(data: data, code: 200, expectedObject: T.self)
            switch response {
            case .success(let object):
                return Just(object)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
                
            case .failure(let error):
                return Fail<T, Error>(error: error).eraseToAnyPublisher()
            }
        }
        
        return self.publishDataRequest(request, verbose: verbose)
    }
}
