//
//  AddRecordView.swift
//  mennikki
//

import SwiftUI
import PhotosUI

/// 新規記録・編集画面
///
/// 入力の値、入力の検証、保存は AddRecordViewModel が受け持つ。この画面は、表示と入力の受け渡し、写真の読み込みを行う。
/// 画面を閉じることと、閉じたあとにストア評価を頼むことは、#27 の移行中は、この画面を入れている AddRecordViewController が受け持つ
struct AddRecordView: View {

    @Bindable var viewModel: AddRecordViewModel
    /// ✕ を押したとき
    let onCancel: () -> Void
    /// 保存して、チェックの印を出し終えたとき。引数は、ストア評価を頼むかどうか
    let onSaved: (_ shouldRequestReview: Bool) -> Void

    /// 入力の欄。キーボードを出している欄と、入力のエラーのときに揺らす欄を表す
    private enum Field: Hashable {
        case storeName
        case cost
        case rating
        case comment
    }

    @FocusState private var focusedField: Field?
    /// 入力のエラーのときに、欄を揺らした回数。数が増えると、その欄を揺らす
    @State private var shakeCounts: [Field: Int] = [:]
    /// 押したときに弾ませている、種類のボタン
    @State private var bouncingRamenType: RamenType?
    @State private var isChoosingPrefecture = false

    /// 写真の選択の画面で選んだもの。選ぶたびに、selectedPhoto に読み込む
    @State private var pickedPhotoItem: PhotosPickerItem?
    /// この画面で選んだ写真。選んでいなければ nil（編集のときの、保存済みの写真は含めない）
    @State private var selectedPhoto: UIImage?
    /// 編集のときに出す、保存済みの写真
    @State private var existingPhoto: UIImage?

    /// 保存している間と、保存できて画面を閉じるまでは、入力を受け付けない（同じ記録を 2 回保存しないため）
    @State private var isSaving = false
    @State private var checkmarkScale = Layout.checkmarkStartScale
    @State private var checkmarkOpacity = 0.0
    @State private var isShowingAlert = false
    @State private var alertContent = AlertContent(title: "", message: "")

