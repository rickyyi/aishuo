//
//  ReportsView.swift
//  aishuo
//
//  Created by cookie on 2026/4/16.
//

import SwiftUI
import Charts

// MARK: - 主题色
private let accentGold = Color(red: 1.0, green: 0.75, blue: 0.40)
private let deepIndigo = Color(red: 0.24, green: 0.10, blue: 0.06)
private let vibrantPurple = Color(red: 1.0, green: 0.416, blue: 0.333)

private let warmBg = LinearGradient(colors: [
    Color(red: 0.98, green: 0.97, blue: 0.95),
    Color(red: 0.95, green: 0.92, blue: 0.90)
], startPoint: .top, endPoint: .bottom)

private let cardShadow = Color.black.opacity(0.08)

struct ReportsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedTimeRange = 0
    let timeRanges = ["本周", "本月", "全部"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 时间范围选择
                    timeRangeSelector
                    
                    // 统计概览
                    statsOverview
                    
                    // 成绩趋势图
                    scoreTrendChart
                    
                    // 训练类型分布
                    trainingDistribution
                    
                    // 详细报告列表
                    detailedReportsList
                }
                .padding()
                .padding(.top, 8)
            }
            .background(warmBg.ignoresSafeArea())
            .navigationTitle("训练报告")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 时间范围选择
    private var timeRangeSelector: some View {
        HStack(spacing: 12) {
            ForEach(Array(timeRanges.enumerated()), id: \.offset) { index, range in
                Button(action: {
                    withAnimation {
                        selectedTimeRange = index
                    }
                }) {
                    Text(range)
                        .font(.subheadline)
                        .fontWeight(selectedTimeRange == index ? .semibold : .regular)
                        .foregroundColor(selectedTimeRange == index ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTimeRange == index {
                                    LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .leading, endPoint: .trailing)
                                } else {
                                    Color(.systemBackground)
                                }
                            }
                        )
                        .cornerRadius(20)
                        .shadow(color: selectedTimeRange == index ? vibrantPurple.opacity(0.25) : .clear, radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: cardShadow, radius: 6, x: 0, y: 3)
        )
    }
    
    // MARK: - 统计概览
    private var statsOverview: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(
                icon: "target.fill",
                title: "平均分数",
                value: String(format: "%.1f", viewModel.averageScore),
                unit: "分",
                color: .blue
            )
            
            StatCard(
                icon: "timer.fill",
                title: "总训练时长",
                value: String(format: "%.1f", viewModel.totalTrainingHours),
                unit: "小时",
                color: .purple
            )
            
            StatCard(
                icon: "checkmark.circle.fill",
                title: "完成次数",
                value: "\(viewModel.userProfile.completedSessions)",
                unit: "次",
                color: .green
            )
            
            StatCard(
                icon: "trophy.fill",
                title: "技能等级",
                value: "\(viewModel.userProfile.skillLevel)",
                unit: "级",
                color: .orange
            )
        }
    }
    
    // MARK: - 成绩趋势图
    private var scoreTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .foregroundColor(vibrantPurple)
                Text("成绩趋势")
                    .font(.headline)
                    .foregroundColor(deepIndigo)
            }
            
            if viewModel.trainingReports.count >= 2 {
                Chart {
                    ForEach(Array(viewModel.trainingReports.prefix(10).reversed().enumerated()), id: \.offset) { index, report in
                        LineMark(
                            x: .value("训练", index + 1),
                            y: .value("分数", report.score)
                        )
                        .foregroundStyle(vibrantPurple)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("训练", index + 1),
                            y: .value("分数", report.score)
                        )
                        .foregroundStyle(Gradient(colors: [vibrantPurple.opacity(0.3), vibrantPurple.opacity(0.05)]))
                    }
                }
                .frame(height: 200)
                .padding()
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground).opacity(0.85))
                        .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
                )
            } else {
                Text("至少需要2次训练记录才能显示趋势")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemBackground).opacity(0.85))
                            .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
                    )
            }
        }
    }
    
    // MARK: - 训练类型分布
    private var trainingDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.pie.fill")
                    .font(.caption)
                    .foregroundColor(vibrantPurple)
                Text("训练分布")
                    .font(.headline)
                    .foregroundColor(deepIndigo)
            }
            
            VStack(spacing: 16) {
                ForEach(TrainingType.allCases) { type in
                    let count = viewModel.trainingReports.filter { $0.trainingType == type }.count
                    let percentage = viewModel.trainingReports.isEmpty ? 0.0 : Double(count) / Double(viewModel.trainingReports.count) * 100
                    
                    TrainingTypeBar(
                        type: type,
                        count: count,
                        percentage: percentage
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - 详细报告列表
    private var detailedReportsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.clipboard.fill")
                    .font(.caption)
                    .foregroundColor(vibrantPurple)
                Text("训练记录")
                    .font(.headline)
                    .foregroundColor(deepIndigo)
            }
            
            if viewModel.trainingReports.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("暂无训练记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground).opacity(0.85))
                        .shadow(color: cardShadow, radius: 6, x: 0, y: 3)
                )
            } else {
                ForEach(viewModel.trainingReports) { report in
                    NavigationLink(destination: ReportDetailView(report: report)) {
                        ReportListItem(report: report)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - 子组件
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(deepIndigo)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: cardShadow, radius: 6, x: 0, y: 3)
        )
    }
}

