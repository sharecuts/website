//
//  Request+RedirectWithMessage.swift
//  App
//
//  Created by Guilherme Rambo on 11/10/18.
//

import Foundation
import Vapor

extension Request {
    
    func redirect(to path: String, with message: String, paramName: String = "error") -> Future<Response> {
        let response: Response = redirect(to: path, with: message, paramName: paramName)
        return future(response)
    }
    
    func redirect(to path: String, with message: String, paramName: String = "error") -> Response {
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let sep = path.contains("?") ? "&" : "?"

        return redirect(to: path + "\(sep)\(paramName)=\(encodedMessage)")
    }
    
}
