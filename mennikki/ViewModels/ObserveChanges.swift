//
//  ObserveChanges.swift
//  mennikki
//

import Observation

/// `update` の中で読んだ `@Observable` のプロパティが変わるたびに、`update` をもう一度呼ぶ。
/// 呼び出したときに、まず 1 回すぐに呼ぶ。
///
/// iOS 17 の UIKit は、`@Observable` の変更を自動では受け取れないため、ViewController が ViewModel の変更を
/// 画面に反映するときに使う。
///
/// `update` の中では、ViewController を `[weak self]` で参照すること。強く参照すると、
/// ViewModel が ViewController を参照し続ける形になり、画面を閉じても解放されない。
func observeChanges(_ update: @escaping @MainActor () -> Void) {
    withObservationTracking {
        update()
    } onChange: {
        // onChange は値が変わる直前に呼ばれるので、変わったあとの値を読めるように、次の順番で呼び直す。
        // withObservationTracking の知らせは 1 回きりなので、呼び直すたびに登録し直す
        Task { @MainActor in
            observeChanges(update)
        }
    }
}