struct TrainingTypeBar: View {
    let type: TrainingType
    let count: Int
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .font(.caption)
                    .foregroundColor(vibrantPurple)
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(count)次 (\(String(format: "%.0f", percentage))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct ReportListItem: View {
    let report: TrainingReport
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: report.trainingType.icon)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [deepIndigo.opacity(0.08), vibrantPurple.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundColor(vibrantPurple)
                .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(report.trainingType.rawValue)
                    .font(.headline)
                    .foregroundColor(deepIndigo)
                
                Text(formatDate(report.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f分", report.score))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(report.score >= 80 ? .green : accentGold)
                
                Text(formatDuration(report.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: cardShadow, radius: 6, x: 0, y: 3)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)分钟"
    }
}

// MARK: - 报告详情
struct ReportDetailView: View {
    let report: TrainingReport
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 基本信息
                basicInfoSection
                
                // 详细反馈
                feedbackSection
                
                // 改进建议
                improvementsSection
            }
            .padding()
        }
        .background(warmBg.ignoresSafeArea())
        .navigationTitle("训练详情")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(colors: [deepIndigo.opacity(0.1), vibrantPurple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: report.trainingType.icon)
                        .font(.title2)
                        .foregroundColor(vibrantPurple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.trainingType.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(deepIndigo)
                    Text(formatDate(report.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(String(format: "%.1f分", report.score))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(report.score >= 80 ? .green : accentGold)
            }
            
            Divider()
                .background(deepIndigo.opacity(0.08))
            
            HStack {
                VStack(spacing: 6) {
                    Text("训练时长")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(report.duration))
                        .font(.headline)
                        .foregroundColor(deepIndigo)
                }
                
                Spacer()
                
                VStack(spacing: 6) {
                    Text("训练类型")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(report.trainingType.rawValue)
                        .font(.headline)
                        .foregroundColor(deepIndigo)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.fill")
                    .font(.caption)
                    .foregroundColor(vibrantPurple)
                Text("Agent反馈")
                    .font(.headline)
                    .foregroundColor(deepIndigo)
            }
            
            Text(report.feedback)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(6)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(vibrantPurple.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(vibrantPurple.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
    
    private var improvementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundColor(accentGold)
                Text("改进建议")
                    .font(.headline)
                    .foregroundColor(deepIndigo)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(report.improvements.enumerated()), id: \.offset) { index, improvement in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 24, height: 24)
                            .background(
                                LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .foregroundColor(.white)
                            .clipShape(Circle())
                        
                        Text(improvement)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .shadow(color: cardShadow, radius: 6, x: 0, y: 3)
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d分%d秒", minutes, seconds)
    }
}

#Preview {
    ReportsView()
        .environmentObject(AppViewModel())
}
