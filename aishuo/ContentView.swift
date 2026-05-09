//
//  ContentView.swift
//  aishuo
//
//  Created by cookie on 2026/4/16.
//

import SwiftUI

// MARK: - 主题色扩展
private extension Color {
    static let primaryBg = LinearGradient(colors: [
        Color(red: 0.20, green: 0.06, blue: 0.03),
        Color(red: 0.32, green: 0.10, blue: 0.05),
        Color(red: 0.42, green: 0.16, blue: 0.08)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    static let warmBg = LinearGradient(colors: [
        Color(red: 0.98, green: 0.97, blue: 0.95),
        Color(red: 0.95, green: 0.92, blue: 0.90)
    ], startPoint: .top, endPoint: .bottom)
    
    static let cardShadow = Color.black.opacity(0.12)
    static let richShadow = Color(red: 0.24, green: 0.10, blue: 0.06).opacity(0.3)
}

private let accentGold = Color(red: 1.0, green: 0.75, blue: 0.40)
private let deepIndigo = Color(red: 0.24, green: 0.10, blue: 0.06)
private let vibrantPurple = Color(red: 1.0, green: 0.416, blue: 0.333)

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("首页", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            TrainingView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("训练", systemImage: selectedTab == 1 ? "mic.fill" : "mic")
                }
                .tag(1)
            
            ReportsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("报告", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("我的", systemImage: selectedTab == 3 ? "person.fill" : "person")
                }
                .tag(3)
        }
        .tint(vibrantPurple)
    }
}

// MARK: - 首页
struct HomeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // 欢迎卡片
                    welcomeCard
                    
                    // 今日练习入口
                    dailyPracticeSection
                    
                    // Agent系统入口
                    agentsSection
                    
                    // 快速训练入口
                    quickTrainingSection
                    
                    // 最近训练报告
                    recentReportsSection
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(
                Color.warmBg
                    .ignoresSafeArea()
            )
            .navigationTitle("爱说")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("早安，\(viewModel.userProfile.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("今天也要加油练习口才哦！")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }
                
                Spacer()
                
                // 装饰圆
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                            .foregroundColor(accentGold)
                    )
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack(spacing: 0) {
                StatItem(icon: "clock.fill", value: String(format: "%.1f", viewModel.totalTrainingHours), label: "总时长(h)", color: .white)
                
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 40)
                
                StatItem(icon: "star.fill", value: "\(viewModel.userProfile.skillLevel)", label: "等级", color: accentGold)
                
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 40)
                
                StatItem(icon: "checkmark.circle.fill", value: "\(viewModel.thisWeekSessions)", label: "本周训练", color: .white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.primaryBg)
                .shadow(color: Color.richShadow, radius: 20, x: 0, y: 8)
        )
        .overlay(
            // 装饰光晕
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.15), .clear, .white.opacity(0.05)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.5
                )
        )
    }
    
    private var dailyPracticeSection: some View {
        NavigationLink(destination: DailyPracticeView().environmentObject(viewModel)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    // 标题
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "sun.max.fill")
                                .font(.caption)
                                .foregroundColor(accentGold)
                            Text("今日练习")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Text(viewModel.todayContent.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(viewModel.todayContent.category)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    
                    Spacer()
                    
                    // 换一个按钮 + 播放按钮
                    HStack(spacing: 8) {
                        Button(action: {
                            viewModel.fetchNextContent()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title3)
                                Text("换一个")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 52, height: 52)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(14)
                        }
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.1)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 52, height: 52)
                            
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .offset(x: 2)
                        }
                    }
                }
                
                // 预览文字
                Text(viewModel.todayContent.content.prefix(80) + "...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
                    .lineSpacing(4)
                
                // 特性标签
                HStack(spacing: 16) {
                    FeatureTag(icon: "waveform", text: "AI朗读", color: .white.opacity(0.7))
                    FeatureTag(icon: "mic", text: "语音复述", color: .white.opacity(0.7))
                    FeatureTag(icon: "star", text: "AI评分", color: .white.opacity(0.7))
                }
                .font(.caption2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.14, blue: 0.07),
                                Color(red: 0.52, green: 0.22, blue: 0.12),
                                Color(red: 0.30, green: 0.10, blue: 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: deepIndigo.opacity(0.4), radius: 16, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var agentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("智能体系统")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(AgentType.allCases) { agent in
                    AgentCard(agent: agent)
                }
            }
        }
    }
    
    private var quickTrainingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("快速训练")
            
            ForEach(TrainingType.allCases) { type in
                TrainingTypeCard(type: type)
            }
        }
    }
    
    private var recentReportsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("最近训练")
            
            if viewModel.trainingReports.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("暂无训练记录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
                .background(Color(.systemBackground).opacity(0.5))
                .cornerRadius(16)
            } else {
                ForEach(viewModel.trainingReports.prefix(3)) { report in
                    ReportCard(report: report)
                }
            }
        }
    }
}

// MARK: - 子组件
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct FeatureTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .foregroundColor(color)
    }
}

extension View {
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(Color(red: 0.24, green: 0.10, blue: 0.06))
            .padding(.top, 4)
    }
}

struct AgentCard: View {
    let agent: AgentType
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: agent.icon)
                .font(.title)
                .frame(width: 52, height: 52)
                .background(agent.color)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(color: deepIndigo.opacity(0.15), radius: 6, x: 0, y: 3)
            
            Text(agent.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground).opacity(0.8))
                .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
}

struct TrainingTypeCard: View {
    let type: TrainingType
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: type.icon)
                .font(.title2)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(colors: [deepIndigo, vibrantPurple],
                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                        .opacity(0.1)
                )
                .foregroundColor(vibrantPurple)
                .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("点击开始训练")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground).opacity(0.8))
                .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
}

struct ReportCard: View {
    let report: TrainingReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: report.trainingType.icon)
                        .font(.subheadline)
                        .foregroundColor(vibrantPurple)
                        .frame(width: 36, height: 36)
                        .background(vibrantPurple.opacity(0.1))
                        .cornerRadius(10)
                    
                    Text(report.trainingType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text(String(format: "%.1f分", report.score))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(report.score >= 80 ? .green : .orange)
            }
            
            Text(report.feedback)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                Text(formatDate(report.date))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground).opacity(0.8))
                .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
