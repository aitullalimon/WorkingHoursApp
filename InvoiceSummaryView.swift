import SwiftUI

/// A view that displays the invoice summary for a single company and billing period.
///
/// This view encapsulates all calculations needed to present total hours/units, pay and
/// transport, and provides buttons to mark the invoice as due or withdrawn.  It is
/// designed to avoid local variable declarations inside view builders, which can
/// cause compile errors.
struct InvoiceSummaryView: View {
    @EnvironmentObject var dataStore: DataStore
    /// The company for which to display the summary.
    let company: Company
    /// The billing period for which this summary applies.
    let period: (start: Date, end: Date)



    /// Filtered entries for this company and period.
    private var entries: [TimeEntry] {
        dataStore.timeEntries(for: company.id).filter { entry in
            entry.date >= period.start && entry.date <= period.end
        }
    }

    /// Total billable hours for this period.
    private var totalHours: Double {
        entries.reduce(0.0) { $0 + $1.billableHours }
    }

    /// Total units and piecework pay for this period.
    private var piecePay: Double {
        entries.reduce(0.0) { partial, entry in
            let rate = entry.unitRate ?? company.pointRate ?? 0
            return partial + (entry.unitCount ?? 0) * rate
        }
    }

    /// Total transport bill for this period.
    private var transportTotal: Double {
        entries.reduce(0.0) { $0 + ($1.transportBill ?? 0) }
    }

    /// Total hourly pay (hours × rate).
    private var hourlyPay: Double {
        totalHours * (company.hourlyRate ?? 0)
    }

    /// Total earned (hourly pay + piecework + transport).
    private var totalEarned: Double {
        hourlyPay + piecePay + transportTotal
    }

    /// DateFormatter for display.
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Billing period
            HStack {
                Text("Period")
                Spacer()
                Text("\(dateFormatter.string(from: period.start)) – \(dateFormatter.string(from: period.end))")
                    .foregroundColor(.secondary)
            }
            // Hours or units
            if company.paymentType == .hourly {
                HStack {
                    Text("Total Hours")
                    Spacer()
                    Text(formattedHours(totalHours))
                }
                HStack {
                    Text("Hourly Pay")
                    Spacer()
                    Text(formattedRate(hourlyPay))
                }
            } else {
                let totalUnits = entries.reduce(0.0) { $0 + ($1.unitCount ?? 0) }
                HStack {
                    Text("Total Units")
                    Spacer()
                    Text(formattedUnits(totalUnits))
                }
                HStack {
                    Text("Units Pay")
                    Spacer()
                    Text(formattedRate(piecePay))
                }
            }
            if transportTotal > 0 {
                HStack {
                    Text("Transport")
                    Spacer()
                    Text(formattedRate(transportTotal))
                }
            }
            HStack {
                Text("Total Earned")
                Spacer()
                Text(formattedRate(totalEarned))
                    .bold()
            }
            // Payment buttons if there are entries
            if !entries.isEmpty {
                HStack(spacing: 16) {
                    Button(action: {
                        dataStore.addPaymentRecord(companyID: company.id, periodStart: period.start, periodEnd: period.end, amount: totalEarned, action: .due)
                    }) {
                        Text("Mark Due")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        dataStore.addPaymentRecord(companyID: company.id, periodStart: period.start, periodEnd: period.end, amount: totalEarned, action: .withdrawn)
                    }) {
                        Text("Withdraw")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    // MARK: - Formatters
    private func formattedRate(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
    
    private func formattedHours(_ hours: Double) -> String {
        return String(format: "%.2f", hours)
    }
    
    private func formattedUnits(_ units: Double) -> String {
        return String(format: "%.2f", units)
    }
}

struct InvoiceSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DataStore()
        let company = Company(name: "Test", paymentType: .hourly, hourlyRate: 40)
        store.companies.append(company)
        let now = Date()
        // Add some entries
        store.timeEntries.append(TimeEntry(companyID: company.id, date: now, startTime: now, endTime: now.addingTimeInterval(3600)))
        // Compute a simple period for preview
        let start = now.startOfDay()
        let end = now.endOfDay()
        return InvoiceSummaryView(company: company, period: (start: start, end: end)).environmentObject(store)
    }
}