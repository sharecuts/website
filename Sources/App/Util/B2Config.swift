//
//  B2Config.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import DotEnv

struct B2Config {

    let infoPath: String
    let executablePath: String
    let bucketName: String
    let baseURL: URL

    init(env: DotEnv) {
        let defaultInfoPath = "~/.b2_account_info"
        let defaultExecutablePath = "/usr/local/bin/b2"
        let defaultName = "sharecuts"
        let defaultUrl = "https://f001.backblazeb2.com/file/sharecuts/"

        let path = env.get("B2_EXECUTABLE_PATH") ?? defaultExecutablePath
        let baseURLStr = env.get("B2_BUCKET_BASE_URL") ?? defaultUrl
        let url = URL(string: baseURLStr)!

        self.infoPath = env.get("B2_INFO_PATH") ?? defaultInfoPath
        self.executablePath = path
        self.bucketName = env.get("B2_BUCKET_NAME") ?? defaultName
        self.baseURL = url
    }

}
