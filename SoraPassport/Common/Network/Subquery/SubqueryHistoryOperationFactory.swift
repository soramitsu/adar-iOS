/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: Apache 2.0
*/

import Foundation
import RobinHood
import FearlessUtils

protocol SubqueryHistoryOperationFactoryProtocol {
    func createOperation(
        address: String,
        count: Int,
        cursor: String?
    ) -> BaseOperation<SubqueryHistoryData>
}

final class SubqueryHistoryOperationFactory {
    let url: URL
    let filter: WalletHistoryFilter

    init(url: URL, filter: WalletHistoryFilter) {
        self.url = url
        self.filter = filter
    }

    private func prepareExtrinsicInclusionFilter() -> String {
        """
        {
          or: [
            {
                  extrinsic: {isNull: true}
            },
            {
              not: {
                and: [
                    {
                      extrinsic: { contains: {module: "Assets"} } ,
                        or: [
                         { extrinsic: {contains: {call: "transfer"} } },
                         { extrinsic: {contains: {call: "transferKeepAlive"} } },
                         { extrinsic: {contains: {call: "forceTransfer"} } },
                      ]
                    }
                ]
               }
            }
          ]
        }
        """
    }

    private func prepareFilter() -> String {
        var filterStrings: [String] = []

        if filter.contains(.extrinsics) {
            filterStrings.append(prepareExtrinsicInclusionFilter())
        } else {
            filterStrings.append("{extrinsic: { isNull: true }}")
        }

        if !filter.contains(.rewardsAndSlashes) {
            filterStrings.append("{reward: { isNull: true }}")
        }

        if !filter.contains(.transfers) {
            filterStrings.append("{transfer: { isNull: true }}")
        }

        return filterStrings.joined(separator: ",")
    }

    private func prepareQueryForAddress(_ address: String, count: Int, cursor: String?) -> String {
        let after = cursor.map { "\"\($0)\"" } ?? "null"
//https://soramitsu.atlassian.net/wiki/spaces/SP/pages/3448406051/Sora+Subquery
        return """
        {
            historyElements(
                 after: \(after),
                 first: \(count),
                 orderBy: TIMESTAMP_DESC,
                 filter: {
                    or: [
                        {
                          address: { equalTo: \"\(address)\" }
                          or: [
                            { module: { equalTo: "assets" } method: { equalTo: "transfer" } }
                            {
                              module: { equalTo: "liquidityProxy" }
                              method: { equalTo: "swap" }
                            }
                          ]
                        }
                        {
                        data: { contains: { to: \"\(address)\" } }
                        execution: { contains: { success: true } }
                        }
                    ]
                 }
             ) {
                 pageInfo {
                     startCursor,
                     endCursor
                 },
                 nodes {
                    id
                    blockHash
                    module
                    method
                    address
                    timestamp
                    networkFee
                    data
                    error
                    execution
                 }
             }
        }
        """
    }
}

extension SubqueryHistoryOperationFactory: SubqueryHistoryOperationFactoryProtocol {
    func createOperation(
        address: String,
        count: Int,
        cursor: String?
    ) -> BaseOperation<SubqueryHistoryData> {
        let queryString = prepareQueryForAddress(address, count: count, cursor: cursor)

        let requestFactory = BlockNetworkRequestFactory {
            var request = URLRequest(url: self.url)

            let info = JSON.dictionaryValue(["query": JSON.stringValue(queryString)])
            request.httpBody = try JSONEncoder().encode(info)
            request.setValue(
                HttpContentType.json.rawValue,
                forHTTPHeaderField: HttpHeaderKey.contentType.rawValue
            )

            request.httpMethod = HttpMethod.post.rawValue
            return request
        }

        let resultFactory = AnyNetworkResultFactory<SubqueryHistoryData> { data in
            let response = try JSONDecoder().decode(
                SubqueryResponse<SubqueryHistoryData>.self,
                from: data
            )

            switch response {
            case let .errors(error):
                throw error
            case let .data(response):
                return response
            }
        }

        let operation = NetworkOperation(requestFactory: requestFactory, resultFactory: resultFactory)

        return operation
    }
}
