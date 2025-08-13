import SwiftUI

/// View listing all companies and providing navigation to add or edit them.
///
/// Displays each company with its name and hourly rate.  Tapping a
/// company navigates to a detailed view showing time entries and
/// aggregated totals.  Users can delete companies with a swipe gesture
/// and use the ``+`` button to add new ones.
struct CompanyListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingAddCompany = false

    var body: some View {
        NavigationView {
            List {
                ForEach(dataStore.companies) { company in
                    NavigationLink(destination: CompanyDetailView(company: company)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(company.name)
                                Text(company.paymentType.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(rateString(for: company))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Companies")
            .toolbar {
                // Add new company
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCompany = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Company")
                }
                // Edit mode for deleting companies
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddCompany) {
                AddCompanyView()
            }
        }
    }

    /// Delete companies at the given index set.
    private func delete(at offsets: IndexSet) {
        dataStore.deleteCompany(at: offsets)
    }

    /// Format a double into a currency string using the current locale.
    private func formattedRate(_ rate: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: rate)) ?? "\(rate)"
    }

    /// Return a display string for a company's rate depending on its payment type.
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
}

struct CompanyListView_Previews: PreviewProvider {
    static var previews: some View {
        CompanyListView()
            .environmentObject(DataStore())
    }
}