import SwiftUI
struct MonthlySummaryView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedDate: Date = Date()
    @State private var editingCompany: Company?
    @State private var tempStart: Date = Date()
    @State private var tempEnd: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                // Month selector
                Section(header: Text("Select Month")) {
                    DatePicker("Month", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                }
                
                // Summary per company
                Section(header: Text("Company Totals")) {
                    if dataStore.companies.isEmpty {
                        Text("No companies available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(dataStore.companies) { company in
                            let period = billingPeriod(for: company)
                            let entries = entries(for: company, within: period)
                            let totalEarned = computeTotalEarned(for: company, with: entries)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(company.name)
                                    Text("\(periodString(period))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(formattedRate(totalEarned))
                            }
                        }
                        // Grand total row
                        if !dataStore.companies.isEmpty {
                            let grandTotal = dataStore.companies.reduce(0.0) { acc, company in
                                let period = billingPeriod(for: company)
                                let entries = entries(for: company, within: period)
                                return acc + computeTotalEarned(for: company, with: entries)
                            }
                            HStack {
                                Text("Grand Total")
                                    .bold()
                                Spacer()
                                Text(formattedRate(grandTotal))
                                    .bold()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Monthly Summary")
        }
    }
    
    // MARK: - Helpers
    
    /// Compute the billing period for a company based on the selected date.
    private func billingPeriod(for company: Company) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let day = components.day ?? 1
        let startDay = company.monthStartDay
        if startDay == 16 {
            if day < 16 {
                // Use previous month 16th to current month 15th
                guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) else {
                    return (selectedDate.startOfDay(), selectedDate.endOfDay())
                }
                let prevComp = calendar.dateComponents([.year, .month], from: previousMonthDate)
                let start = calendar.date(from: DateComponents(year: prevComp.year, month: prevComp.month, day: 16)) ?? previousMonthDate
                let end = calendar.date(from: DateComponents(year: components.year, month: components.month, day: 15)) ?? selectedDate
                return (start.startOfDay(), end.endOfDay())
            } else {
                // Use current month 16th to next month 15th
                let start = calendar.date(from: DateComponents(year: components.year, month: components.month, day: 16)) ?? selectedDate
                guard let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: start) else {
                    let end = calendar.date(from: DateComponents(year: components.year, month: components.month, day: 15)) ?? selectedDate
                    return (start.startOfDay(), end.endOfDay())
                }
                let nextComp = calendar.dateComponents([.year, .month], from: nextMonthDate)
                let end = calendar.date(from: DateComponents(year: nextComp.year, month: nextComp.month, day: 15)) ?? nextMonthDate
                return (start.startOfDay(), end.endOfDay())
            }
        } else {
            // Standard month: 1st to last day
            components.day = 1
            let start = calendar.date(from: components) ?? selectedDate
            var comps = DateComponents()
            comps.month = 1
            comps.day = -1
            let end = calendar.date(byAdding: comps, to: start) ?? selectedDate
            return (start.startOfDay(), end.endOfDay())
        }
    }

    /// Retrieve entries for the given company within the specified period.
    private func entries(for company: Company, within period: (start: Date, end: Date)) -> [TimeEntry] {
        dataStore.timeEntries(for: company.id).filter { entry in
            entry.date >= period.start && entry.date <= period.end
        }
    }

    /// Compute the total earned for a company based on its entries in a period.
    private func computeTotalEarned(for company: Company, with entries: [TimeEntry]) -> Double {
        let hours = entries.reduce(0.0) { $0 + $1.billableHours }
        // piecework pay uses entry.unitRate when present or company.pointRate for point companies
        let piecePay = entries.reduce(0.0) { partial, entry in
            let rate = entry.unitRate ?? company.pointRate ?? 0
            return partial + (entry.unitCount ?? 0) * rate
        }
        let transport = entries.reduce(0.0) { $0 + ($1.transportBill ?? 0) }
        let hourlyPay = hours * (company.hourlyRate ?? 0)
        return hourlyPay + piecePay + transport
    }

    /// Format a period as a string "MMM d – MMM d".
    private func periodString(_ period: (start: Date, end: Date)) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: period.start)) – \(formatter.string(from: period.end))"
    }
    
    /// Format a currency value.
    private func formattedRate(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

struct MonthlySummaryView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DataStore()
        // Add example companies and entries
        let companyA = Company(name: "A", paymentType: .hourly, hourlyRate: 30, monthStartDay: 1)
        let companyB = Company(name: "B", paymentType: .hourly, hourlyRate: 20, monthStartDay: 16)
        store.companies.append(contentsOf: [companyA, companyB])
        let cal = Calendar.current
        // Example entries for company A within January 1-31
        if let jan1 = cal.date(from: DateComponents(year: 2023, month: 1, day: 10)) {
            store.timeEntries.append(TimeEntry(companyID: companyA.id, date: jan1, startTime: jan1, endTime: jan1.addingTimeInterval(3600)))
        }
        // Example entries for company B in cycle Jan16-Feb15
        if let jan18 = cal.date(from: DateComponents(year: 2023, month: 1, day: 20)) {
            store.timeEntries.append(TimeEntry(companyID: companyB.id, date: jan18, startTime: jan18, endTime: jan18.addingTimeInterval(7200)))
        }
        return MonthlySummaryView().environmentObject(store)
    }
}
