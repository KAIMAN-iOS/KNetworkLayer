//
//  File.swift
//  
//
//  Created by GG on 29/09/2020.
//

import Foundation
import PromiseKit
import KNetworkLayer
import Alamofire

public extension API {
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
}
