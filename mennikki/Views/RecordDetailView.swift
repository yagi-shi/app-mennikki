//
//  RecordDetailView.swift
//  mennikki
//

import SwiftUI

/// 記録詳細画面
/// - 上部: 写真か、種類の色の背景（ヘッダー）
/// - 下部: 白い背景の情報エリア
///
/// 記録の読み込みや、画面に出す値の組み立ては RecordDetailViewModel が受け持つ。この画面は、表示だけを行う。
/// 編集画面を開くことと一覧に戻ることは、#27 の移行中は、この画面を入れている RecordDetailViewController が受け持つ
struct RecordDetailView: View {

    let viewModel: RecordDetailViewModel
    /// 編集ボタンを押したとき
    let onEdit: () -> Void
    /// 記録を削除できたとき
    let onDelete: () -> Void

    /// ヘッダーに出す写真。写真のデータを、メインスレッドの外で画像にしてから入れる
    @State private var headerPhoto: UIImage?
    /// 画面の幅。写真を出すときのヘッダーの高さを決めるのに使う
    @State private var contentWidth: CGFloat = 0
    @State private var isConfirmingDelete = false
    @State private var errorMessage: String?
    /// お気に入りのハートの大きさ。押したときに弾ませる
    @State private var favoriteIconScale: CGFloat = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                infoArea
            }
        }
        .scrollIndicators(.hidden)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            contentWidth = width
        }
        .background(Color.white)
        // タイトルは出さない。大きいタイトルの場所も空けない
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        // 写真が変わったときだけ読み直す（編集で写真を変えたとき）
        .task(id: viewModel.photoData) {
            await loadHeaderPhoto()
        }
        .alert("記録を削除しますか？", isPresented: $isConfirmingDelete) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) { deleteRecord() }
        } message: {
            Text("この操作は取り消せません")
        }
        .alert("エラー", isPresented: isShowingError, presenting: errorMessage) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - ヘッダー

    private var typeColor: Color {
        Color.colorForRamenType(viewModel.ramenType)
    }

    /// 写真か、種類の色の背景。写真を読み終わるまでは、種類の色の背景を出しておく
    @ViewBuilder
    private var header: some View {
        if let headerPhoto {
            Color.clear
                .frame(height: RecordDetailHeader.height(forPhotoSize: headerPhoto.size, width: contentWidth))
                .overlay {
                    Image(uiImage: headerPhoto)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
        } else {
            typeColor
                .frame(height: RecordDetailHeader.minHeight)
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.system(size: Layout.placeholderIconSize, weight: .thin))
                        .foregroundStyle(Color.white.opacity(Layout.placeholderIconOpacity))
                }
        }
    }

    private func loadHeaderPhoto() async {
        guard let photoData = viewModel.photoData else {
            headerPhoto = nil
            return
        }
        // 写真が変わったときは、読み終わるまで種類の色の背景に戻す
        headerPhoto = nil
        let decodedPhoto = await Self.decodePhoto(photoData)
        // 読んでいる間に写真が変わったときは、古い写真を出さない
        guard !Task.isCancelled else { return }
        headerPhoto = decodedPhoto
    }

    /// 写真のデータを、表示できる画像にする。大きい写真で画面が止まらないように、メインスレッドの外で行う
    @concurrent
    nonisolated private static func decodePhoto(_ photoData: Data) async -> UIImage? {
        guard let image = UIImage(data: photoData) else { return nil }
        return image.preparingForDisplay() ?? image
    }

    // MARK: - 情報エリア

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 一覧のカードでは省略するため、詳細では全文を出す
            Text(viewModel.storeName)
                .font(.appDetailTitle)
                .foregroundStyle(Color.appText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Layout.storeNameTopPadding)
                .padding(.horizontal, Layout.infoHorizontalPadding)

            typeTag
                .padding(.top, Layout.typeTagTopPadding)
                .padding(.horizontal, Layout.infoHorizontalPadding)

            starRating
                .padding(.top, Layout.starRatingTopPadding)
                .padding(.horizontal, Layout.infoHorizontalPadding)

            infoRows
                .padding(.top, Layout.infoRowsTopPadding)

            if let comment = viewModel.commentToShow {
                commentCard(comment)
                    .padding(.top, Layout.commentTopPadding)
                    .padding(.horizontal, Layout.commentHorizontalMargin)
            }
        }
        .padding(.bottom, Layout.bottomPadding)
    }

    private var typeTag: some View {
        Text(viewModel.ramenType.rawValue)
            .font(.appTag)
            .foregroundStyle(Color.white)
            .padding(.vertical, Layout.typeTagVerticalPadding)
            .padding(.horizontal, Layout.typeTagHorizontalPadding)
            .background(typeColor, in: RoundedRectangle(cornerRadius: Layout.typeTagCornerRadius))
    }

    /// 読むだけの星。評価がないときも、星の行の高さは空けておく（UIKit の画面と同じ見た目にするため）
    private var starRating: some View {
        HStack(spacing: Layout.starSpacing) {
            if let rating = viewModel.ratingToShow {
                ForEach(1...Layout.maxRating, id: \.self) { star in
                    let isFilled = star <= rating
                    Image(systemName: isFilled ? "star.fill" : "star")
                        .font(.system(size: Layout.starSize))
                        .foregroundStyle(isFilled ? Color.appSuccess : Color.appBorder)
                        .accessibilityLabel("\(star)星")
                        .accessibilityAddTraits(isFilled ? .isSelected : [])
                }
            }
        }
        .frame(height: Layout.starRowHeight)
    }

    /// 都道府県・訪問日・費用の行。値がある項目だけを、区切り線を挟んで並べる
    private var infoRows: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.infoRows, id: \.kind) { row in
                if row.kind != viewModel.infoRows.first?.kind {
                    Rectangle()
                        .fill(Color.appBorder)
                        .frame(height: Layout.dividerHeight)
                }
                infoRow(row)
            }
        }
    }

    private func infoRow(_ row: RecordDetailViewModel.InfoRow) -> some View {
        let style = Self.infoRowStyle(for: row.kind)
        return HStack(spacing: Layout.infoRowIconTextSpacing) {
            Image(systemName: style.icon)
                .font(.system(size: Layout.infoIconSize, weight: .semibold))
                .foregroundStyle(style.color)
                .frame(width: Layout.infoIconFrameSize, height: Layout.infoIconFrameSize)

            VStack(alignment: .leading, spacing: Layout.infoRowTitleValueSpacing) {
                Text(row.title)
                    .font(.appCaption)
                    .foregroundStyle(Color.appSecondaryText)
                // 文字が大きくて入りきらないときは折り返す
                Text(row.value)
                    .font(.appInfoValue)
                    .foregroundStyle(Color.appText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Layout.infoRowVerticalPadding)
        .padding(.horizontal, Layout.infoHorizontalPadding)
        // 文字が小さいときは最低の高さにし、大きいときは文字に合わせて高くする
        .frame(minHeight: Layout.infoRowMinHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.title)、\(row.value)")
    }

    /// 情報行の種類ごとの、アイコン（SF Symbols 名）と色
    private static func infoRowStyle(for kind: RecordDetailViewModel.InfoRow.Kind) -> (icon: String, color: Color) {
        switch kind {
        case .prefecture: return (icon: "mappin.circle", color: .appPrimary)
        case .visitDate: return (icon: "calendar", color: .appSecondary)
        case .cost: return (icon: "yensign.circle", color: .appSuccess)
        }
    }

    private func commentCard(_ comment: String) -> some View {
        Text(comment)
            .font(.appBody)
            .foregroundStyle(Color.appText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Layout.commentPadding)
            .background(Color.appBackground, in: RoundedRectangle(cornerRadius: Layout.commentCornerRadius))
    }

    // MARK: - ナビゲーションバー

    /// 右から、編集、お気に入り、削除の順に並べる
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                isConfirmingDelete = true
            } label: {
                Image(systemName: "trash")
            }
            .tint(Color.appPrimary)
            .accessibilityLabel("記録を削除")

            Button {
                toggleFavorite()
            } label: {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: Layout.favoriteIconSize))
                    .scaleEffect(favoriteIconScale)
            }
            .tint(viewModel.isFavorite ? Color.appPrimary : Color.appSecondaryText)
            .accessibilityLabel(viewModel.isFavorite ? "お気に入り解除" : "お気に入り登録")

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
            }
            .tint(Color.appSecondaryText)
            .accessibilityLabel("記録を編集")
        }
    }

    // MARK: - Actions

    private func toggleFavorite() {
        guard viewModel.toggleFavorite() else {
            errorMessage = "お気に入りの変更に失敗しました"
            return
        }
        // ハートを大きくしてから、元の大きさに戻して弾ませる
        withAnimation(.spring(duration: Layout.favoriteBounceDuration, bounce: Layout.favoriteBounce)) {
            favoriteIconScale = Layout.favoriteBounceScale
        } completion: {
            withAnimation(.spring(duration: Layout.favoriteBounceDuration, bounce: Layout.favoriteBounce)) {
                favoriteIconScale = 1
            }
        }
    }

    private func deleteRecord() {
        guard viewModel.deleteRecord() else {
            errorMessage = "記録の削除に失敗しました"
            return
        }
        onDelete()
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isShowing in
                if !isShowing { errorMessage = nil }
            }
        )
    }

    private enum Layout {
        // SF Symbols のアイコンの大きさ。今の UIKit の画面と同じく、「テキストサイズ」の設定では変えない
        static let placeholderIconSize: CGFloat = 60
        static let placeholderIconOpacity: CGFloat = 0.6
        static let favoriteIconSize: CGFloat = 18
        static let starSize: CGFloat = 32
        static let infoIconSize: CGFloat = 16
        /// 情報行のアイコンを置く枠。項目名と値の左端を、行ごとにそろえる
        static let infoIconFrameSize: CGFloat = 22

        static let maxRating = 5
        static let starSpacing: CGFloat = 8
        static let starRowHeight: CGFloat = 44

        static let infoHorizontalPadding: CGFloat = 20
        static let storeNameTopPadding: CGFloat = 20
        static let typeTagTopPadding: CGFloat = 10
        static let typeTagVerticalPadding: CGFloat = 4
        static let typeTagHorizontalPadding: CGFloat = 10
        static let typeTagCornerRadius: CGFloat = 11
        static let starRatingTopPadding: CGFloat = 16
        static let infoRowsTopPadding: CGFloat = 4

        static let infoRowMinHeight: CGFloat = 60
        /// 情報行の、文字の上下の余白
        static let infoRowVerticalPadding: CGFloat = 12
        static let infoRowIconTextSpacing: CGFloat = 14
        static let infoRowTitleValueSpacing: CGFloat = 2
        static let dividerHeight: CGFloat = 1

        static let commentTopPadding: CGFloat = 16
        static let commentHorizontalMargin: CGFloat = 16
        static let commentPadding: CGFloat = 16
        static let commentCornerRadius: CGFloat = 16
        static let bottomPadding: CGFloat = 32

        /// お気に入りを押したときに、ハートを何倍まで大きくするか
        static let favoriteBounceScale: CGFloat = 1.4
        static let favoriteBounceDuration: TimeInterval = 0.12
        /// ばねの弾み（UIKit の画面の、ばねの減衰 0.4 に当たる）
        static let favoriteBounce: Double = 0.6
    }
}
