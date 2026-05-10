//
//  DailyPracticeView.swift
//  aishuo
//
//  Created by cookie on 2026/5/7.
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

private let richShadow = Color(red: 0.24, green: 0.10, blue: 0.06).opacity(0.3)

// MARK: - 每日练习主视图
struct DailyPracticeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showRetellResult = false
    @State private var showOpinionResult = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 步骤指示器
                stepIndicator
                
                // 根据当前步骤显示不同内容
                switch viewModel.currentStep {
                case .reading:
                    readingView
                case .retelling:
                    if showRetellResult, let result = viewModel.lastPracticeResult {
                        retellResultView(scores: result.retellScores, feedback: result.retellFeedback, suggestions: result.retellSuggestions)
                    } else {
                        retellingInputView
                    }
                case .opinion:
                    if showOpinionResult, let result = viewModel.lastPracticeResult {
                        opinionResultView(scores: result.opinionScores, feedback: result.opinionFeedback)
                    } else {
                        opinionInputView
                    }
                case .completed:
                    if let result = viewModel.lastPracticeResult {
                        completedResultView(result: result)
                    }
                }
            }
            .padding()
        }
        .background(
            warmBg
                .ignoresSafeArea()
        )
        .navigationTitle("今日练习")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startDailyPractice()
        }
    }
    
    // MARK: - 步骤指示器
    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(Array(DailyPracticeStep.allCases.enumerated()), id: \.offset) { index, step in
                let stepIndex = DailyPracticeStep.allCases.firstIndex(of: viewModel.currentStep) ?? 0
                let isCompleted = index < stepIndex
                let isCurrent = index == stepIndex
                
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.green : isCurrent ? vibrantPurple : Color.gray.opacity(0.2))
                            .frame(width: 34, height: 34)
                            .shadow(color: isCurrent ? vibrantPurple.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(isCurrent ? .white : .gray)
                        }
                    }
                    
                    Text(step.rawValue)
                        .font(.system(size: 10, weight: isCurrent ? .semibold : .regular))
                        .foregroundColor(isCurrent ? vibrantPurple : .gray)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    if index < stepIndex {
                        goBackToStep(step)
                    }
                }
                
                if index < DailyPracticeStep.allCases.count - 1 {
                    Rectangle()
                        .fill(index < stepIndex ? Color.green : Color.gray.opacity(0.2))
                        .frame(height: 2)
                        .frame(maxWidth: 30)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }
    
    // MARK: - 阅读视图
    private var readingView: some View {
        VStack(spacing: 20) {
            // 内容卡片
            VStack(alignment: .leading, spacing: 16) {
                // 标题和分类
                HStack {
                    Text(viewModel.todayContent.category)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text(viewModel.todayContent.source)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text(viewModel.todayContent.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // 内容正文
                Text(viewModel.todayContent.content)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(8)
                    .opacity(1)
                
                // 关键点
                VStack(alignment: .leading, spacing: 8) {
                    Text("关键要点")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    ForEach(Array(viewModel.todayContent.keyPoints.enumerated()), id: \.offset) { index, point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "\(index + 1).circle.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(point)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.25, blue: 0.12),
                                Color(red: 0.70, green: 0.36, blue: 0.20),
                                Color(red: 0.48, green: 0.20, blue: 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: richShadow, radius: 20, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            
            // 操作按钮
            if viewModel.isLoading {
                // 加载中
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.isAISpeaking {
                // 朗读中
                HStack(spacing: 12) {
                    WaveformAnimation()
                        .frame(height: 16)
                    
                    Text("AI正在朗读...")
                        .font(.subheadline)
                        .foregroundColor(vibrantPurple)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.stopAISpeaking()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                                .font(.caption)
                            Text("停止")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.8))
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.12))
                )
            } else {
                // 默认：开始复述 + AI朗读 + 换一个
                VStack(spacing: 12) {
                    // 开始复述
                    Button(action: {
                        viewModel.proceedToRetelling()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.forward.circle.fill")
                                .font(.title2)
                            Text("开始复述")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [Color.green, Color.teal], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    HStack(spacing: 12) {
                        // AI朗读
                        Button(action: {
                            viewModel.startAISpeaking()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.circle.fill")
                                    .font(.subheadline)
                                Text("AI朗读")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                            )
                        }
                        
                        // 换一个
                        Button(action: {
                            viewModel.fetchNextContent()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.subheadline)
                                Text("换一个")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.12))
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 复述输入视图
    private var retellingInputView: some View {
        VStack(spacing: 20) {
            // 提示卡片
            VStack(alignment: .leading, spacing: 8) {
                Label("复述练习", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .foregroundColor(vibrantPurple)
                
                Text("请用自己的话复述刚才听到的故事/新闻内容，尽量完整地覆盖关键要点。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(vibrantPurple.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(vibrantPurple.opacity(0.15), lineWidth: 1)
            )
            
            // 录音按钮
            VStack(spacing: 16) {
                ZStack {
                    // 外圈脉冲动画
                    if viewModel.isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 4)
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseAnimation ? 1.2 : 0.9)
                            .opacity(pulseAnimation ? 0.5 : 1)
                    }
                    
                    Circle()
                        .fill(viewModel.isRecording ?
                              LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom) :
                              LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .top, endPoint: .bottom))
                        .frame(width: 100, height: 100)
                        .shadow(color: (viewModel.isRecording ? Color.red : vibrantPurple).opacity(0.4), radius: 15, x: 0, y: 5)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                .onTapGesture {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulseAnimation.toggle()
                        }
                    }
                }
                
                Text(viewModel.isRecording ? "点击停止录音" : "点击开始录音")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
            
            // 识别文本显示
            if !viewModel.retellText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("你的复述")
                        .font(.headline)
                        .foregroundColor(deepIndigo)
                    
                    Text(viewModel.retellText)
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
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
            
            // 提交按钮
            if viewModel.isEvaluating {
                if viewModel.streamingFeedback.isEmpty {
                    // 初始加载中
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(vibrantPurple)
                        Text("AI评测中...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground).opacity(0.85))
                    )
                } else {
                    // 流式反馈展示
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(vibrantPurple)
                            Text("AI实时评测")
                                .font(.headline)
                                .foregroundColor(deepIndigo)
                        }
                        
                        Text(viewModel.streamingFeedback)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(vibrantPurple.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(vibrantPurple.opacity(0.15), lineWidth: 0.5)
                    )
                }
            } else {
                Button(action: {
                    withAnimation {
                        viewModel.submitRetelling()
                        showRetellResult = true
                    }
                }) {
                    Text("提交复述")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.retellText.isEmpty ?
                            LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: viewModel.retellText.isEmpty ? .clear : vibrantPurple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.retellText.isEmpty)
            }
            
            // 返回按钮
            Button(action: { goBackToStep(.reading) }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                    Text("返回阅读")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - 复述结果
    private func retellResultView(scores: RetellScores, feedback: String, suggestions: [String]) -> some View {
        VStack(spacing: 20) {
            // 完成提示
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                }
                
                Text("复述完成！")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(deepIndigo)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
            
            // 评分卡片
            scoreCard(
                title: "复述评分",
                items: [
                    ("流畅度", scores.fluency, vibrantPurple),
                    ("准确性", scores.accuracy, Color.green),
                    ("完整性", scores.completeness, accentGold)
                ]
            )
            
            // 反馈
            feedbackCard(feedback: feedback, color: vibrantPurple)
            
            // AI提升建议
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(accentGold)
                        Text("AI提升建议")
                            .font(.headline)
                            .foregroundColor(deepIndigo)
                    }
                    
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(vibrantPurple)
                                .cornerRadius(10)
                            
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accentGold.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentGold.opacity(0.15), lineWidth: 0.5)
                )
            }
            
            // 继续按钮
            Button(action: {
                withAnimation {
                    showRetellResult = false
                    showOpinionResult = false
                    viewModel.proceedToRetelling()
                    viewModel.currentStep = .opinion
                }
            }) {
                HStack(spacing: 8) {
                    Text("发表看法")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: vibrantPurple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // 返回阅读
            Button(action: { goBackToStep(.reading) }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                    Text("返回重新阅读")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - 观点输入视图
    private var opinionInputView: some View {
        VStack(spacing: 20) {
            // 提示卡片
            VStack(alignment: .leading, spacing: 8) {
                Label("发表看法", systemImage: "quote.bubble.fill")
                    .font(.headline)
                    .foregroundColor(vibrantPurple)
                
                Text("请对刚才的故事/新闻发表你的看法。可以谈谈你的感受、评价，或者从中学到了什么。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(vibrantPurple.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(vibrantPurple.opacity(0.15), lineWidth: 1)
            )
            
            // 录音按钮
            VStack(spacing: 16) {
                ZStack {
                    if viewModel.isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 4)
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseAnimation ? 1.2 : 0.9)
                            .opacity(pulseAnimation ? 0.5 : 1)
                    }
                    
                    Circle()
                        .fill(viewModel.isRecording ?
                              LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom) :
                              LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .top, endPoint: .bottom))
                        .frame(width: 100, height: 100)
                        .shadow(color: (viewModel.isRecording ? Color.red : vibrantPurple).opacity(0.4), radius: 15, x: 0, y: 5)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                .onTapGesture {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulseAnimation.toggle()
                        }
                    }
                }
                
                Text(viewModel.isRecording ? "点击停止录音" : "点击开始录音")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
            
            // 识别文本显示
            if !viewModel.opinionText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("你的看法")
                        .font(.headline)
                        .foregroundColor(deepIndigo)
                    
                    Text(viewModel.opinionText)
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
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
            
            // 提交按钮
            Button(action: {
                withAnimation {
                    viewModel.submitOpinion()
                    showOpinionResult = true
                }
            }) {
                Text("提交看法")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        viewModel.opinionText.isEmpty ?
                        LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: viewModel.opinionText.isEmpty ? .clear : vibrantPurple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(viewModel.opinionText.isEmpty)
            
            // 返回按钮
            Button(action: { goBackToStep(.retelling) }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                    Text("返回复述")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - 观点结果
    private func opinionResultView(scores: OpinionScores, feedback: String) -> some View {
        VStack(spacing: 20) {
            // 完成提示
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(vibrantPurple.opacity(0.1))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(vibrantPurple)
                }
                
                Text("观点已提交！")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(deepIndigo)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
            
            // 评分卡片
            scoreCard(
                title: "观点评分",
                items: [
                    ("思考深度", scores.depth, vibrantPurple),
                    ("表达能力", scores.expression, accentGold),
                    ("思辨能力", scores.criticalThinking, deepIndigo)
                ]
            )
            
            // 反馈
            feedbackCard(feedback: feedback, color: vibrantPurple)
            
            // 查看完整报告
            Button(action: {
                withAnimation {
                    showOpinionResult = false
                    showRetellResult = false
                    viewModel.currentStep = .completed
                }
            }) {
                HStack(spacing: 8) {
                    Text("查看完整报告")
                        .font(.headline)
                    Image(systemName: "doc.text.fill")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: vibrantPurple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // 返回复述
            Button(action: { goBackToStep(.retelling) }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                    Text("返回修改复述")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - 完成结果视图
    private func completedResultView(result: DailyPracticeResult) -> some View {
        VStack(spacing: 24) {
            // 完成头
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: vibrantPurple.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 36))
                        .foregroundColor(accentGold)
                }
                
                Text("今日练习完成！")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(deepIndigo)
                
                Text(formatDate(Date()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .shadow(color: vibrantPurple.opacity(0.1), radius: 12, x: 0, y: 6)
            )
            
            // 综合分数
            let retellAvg = (result.retellScores.fluency + result.retellScores.accuracy + result.retellScores.completeness) / 3
            let opinionAvg = (result.opinionScores.depth + result.opinionScores.expression + result.opinionScores.criticalThinking) / 3
            let totalAvg = (retellAvg + opinionAvg) / 2
            
            VStack(spacing: 12) {
                Text("综合评分")
                    .font(.headline)
                    .foregroundColor(deepIndigo)
                
                Text(String(format: "%.1f", totalAvg))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(scoreColor(totalAvg))
                
                HStack(spacing: 32) {
                    VStack(spacing: 6) {
                        Text("复述")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", retellAvg))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(vibrantPurple)
                    }
                    
                    Rectangle()
                        .fill(deepIndigo.opacity(0.1))
                        .frame(width: 1, height: 40)
                    
                    VStack(spacing: 6) {
                        Text("观点")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", opinionAvg))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(accentGold)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
            
            // 复述评分
            scoreCard(
                title: "复述评分",
                items: [
                    ("流畅度", result.retellScores.fluency, vibrantPurple),
                    ("准确性", result.retellScores.accuracy, Color.green),
                    ("完整性", result.retellScores.completeness, accentGold)
                ]
            )
            
            feedbackCard(feedback: result.retellFeedback, color: vibrantPurple)
            
            // AI提升建议
            if !result.retellSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(accentGold)
                        Text("AI提升建议")
                            .font(.headline)
                            .foregroundColor(deepIndigo)
                    }
                    
                    ForEach(Array(result.retellSuggestions.enumerated()), id: \.offset) { index, suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(vibrantPurple)
                                .cornerRadius(10)
                            
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accentGold.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentGold.opacity(0.15), lineWidth: 0.5)
                )
            }
            
            // 观点评分
            scoreCard(
                title: "观点评分",
                items: [
                    ("思考深度", result.opinionScores.depth, vibrantPurple),
                    ("表达能力", result.opinionScores.expression, accentGold),
                    ("思辨能力", result.opinionScores.criticalThinking, deepIndigo)
                ]
            )
            
            feedbackCard(feedback: result.opinionFeedback, color: vibrantPurple)
            
            // 返回看法
            Button(action: { goBackToStep(.opinion) }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                    Text("返回修改看法")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // 返回按钮
            Button(action: { dismiss() }) {
                Text("完成")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: vibrantPurple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    // MARK: - 子组件
    private func scoreCard(title: String, items: [(String, Double, Color)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(deepIndigo)
                Text(title)
                    .font(.headline)
                    .foregroundColor(deepIndigo)
            }
            
            VStack(spacing: 16) {
                ForEach(items, id: \.0) { label, score, color in
                    VStack(spacing: 6) {
                        HStack {
                            Text(label)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f", score))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.12))
                                    .frame(height: 8)
                                
                                Capsule()
                                    .fill(color.gradient)
                                    .frame(width: geo.size.width * CGFloat(score / 100), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.85))
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }
    
    private func feedbackCard(feedback: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.title2)
                .foregroundColor(color)
            
            Text(feedback)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.15), lineWidth: 0.5)
        )
    }
    
    // MARK: - 方法
    private func goBackToStep(_ step: DailyPracticeStep) {
        withAnimation {
            showRetellResult = false
            showOpinionResult = false
            viewModel.goBackToStep(step)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 85 { return .green }
        else if score >= 70 { return .orange }
        else { return .red }
    }
}

// MARK: - 波形动画
struct WaveformAnimation: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 4, height: animate ? CGFloat.random(in: 10...50) : 15)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.08),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

#Preview {
    NavigationView {
        DailyPracticeView()
            .environmentObject(AppViewModel())
    }
}
