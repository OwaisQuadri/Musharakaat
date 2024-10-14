//
//  Listing.swift
//  Musharakaat
//
//  Created by Owais on 2024-10-12.
//

import Foundation
class Listing {
    var status: ListingStatus {
        if isDraft { return .draft }
        if buyer == nil { return .lookingForBuyer }
        if sellerEquityPercent <= 0 { return .closed }
        return .inProgress
    }
    var isDraft: Bool = true
    let id: UUID
    let title: String
    let value: Double
    let rentPrice: Double
    let rentCurrency: String
    var seller: UUID
    var buyer: UUID?
    var sellerEquityPercent: Double {
        let totalEquityPayment = equityPayments.reduce(0) { partialResult, payment in
            partialResult + payment.amount
        }
        return max(1.0 - (totalEquityPayment / value), 0)
    }
    var invoices: [Invoice] = []
    var onHoldPayments: [Payment] = []
    var equityPayments: [Payment] = []
    init(
        id: UUID = UUID(),
        title: String,
        value: Double,
        rentPrice: Double,
        rentCurrency: String,
        seller: UUID,
        buyer: UUID? = nil,
        on date: Date = .now
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.rentPrice = rentPrice
        self.rentCurrency = rentCurrency
        self.seller = seller
        self.buyer = buyer

        generateInvoice(on: date)
    }
    func generateInvoice(on date: Date = .now) {
        guard let newDueDate = Calendar.current
            .date(
                byAdding: .month,
                value: 1,
                to: date
            ) else { return }
        if let currentInvoice = invoices
            .last(where: {$0.dueDate < date}) {
            // due date has passed for this one
            // check for bad behavior
            let standing: InvoiceStanding
            if currentInvoice.isPaid {
                standing = .rentAndEquity
                currentInvoice.close()
            } else {
                currentInvoice.standing = .late
                standing = .rentOnly
            }
            let newInvoice = Invoice(
                id: .init(),
                listing: self,
                dueDate: Calendar.current
                    .startOfDay(for: newDueDate),
                payments: [],
                status: .open,
                standing: standing
            )
            invoices.append(newInvoice)
        } else {
            let newInvoice = Invoice(
                id: .init(),
                listing: self,
                dueDate: Calendar.current
                    .startOfDay(for: newDueDate),
                payments: [],
                status: .open,
                standing: .rentAndEquity
            )
            invoices.append(newInvoice)
        }
        let heldPayments = onHoldPayments
        onHoldPayments = []
        for payment in heldPayments {
            makePayment(payment)
        }
    }
    func makeDownPayment(_ payment: Payment) {
        equityPayments.append(payment)
    }

    func makePayment(_ payment: Payment) {
        let openInvoices = invoices.filter({!$0.isPaid && $0.status == .open})
        var paymentPot = payment.amount + onHoldPayments.reduce(
            0,
            {$0 + $1.amount}
        )
        for invoice in openInvoices {
            if paymentPot.isZero { break }
            if paymentPot <= invoice.totalAmountDue {
                invoice.payments.append(payment)
                paymentPot -= invoice.totalAmountDue
            } else {
                let splitAmount = invoice.totalAmountDue
                let splitPayment = Payment(
                    id: UUID(),
                    amount: splitAmount,
                    date: payment.date
                )
                invoice.payments.append(splitPayment)
                paymentPot -= splitAmount
            }
            if invoice.isPaid { invoice.close() }
        }
        if paymentPot > 0 {
            // equity payment
            let eqPayment = Payment(
                id: UUID(),
                amount: paymentPot,
                date: payment.date
            )
            if invoices.last?.standing == .rentOnly {
                // if overpaid on a rentOnly invoice, split it and (generate + send to) next month's invoice
                onHoldPayments.append(eqPayment)
            } else {
                // if payment is full before due date, start taking from equity
                equityPayments.append(eqPayment)
            }
        }
    }

    func estimatedMonthlyPayment(
        startingOn startDate: Date = .now,
        toEndOn endDate: Date,
        withDownPaymentOf downPayment: Double? = nil
    ) -> Double {
        let hoursRemaining = endDate.timeIntervalSince(Calendar.current.startOfDay(for: startDate)).convert(
            from: .seconds,
            to: .hours
        )
        if let downPayment {
            makeDownPayment(
                Payment(id: .init(), amount: downPayment, date: startDate)
            )
        }
        let monthsRemaining = Int(hoursRemaining / 24 / 30)
        let principalRemaining = value * sellerEquityPercent
        let remainingMaxRent = rentPrice * sellerEquityPercent
        let estimatedTotalPayment = principalRemaining + remainingMaxRent * Double(monthsRemaining) / 2
        if let downPayment {
            equityPayments.removeLast()
        }
        return estimatedTotalPayment / Double(monthsRemaining)
    }

    func simulateEstimationAndGetSchedule(
        startingOn startDate: Date = .now,
        endingOn endDate: Date = .now,
        withEqualMonthlyPaymentOf payment: Double,
        withDownPaymentOf downPayment: Double = 0
    ) -> [(
        Payment,
        rentAmountAfterPayment: Double,
        equityAfterPayment: Double
    )] {
        var schedule: [(Payment, Double, Double)] = []
        var runningTime = startDate
        let dummyListing = Listing(
            id: UUID(),
            title: "Simulated Listing",
            value: value,
            rentPrice: rentPrice,
            rentCurrency: rentCurrency,
            seller: seller
        )
        let downPayment = Payment(
            id: .init(),
            amount: downPayment,
            date: runningTime
        )
        dummyListing.makeDownPayment(downPayment)
        while dummyListing.sellerEquityPercent > 0 {
            runningTime = Calendar.current
                .date(
                    byAdding: .month,
                    value: 1,
                    to: runningTime
                ) ?? runningTime.addingTimeInterval(3600 * 24 * 30)
            let currentRentAmount = dummyListing.sellerEquityPercent * dummyListing.rentPrice
            let remainingEquityPayment = dummyListing.sellerEquityPercent * dummyListing.value
            let lastPaymentAmount = currentRentAmount + remainingEquityPayment
            let isLastPayment = lastPaymentAmount < payment
            let paymentAmount = isLastPayment ? lastPaymentAmount : payment
            let curPayment = Payment(id: .init(), amount: paymentAmount, date: runningTime)
            dummyListing
                .makePayment(
                    curPayment
                )
            dummyListing.generateInvoice(on: runningTime)
            schedule
                .append(
                    (
                        curPayment,
                        currentRentAmount,
                        1.0 - dummyListing.sellerEquityPercent
                    )
                )
        }
        return schedule
    }
}

enum ListingStatus {
    case draft, lookingForBuyer, inProgress, closed
}
