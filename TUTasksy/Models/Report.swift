//
//  Report.swift
//  TUTasksy
//
//  Created by นางสาวณัฐภูพิชา อรุณกรพสุรักษ์ on 13/5/2568 BE.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct Report: Identifiable {
    var id: String           
    var reportedUserId: String
    var reporterUserId: String?
    var reason: String?
    var timestamp: Date?
}

class ReportManager {
    
    private let db = Firestore.firestore()

    // Function to create a new report
    func reportUser(reportedUserId: String, reason: String, completion: @escaping (Error?) -> Void) {
        guard let reporterId = Auth.auth().currentUser?.uid else {
            print("No user logged in.")
            return
        }
        
        let reportData: [String: Any] = [
            "reportedUserId": reportedUserId,
            "reportedBy": reporterId,
            "reason": reason,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        print("Sending report data: \(reportData)")

        db.collection("reports").addDocument(data: reportData) { error in
            if let error = error {
                print("Failed to submit report: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Report submitted successfully")
                completion(nil)
            }
        }
    }
    
    // Function to fetch reports
    func fetchReports(completion: @escaping ([Report]?, Error?) -> Void) {
        db.collection("reports").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            var reports: [Report] = []
            for document in snapshot?.documents ?? [] {
                let data = document.data()
                let report = Report(
                    id: document.documentID,
                    reportedUserId: data["reportedUserId"] as? String ?? "",
                    reporterUserId: data["reportedBy"] as? String,
                    reason: data["reason"] as? String
                )
                reports.append(report)
            }
            completion(reports, nil)
        }
    }
}
