//
//  TimeInterval+ConvertTime.swift
//  Musharakaat
//
//  Created by Owais on 2024-10-12.
//

import Foundation

extension TimeInterval {
    func convert(from unit: UnitDuration = .seconds, to unitTarget: UnitDuration = .seconds) -> Double {
        let measurement = Measurement(value: self, unit: unit)
        return measurement.converted(to: unitTarget).value
    }
}
