//
//  MusharakaatTests.swift
//  MusharakaatTests
//
//  Created by Owais on 2024-10-12.
//

import Testing
@testable import Musharakaat
import Foundation

struct ListingTests {

    var sut: Listing!
    let startDate = Date.now

    init() {
        self.sut = Listing(
            id: .init(),
            title: "Something",
            value: 1000,
            rentPrice: 10,
            rentCurrency: "CAD",
            seller: .init(
                id: .init(),
                name: .init(first: "Owais", last: "Quadri", middleInitial: "S"),
                email: "owais@test.com",
                listings: [],
                purchases: []
            ),
            invoices: [],
            on: startDate
        )
    }

    @Test func testInit() async throws {
        #expect(sut != nil)
    }


    @Test func estimatedMonthlyPayment() async throws {
        let endDate = startDate.addingTimeInterval(3600 * 24 * 365)
        let estimatedMonthlyPayments = sut.estimatedMonthlyPayment(
            startingOn: startDate,
            toEndOn: endDate
        )
        let estimate: Double = (1000 + 10 * 12 / 2) / 12
        #expect(estimatedMonthlyPayments == estimate)
    }

    @Test func simulateSchedule() async throws {
        let endDate = startDate.addingTimeInterval(3600 * 24 * 365)
        let estimatedMonthlyPayments = sut.estimatedMonthlyPayment(
            toEndOn: endDate
        )
        let schedule = sut.simulateEstimationAndGetSchedule(
            startingOn: startDate,
            endingOn: endDate,
            withEqualMonthlyPaymentOf: estimatedMonthlyPayments,
            withDownPaymentOf: 0
        )
        #expect(schedule.count == 12)
    }

    @Test func simulateLatePaymentsExpectRentOnlyPayments() async throws {
        // wait 35 days to make a payment
        let paymentDate = try #require(Calendar.current.date(
            byAdding: .day,
            value: 35,
            to: startDate
        ))
        sut.generateInvoice(on: paymentDate)
        let payment = Payment(
            id: .init(),
            amount: 80,
            date: paymentDate
        )
        sut.makePayment(payment)
        #expect(sut.invoices.count == 2)
        #expect(sut.invoices.first?.standing == .late)
        #expect(sut.invoices.first?.status == .closed)
        #expect(sut.invoices.last?.standing == .rentOnly)
        #expect(sut.invoices.last?.status == .closed)
        #expect(sut.onHoldPayments.count == 1)
        // waiting until the next invoice
        let nextInvoiceDate = try #require(Calendar.current.date(
            byAdding: .day,
            value: 25,
            to: paymentDate
        ))
        sut.generateInvoice(on: nextInvoiceDate)
        // check if user is reformed
        #expect(sut.onHoldPayments.count == 0)
        #expect(sut.invoices.last?.standing == .rentAndEquity)
        #expect(sut.invoices.last?.status == .closed)
        #expect(sut.equityPayments.count == 1)
        #expect(sut.sellerEquityPercent < 1.0)
    }

}
