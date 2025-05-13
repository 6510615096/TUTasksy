import Foundation
import SwiftUI

struct Report: Identifiable {
    let id: String
    let reportedUserId: String
    let reporterUserId: String?
    let reason: String?
    let timestamp: Date?
    let status: ReportStatus
    
    enum ReportStatus: String, CaseIterable {
        case pending = "Pending"
        case investigating = "Investigating"
        case resolved = "Resolved"
        case dismissed = "Dismissed"
        
        var color: Color {
            switch self {
            case .pending: return .yellow
            case .investigating: return .blue
            case .resolved: return .green
            case .dismissed: return .gray
            }
        }
    }
}
