//
//  MCommunication.swift
//  Memoria
//
//  Created by Sagar on 2021-08-07.
//

import Alamofire
import Foundation
import KeychainAccess

public class MComm: SessionDelegate {
    static let shared: MComm = .init()

    private let keychain = Keychain(service: "com.memoria.tokens")
    private var reachabilityStatus: NetworkReachabilityManager.NetworkReachabilityStatus = .unknown

    internal lazy var session: Alamofire.Session = {
        let configuration = URLSessionConfiguration.af.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return Alamofire.Session(
            configuration: configuration,
            delegate: self,
            rootQueue: DispatchQueue(label: "com.memoria.sessionManagerData.rootQueue"),
            startRequestsImmediately: true,
            interceptor: JwtInterceptor(storage: keychain)
        )
    }()

    private let reachabilityManager = Alamofire.NetworkReachabilityManager()

    override public init(fileManager: FileManager = .default) {
        super.init(fileManager: fileManager)

        print("Starting Communication Services")
        startNetworkReachabilityObserver()

        testing()
    }

    deinit {
        print("Stopping Communication Services")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "changeUser"), object: nil)
        stopNetworkReachabilityObserver()
    }

    public func testing() {
        let items = keychain.allItems()
        for item in items {
            print("item: \(item)")
        }
    }

    // MARK: - Uploads

    func upload(file: FileUpload, serverUrl: String, queue: DispatchQueue = .main,
                requestHandler _: @escaping (_ request: UploadRequest) -> Void = { _ in },
                taskHandler: @escaping (_ task: URLSessionTask) -> Void = { _ in },
                progressHandler: @escaping (_ progress: Progress) -> Void = { _ in },
                completionHandler: @escaping (_ account: String, _ error: AFError?, _ errorCode: Int?, _ errorDescription: String?) -> Void)
    {
        guard serverUrl != "" else { return }

        let parameters: [String: String] = [
            "assetId": String(file.assetId),
            "filename": String(file.filename),
            "mediaType": String(file.mediaType),
            "mediaSubType": String(file.mediaSubType),
            "creationDate": String(file.creationDate.timeIntervalSince1970),
            "modificationDate": String(file.modificationDate.timeIntervalSince1970),
            "duration": String(file.duration),
            "isFavorite": file.isFavorite.description,
            "isHidden": file.isHidden.description,
            "isLivePhoto": file.isLivePhoto.description,
        ]

        session.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: .utf8)!, withName: key)
            }

            if (file.url?.isFileURL) != nil {
                multipartFormData.append(file.url!, withName: "files")
            }
            if (file.livePhotoUrl?.isFileURL) != nil {
                multipartFormData.append(file.livePhotoUrl!, withName: "files")
            }

        }, to: serverUrl, method: .post)
            .validate()
            .onURLSessionTaskCreation(perform: { task in
                queue.async { taskHandler(task) }
            })
            .uploadProgress { progress in
                queue.async { progressHandler(progress) }
            }
            .response(queue: DispatchQueue.main) { response in
                switch response.result {
                case let .failure(error):
                    let resultError = MCommError().getError(error: error, httResponse: response.response)
                    queue.async { completionHandler("nil", error, resultError.errorCode, resultError.description ?? "") }
                case .success:
                    queue.async { completionHandler("nil", nil, nil, nil) }
                }
            }
    }

    // MARK: - Downloads

    func downloadSavedAssets(serverUrl: String, queue: DispatchQueue = .main,
                             requestHandler _: @escaping (_ request: UploadRequest) -> Void = { _ in },
                             taskHandler: @escaping (_ task: URLSessionTask) -> Void = { _ in },
                             completionHandler: @escaping (_ res: AssetCollection?, _ error: AFError?, _ errorCode: Int?, _ errorDescription: String?) -> Void)
    {
        guard serverUrl != "" else { return }

        session.request(serverUrl, method: .get)
            .validate()
            .onURLSessionTaskCreation(perform: { task in
                queue.async { taskHandler(task) }
            })
            .responseDecodable(of: AssetCollection.self) { response in
                switch response.result {
                case let .failure(error):
                    let resultError = MCommError().getError(error: error, httResponse: response.response)
                    queue.async { completionHandler(nil, error, resultError.errorCode, resultError.description ?? "") }
                case .success:
                    queue.async { completionHandler(response.value, nil, nil, nil) }
                }
            }
    }

    // MARK: - Reachability

    private func startNetworkReachabilityObserver() {
        reachabilityManager?.startListening(onUpdatePerforming: { status in
            self.reachabilityStatus = status
        })
    }

    private func stopNetworkReachabilityObserver() {
        reachabilityManager?.stopListening()
    }

    public func isNetworkReachable() -> Bool {
        return reachabilityManager?.isReachable ?? false
    }
}

struct JwtInterceptor: RequestInterceptor {
    private let storage: Keychain

    init(storage: Keychain) {
        self.storage = storage
    }

    func adapt(_ urlRequest: URLRequest, for _: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard urlRequest.url?.absoluteString.hasPrefix("http://192.168.100.35:12480") == true
        else {
            return completion(.success(urlRequest))
        }

        var urlRequest = urlRequest
        let token = (try? storage.get("bearer_token")) ?? ""
        urlRequest.headers.add(.authorization(bearerToken: token))

        completion(.success(urlRequest))
    }

    func retry(_ request: Alamofire.Request, for _: Alamofire.Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetryWithError(error))
        }

        print("\nretried; retry count: \(request.retryCount)\n")
        refreshToken { isSuccess in
            isSuccess ? completion(.retry) : completion(.doNotRetry)
        }
    }

    func refreshToken(completion: @escaping (_ isSuccess: Bool) -> Void) {
        guard let refToken = try? storage.get("refresh_token") else {
            completion(false)
            return
        }

        let parameters = ["refresh_token": refToken]

        AF.request("http://192.168.100.35:12480/api/auth/refresh", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: RefreshToken.self) { response in
                switch response.result {
                case let .failure(error):
                    let resultError = MCommError().getError(error: error, httResponse: response.response)
                    completion(false)
                case .success:
                    self.storage["bearer_token"] = response.value?.data.payload.token
                    completion(true)
                }
            }
    }
}