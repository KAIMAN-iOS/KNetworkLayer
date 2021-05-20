//
//  File.swift
//  
//
//  Created by GG on 19/05/2021.
//

import Foundation
import Alamofire

// for 401 refreshToken retry policy
public protocol AccessTokenStorage: NSObjectProtocol {
    typealias JWT = String
    var accessToken: JWT { get set }
}

final class RequestInterceptor: Alamofire.RequestInterceptor {
    private let storage: AccessTokenStorage
    private let handleAuthentication: Bool
    var refreshToken: (((Result<AccessTokenStorage, Error>) -> Void) -> Void)

    init(storage: AccessTokenStorage, handleAuthentication: Bool = false, refreshToken: @escaping (((Result<AccessTokenStorage, Error>) -> Void) -> Void)) {
        self.storage = storage
        self.handleAuthentication = handleAuthentication
        self.refreshToken = refreshToken
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard handleAuthentication else {
            /// If the request does not require authentication, we can directly return it as unmodified.
            return completion(.success(urlRequest))
        }
        var urlRequest = urlRequest

        /// Set the Authorization header value using the access token.
        urlRequest.setValue("Bearer " + storage.accessToken, forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request,
               for session: Session,
               dueTo error: Error,
               completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetryWithError(error))
        }

        refreshToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let token):
                self.storage.accessToken = token.accessToken
                /// After updating the token we can safely retry the original request.
                completion(.retry)
            case .failure(let error):
                completion(.doNotRetryWithError(error))
            }
        }
    }
}
