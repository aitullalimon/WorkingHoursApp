import Foundation
import Combine

/// The payment model for a company.
///
/// Companies can either compensate employees on an hourly basis or via a
/// point‑based (per unit) system.
enum PaymentType: String, Codable, CaseIterable, Identifiable {
    case hourly
    case point

    var id: String { rawValue }

    /// A user‑friendly display name.
    var displayName: String {
        switch self {
        case .hourly: return "Hourly"
        case .point: return "Point"
        }
    }
}

/// A single company for which you track hours and earnings.
///
/// Each company has a unique identifier, a name, a payment type, and one or
/// more associated rates depending on that type.  For an hourly company,
/// ``hourlyRate`` is used; for a point company, ``pointRate`` applies.
struct Company: Identifiable, Codable {
    /// Unique identifier for the company.
    let id: UUID
    /// Human‑readable company name.
    var name: String
    /// The payment model used by this company.
    var paymentType: PaymentType
    /// Pay rate per hour for hourly companies.  Should be nil for point companies.
    var hourlyRate: Double?
    /// Pay rate per unit for point companies.  Should be nil for hourly companies.
    var pointRate: Double?

    /// The day of the month on which this company's billing cycle starts.
    ///
    /// Some companies invoice on a mid‑month cycle (e.g. from the 16th of one month
    /// through the 15th of the next).  The default value of `1` corresponds to a
    /// standard calendar month (1st through last day).  A value of `16` represents
    /// a cycle from the 16th of one month until the 15th of the following month.
    var monthStartDay: Int

    init(id: UUID = UUID(), name: String, paymentType: PaymentType, hourlyRate: Double? = nil, pointRate: Double? = nil, monthStartDay: Int = 1) {
        self.id = id
        self.name = name
        self.paymentType = paymentType
        self.hourlyRate = hourlyRate
        self.pointRate = pointRate
        self.monthStartDay = monthStartDay
    }

    /// Coding keys for manual decoding/encoding.
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case paymentType
        case hourlyRate
        case pointRate
        case monthStartDay
    }

    /// Custom decoding to provide a default value for `monthStartDay` when missing.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        paymentType = try container.decode(PaymentType.self, forKey: .paymentType)
        hourlyRate = try container.decodeIfPresent(Double.self, forKey: .hourlyRate)
        pointRate = try container.decodeIfPresent(Double.self, forKey: .pointRate)
        monthStartDay = try container.decodeIfPresent(Int.self, forKey: .monthStartDay) ?? 1
    }

    /// Custom encoding using the default synthesis.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(paymentType, forKey: .paymentType)
        try container.encodeIfPresent(hourlyRate, forKey: .hourlyRate)
        try container.encodeIfPresent(pointRate, forKey: .pointRate)
        try container.encode(monthStartDay, forKey: .monthStartDay)
    }
}

/// A single block of time worked for a given company on a specific date.
///
/// ``hoursWorked`` captures the number of hours worked on ``date``.  Each
/// entry references the company by its ``companyID``.
struct TimeEntry: Identifiable, Codable {
    /// Unique identifier for the time entry.
    let id: UUID
    /// The company to which the entry belongs.
    var companyID: UUID
    /// The calendar date of the entry.
    var date: Date
    /// Optional start time; when set together with ``endTime``, hours are calculated automatically.
    var startTime: Date?
    /// Optional end time.
    var endTime: Date?
    /// Optional manually entered hours (used if start/end times are not provided).
    var hoursWorked: Double?
    /// Optional transport bill applied to this entry.
    var transportBill: Double?
    /// Optional count of units (e.g. pieces or items) for piecework compensation.
    var unitCount: Double?
    /// Optional rate per unit for piecework compensation.
    var unitRate: Double?

    /// Optional break duration in hours.  For hourly companies, this represents
    /// the total break time (e.g. lunch) in decimal hours that should be subtracted
    /// from the raw ``calculatedHours``.  Nil indicates no break.
    var breakDuration: Double?

    init(
        id: UUID = UUID(),
        companyID: UUID,
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        hoursWorked: Double? = nil,
        transportBill: Double? = nil,
        unitCount: Double? = nil,
        unitRate: Double? = nil,
        breakDuration: Double? = nil
    ) {
        self.id = id
        self.companyID = companyID
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.hoursWorked = hoursWorked
        self.transportBill = transportBill
        self.unitCount = unitCount
        self.unitRate = unitRate
        self.breakDuration = breakDuration
    }

