import Foundation
import FirebaseFirestore
import FirebaseAuth

class ReportManager {
    
    private let db = Firestore.firestore()

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
                    reason: data["reason"] as? String,
                    timestamp: data["timestamp"] as? Date,
                    status: data["status"] as? Report.ReportStatus ?? .pending
                )
                reports.append(report)
            }
            completion(reports, nil)
        }
    }
}
