import SwiftUI

/// A form for editing an existing time entry.
///
/// It pre‑populates fields with the entry's current values and allows modifications.
/// When saved, the updated entry replaces the old one in the data store.
struct EditTimeEntryView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode

    let entry: TimeEntry
    let company: Company

    // Date of entry (calendar day)
    @State private var date: Date
    // Start and end times
    @State private var startTime: Date
    @State private var endTime: Date
    // Optional transport bill
    @State private var transportBillString: String
    // Piecework: units and rate
    @State private var unitCountString: String
    @State private var unitRateString: String
    // Break hours and minutes for hourly companies
    @State private var breakHours: Int
    @State private var breakMinutes: Int

    init(entry: TimeEntry, company: Company) {
        self.entry = entry
        self.company = company
        // Initialize state values from the existing entry
        _date = State(initialValue: entry.date)
        _startTime = State(initialValue: entry.startTime ?? Date())
        _endTime = State(initialValue: entry.endTime ?? Date())
        if let bill = entry.transportBill {
            _transportBillString = State(initialValue: String(format: "%g", bill))
        } else {
            _transportBillString = State(initialValue: "")
        }
        if let units = entry.unitCount {
            _unitCountString = State(initialValue: String(format: "%g", units))
        } else {
            _unitCountString = State(initialValue: "")
        }
        if let rate = entry.unitRate {
            _unitRateString = State(initialValue: String(format: "%g", rate))
        } else if let defaultRate = company.pointRate {
            _unitRateString = State(initialValue: String(format: "%g", defaultRate))
        } else {
            _unitRateString = State(initialValue: "")
        }
        // Break duration into hours and minutes
        let brk = entry.breakDuration ?? 0
        let totalMinutes = Int(round(brk * 60))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        _breakHours = State(initialValue: h)
        _breakMinutes = State(initialValue: m)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date")) {
                    DatePicker("Entry Date", selection: $date, displayedComponents: [.date])
                }
                if company.paymentType == .hourly {
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
                } else {
                    // Point rate: units, rate, transport
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
                // Optional: Delete button
                Section {
                    Button(role: .destructive) {
                        deleteEntry()
                    } label: {
                        Text("Delete Entry")
                    }
                }
            }
            .navigationTitle("Edit Time Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    /// Calculate the raw hours from start and end times.
    private var calculatedHours: Double {
        return max(endTime.timeIntervalSince(startTime) / 3600.0, 0)
    }

    /// Break duration in hours.
    private var breakDuration: Double {
        return Double(breakHours) + Double(breakMinutes) / 60.0
    }

    /// Billable hours after subtracting break.
    private var billableHours: Double {
        return max(calculatedHours - breakDuration, 0)
    }

    /// Validate the edited entry.
    private var canSave: Bool {
        let transport = Double(transportBillString) ?? 0
        switch company.paymentType {
        case .hourly:
            return billableHours > 0 || transport > 0
        case .point:
            guard let units = Double(unitCountString), units > 0 else { return false }
            let rate = Double(unitRateString) ?? (company.pointRate ?? 0)
            return rate > 0
        }
    }

    /// Save the updated entry back to the data store.
    private func saveChanges() {
        let transportBill = Double(transportBillString)
        let units = Double(unitCountString)
        let rateInput = Double(unitRateString)
        let updated: TimeEntry
        switch company.paymentType {
        case .hourly:
            updated = TimeEntry(
                id: entry.id,
                companyID: entry.companyID,
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
            let finalRate: Double?
            if let r = rateInput, r > 0 {
                finalRate = r
            } else {
                finalRate = company.pointRate
            }
            updated = TimeEntry(
                id: entry.id,
                companyID: entry.companyID,
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
        dataStore.updateTimeEntry(updated)
        presentationMode.wrappedValue.dismiss()
    }

    /// Delete the current entry from the data store.
    private func deleteEntry() {
        if let index = dataStore.timeEntries.firstIndex(where: { $0.id == entry.id }) {
            // Use the DataStore's delete method to remove the entry and persist the change
            dataStore.deleteTimeEntry(at: IndexSet(integer: index))
        }
        presentationMode.wrappedValue.dismiss()
    }
}