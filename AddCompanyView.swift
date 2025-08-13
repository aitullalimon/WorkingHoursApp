import SwiftUI

/// A form for creating a new company.
///
/// The user enters a company name and hourly rate.  The `Save` button
/// becomes enabled only when both fields are valid.  On save, the
/// new company is added to the data store and the sheet dismisses.
struct AddCompanyView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var paymentType: PaymentType = .hourly
    @State private var hourlyRateString: String = ""
    @State private var pointRateString: String = ""
    /// Billing cycle start day (1 or 16).  Defaults to 1.
    @State private var monthStartDay: Int = 1

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Company Details")) {
                    TextField("Company name", text: $name)
                        .autocapitalization(.words)
                    // Payment type selector
                    Picker("Payment Type", selection: $paymentType) {
                        ForEach(PaymentType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    // Rate input depends on type
                    if paymentType == .hourly {
                        TextField("Hourly rate", text: $hourlyRateString)
                            .keyboardType(.decimalPad)
                    } else {
                        TextField("Rate per unit", text: $pointRateString)
                            .keyboardType(.decimalPad)
                    }
                }
                // Billing cycle start selection
                Section(header: Text("Billing Cycle Start")) {
                    Picker("Start day", selection: $monthStartDay) {
                        Text("1st").tag(1)
                        Text("16th").tag(16)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Text("Invoices run from the selected day of one month to the day before the same day of the next month.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Company")
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                // Save button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCompany()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    /// Determine whether the form fields are valid.
    private var canSave: Bool {
        guard !name.isEmpty else { return false }
        switch paymentType {
        case .hourly:
            guard let rate = Double(hourlyRateString), rate > 0 else { return false }
            return true
        case .point:
            guard let rate = Double(pointRateString), rate > 0 else { return false }
            return true
        }
    }

    /// Add the company to the data store and dismiss the view.
    private func saveCompany() {
        switch paymentType {
        case .hourly:
            let rate = Double(hourlyRateString) ?? 0
            dataStore.addCompany(name: name, paymentType: .hourly, hourlyRate: rate, monthStartDay: monthStartDay)
        case .point:
            let rate = Double(pointRateString) ?? 0
            dataStore.addCompany(name: name, paymentType: .point, pointRate: rate, monthStartDay: monthStartDay)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddCompanyView_Previews: PreviewProvider {
    static var previews: some View {
        AddCompanyView()
            .environmentObject(DataStore())
    }
}