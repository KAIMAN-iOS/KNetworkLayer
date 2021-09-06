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
        nil
    }
    
    open var multipartData: MultipartFormData? {
        nil
    }
    
    open var headers:  HTTPHeaders? {
        nil
    }
    
    open var method: HTTPMethod {
        .get
    }
    
    open var endpoint: String? {
        nil
    }
    
    open var uploadFiles: Bool {
        false
    }
    
    open var encoding: ParameterEncoding {
        switch method {
            case .get:  return URLEncoding.default
            default:    return URLEncoding.default
        }
    }
    
    open var encoder: ParameterEncoder {
        switch method {
        case .post, .patch: return JSONParameterEncoder.default
        default: return URLEncodedFormParameterEncoder.init(destination: .queryString)
        }
    }
    
    open func createMultiPartFormData(_ mpfd: MultipartFormData) {}
    
    open var mockJsonName: String? {
        nil
    }
    
    open var mockResponse: Bool {
        false
    }
    public init() {}
}

open class RequestParameters: Encodable {
    public init() {}
}
