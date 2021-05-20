//
//  File.swift
//  
//
//  Created by GG on 19/05/2021.
//

import Foundation
import Alamofire

open class AuthenticatedApi: API {
    var storage: AccessTokenStorage
    var refreshToken: (((Result<AccessTokenStorage, Error>) -> Void) -> Void)
    public var baseURL: URL
    public var commonHeaders: HTTPHeaders?
    public lazy var sessionManager: Session = { Session(interceptor: RequestInterceptor(storage: storage,
                                                                                        handleAuthentication: true,
                                                                                        refreshToken: refreshToken)) } ()
    
    public init(baseURL: URL,
                storage: AccessTokenStorage,
                refreshToken: @escaping (((Result<AccessTokenStorage, Error>) -> Void) -> Void)) {
        self.baseURL = baseURL
        self.storage = storage
        self.refreshToken = refreshToken
    }
}
