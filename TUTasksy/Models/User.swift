import Foundation

struct UserInfo: Codable {
    let displayname_th: String
    let displayname_en: String
    let username: String
    let type: String
    let email: String
    let department: String
    let faculty: String
}

struct Response: Decodable {
    let token: String
    let userInfo: UserInfo
}
