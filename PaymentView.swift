import SwiftUI

/// Displays a list of payment records (due and withdrawn) for all companies.
///
/// Each record includes the company name, invoice period, amount and action.  The list
/// is sorted by record date, most recent first.  Users cannot create records directly
/// here; records are added via the invoice view.
struct PaymentView: View {
    @EnvironmentObject var dataStore: DataStore
    
    /// Format a date as a medium string.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        NavigationView {
            List {
                if dataStore.paymentRecords.isEmpty {
                    Text("No payment records yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sortedRecords) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            // Company name and action
                            HStack {
                                Text(companyName(for: record.companyID))
                                    .font(.headline)
                                Spacer()
                                Text(record.action.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(record.action == .due ? .orange : .green)
                            }
                            // Period
                            Text("Period: \(dateFormatter.string(from: record.periodStart)) – \(dateFormatter.string(from: record.periodEnd))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            // Amount
                            Text(formattedRate(record.amount))
                                .font(.subheadline)
                                .bold()
                            // Date recorded
                            Text("Recorded: \(dateFormatter.string(from: record.date))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteRecords)
                }
            }
            .navigationTitle("Payments")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
    }
    
    /// Sorted payment records (most recent first).
    private var sortedRecords: [PaymentRecord] {
        dataStore.paymentRecords.sorted { $0.date > $1.date }
    }
    
    /// Return the company name for the given ID, or a placeholder if not found.
    private func companyName(for id: UUID) -> String {
        dataStore.companies.first(where: { $0.id == id })?.name ?? "Unknown Company"
    }
    
    /// Format a currency value.
    private func formattedRate(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
    
    /// Delete payment records at offsets.
    private func deleteRecords(at offsets: IndexSet) {
        dataStore.paymentRecords.remove(atOffsets: offsets)
        dataStore.objectWillChange.send()
        // Save after deletion
        // DataStore.saveData is private; rely on property publisher to trigger save via DataStore.saveData when mutated.
        let _ = offsets
    }
}

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DataStore()
        let company = Company(name: "Test Co", paymentType: .hourly, hourlyRate: 50)
        store.companies.append(company)
        // Add sample record
        let now = Date()
        let record = PaymentRecord(companyID: company.id, periodStart: now, periodEnd: now, amount: 1000, action: .due)
        store.paymentRecords.append(record)
        return PaymentView().environmentObject(store)
    }
}