    /// Compute the total hours for this entry.
    ///
    /// If both ``startTime`` and ``endTime`` are specified, the difference between
    /// them (in hours) is returned.  Otherwise, the optional ``hoursWorked`` is
    /// returned (or `0` if `nil`).
    var calculatedHours: Double {
        if let start = startTime, let end = endTime {
            return max(end.timeIntervalSince(start) / 3600.0, 0)
        }
        return hoursWorked ?? 0
    }

    /// Compute the billable hours for this entry by subtracting any break time
    /// from ``calculatedHours``.  A nil break duration is treated as zero.  The
    /// result is clamped at zero to avoid negative values.
    var billableHours: Double {
        let base = calculatedHours
        let brk = breakDuration ?? 0
        return max(base - brk, 0)
    }
}

/// Represents a financial action recorded against a specific invoice period.
///
/// A payment action can mark when an invoice becomes due or when it is withdrawn
/// (i.e. paid out).  These records are tracked separately from time entries.
enum PaymentAction: String, Codable, CaseIterable, Identifiable {
    case due
    case withdrawn
    
    var id: String { rawValue }
    
    /// A user‑friendly description of the action.
    var displayName: String {
        switch self {
        case .due: return "Due"
        case .withdrawn: return "Withdrawn"
        }
    }
}

/// Records a due or withdrawn payment for a company's invoice period.
struct PaymentRecord: Identifiable, Codable {
    let id: UUID
    /// The company this payment pertains to.
    let companyID: UUID
    /// The start date of the invoice period for which the payment applies.
    let periodStart: Date
    /// The end date of the invoice period for which the payment applies.
    let periodEnd: Date
    /// The monetary value of the payment.
    let amount: Double
    /// Indicates whether the payment was marked as due or withdrawn.
    let action: PaymentAction
    /// The date on which the payment record was created.
    let date: Date
    
    init(id: UUID = UUID(), companyID: UUID, periodStart: Date, periodEnd: Date, amount: Double, action: PaymentAction, date: Date = Date()) {
        self.id = id
        self.companyID = companyID
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.amount = amount
        self.action = action
        self.date = date
    }
}

/// Centralised storage for companies and time entries.
///
/// This class holds arrays of companies and time entries and publishes
/// changes so that SwiftUI views reactively update.  It also persists
/// data to ``UserDefaults`` so that it persists across app launches.
final class DataStore: ObservableObject {
    /// A published list of all companies defined by the user.
    @Published var companies: [Company] = []
    /// A published list of all time entries across all companies.
    @Published var timeEntries: [TimeEntry] = []

    /// A published list of all payment records recorded by the user.
    @Published var paymentRecords: [PaymentRecord] = []

    private let companiesKey = "companiesKey"
    private let timeEntriesKey = "timeEntriesKey"
    private let paymentRecordsKey = "paymentRecordsKey"

    init() {
        loadData()
    }

    /// Add a new company with the specified payment model and rate.
    ///
    /// - Parameters:
    ///   - name: Human‑readable name for the company.
    ///   - paymentType: The payment model (hourly or point).
    ///   - hourlyRate: The hourly rate for hourly companies.
    ///   - pointRate: The rate per unit for point companies.
    /// Add a new company to the store.
    ///
    /// - Parameters:
    ///   - name: Name of the company.
    ///   - paymentType: The payment model (hourly or point).
    ///   - hourlyRate: Optional hourly rate if `paymentType` is `.hourly`.
    ///   - pointRate: Optional rate per unit if `paymentType` is `.point`.
    ///   - monthStartDay: The day of the month the billing cycle begins (default 1 or 16).
    func addCompany(name: String, paymentType: PaymentType, hourlyRate: Double? = nil, pointRate: Double? = nil, monthStartDay: Int = 1) {
        let newCompany = Company(name: name, paymentType: paymentType, hourlyRate: hourlyRate, pointRate: pointRate, monthStartDay: monthStartDay)
        companies.append(newCompany)
        saveData()
    }

    /// Delete companies at the given index set.  Any time entries
    /// associated with the deleted companies are also removed.
    func deleteCompany(at offsets: IndexSet) {
        let idsToDelete = offsets.map { companies[$0].id }
        companies.remove(atOffsets: offsets)
        // Remove associated time entries
        timeEntries.removeAll { idsToDelete.contains($0.companyID) }
        saveData()
    }

