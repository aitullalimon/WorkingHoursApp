import SwiftUI

/// Provides a simple interface for viewing monthly invoices by company.
///
/// The user selects a company and a month.  The view then filters
/// time entries for that company within the chosen month and displays
/// the total hours and total amount earned.  This view can be
/// extended to generate shareable PDFs or exports.
struct InvoiceView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedCompanyID: UUID?
    @State private var selectedDate: Date = Date()
    /// The type of invoice range: cycle uses the company's billing cycle; custom uses a manual date range.
    private enum RangeType: String, CaseIterable, Identifiable {
        case cycle
        case custom
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .cycle: return "Billing Cycle"
            case .custom: return "Custom Range"
            }
        }
    }
    @State private var rangeType: RangeType = .cycle
    // Custom range dates
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                // Company picker
                Section(header: Text("Select Company")) {
                    if dataStore.companies.isEmpty {
                        Text("No companies available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Company", selection: Binding(
                            get: { selectedCompanyID ?? dataStore.companies.first?.id },
                            set: { selectedCompanyID = $0 }
                        )) {
                            ForEach(dataStore.companies) { company in
                                Text(company.name).tag(company.id as UUID?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                // Month picker
                if rangeType == .cycle {
                    Section(header: Text("Select Month")) {
                        DatePicker("Month", selection: $selectedDate, displayedComponents: [.date])
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                    }
                }
                // Range type picker
                Section(header: Text("Invoice Range")) {
                    Picker("Range Type", selection: $rangeType) {
                        ForEach(RangeType.allCases) { rt in
                            Text(rt.displayName).tag(rt)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                // Custom range pickers
                if rangeType == .custom {
                    Section(header: Text("Custom Date Range")) {
                        DatePicker("Start Date", selection: $customStartDate, displayedComponents: [.date])
                        DatePicker("End Date", selection: $customEndDate, displayedComponents: [.date])
                    }
                }

                // Invoice summary
                if let company = selectedCompany {
                    Section(header: Text("Invoice Summary")) {
                        InvoiceSummaryView(
                            company: company,
                            period: rangeType == .cycle ? billingPeriod(for: company) : (start: min(customStartDate, customEndDate).startOfDay(), end: max(customStartDate, customEndDate).endOfDay())
                        )
                        .environmentObject(dataStore)
                    }
                }
            }
            .navigationTitle("Invoice")
        }
    }

    /// Resolve the selected company based on the current selection or default.
    private var selectedCompany: Company? {
        if let id = selectedCompanyID {
            return dataStore.companies.first { $0.id == id }
        }
        return dataStore.companies.first
    }

    /// Compute the billing period (start and end dates) for the given company based on the selected date.
    private func billingPeriod(for company: Company) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let day = components.day ?? 1
        let monthStart = company.monthStartDay
        // Determine the start and end of the period
        if monthStart == 16 {
            if day < 16 {
                // Start is the 16th of the previous month
                // End is the 15th of the current month
                // Compute previous month date
                guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) else {
                    // Fallback to start of current month
                    let start = calendar.date(from: DateComponents(year: components.year, month: components.month, day: 16)) ?? selectedDate
                    let end = calendar.date(from: DateComponents(year: components.year, month: components.month! + 1, day: 15)) ?? selectedDate
                    return (start, end)
                }
                let prevComponents = calendar.dateComponents([.year, .month], from: previousMonthDate)
                let start = calendar.date(from: DateComponents(year: prevComponents.year, month: prevComponents.month, day: 16)) ?? previousMonthDate
                let end = calendar.date(from: DateComponents(year: components.year, month: components.month, day: 15)) ?? selectedDate
                return (start.startOfDay(), end.endOfDay())
            } else {
                // Start is the 16th of the current month
                // End is the 15th of the next month
                let start = calendar.date(from: DateComponents(year: components.year, month: components.month, day: 16)) ?? selectedDate
                // Compute next month date
                guard let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: start) else {
                    let end = calendar.date(from: DateComponents(year: components.year, month: components.month, day: 15)) ?? selectedDate
                    return (start.startOfDay(), end.endOfDay())
                }
                let nextComponents = calendar.dateComponents([.year, .month], from: nextMonthDate)
                let end = calendar.date(from: DateComponents(year: nextComponents.year, month: nextComponents.month, day: 15)) ?? nextMonthDate
                return (start.startOfDay(), end.endOfDay())
            }
        } else {
            // Standard month start (1st to last day)
            // Start is the first day of the selected month
            components.day = 1
            let start = calendar.date(from: components) ?? selectedDate
            // End is the last day of the selected month
            var comps = DateComponents()
            comps.month = 1
            comps.day = -1
            let end = calendar.date(byAdding: comps, to: start) ?? selectedDate
            return (start.startOfDay(), end.endOfDay())
        }
    }

    /// Filter time entries for a company within a specific billing period.
    private func invoiceEntries(for company: Company, within period: (start: Date, end: Date)) -> [TimeEntry] {
        dataStore.timeEntries(for: company.id).filter { entry in
            entry.date >= period.start && entry.date <= period.end
        }
    }

    /// Sum the hours of the given entries.
    private func totalHours(_ entries: [TimeEntry]) -> Double {
        entries.reduce(0) { $0 + $1.billableHours }
    }

    /// Format units (piece counts) to up to two decimal places.
    private func formattedUnits(_ units: Double) -> String {
        return String(format: "%.2f", units)
    }

    /// Format currency amounts.
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
}

// MARK: - Date Utilities

extension Date {
    /// Returns a date representing the start of the day (00:00) in the current calendar.
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    /// Returns a date representing the end of the day (23:59:59) in the current calendar.
    func endOfDay() -> Date {
        let start = Calendar.current.startOfDay(for: self)
        return Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? self
    }
}

struct InvoiceView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DataStore()
        let company = Company(name: "Test", paymentType: .hourly, hourlyRate: 30)
        store.companies.append(company)
        store.timeEntries.append(TimeEntry(companyID: company.id, date: Date(), startTime: Date(), endTime: Date().addingTimeInterval(3600)))
        return InvoiceView()
            .environmentObject(store)
    }
}