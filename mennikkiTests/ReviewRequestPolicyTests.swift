//
//  ReviewRequestPolicyTests.swift
//  mennikkiTests
//

import Testing
@testable import mennikki

/// ReviewRequestPolicy のテスト。ストア評価を依頼する記録の件数を確かめる
@MainActor
struct ReviewRequestPolicyTests {

    @Test(
        "記録の総数が 3、10、20、…、100 のとき、依頼すると判定される",
        arguments: [3, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    )
    func requestsReviewAtMilestones(recordCount: Int) {
        #expect(ReviewRequestPolicy.shouldRequestReview(recordCount: recordCount))
    }

    @Test(
        "それ以外の件数では、依頼しないと判定される",
        arguments: [0, 1, 2, 4, 9, 11, 25, 99, 101, 110]
    )
    func doesNotRequestReviewOtherwise(recordCount: Int) {
        #expect(ReviewRequestPolicy.shouldRequestReview(recordCount: recordCount) == false)
    }
}
