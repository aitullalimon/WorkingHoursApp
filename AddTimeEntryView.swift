import SwiftUI

/// A form for recording hours worked for a particular company on a given date.
///
/// The user selects a date and enters the number of hours worked.  Upon
/// saving, the entry is added to the data store and the sheet is dismissed.
struct AddTimeEntryView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    /// The company for which the new time entry is being created.
    var company: Company

    // Date of entry (calendar day)
    @State private var date: Date = Date()
    // Start and end times
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600) // default one hour later
    // Optional transport bill
    @State private var transportBillString: String = ""
    // Piecework: units and rate. These fields are only relevant for point‑based companies.
    @State private var unitCountString: String = ""
    @State private var unitRateString: String = "570"

    // Break duration components for hourly companies.  Users can specify hours and minutes of break
    // which will be subtracted from the total worked hours.
    @State private var breakHours: Int = 0
    @State private var breakMinutes: Int = 0

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date")) {
                    DatePicker("Entry Date", selection: $date, displayedComponents: [.date])
                }
                if company.paymentType == .hourly {
                    // For hourly companies, allow the user to record start/end times and an optional transport bill.
                    Section(header: Text("Time")) {
                        DatePicker("Start", selection: $startTime, displayedComponents: [.hourAndMinute])
                        DatePicker("End", selection: $endTime, displayedComponents: [.hourAndMinute])
                        HStack {
                            Text("Billable Hours")
                            Spacer()
                            Text(String(format: "%.2f", billableHours))
                                .foregroundColor(.secondary)
                        }
                    }
                    // Break selection: users choose hours and minutes of break time
                    Section(header: Text("Break")) {
                        Picker("Hours", selection: $breakHours) {
                            ForEach(0..<6) { i in
                                Text("\(i) h").tag(i)
                            }
                        }
                        Picker("Minutes", selection: $breakMinutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                    }
                    Section(header: Text("Transport Bill (Optional)")) {
                        TextField("Amount", text: $transportBillString)
                            .keyboardType(.decimalPad)
                    }
                    // Note: piecework fields are omitted for hourly companies.
                } else {
                    // Point rate: no time fields, only units and transport
                    Section(header: Text("Units")) {
                        TextField("Number of units", text: $unitCountString)
                            .keyboardType(.decimalPad)
                    }
                    Section(header: Text("Rate per Unit")) {
                        TextField("Rate per unit", text: $unitRateString)
                            .keyboardType(.decimalPad)
                    }
                    Section(header: Text("Transport Bill (Optional)")) {
                        TextField("Amount", text: $transportBillString)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Add Time Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                // Pre‑populate unit rate for point companies if not already set
                if company.paymentType == .point {
                    if unitRateString.isEmpty {
                        if let defaultRate = company.pointRate {
                            unitRateString = String(format: "%g", defaultRate)
                        }
                    }
                }
            }
        }
    }

    /// Compute hours from start and end times.  Ensures non‑negative values.
    private var calculatedHours: Double {
        return max(endTime.timeIntervalSince(startTime) / 3600.0, 0)
    }

    /// Compute the total break duration in hours based on the selected hours and minutes.
    private var breakDuration: Double {
        return Double(breakHours) + Double(breakMinutes) / 60.0
    }

    /// Compute the billable hours by subtracting the break duration from the calculated hours.
    private var billableHours: Double {
        return max(calculatedHours - breakDuration, 0)
    }

    /// Validate the form depending on the company's payment type.
    private var canSave: Bool {
        let transport = Double(transportBillString) ?? 0
        switch company.paymentType {
        case .hourly:
            // For hourly companies, ensure there is at least some billable time (after subtracting break)
            // or a positive transport bill.
            let hoursValid = billableHours > 0
            return hoursValid || transport > 0
        case .point:
            // For point companies, require at least units > 0 and rate > 0
            guard let units = Double(unitCountString), units > 0 else { return false }
            let rate = Double(unitRateString) ?? (company.pointRate ?? 0)
            return rate > 0
        }
    }

    /// Persist the new time entry and dismiss.
    private func saveEntry() {
        let transportBill = Double(transportBillString)
        let units = Double(unitCountString)
        let rateInput = Double(unitRateString)
        switch company.paymentType {
        case .hourly:
            // For hourly companies, record start/end times, break duration, and transport bill.
            dataStore.addTimeEntry(
                companyID: company.id,
                date: date,
                startTime: startTime,
                endTime: endTime,
                hoursWorked: nil,
                transportBill: transportBill,
                unitCount: nil,
                unitRate: nil,
                breakDuration: breakDuration
            )
        case .point:
            // For point companies, ignore start/end times and hours; use units and rate
            // If user leaves the rate empty, fall back to company's point rate.
            let finalRate: Double?
            if let r = rateInput, r > 0 {
                finalRate = r
            } else {
                finalRate = company.pointRate
            }
            dataStore.addTimeEntry(
                companyID: company.id,
                date: date,
                startTime: nil,
                endTime: nil,
                hoursWorked: nil,
                transportBill: transportBill,
                unitCount: units,
                unitRate: finalRate,
                breakDuration: nil
            )
        }
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddTimeEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let store = DataStore()
        let company = Company(name: "Sample Co.", paymentType: .hourly, hourlyRate: 50)
        store.companies.append(company)
        return AddTimeEntryView(company: company)
            .environmentObject(store)
    }
}