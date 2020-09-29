//
//  RequestObject.swift
//  GameOffer
//
//  Created by Jean Philippe on 10/09/2019.
//  Copyright © 2019 jps. All rights reserved.
//

import Alamofire
import Foundation
import UIKit

/**
    Objet à fournir à l'objet API, ExpectedObject etant le type de réponse attendu si la requête à réussie.
 */
open class RequestObject<ExpectedObject: Decodable> {
    public typealias RequestObjectCompletionHandler = (_ result: Result<ExpectedObject, Error>) -> Void
    
    let uniqueId: String = UUID().uuidString
    
    open var parameters: RequestParameters? {
        return nil
    }
    
    open var headers:  HTTPHeaders? {
        return nil
    }
    
    open var method: HTTPMethod {
        return .get
    }
    
    open var endpoint: String? {
        return nil
    }
    
    open var uploadFiles: Bool {
        return false
    }
    
    open var encoding: ParameterEncoding {
        switch method {
            case .get:  return URLEncoding.default
            default:    return URLEncoding.default
        }
    }
    
    open func createMultiPartFormData(_ mpfd: MultipartFormData) {}
    
    open var mockJsonName: String? {
        return nil
    }
    
    open var mockResponse: Bool {
        return false
    }
    public init() {}
}

open class RequestParameters: Encodable {
    public init() {}
}
