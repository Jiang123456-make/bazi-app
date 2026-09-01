import SwiftUI

/// 出生地选择（省/地区 → 城市分组 + 搜索 + 默认「未知地区」）
struct PlacePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: String
    @State private var searchText = ""

    private let groups = PlaceData.grouped()

    var body: some View {
        NavigationStack {
            List {
                // 未知地区（默认北京时间）
                Section {
                    row(PlaceData.unknown)
                }
                ForEach(filteredGroups, id: \.province) { group in
                    Section(header: Text(group.province)) {
                        ForEach(group.cities) { city in
                            row(city)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索城市")
            .navigationTitle("选择出生地")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private var filteredGroups: [(province: String, cities: [Place])] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return groups }
        return groups
            .map { group in
                (group.province, group.cities.filter { $0.name.contains(q) || $0.province.contains(q) })
            }
            .filter { !$0.cities.isEmpty }
    }

    private func row(_ place: Place) -> some View {
        Button {
            selection = place.name
            dismiss()
        } label: {
            HStack {
                Text(place.name)
                    .font(BaziTheme.body())
                    .foregroundStyle(BaziTheme.ink)
                Spacer()
                if place.name == selection {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BaziTheme.actionBlue)
                }
            }
        }
    }
}
