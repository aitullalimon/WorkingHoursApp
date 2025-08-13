import SwiftUI

/// Displays all time entries across all companies.
///
/// Each row shows the company name, date, number of hours, and the amount
/// earned.  Users can delete entries using swipe gestures or Edit mode.
struct TimeEntryListView: View {
    @EnvironmentObject var dataStore: DataStore

    @State private var selectedEntry: TimeEntry?

    var body: some View {
        NavigationView {
            List {
                let sortedEntries = dataStore.timeEntries.sorted { $0.date > $1.date }
                if sortedEntries.isEmpty {
                    Text("No time entries")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sortedEntries) { entry in
                        VStack(alignment: .leading) {
                            Text(companyName(for: entry))
                                .font(.headline)
                            Text(dateFormatter.string(from: entry.date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Determine company and rate
                            let company = dataStore.companies.first { $0.id == entry.companyID }

                            if let company = company {
                                switch company.paymentType {
                                case .hourly:
                                    let hours = entry.billableHours
                                    HStack {
                                        Text("Hours: \(formattedHours(hours))")
                                        Spacer()
                                        let rate = company.hourlyRate ?? 0
                                        Text("Hourly: \(formattedRate(hours * rate))")
                                    }
                                    .font(.subheadline)
                                    // Show break duration if present
                                    if let brk = entry.breakDuration, brk > 0 {
                                        HStack {
                                            Text("Break")
                                            Spacer()
                                            Text(formattedBreak(brk))
                                        }
                                        .font(.subheadline)
                                    }

                                    // Piecework for hourly companies (legacy data)
                                    if let units = entry.unitCount, units > 0, let unitRate = entry.unitRate {
                                        HStack {
                                            Text("Pieces: \(formattedUnits(units))")
                                            Spacer()
                                            Text(formattedRate(units * unitRate))
                                        }
                                        .font(.subheadline)
                                    }

                                    if let bill = entry.transportBill, bill > 0 {
                                        HStack {
                                            Text("Transport")
                                            Spacer()
                                            Text(formattedRate(bill))
                                        }
                                        .font(.subheadline)
                                    }

                                    let piecePay = (entry.unitCount ?? 0) * (entry.unitRate ?? 0)
                                    let totalEarned = hours * (company.hourlyRate ?? 0) + piecePay + (entry.transportBill ?? 0)
                                    HStack {
                                        Text("Total")
                                        Spacer()
                                        Text(formattedRate(totalEarned))
                                    }
                                    .font(.subheadline)
                                    .bold()
                                case .point:
                                    // Units and rate for point companies
                                    let units = entry.unitCount ?? 0
                                    let rate = entry.unitRate ?? company.pointRate ?? 0
                                    HStack {
                                        Text("Units: \(formattedUnits(units))")
                                        Spacer()
                                        Text("Rate: \(formattedRate(rate))")
                                    }
                                    .font(.subheadline)
                                    if let bill = entry.transportBill, bill > 0 {
                                        HStack {
                                            Text("Transport")
                                            Spacer()
                                            Text(formattedRate(bill))
                                        }
                                        .font(.subheadline)
                                    }
                                    let totalEarned = units * rate + (entry.transportBill ?? 0)
                                    HStack {
                                        Text("Total")
                                        Spacer()
                                        Text(formattedRate(totalEarned))
                                    }
                                    .font(.subheadline)
                                    .bold()
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEntry = entry
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Time Entries")
            .toolbar {
                // Edit button for enabling deletion
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            // Sheet for editing an entry from the global list
            .sheet(item: $selectedEntry) { entry in
                if let comp = dataStore.companies.first(where: { $0.id == entry.companyID }) {
                    EditTimeEntryView(entry: entry, company: comp)
                        .environmentObject(dataStore)
                }
            }
        }
    }

    /// Lookup the company name for a given entry.
    private func companyName(for entry: TimeEntry) -> String {
        dataStore.companies.first { $0.id == entry.companyID }?.name ?? "Unknown"
    }

    /// Delete time entries at the given offsets.
    private func delete(at offsets: IndexSet) {
        dataStore.deleteTimeEntry(at: offsets)
    }

    /// Formatter for displaying dates.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    /// Format a double as currency.
    private func formattedRate(_ rate: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: rate)) ?? "\(rate)"
    }

    /// Format hours worked with two decimal places.
    private func formattedHours(_ hours: Double) -> String {
        return String(format: "%.2f", hours)
    }

    /// Format units with up to two decimal places.
    private func formattedUnits(_ units: Double) -> String {
        return String(format: "%.2f", units)
    }

    /// Format a break duration (in hours) to a human‑readable string, e.g. "1h 15m".
    private func formattedBreak(_ brk: Double) -> String {
        let totalMinutes = Int(round(brk * 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

struct TimeEntryListView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DataStore()
        let company1 = Company(name: "ABC Inc.", paymentType: .hourly, hourlyRate: 40)
        let company2 = Company(name: "XYZ Ltd.", paymentType: .hourly, hourlyRate: 60)
        store.companies.append(contentsOf: [company1, company2])
        store.timeEntries.append(TimeEntry(companyID: company1.id, date: Date(), startTime: Date(), endTime: Date().addingTimeInterval(5 * 3600)))
        store.timeEntries.append(TimeEntry(companyID: company2.id, date: Date(), startTime: Date(), endTime: Date().addingTimeInterval(3 * 3600)))
        return TimeEntryListView()
            .environmentObject(store)
    }
}