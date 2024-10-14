//
//  Invoice.swift
//  Musharakaat
//
//  Created by Owais on 2024-10-12.
//

import Foundation

class Invoice {
    init(
        id: UUID,
        listing: Listing,
        dueDate: Date,
        payments: [Payment],
        status: InvoiceStatus,
        standing: InvoiceStanding
    ) {
        self.id = id
        self.listing = listing
        self.dueDate = dueDate
        self.payments = payments
        self.status = status
        self.standing = standing
    }

    let id: UUID
    let listing: Listing
    let dueDate: Date
    var payments: [Payment] = []
    var status: InvoiceStatus
    var standing: InvoiceStanding

    var totalAmountDue: Double {
        listing.rentPrice * listing.sellerEquityPercent
    }

    var remainingAmountDue: Double {
        totalAmountDue - payments.reduce(0) { $0 + $1.amount }
    }

    var amountIntoEquity: Double {
        if standing == .rentOnly {
            return 0
        } else if remainingAmountDue <= 0 {
            return (-1) * remainingAmountDue
        }
        return 0
    }

    var isPaid: Bool {
        payments.reduce(0) { $0 + $1.amount } >= totalAmountDue
    }

    func close() {
        status = .closed
        if dueDate < .now { standing = .late }
    }
}

enum InvoiceStanding {
    case rentOnly, rentAndEquity, late
}

enum InvoiceStatus {
    case open, closed
}
