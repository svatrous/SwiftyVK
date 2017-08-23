protocol ApiErrorHandler {
    func handle(error: ApiError) throws -> ApiErrorHandlerResult
}

final class ApiErrorHandlerImpl: ApiErrorHandler {
    
    private let executor: ApiErrorExecutor
    
    init(executor: ApiErrorExecutor) {
        self.executor = executor
    }
    
    func handle(error: ApiError) throws -> ApiErrorHandlerResult {
        switch error.code {
        case 5:
            _ = try executor.logIn(revoke: false)
            return .none
        case 14:
            guard
                let sid = error.otherInfo["captcha_sid"],
                let imgRawUrl = error.otherInfo["captcha_img"]
                else {
                    throw VkError.api(error)
            }
            
            let key = try executor.captcha(rawUrlToImage: imgRawUrl, dismissOnFinish: false)
            return .captcha(Captcha(sid, key))
        case 17:
            guard
                let rawUrl = error.otherInfo["redirect_uri"],
                let url = URL(string: rawUrl)
                else {
                    throw VkError.api(error)
            }
            
            try executor.validate(redirectUrl: url)
            return .none
        default:
            throw VkError.api(error)
        }
    }
}

enum ApiErrorHandlerResult {
    case captcha(Captcha)
    case none
}