    /// Add a new time entry for the specified company.
    ///
    /// - Parameters:
    ///   - companyID: Identifier of the company the entry belongs to.
    ///   - date: The calendar date of the entry.
    ///   - startTime: Optional start time for the entry.  If both start and end times are provided,
    ///     ``TimeEntry.calculatedHours`` is derived from them.
    ///   - endTime: Optional end time for the entry.
    ///   - hoursWorked: Optional manually entered hours if start and end times are not provided.
    ///   - transportBill: Optional transport bill associated with this entry.
    ///   - unitCount: Optional number of units for piecework compensation.
    ///   - unitRate: Optional rate per unit for piecework compensation.
    func addTimeEntry(
        companyID: UUID,
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        hoursWorked: Double? = nil,
        transportBill: Double? = nil,
        unitCount: Double? = nil,
        unitRate: Double? = nil,
        breakDuration: Double? = nil
    ) {
        let newEntry = TimeEntry(
            companyID: companyID,
            date: date,
            startTime: startTime,
            endTime: endTime,
            hoursWorked: hoursWorked,
            transportBill: transportBill,
            unitCount: unitCount,
            unitRate: unitRate,
            breakDuration: breakDuration
        )
        timeEntries.append(newEntry)
        saveData()
    }

    /// Delete time entries at the given index set.
    func deleteTimeEntry(at offsets: IndexSet) {
        timeEntries.remove(atOffsets: offsets)
        saveData()
    }

    /// Update an existing time entry with new data.
    ///
    /// - Parameter updatedEntry: The entry containing updated values.  The `id` must match
    ///   an existing entry.  If found, the entry is replaced and changes saved.
    func updateTimeEntry(_ updatedEntry: TimeEntry) {
        if let index = timeEntries.firstIndex(where: { $0.id == updatedEntry.id }) {
            timeEntries[index] = updatedEntry
            saveData()
        }
    }

    /// Return all time entries belonging to a specific company.
    func timeEntries(for companyID: UUID) -> [TimeEntry] {
        return timeEntries.filter { $0.companyID == companyID }
    }

    // MARK: - Payment Records

    /// Add a new payment record (due or withdrawn) for a company's invoice period.
    ///
    /// - Parameters:
    ///   - companyID: The identifier of the company the record pertains to.
    ///   - periodStart: The start date of the invoice period.
    ///   - periodEnd: The end date of the invoice period.
    ///   - amount: The total invoice amount for the period.
    ///   - action: Whether the payment is due or withdrawn.
    func addPaymentRecord(companyID: UUID, periodStart: Date, periodEnd: Date, amount: Double, action: PaymentAction) {
        let record = PaymentRecord(companyID: companyID, periodStart: periodStart, periodEnd: periodEnd, amount: amount, action: action)
        paymentRecords.append(record)
        saveData()
    }

    // MARK: - Persistence

    /// Load companies and time entries from ``UserDefaults`` if available.
    private func loadData() {
        let decoder = JSONDecoder()
        if let companiesData = UserDefaults.standard.data(forKey: companiesKey),
           let savedCompanies = try? decoder.decode([Company].self, from: companiesData) {
            self.companies = savedCompanies
        }

        if let entriesData = UserDefaults.standard.data(forKey: timeEntriesKey),
           let savedEntries = try? decoder.decode([TimeEntry].self, from: entriesData) {
            self.timeEntries = savedEntries
        }

        if let paymentsData = UserDefaults.standard.data(forKey: paymentRecordsKey),
           let savedPayments = try? decoder.decode([PaymentRecord].self, from: paymentsData) {
            self.paymentRecords = savedPayments
        }
    }

    /// Save the current lists of companies and time entries to ``UserDefaults``.
    private func saveData() {
        let encoder = JSONEncoder()
        if let encodedCompanies = try? encoder.encode(companies) {
            UserDefaults.standard.set(encodedCompanies, forKey: companiesKey)
        }
        if let encodedEntries = try? encoder.encode(timeEntries) {
            UserDefaults.standard.set(encodedEntries, forKey: timeEntriesKey)
        }
        if let encodedPayments = try? encoder.encode(paymentRecords) {
            UserDefaults.standard.set(encodedPayments, forKey: paymentRecordsKey)
        }
    }
}