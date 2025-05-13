//
//  AdminReportsTabView.swift
//  TUTasksy
//
//  Created by นางสาวณัฐภูพิชา อรุณกรพสุรักษ์ on 13/5/2568 BE.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AdminReportsTabView: View {
    @State private var reports: [Report] = []
    
    var body: some View {
        NavigationView {
            List(reports) { report in
                VStack(alignment: .leading) {
                    Text("Reported User ID: \(report.reportedUserId)")
                        .font(.headline)
                    
                    if let reporterUserId = report.reporterUserId {
                        Text("Reported By: \(reporterUserId)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    if let reason = report.reason {
                        Text("Reason: \(reason)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    if let timestamp = report.timestamp {
                        Text("Reported At: \(timestamp, formatter: DateFormatter.shortDateFormatter)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            fetchReports()
        }
    }
    
    private func fetchReports() {
        let db = Firestore.firestore()
        db.collection("reports")
            .order(by: "timestamp", descending: true) // เรียงลำดับตามเวลา
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching reports: \(error.localizedDescription)")
                    return
                }
                
                self.reports = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let reportedUserId = data["reportedUserId"] as? String else {
                        return nil
                    }
                    
                    let reporterUserId = data["reportedBy"] as? String
                    let reason = data["reason"] as? String
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()

                    return Report(
                        id: doc.documentID,
                        reportedUserId: reportedUserId,
                        reporterUserId: reporterUserId,
                        reason: reason,
                        timestamp: timestamp
                    )
                } ?? []
            }
    }
}

extension DateFormatter {
    static var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