    private struct AlertContent {
        let title: String
        let message: String
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                form
                saveButton
            }
            .background(Color.appBackground)
            .overlay { checkmark }
            .allowsHitTesting(!isSaving)
            .navigationTitle(viewModel.isEditMode ? "記録を編集" : "新規記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert(alertContent.title, isPresented: $isShowingAlert) {
                Button("OK") {}
            } message: {
                Text(alertContent.message)
            }
            .task {
                await loadExistingPhoto()
            }
            // 写真を選び直したときは、前の写真の読み込みをやめて、新しい写真を読む
            .task(id: pickedPhotoItem) {
                await loadPickedPhoto()
            }
        }
    }

    // MARK: - 入力の欄

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                section("店舗名", isRequired: true) { storeNameField }
                section("ラーメンの種類", isRequired: true) { ramenTypeChips }
                section("都道府県") { prefectureField }
                section("訪問日") { visitDatePicker }
                section("費用") { costField }
                section("評価", isRequired: true) { ratingStars }
                section("コメント") { commentEditor }
                section("写真") { photoPicker }
            }
            .padding(Layout.formPadding)
            // 欄の外（項目名や、欄の間）を押したら、キーボードを閉じる
            .background {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { focusedField = nil }
            }
        }
        .scrollIndicators(.hidden)
        // 今の UIKit の画面と同じく、スクロールしてもキーボードを閉じない
        .scrollDismissesKeyboard(.never)
        // 画面の下の保存ボタンに、最後の欄が隠れないようにする
        .contentMargins(.bottom, Layout.saveButtonAreaHeight, for: .scrollContent)
    }

    /// 項目名と、入力の欄の組
    private func section<Content: View>(
        _ title: String,
        isRequired: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.sectionTitleSpacing) {
            sectionTitle(title, isRequired: isRequired)
                .padding(.leading, Layout.sectionTitleLeadingPadding)
            content()
        }
    }

    /// 項目名。必須の項目には、赤い「＊」を付ける
    private func sectionTitle(_ title: String, isRequired: Bool) -> some View {
        let titleText = Text(title)
            .kerning(Layout.sectionTitleKerning)
            .foregroundStyle(Color.appSecondaryText)
        let requiredMark = Text(" ＊").foregroundStyle(Color.appPrimary)
        let label = isRequired ? Text("\(titleText)\(requiredMark)") : titleText
        return label
            .font(.appFormLabel)
            .accessibilityLabel(isRequired ? "\(title)、必須" : title)
            // 押しても何もしない文字なので、押したときは下の背景に渡して、キーボードを閉じる
            .allowsHitTesting(false)
    }

    private var storeNameField: some View {
        TextField("店舗名を入力", text: $viewModel.storeName)
            .font(.appBody)
            .focused($focusedField, equals: .storeName)
            .accessibilityLabel("店舗名")
            .padding(.horizontal, Layout.fieldHorizontalPadding)
            .frame(height: Layout.fieldHeight)
            .inputFieldBackground(borderColor: borderColor(for: .storeName))
            .shake(trigger: shakeCounts[.storeName, default: 0])
    }

    private var ramenTypeChips: some View {
        ScrollView(.horizontal) {
            // 今の UIKit の画面と同じく、どのボタンも、いちばん長い名前のボタンと同じ幅にする
            EqualWidthHStack(spacing: Layout.chipSpacing) {
                ForEach(RamenType.allCases, id: \.self) { ramenType in
                    ramenTypeChip(ramenType)
                }
            }
        }
        .scrollIndicators(.hidden)
        .closesKeyboardOnTap($focusedField)
    }

    /// 種類のボタン。選んでいないときは薄い種類の色、選んだときは濃い種類の色にして、少し大きくする
    private func ramenTypeChip(_ ramenType: RamenType) -> some View {
        let isSelected = viewModel.ramenType == ramenType
        let color = Color.colorForRamenType(ramenType)
        return Button {
            selectRamenType(ramenType)
        } label: {
            Text(ramenType.rawValue)
                .font(.appChip)
                .foregroundStyle(isSelected ? Color.white : color)
                .padding(.horizontal, Layout.chipHorizontalPadding)
                // 名前が短いボタンも、並べたときに決まる幅まで広げる
                .frame(maxWidth: .infinity)
                .padding(.vertical, Layout.chipVerticalPadding)
                // 文字が小さいときは最低の高さにし、大きいときは文字に合わせて高くする
                .frame(minHeight: Layout.chipMinHeight)
                .background(isSelected ? color : color.opacity(Layout.chipBackgroundOpacity), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(isSelected ? color : Color.clear, lineWidth: Layout.borderWidth)
                }
                // 色は、今の UIKit の画面と同じく、すぐに変える（大きさだけを動かす）
                .animation(nil, value: isSelected)
        }
        .buttonStyle(.plain)
        .scaleEffect(chipScale(for: ramenType, isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func chipScale(for ramenType: RamenType, isSelected: Bool) -> CGFloat {
        if bouncingRamenType == ramenType { return Layout.chipBounceScale }
        return isSelected ? Layout.chipSelectedScale : 1
    }

    private var prefectureField: some View {
        Button {
            focusedField = nil
            isChoosingPrefecture = true
        } label: {
            Text(viewModel.prefecture?.rawValue ?? "都道府県を選択")
                .font(.appBody)
                .foregroundStyle(viewModel.prefecture == nil ? Color.appSecondaryText : Color.appText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Layout.fieldHorizontalPadding)
                .frame(height: Layout.fieldHeight)
                .inputFieldBackground(borderColor: .appFieldBorder)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .confirmationDialog("都道府県を選択", isPresented: $isChoosingPrefecture, titleVisibility: .visible) {
            if viewModel.prefecture != nil {
                Button("選択を解除", role: .destructive) {
                    viewModel.prefecture = nil
                }
            }
            ForEach(Prefecture.allCases, id: \.self) { prefecture in
                Button(prefecture.rawValue) {
                    viewModel.prefecture = prefecture
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    /// 訪問日のカレンダー。未来の日は選べない
    private var visitDatePicker: some View {
        DatePicker("訪問日", selection: $viewModel.visitDate, in: ...Date(), displayedComponents: .date)
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(Color.appPrimary)
            .environment(\.locale, Locale(identifier: "ja_JP"))
            .background(Color.white, in: RoundedRectangle(cornerRadius: Layout.fieldCornerRadius))
    }

    private var costField: some View {
        TextField("費用（円）", text: $viewModel.costText)
            .font(.appBody)
            .keyboardType(.numberPad)
            .focused($focusedField, equals: .cost)
            .accessibilityLabel("費用")
            .padding(.horizontal, Layout.fieldHorizontalPadding)
            .frame(height: Layout.fieldHeight)
            .inputFieldBackground(borderColor: borderColor(for: .cost))
            .onChange(of: viewModel.costText) { oldText, newText in
                // 数字以外の文字と、上限を超える数は、入力されなかったことにする
                if !AddRecordViewModel.isAcceptableCostText(newText) {
                    viewModel.costText = oldText
                }
            }
    }

    private var ratingStars: some View {
        StarRatingInputView(rating: $viewModel.rating)
            .frame(height: Layout.starRowHeight)
            .closesKeyboardOnTap($focusedField)
            .shake(trigger: shakeCounts[.rating, default: 0])
    }

    private var commentEditor: some View {
        TextEditor(text: $viewModel.comment)
            .font(.appBody)
            .foregroundStyle(Color.appText)
            .scrollContentBackground(.hidden)
            .focused($focusedField, equals: .comment)
            .accessibilityLabel("コメント")
            .padding(.horizontal, Layout.commentHorizontalPadding)
            .padding(.vertical, Layout.commentVerticalPadding)
            .frame(minHeight: Layout.commentMinHeight)
            .inputFieldBackground(borderColor: .appFieldBorder)
            .shake(trigger: shakeCounts[.comment, default: 0])
    }

    // MARK: - 写真

    /// 写真の欄。写真を出しているときも、押すと選び直せる
    private var photoPicker: some View {
        let photo = selectedPhoto ?? existingPhoto
        return PhotosPicker(selection: $pickedPhotoItem, matching: .images) {
            photoArea(photo)
        }
        .buttonStyle(.plain)
        .closesKeyboardOnTap($focusedField)
        .accessibilityLabel(photo == nil ? "写真を選択" : "写真を変更")
        .accessibilityHint(photo == nil ? "" : "ダブルタップして別の写真を選択")
    }

    @ViewBuilder
    private func photoArea(_ photo: UIImage?) -> some View {
        let shape = RoundedRectangle(cornerRadius: Layout.fieldCornerRadius)
        if let photo {
            Color.appFieldBorderOpaque.opacity(Layout.photoBackgroundOpacity)
                .frame(height: Layout.photoHeight)
                .overlay {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(shape)
                .contentShape(shape)
        } else {
            Image(systemName: "camera.fill")
                .font(.system(size: Layout.cameraIconSize))
                .foregroundStyle(Color.appFieldBorderOpaque)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.photoHeight)
                .background(Color.white, in: shape)
                .overlay {
                    shape.strokeBorder(Color.appFieldBorderOpaque.opacity(Layout.photoBorderOpacity),
                                       lineWidth: Layout.borderWidth)
                }
                .contentShape(shape)
        }
    }

    private func loadExistingPhoto() async {
        guard let photoData = viewModel.existingPhotoData else { return }
        existingPhoto = await UIImage.decodedForDisplay(from: photoData)
    }

    private func loadPickedPhoto() async {
        guard let pickedPhotoItem else { return }
        // 保存のときに、今の処理（UIImage）で縮小・変換するので、UIImage にしておく
        guard let photoData = try? await pickedPhotoItem.loadTransferable(type: Data.self),
              let photo = UIImage(data: photoData) else { return }
        // 読んでいる間に写真を選び直したときは、古い写真を出さない
        guard !Task.isCancelled else { return }
        selectedPhoto = photo
    }

    // MARK: - 保存

    /// 画面の下に固定した保存ボタン。押すと沈み込む
    private var saveButton: some View {
        Button(action: save) {
            Text("保存する")
                .font(.appButton)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.saveButtonHeight)
                .background(Color.appSuccess, in: RoundedRectangle(cornerRadius: Layout.saveButtonCornerRadius))
        }
        .buttonStyle(PushDownButtonStyle(shadowColor: .appSuccessShadow))
        .accessibilityLabel("保存")
        .padding(.horizontal, Layout.formPadding)
        .padding(.bottom, Layout.saveButtonBottomPadding)
        // 今の UIKit の画面と同じく、キーボードが出ても、ボタンをキーボードの上に持ち上げない
        .ignoresSafeArea(.keyboard)
    }

    /// 保存できたときに、画面の真ん中に出すチェックの印
    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: Layout.checkmarkSize))
            .foregroundStyle(Color.appSuccess)
            .scaleEffect(checkmarkScale)
            .opacity(checkmarkOpacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func save() {
        focusedField = nil
        if let error = viewModel.validate() {
            showValidationError(error)
            return
        }

        isSaving = true
        Task {
            await saveRecord()
        }
    }

    private func saveRecord() async {
        let newPhoto = selectedPhoto
        let photoResult = await Self.photoDataToSave(existingPhotoData: viewModel.existingPhotoData, newPhoto: newPhoto)

        // 写真を変換できなかった場合は保存しない（保存済みの写真を失わないため）
        guard case .success(let photoData) = photoResult else {
            isSaving = false
            showAlert(title: "保存エラー", message: "写真を保存できる形式に変換できませんでした。別の写真を選んでください。")
            return
        }

        if newPhoto != nil, let record = viewModel.recordToEdit {
            // 写真を差し替えるので、一覧に古いサムネイルが残らないようにする
            RecordCell.removeCachedImage(for: record)
        }

        guard case .saved(let shouldRequestReview) = viewModel.save(photoData: photoData) else {
            isSaving = false
            showAlert(title: "保存エラー", message: "データの保存に失敗しました。空き容量を確認してください。")
            return
        }

        showCheckmark()
        try? await Task.sleep(for: Layout.closeDelay)
        onSaved(shouldRequestReview)
    }

    /// 保存する写真のデータを決める。写真を選び直していなければ、保存済みのデータをそのまま使う（再圧縮しない）。
    /// 写真の変換は時間がかかるので、メインスレッドの外で行う
    @concurrent
    nonisolated private static func photoDataToSave(existingPhotoData: Data?, newPhoto: UIImage?) async -> Result<Data?, any Error> {
        Result {
            try RecordPhotoResolver.resolve(
                existingPhoto: existingPhotoData,
                didPickNewPhoto: newPhoto != nil,
                encodeNewPhoto: {
                    guard let newPhoto else { return nil }
                    return RecordPhotoEncoder.jpegData(from: newPhoto)
                }
            )
        }
    }

    private func showCheckmark() {
        withAnimation(.spring(duration: Layout.checkmarkAppearDuration, bounce: Layout.checkmarkBounce)) {
            checkmarkScale = Layout.checkmarkEndScale
            checkmarkOpacity = 1
        } completion: {
            withAnimation(.easeInOut(duration: Layout.checkmarkFadeDuration).delay(Layout.checkmarkFadeDelay)) {
                checkmarkOpacity = 0
            }
        }
    }

    // MARK: - Actions

    private func selectRamenType(_ ramenType: RamenType) {
        focusedField = nil
        // 前に選んでいたボタンを、元の大きさに戻す
        withAnimation(.easeInOut(duration: Layout.chipSelectDuration)) {
            viewModel.ramenType = ramenType
        }
        // 押したボタンを大きくしてから、選んだときの大きさに戻して弾ませる
        withAnimation(.spring(duration: Layout.chipBounceDuration, bounce: Layout.chipBounce)) {
            bouncingRamenType = ramenType
        } completion: {
            withAnimation(.spring(duration: Layout.chipBounceDuration, bounce: Layout.chipBounce)) {
                bouncingRamenType = nil
            }
        }
    }

    /// 入力のエラーを、該当する欄を揺らしてから、アラートで知らせる
    private func showValidationError(_ error: AddRecordViewModel.ValidationError) {
        if let field = Self.fieldToShake(for: error) {
            shakeCounts[field, default: 0] += 1
        }
        showAlert(title: "エラー", message: error.message)
    }

    /// エラーのときに揺らす欄。種類のエラーでは揺らさない（移行前と同じ）
    private static func fieldToShake(for error: AddRecordViewModel.ValidationError) -> Field? {
        switch error {
        case .storeNameEmpty, .storeNameTooLong: return .storeName
        case .ramenTypeNotSelected: return nil
        case .ratingNotSelected: return .rating
        case .commentTooLong: return .comment
        }
    }

    private func showAlert(title: String, message: String) {
        alertContent = AlertContent(title: title, message: message)
        isShowingAlert = true
    }

    /// 入力している欄の枠は、青くする
    private func borderColor(for field: Field) -> Color {
        focusedField == field ? .appSecondary : .appFieldBorder
    }

    fileprivate enum Layout {
        // SF Symbols のアイコンの大きさ。今の UIKit の画面と同じく、「テキストサイズ」の設定では変えない
        static let cameraIconSize: CGFloat = 40
        /// チェックの印の大きさ。今の UIKit の画面の、100pt 四方の印に合わせる
        static let checkmarkSize: CGFloat = 85

        static let formPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
        static let sectionTitleSpacing: CGFloat = 8
        static let sectionTitleLeadingPadding: CGFloat = 4
        static let sectionTitleKerning: CGFloat = 1.5

        static let fieldHeight: CGFloat = 48
        static let fieldHorizontalPadding: CGFloat = 16
        static let fieldCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 2

        static let chipSpacing: CGFloat = 8
        static let chipMinHeight: CGFloat = 44
        /// 種類のボタンの、文字の上下の余白（文字が大きいときに、ボタンの高さを決める）
        static let chipVerticalPadding: CGFloat = 10
        static let chipHorizontalPadding: CGFloat = 14
        static let chipBackgroundOpacity: CGFloat = 0.12
        static let chipSelectedScale: CGFloat = 1.05
        static let chipSelectDuration: TimeInterval = 0.2
        static let chipBounceScale: CGFloat = 1.1
        static let chipBounceDuration: TimeInterval = 0.12
        /// ばねの弾み（UIKit の画面の、ばねの減衰 0.4 に当たる）
        static let chipBounce: Double = 0.6

        static let starRowHeight: CGFloat = 50

        static let commentMinHeight: CGFloat = 100
        // コメントの欄の、文字のまわりの余白。TextEditor の中の余白と合わせて、今の UIKit の画面と同じにする
        static let commentHorizontalPadding: CGFloat = 12
        static let commentVerticalPadding: CGFloat = 4

        static let photoHeight: CGFloat = 200
        static let photoBorderOpacity: CGFloat = 0.3
        static let photoBackgroundOpacity: CGFloat = 0.1

        static let saveButtonHeight: CGFloat = 54
        static let saveButtonCornerRadius: CGFloat = 16
        static let saveButtonBottomPadding: CGFloat = 12
        /// 保存ボタンと、その上下の余白を合わせた高さ。スクロールの下の余白に使う
        static let saveButtonAreaHeight: CGFloat = 80

        static let checkmarkStartScale: CGFloat = 0.5
        static let checkmarkEndScale: CGFloat = 1.2
        static let checkmarkAppearDuration: TimeInterval = 0.3
        /// ばねの弾み（UIKit の画面の、ばねの減衰 0.6 に当たる）
        static let checkmarkBounce: Double = 0.4
        static let checkmarkFadeDelay: TimeInterval = 0.2
        static let checkmarkFadeDuration: TimeInterval = 0.2
        /// チェックの印を出してから、画面を閉じるまでの時間
        static let closeDelay: Duration = .seconds(0.5)

        /// 入力のエラーのときに、まず左にずらす幅
        static let shakeFirstOffset: CGFloat = -8
        /// shakeFirstOffset のあとに、順に動かす位置。左右に、だんだん小さくしながら揺らして、元の位置に戻す
        static let shakeOffsets: [CGFloat] = [8, -6, 6, -4, 4, 0]
        static let shakeDuration: TimeInterval = 0.4
    }
}

// MARK: - 種類のボタンの並べ方

/// 中の部品を横に並べ、どの部品も、いちばん広い部品と同じ幅にする
private struct EqualWidthHStack: Layout {

    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let itemSize = largestItemSize(of: subviews)
        let totalSpacing = spacing * CGFloat(subviews.count - 1)
        return CGSize(width: itemSize.width * CGFloat(subviews.count) + totalSpacing, height: itemSize.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let itemSize = largestItemSize(of: subviews)
        var x = bounds.minX
        for subview in subviews {
            subview.place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(itemSize))
            x += itemSize.width + spacing
        }
    }

    /// 部品ごとの、ちょうどよい大きさのうち、いちばん広い幅と、いちばん高い高さ
    private func largestItemSize(of subviews: Subviews) -> CGSize {
        subviews
            .map { $0.sizeThatFits(.unspecified) }
            .reduce(CGSize.zero) { largest, size in
                CGSize(width: max(largest.width, size.width), height: max(largest.height, size.height))
            }
    }
}

// MARK: - 入力の欄の見た目と動き

private extension View {

    /// 入力の欄の見た目（白い背景、角丸、枠）
    func inputFieldBackground(borderColor: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: AddRecordView.Layout.fieldCornerRadius)
        return background(Color.white, in: shape)
            .overlay {
                shape.strokeBorder(borderColor, lineWidth: AddRecordView.Layout.borderWidth)
            }
    }

    /// 押したときに、キーボードを閉じる。今の UIKit の画面と同じく、入力の欄の外を押したら閉じるため。
    /// カレンダー（DatePicker）には付けない。カレンダーの日付を押せなくなることがあるため
    func closesKeyboardOnTap<Field: Hashable>(_ focusedField: FocusState<Field?>.Binding) -> some View {
        simultaneousGesture(TapGesture().onEnded {
            focusedField.wrappedValue = nil
        })
    }

    /// 入力のエラーのときに、左右に揺らす。trigger の値が変わるたびに揺らす
    func shake(trigger: Int) -> some View {
        let offsets = AddRecordView.Layout.shakeOffsets
        let stepDuration = AddRecordView.Layout.shakeDuration / Double(offsets.count)
        return keyframeAnimator(initialValue: CGFloat(0), trigger: trigger) { content, offsetX in
            content.offset(x: offsetX)
        } keyframes: { _ in
            KeyframeTrack {
                MoveKeyframe(AddRecordView.Layout.shakeFirstOffset)
                for offset in offsets {
                    LinearKeyframe(offset, duration: stepDuration)
                }
            }
        }
    }
}
