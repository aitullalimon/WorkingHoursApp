import SwiftUI

/// The root view of the application.
///
/// This view hosts a tabbed interface that allows the user to manage
/// companies, view time entries across all companies, and review
/// invoices on a per‑company and per‑month basis.  Each tab is
/// represented by its own view with dedicated functionality.
struct ContentView: View {
    var body: some View {
        TabView {
            CompanyListView()
                .tabItem {
                    Label("Companies", systemImage: "building.2")
                }

            TimeEntryListView()
                .tabItem {
                    Label("Time Entries", systemImage: "clock")
                }

            InvoiceView()
                .tabItem {
                    Label("Invoice", systemImage: "doc.plaintext")
                }

            MonthlySummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar")
                }

            PaymentView()
                .tabItem {
                    Label("Payments", systemImage: "creditcard")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataStore())
    }
}