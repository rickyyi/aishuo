//
//  ProfileView.swift
//  aishuo
//
//  Created by cookie on 2026/4/16.
//

import SwiftUI

// MARK: - 主题色
private let accentGold = Color(red: 1.0, green: 0.75, blue: 0.40)
private let deepIndigo = Color(red: 0.24, green: 0.10, blue: 0.06)
private let vibrantPurple = Color(red: 1.0, green: 0.416, blue: 0.333)

private let warmBg = LinearGradient(colors: [
    Color(red: 0.98, green: 0.97, blue: 0.95),
    Color(red: 0.95, green: 0.92, blue: 0.90)
], startPoint: .top, endPoint: .bottom)

private let cardShadow = Color.black.opacity(0.08)

struct ProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 用户信息卡片
                    userProfileCard
                    
                    // 打卡日历
                    contributionCalendar
                    
                    // 成就徽章
                    achievementsSection
                    
                    // 设置选项
                    settingsSection
                }
                .padding()
                .padding(.top, 8)
            }
            .background(warmBg.ignoresSafeArea())
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 用户信息卡片
    private var userProfileCard: some View {
        VStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: vibrantPurple.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                Image(systemName: viewModel.userProfile.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
            }
            
            // 用户名
            Text(viewModel.userProfile.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(deepIndigo)
            
            // 等级标签
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(accentGold)
                    .font(.caption)
                Text("Lv.\(viewModel.userProfile.skillLevel)")
                    .font(.headline)
                    .foregroundColor(accentGold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(accentGold.opacity(0.12))
            .cornerRadius(20)
            
            // 编辑按钮
            Button(action: { showEditProfile = true }) {
                Text("编辑资料")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(vibrantPurple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(vibrantPurple.opacity(0.3), lineWidth: 1)
                    )
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
                    .environmentObject(viewModel)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: cardShadow, radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(deepIndigo.opacity(0.06), lineWidth: 0.5)
        )
    }
    
    // MARK: - 打卡日历
    private var contributionCalendar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar.day.timeline.left")
                    .font(.caption)
                    .foregroundColor(vibrantPurple)
                Text("训练日历")
                    .font(.headline)
                    .foregroundColor(deepIndigo)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Lv.\(viewModel.userProfile.skillLevel)")
                        .font(.caption.bold())
                        .foregroundColor(accentGold)
                    Text("· 累计\(viewModel.userProfile.completedSessions)次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ContributionGrid(reports: viewModel.trainingReports)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 成就徽章
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("成就徽章")
                .font(.headline)
                .foregroundColor(deepIndigo)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 设置选项
    private var settingsSection: some View {
        VStack(spacing: 0) {
            ForEach(settingsItems) { item in
                SettingItem(item: item)
                
                if item.id < settingsItems.count {
                    Divider()
                        .padding(.leading, 50)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 成就徽章
    private var achievements: [Achievement] {
        [
            Achievement(icon: "mic.fill", name: "初次演讲", unlocked: viewModel.userProfile.completedSessions >= 1),
            Achievement(icon: "number.5.circle.fill", name: "五次训练", unlocked: viewModel.userProfile.completedSessions >= 5),
            Achievement(icon: "number.10.circle.fill", name: "十次训练", unlocked: viewModel.userProfile.completedSessions >= 10),
            Achievement(icon: "trophy.fill", name: "高手进阶", unlocked: viewModel.userProfile.skillLevel >= 5),
            Achievement(icon: "star.fill", name: "满分达人", unlocked: viewModel.trainingReports.contains { $0.score >= 95 }),
            Achievement(icon: "clock.fill", name: "时长达人", unlocked: viewModel.totalTrainingHours >= 10),
            Achievement(icon: "flame.fill", name: "连续训练", unlocked: false),
            Achievement(icon: "crown.fill", name: "口才大师", unlocked: viewModel.userProfile.skillLevel >= 8)
        ]
    }
    
    private var settingsItems: [SettingsItem] {
        [
            SettingsItem(id: 1, icon: "bell.fill", title: "训练提醒", color: .orange),
            SettingsItem(id: 2, icon: "gearshape.fill", title: "设置", color: .gray),
            SettingsItem(id: 3, icon: "questionmark.circle.fill", title: "帮助中心", color: .blue),
            SettingsItem(id: 4, icon: "info.circle.fill", title: "关于我们", color: .purple)
        ]
    }
}

// MARK: - 数据模型
struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let unlocked: Bool
}

struct SettingsItem: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let color: Color
}

// MARK: - 子组件
struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(
                    achievement.unlocked ?
                    LinearGradient(colors: [accentGold, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(achievement.unlocked ? accentGold.opacity(0.3) : Color.clear, lineWidth: 2)
                )
                .shadow(color: achievement.unlocked ? accentGold.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                .opacity(achievement.unlocked ? 1.0 : 0.4)
            
            Text(achievement.name)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(achievement.unlocked ? deepIndigo : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingItem: View {
    let item: SettingsItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(item.color.opacity(0.1))
                .foregroundColor(item.color)
                .cornerRadius(10)
            
            Text(item.title)
                .font(.body)
                .foregroundColor(deepIndigo)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding()
    }
}

// MARK: - 编辑资料
struct EditProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    
    init() {
        _name = State(initialValue: UserProfile.example.name)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    HStack {
                        Text("头像")
                        Spacer()
                        Image(systemName: viewModel.userProfile.avatar)
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    
                    TextField("用户名", text: $name)
                }
                
                Section(header: Text("统计信息")) {
                    HStack {
                        Text("训练次数")
                        Spacer()
                        Text("\(viewModel.userProfile.completedSessions)次")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("总时长")
                        Spacer()
                        Text(String(format: "%.1f小时", viewModel.totalTrainingHours))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("技能等级")
                        Spacer()
                        Text("Lv.\(viewModel.userProfile.skillLevel)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.userProfile.name = name
                        dismiss()
                    }
                }
            }
        }
    }
}


// MARK: - GitHub风格打卡日历（按月显示）
struct ContributionGrid: View {
    let reports: [TrainingReport]
    
    @State private var currentMonth: Date = Calendar.current.startOfDay(for: Date())
    
    private let calendar = Calendar.current
    
    // 颜色级别（橙色系）
    private let levelColors: [Color] = [
        Color(.systemGray5),                         // 0次
        Color(red: 1.0, green: 0.92, blue: 0.78),   // 1次
        Color(red: 1.0, green: 0.78, blue: 0.50),   // 2次
        Color(red: 1.0, green: 0.55, blue: 0.30),   // 3-4次
        Color(red: 0.85, green: 0.35, blue: 0.18)   // 5次+
    ]
    
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]
    
    var body: some View {
        VStack(spacing: 12) {
            // 月份切换
            monthHeader
            
            // 星期标签
            weekdayHeader
            
            // 日网格
            dayGrid
            
            // 图例
            legend
        }
    }
    
    // MARK: - 月份切换头
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.416, blue: 0.333))
                    .frame(width: 32, height: 32)
                    .background(Color(red: 1.0, green: 0.416, blue: 0.333).opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title3.weight(.bold))
                .foregroundColor(Color(red: 0.24, green: 0.10, blue: 0.06))
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.416, blue: 0.333))
                    .frame(width: 32, height: 32)
                    .background(Color(red: 1.0, green: 0.416, blue: 0.333).opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - 星期标签
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - 日网格
    private var dayGrid: some View {
        let dateCounts = aggregateReports()
        let days = daysInMonth()
        let firstWeekday = firstWeekdayOfMonth()  // 0=Sun, 1=Mon...
        let totalCells = days + firstWeekday
        let rows = Int(ceil(Double(totalCells) / 7.0))
        
        return VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let cellIndex = row * 7 + col
                        if cellIndex < firstWeekday {
                            // 当月第一天前的空白
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: cellSize + 8)
                        } else {
                            let day = cellIndex - firstWeekday + 1
                            if day <= days {
                                dayCell(day: day, dateCounts: dateCounts)
                            } else {
                                // 当月最后一天后的空白
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: cellSize + 8)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 单日格子
    private func dayCell(day: Int, dateCounts: [Date: Int]) -> some View {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let date = calendar.date(from: DateComponents(year: components.year, month: components.month, day: day)) else {
            return AnyView(Color.clear.frame(maxWidth: .infinity).frame(height: cellSize + 8))
        }
        let count = dateCounts[date] ?? 0
        let isToday = calendar.isDateInToday(date)
        
        return AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(contributionColor(for: count))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isToday ? Color(red: 1.0, green: 0.416, blue: 0.333) : Color.clear, lineWidth: 1.5)
                    )
                
                Text("\(day)")
                    .font(.system(size: 10, weight: count > 0 ? .semibold : .regular))
                    .foregroundColor(count > 0 ? .white : .secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: cellSize + 8)
        )
    }
    
    // MARK: - 聚合训练数据
    private func aggregateReports() -> [Date: Int] {
        var counts: [Date: Int] = [:]
        for report in reports {
            let date = calendar.startOfDay(for: report.date)
            counts[date, default: 0] += 1
        }
        return counts
    }
    
    // MARK: - 颜色计算
    private func contributionColor(for count: Int) -> Color {
        switch count {
        case 0:  return levelColors[0]
        case 1:  return levelColors[1]
        case 2:  return levelColors[2]
        case 3...4: return levelColors[3]
        default: return levelColors[4]
        }
    }
    
    // MARK: - 图例
    private var legend: some View {
        HStack(spacing: 6) {
            Spacer()
            Text("少")
                .font(.caption2)
                .foregroundColor(.secondary)
            ForEach(levelColors, id: \.self) { color in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
            Text("多")
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // MARK: - 日期计算
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }
    
    private func daysInMonth() -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return 30 }
        return range.count
    }
    
    private func firstWeekdayOfMonth() -> Int {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDate = calendar.date(from: components) else { return 0 }
        // 周日=1...周六=7, 转为 周日=0...周六=6
        return calendar.component(.weekday, from: firstDate) - 1
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    // MARK: - 尺寸常量
    private var cellSize: CGFloat { 28 }
}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
}
