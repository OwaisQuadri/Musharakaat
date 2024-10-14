//
//  ContentView.swift
//  Musharakaat
//
//  Created by Owais on 2024-10-12.
//

import SwiftUI

enum Currency: String, CaseIterable {
    case cad = "CAD"
    case usd = "USD"
    case gbp = "GBP"
}

struct ContentView: View {
    @State private var isLoading = false
    @State private var isShowingSchedule: Bool = false
    @State var listing: Listing?
    @State var title: String = ""
    @State var value: String = ""
    @State var downPayment: String = ""
    @State var rentPercent: Double = 0.01
    @State var currency: Currency = .cad
    var rentValue: Double {
        let value = Double(self.value) ?? 0
        return value * rentPercent
    }
    @State var periodAmountString: String = ""
    var periodAmount: Int { Int(periodAmountString) ?? 0}
    @State var periodUnit: TimeUnit = .month

    @State var schedule: [(Payment, Double, Double)]?

    var body: some View {
        NavigationStack {
            List {

                Section ("Financing Metadata") {
                    HStack {
                        Text("Item Name:")
                        TextField("2024 Toyota Corolla", text: $title)
                    }
                    HStack {
                        Text("Total Value:")
                        TextField("$25,000.00", text: $value)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: .infinity)
                        Picker(selection: $currency) {
                            Label("Select Currency", systemImage: "cedisign.arrow.trianglehead.counterclockwise.rotate.90")
                                .disabled(true)
                            ForEach(Currency.allCases, id: \.self) { currency in
                                Text(currency.rawValue)
                            }
                        } label: { }
                    }
                    HStack {
                        Text("Down Payment:")
                        TextField("$5,000.00", text: $downPayment)
                            .keyboardType(.decimalPad)
                    }
                    VStack {
                        HStack {
                            Text("Rent:")
                            Spacer()
                            Text("\(rentValue.formatted(.currency(code: currency.rawValue))) per month")
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: $rentPercent,
                            in: 0.0001...0.05,
                            step: 0.0001
                        )
                    }
                    HStack {
                        Text("Timeline:")
                        TextField("12", text: $periodAmountString)
                            .keyboardType(.numberPad)
                        Picker(selection: $periodUnit) {
                            ForEach(TimeUnit.allCases, id: \.self) { unit in
                                Text(periodAmount == 1 ? unit.rawValue :unit.plural).tag(unit)
                            }
                        } label: { }
                    }
                    Button {
                        hideKeyboard()
                        isLoading = true
                        runSimulation()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                            } else {
                                HStack{
                                    Image(systemName: "gearshape")
                                    Text("Generate Schedule")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                if isShowingSchedule, let schedule {
                    Section ("Schedule") {
                        Text(
                            "It will take approx. \(schedule.count) payments of \(schedule.first?.0.amount.formatted(.currency(code: currency.rawValue)) ?? "the recommeded amount") to complete your musharakah financing by \(schedule.last?.0.date.formatted(date: .abbreviated, time: .omitted) ?? "the end date")."
                        )
                        .multilineTextAlignment(.leading)
                        Grid {
                            GridRow {
                                Text("Date")
                                Text("Rent Portion")
                                Text("Equity Portion")
                                Text("Total")
                                Text("Equity After Payment")
                            }
                            ForEach(schedule, id: \.self.0.id) { (
                                payment,
                                rentPortion,
                                equityPercent
                            ) in
                                GridRow {
                                    Text(
                                        payment.date
                                            .formatted(
                                                date: .numeric,
                                                time: .omitted
                                            )
                                    )
                                    Text(rentPortion.formatted(.currency(code: currency.rawValue)))
                                    Text((payment.amount - rentPortion).formatted(.currency(code: currency.rawValue)))
                                    Text(payment.amount.formatted(.currency(code: currency.rawValue)))
                                    Text(equityPercent.formatted(.percent))
                                }
                            }
                        }
                        .font(.caption)
                    }
                }

            }
            .multilineTextAlignment(.trailing)
            .navigationTitle("Musharakah")
        }
    }
    func runSimulation() {
        let valueDouble = Double(value) ?? 0.0
        let listing = Listing(
            title: title,
            value: valueDouble,
            rentPrice: rentPercent * valueDouble,
            rentCurrency: currency.rawValue,
            seller: UUID()
        )
        let startDate = Date()
        guard
            let endDate = Calendar.current.date(
                byAdding: periodUnit.component,
                value: periodAmount,
                to: startDate
            ) else {
            isLoading = false
            return
        }
        let monthlyPayment = listing.estimatedMonthlyPayment(
            startingOn: startDate,
            toEndOn: endDate,
            withDownPaymentOf: Double(downPayment)
        )
        schedule = listing
            .simulateEstimationAndGetSchedule(
                startingOn: startDate,
                endingOn: endDate,
                withEqualMonthlyPaymentOf: monthlyPayment,
                withDownPaymentOf: Double(downPayment) ?? 0
            )
        isShowingSchedule = true
        isLoading = false
    }
}

#Preview {
    ContentView()
}
enum TimeUnit: String, CaseIterable {
    case month = "month"
    case year = "year"
    var plural: String {
        return self.rawValue.appending("s")
    }
    var component: Calendar.Component {
        switch self {
        case .month: return .month
        case .year: return .year
        }
    }
}
