import SwiftUI

/// Displays details for a single company along with its time entries.
///
/// The view shows the company name, hourly rate, total hours worked,
/// and total earnings.  It also lists individual time entries and
/// allows the user to add new entries or delete existing ones.
struct CompanyDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    /// The company being displayed.
    var company: Company
    @State private var showingAddEntry = false
    /// The entry currently selected for editing.  When set, a sheet is presented allowing
    /// the user to modify the entry.  After editing, the sheet dismisses automatically.
    @State private var selectedEntry: TimeEntry?

    var body: some View {
        List {
            // Company summary
            Section(header: Text("Company Info")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(company.name)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Payment Type")
                    Spacer()
                    Text(company.paymentType.displayName)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text(company.paymentType == .hourly ? "Hourly Rate" : "Rate per Unit")
                    Spacer()
                    Text(rateString(for: company))
                        .foregroundColor(.secondary)
                }
                // Show billing cycle start day
                HStack {
                    Text("Billing Start")
                    Spacer()
                    Text(company.monthStartDay == 16 ? "16th" : "1st")
                        .foregroundColor(.secondary)
                }
                // Show total hours only for hourly companies
                if company.paymentType == .hourly {
                    HStack {
                        Text("Total Hours")
                        Spacer()
                        Text(formattedHours(totalHours))
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Text("Total Earned")
                    Spacer()
                    Text(formattedRate(totalEarned))
                        .foregroundColor(.secondary)
                }
            }

            // List of time entries
            Section(header: Text("Time Entries")) {
                let entries = dataStore.timeEntries(for: company.id).sorted { $0.date > $1.date }
                if entries.isEmpty {
                    Text("No time entries")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(entries) { entry in
                        // The row is tapable to allow editing.  Use a content shape so the entire
                        // VStack responds to touches.
                        VStack(alignment: .leading) {
                            // Show the date
                            Text(dateFormatter.string(from: entry.date))
                                .font(.headline)
                            // Hours and break
                            let hours = entry.billableHours
                            Text("Hours: \(formattedHours(hours))")
                                .font(.subheadline)
                            if let brk = entry.breakDuration, brk > 0 {
                                Text("Break: \(formattedBreak(brk))")
                                    .font(.subheadline)
                            }
                            // Transport
                            if let bill = entry.transportBill, bill > 0 {
                                Text("Transport: \(formattedRate(bill))")
                                    .font(.subheadline)
                            }
                            // Piecework
                            if let units = entry.unitCount, units > 0, let rate = entry.unitRate {
                                Text("Pieces: \(formattedUnits(units)) × \(formattedRate(rate))")
                                    .font(.subheadline)
                            }
                            // Total earned for this entry
                            let piecePay = (entry.unitCount ?? 0) * (entry.unitRate ?? 0)
                            let totalEarned = hours * (company.hourlyRate ?? 0) + piecePay + (entry.transportBill ?? 0)
                            Text("Total: \(formattedRate(totalEarned))")
                                .font(.subheadline)
                                .bold()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // When tapped, set the selected entry to present the edit sheet
                            selectedEntry = entry
                        }
                    }
                    .onDelete(perform: deleteEntry)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(company.name)
        .toolbar {
            // Add button on the trailing side to create a new entry
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddEntry = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Time Entry")
            }
            // Edit button on the leading side to enable deletion of entries via swipe/selection
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddTimeEntryView(company: company)
                .environmentObject(dataStore)
        }
        // Sheet for editing an existing time entry
        .sheet(item: $selectedEntry) { entry in
            EditTimeEntryView(entry: entry, company: company)
                .environmentObject(dataStore)
        }
    }

    /// Calculate the total hours worked for this company.
    private var totalHours: Double {
        // Sum billable hours (after subtracting breaks) for this company's entries
        dataStore.timeEntries(for: company.id).reduce(0) { $0 + $1.billableHours }
    }

    /// Calculate the total amount earned across all entries for this company.
    ///
    /// Includes hourly pay, piecework pay and transport bills.
    private var totalEarned: Double {
        dataStore.timeEntries(for: company.id).reduce(0) { partial, entry in
            let hours = entry.billableHours
            let piecePay = (entry.unitCount ?? 0) * (entry.unitRate ?? 0)
            let transport = entry.transportBill ?? 0
            return partial + hours * (company.hourlyRate ?? 0) + piecePay + transport
        }
    }

    /// Delete selected time entries.
    private func deleteEntry(at offsets: IndexSet) {
        // Determine which entries correspond to the offsets
        let entriesForCompany = dataStore.timeEntries(for: company.id).sorted { $0.date > $1.date }
        let idsToDelete = offsets.map { entriesForCompany[$0].id }
        dataStore.timeEntries.removeAll { idsToDelete.contains($0.id) }
        dataStore.objectWillChange.send()
    }

    /// A date formatter used for displaying entry dates.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    /// Format a currency value.
    private func formattedRate(_ rate: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: rate)) ?? "\(rate)"
    }

    /// Format hours worked to two decimal places.
    private func formattedHours(_ hours: Double) -> String {
        return String(format: "%.2f", hours)
    }

    /// Format the number of units with up to two decimal places.
    private func formattedUnits(_ units: Double) -> String {
        return String(format: "%.2f", units)
    }

    /// Return a human‑readable string for the company's rate based on its payment type.
    private func rateString(for company: Company) -> String {
        switch company.paymentType {
        case .hourly:
            if let rate = company.hourlyRate { return formattedRate(rate) }
            return "—"
        case .point:
            if let rate = company.pointRate { return formattedRate(rate) + "/unit" }
            return "—"
        }
    }

    /// Format a break duration (in hours) as a human‑readable string, e.g. "1h 30m".
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

struct CompanyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DataStore()
        let hourlyCompany = Company(name: "Sample Co.", paymentType: .hourly, hourlyRate: 50)
        store.companies.append(hourlyCompany)
        // Sample hourly entry
        store.timeEntries.append(TimeEntry(companyID: hourlyCompany.id, date: Date(), startTime: Date(), endTime: Date().addingTimeInterval(3600)))
        return NavigationView {
            CompanyDetailView(company: hourlyCompany)
                .environmentObject(store)
        }
    }
}