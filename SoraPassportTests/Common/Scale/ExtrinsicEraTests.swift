/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import XCTest
@testable import SoraPassport
import FearlessUtils

class ExtrinsicEraTests: XCTestCase {
    func testMortalEraDecoding() throws {
        // given

        let data = Data([78, 156])

        let scaleDecoder = try ScaleDecoder(data: data)

        // when

        let era = try Era(scaleDecoder: scaleDecoder)

        // then

        switch era {
        case .immortal:
            XCTFail("Mortal era expected")
        case .mortal(let period, let phase):
            XCTAssertEqual(period, 32768)
            XCTAssertEqual(phase, 20000)
        }
    }

    func testImmortalEraDecoding() throws {
        // given

        let data = Data([0])

        let scaleDecoder = try ScaleDecoder(data: data)

        // when

        let era = try Era(scaleDecoder: scaleDecoder)

        // then

        switch era {
        case .immortal:
            break
        case .mortal:
            XCTFail("Immortal era expected")
        }
    }
}
