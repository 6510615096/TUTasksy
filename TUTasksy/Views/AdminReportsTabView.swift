import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AdminReportsTabView: View {
    @State private var reports: [Report] = []
    @State private var showingActionSheet = false
    @State private var selectedReport: Report?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var filterStatus: Report.ReportStatus?
    @State private var showUserProfile = false
    @State private var userProfileId: String?

    var body: some View {
        NavigationView {
            VStack {
                // Filter options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        filterButton(status: nil, label: "All")
                        ForEach(Report.ReportStatus.allCases, id: \.self) { status in
                            filterButton(status: status, label: status.rawValue)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else if reports.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .padding()
                        Text("No reports found")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredReports) { report in
                            ReportRowView(report: report)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedReport = report
                                    showingActionSheet = true
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await refreshReports()
                    }
                }
            }
           // .navigationTitle("User Reports")
            .actionSheet(isPresented: $showingActionSheet) {
                actionSheetForReport()
            }
            .alert("Report Action", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showUserProfile) {
                if let userId = userProfileId {
                    NavigationView {
                        UserProfileView(userId: userId)
                    }
                }
            }
        }
        .onAppear {
            fetchReports()
        }
    }
    
    private func filterButton(status: Report.ReportStatus?, label: String) -> some View {
        Button(action: {
            filterStatus = status
        }) {
            Text(label)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(status == filterStatus ? (status?.color ?? Color.purple) : Color.gray.opacity(0.2))
                )
                .foregroundColor(status == filterStatus ? .white : .primary)
        }
    }
    
    private var filteredReports: [Report] {
        guard let status = filterStatus else {
            return reports
        }
        return reports.filter { $0.status == status }
    }
    
    private func actionSheetForReport() -> ActionSheet {
        guard let report = selectedReport else {
            return ActionSheet(title: Text("Error"), message: Text("No report selected"), buttons: [.cancel()])
        }
        
        var buttons: [ActionSheet.Button] = []
        
        buttons.append(.default(Text("View User Profile")) {
            userProfileId = report.reportedUserId
            showUserProfile = true
        })
        
        if report.status != .investigating {
            buttons.append(.default(Text("Mark as Investigating")) {
                updateReportStatus(report: report, newStatus: .investigating)
            })
        }
        
        if report.status != .resolved {
            buttons.append(.default(Text("Mark as Resolved")) {
                updateReportStatus(report: report, newStatus: .resolved)
            })
        }
        
        if report.status != .dismissed {
            buttons.append(.default(Text("Dismiss Report")) {
                updateReportStatus(report: report, newStatus: .dismissed)
            })
        }
        
        buttons.append(.destructive(Text("Ban User")) {
            banUser(userId: report.reportedUserId)
        })
        
        buttons.append(.destructive(Text("Delete Report")) {
            deleteReport(report: report)
        })
        
        buttons.append(.cancel())
        
        return ActionSheet(
            title: Text("Report Actions"),
            message: Text("User ID: \(report.reportedUserId)"),
            buttons: buttons
        )
    }
    
    private func updateReportStatus(report: Report, newStatus: Report.ReportStatus) {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("reports").document(report.id)
            .updateData([
                "status": newStatus.rawValue,
                "lastUpdated": Timestamp()
            ]) { error in
                isLoading = false
                if let error = error {
                    alertMessage = "Failed to update report: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    alertMessage = "Report status updated to \(newStatus.rawValue)"
                    showAlert = true
                    fetchReports()
                }
            }
    }
    
    private func banUser(userId: String) {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users").document(userId)
            .updateData([
                "isBanned": true,
                "bannedAt": Timestamp(),
                "bannedBy": Auth.auth().currentUser?.uid ?? "unknown_admin"
            ]) { error in
                isLoading = false
                if let error = error {
                    alertMessage = "Failed to ban user: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    alertMessage = "User has been banned"
                    showAlert = true
 
                    updateAllReportsForUser(userId: userId, newStatus: .resolved)
                }
            }
    }
    
    private func updateAllReportsForUser(userId: String, newStatus: Report.ReportStatus) {
        let db = Firestore.firestore()
        db.collection("reports")
            .whereField("reportedUserId", isEqualTo: userId)
            .whereField("status", isNotEqualTo: newStatus.rawValue)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting reports for user: \(error.localizedDescription)")
                    return
                }
                
                let batch = db.batch()
                snapshot?.documents.forEach { doc in
                    let reportRef = db.collection("reports").document(doc.documentID)
                    batch.updateData([
                        "status": newStatus.rawValue,
                        "lastUpdated": Timestamp(),
                        "resolution": "User banned"
                    ], forDocument: reportRef)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error updating reports: \(error.localizedDescription)")
                    } else {
                        fetchReports() // Refresh the list
                    }
                }
            }
    }
    
    private func deleteReport(report: Report) {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("reports").document(report.id).delete { error in
            isLoading = false
            if let error = error {
                alertMessage = "Failed to delete report: \(error.localizedDescription)"
                showAlert = true
            } else {
                alertMessage = "Report deleted successfully"
                showAlert = true
                fetchReports() 
            }
        }
    }
    
    @MainActor
    private func refreshReports() async {
        fetchReports()
    }
    
    private func fetchReports() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("reports")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
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
                    let statusString = (data["status"] as? String) ?? "Pending"
                    let status = Report.ReportStatus(rawValue: statusString) ?? .pending

                    return Report(
                        id: doc.documentID,
                        reportedUserId: reportedUserId,
                        reporterUserId: reporterUserId,
                        reason: reason,
                        timestamp: timestamp,
                        status: status
                    )
                } ?? []
            }
    }
}

struct ReportRowView: View {
    let report: Report
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reported User: \(report.reportedUserId)")
                    .font(.headline)
                Spacer()
                StatusBadge(status: report.status)
            }
            
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
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: Report.ReportStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontDesign(.rounded)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(status.color.opacity(0.2))
            )
            .foregroundColor(status.color)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(status.color, lineWidth: 1)
            )
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
