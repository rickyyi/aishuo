//
//  TrainingView.swift
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

struct TrainingView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedScene: DialogueScene?
    @State private var showResult = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var animateMic = false
    
    var body: some View {
        NavigationView {
            Group {
                if let session = viewModel.dialogueSession {
                    if session.isCompleted {
                        dialogueResultView(session: session)
                    } else {
                        dialogueSessionView
                    }
                } else {
                    sceneSelectionView
                }
            }
            .navigationTitle("场景对话")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 场景选择
    private var sceneSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.and.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(vibrantPurple)
                        .frame(width: 70, height: 70)
                        .background(vibrantPurple.opacity(0.1))
                        .cornerRadius(20)
                    
                    Text("选择对话场景")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(deepIndigo)
                    
                    Text("模拟真实高压对话，AI会不断施压，锻炼你的临场反应")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                
                // 场景卡片
                ForEach(DialogueScene.presets) { scene in
                    SceneCard(
                        scene: scene,
                        isSelected: selectedScene?.id == scene.id
                    ) {
                        withAnimation(.spring()) {
                            selectedScene = scene
                        }
                    }
                }
                
                // 开始按钮
                Button(action: startDialogue) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                        Text("开始对话")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        selectedScene != nil ?
                        LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: selectedScene != nil ? vibrantPurple.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                }
                .disabled(selectedScene == nil)
                .padding(.top, 8)
            }
            .padding()
            .padding(.top, 8)
        }
        .background(warmBg.ignoresSafeArea())
    }
    
    // MARK: - 对话会话
    private var dialogueSessionView: some View {
        VStack(spacing: 0) {
            // 顶部信息栏
            topBar
            
            // 消息列表
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.dialogueSession?.messages ?? []) { message in
                            DialogueBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isAIThinking {
                            AIThinkingIndicator()
                                .id("thinking")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.dialogueSession?.messages.count) { _ in
                    if let last = viewModel.dialogueSession?.messages.last {
                        withAnimation {
                            scrollView.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isAIThinking) { thinking in
                    if thinking {
                        withAnimation {
                            scrollView.scrollTo("thinking", anchor: .bottom)
                        }
                    }
                }
            }
            
            // 输入区域
            inputBar
        }
        .background(warmBg.ignoresSafeArea())
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - 顶部栏
    private var topBar: some View {
        HStack(spacing: 12) {
            if let session = viewModel.dialogueSession {
                // 场景信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.scene.name)
                        .font(.headline)
                        .foregroundColor(deepIndigo)
                    HStack(spacing: 4) {
                        Text("第 \(session.currentRound) 轮")
                            .font(.caption)
                            .foregroundColor(vibrantPurple)
                        if session.canEnd {
                            Text("· 可结束")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // 计时器
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatTime(elapsedTime))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                
                // 结束按钮
                Button(action: endDialogue) {
                    Text("结束")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(session.canEnd ? vibrantPurple : Color.gray.opacity(0.4))
                        )
                }
                .disabled(!session.canEnd)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    // MARK: - 输入栏（语音）
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(deepIndigo.opacity(0.06))
            
            HStack(spacing: 12) {
                // 语音识别结果显示区域
                ZStack(alignment: .leading) {
                    if viewModel.isDialogueRecording {
                        // 录音中
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                                .font(.caption)
                                .foregroundColor(vibrantPurple)
                                .scaleEffect(animateMic ? 1.2 : 0.8)
                                .animation(
                                    Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                    value: animateMic
                                )
                            
                            Text(viewModel.dialogueTranscribedText.isEmpty ? "正在聆听..." : viewModel.dialogueTranscribedText)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(vibrantPurple.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(vibrantPurple.opacity(0.3), lineWidth: 1)
                        )
                    } else {
                        // 空闲状态
                        Text("按住说话")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
                .disabled(viewModel.isAIThinking)
                
                // 麦克风按钮
                Button(action: toggleRecording) {
                    Image(systemName: viewModel.isDialogueRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(
                            viewModel.isAIThinking ? .gray.opacity(0.4) :
                            (viewModel.isDialogueRecording ? vibrantPurple : deepIndigo)
                        )
                }
                .disabled(viewModel.isAIThinking)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground).opacity(0.95))
        }
        .onAppear { animateMic = true }
    }
    
    // MARK: - 对话结果
    private func dialogueResultView(session: DialogueSession) -> some View {
        ScrollView {
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
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    
                    Text("对话训练完成！")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(deepIndigo)
                    
                    Text("场景: \(session.scene.name) · 共 \(session.currentRound) 轮")
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
                
                // 分数
                VStack(spacing: 12) {
                    Text("综合评分")
                        .font(.headline)
                        .foregroundColor(deepIndigo)
                    
                    Text(String(format: "%.1f", session.score ?? 0))
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(scoreColor(session.score ?? 0))
                    
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("对话轮次")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(session.currentRound) 轮")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(vibrantPurple)
                        }
                        
                        Rectangle()
                            .fill(deepIndigo.opacity(0.1))
                            .frame(width: 1, height: 36)
                        
                        VStack(spacing: 4) {
                            Text("训练时长")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatTime(elapsedTime))
                                .font(.title3)
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
                        .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
                )
                
                // 反馈
                if let feedback = session.feedback {
                    feedbackCard(feedback: feedback)
                }
                
                // 对话记录预览
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "text.bubble.fill")
                            .font(.caption)
                            .foregroundColor(vibrantPurple)
                        Text("对话记录")
                            .font(.headline)
                            .foregroundColor(deepIndigo)
                    }
                    
                    ForEach(session.messages) { msg in
                        HStack(alignment: .top, spacing: 8) {
                            Text(msg.role.rawValue)
                                .font(.caption2.bold())
                                .foregroundColor(msg.role == .ai ? vibrantPurple : .green)
                                .frame(width: 20)
                            
                            Text(msg.content)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                        
                        if msg.id != session.messages.last?.id {
                            Divider()
                                .background(deepIndigo.opacity(0.05))
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground).opacity(0.85))
                        .shadow(color: cardShadow, radius: 8, x: 0, y: 4)
                )
                
                // 返回按钮
                Button(action: {
                    viewModel.resetDialogue()
                    stopTimer()
                    elapsedTime = 0
                }) {
                    Text("返回选择场景")
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
            .padding()
            .padding(.top, 8)
        }
        .background(warmBg.ignoresSafeArea())
    }
    
    // MARK: - 子组件
    private func feedbackCard(feedback: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.title2)
                .foregroundColor(vibrantPurple)
            
            Text(feedback)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(vibrantPurple.opacity(0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(vibrantPurple.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 85 { return .green }
        else if score >= 70 { return accentGold }
        else { return vibrantPurple }
    }
    
    // MARK: - 方法
    private func startDialogue() {
        guard let scene = selectedScene else { return }
        viewModel.startSceneDialogue(scene: scene)
        elapsedTime = 0
    }
    
    private func toggleRecording() {
        if viewModel.isDialogueRecording {
            // 停止录音 → 自动发送
            viewModel.stopDialogueRecording()
            let text = viewModel.dialogueTranscribedText.trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                viewModel.sendDialogueResponse(text: text)
                viewModel.dialogueTranscribedText = ""
            }
        } else {
            viewModel.startDialogueRecording()
        }
    }
    
    private func endDialogue() {
        stopTimer()
        viewModel.endSceneDialogue()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 场景卡片
struct SceneCard: View {
    let scene: DialogueScene
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ?
                            LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [deepIndigo.opacity(0.08), vibrantPurple.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: scene.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : vibrantPurple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? deepIndigo : .primary)
                    
                    Text(scene.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(scene.difficulty == "困难" ? vibrantPurple : accentGold)
                            .frame(width: 6, height: 6)
                        Text("\(scene.difficulty) · 最少\(scene.minRounds)轮")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(vibrantPurple)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .shadow(color: isSelected ? vibrantPurple.opacity(0.12) : cardShadow, radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? vibrantPurple.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 对话气泡
struct DialogueBubble: View {
    let message: DialogueMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                // AI头像
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "brain")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if message.isPressure && message.role == .ai {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(vibrantPurple)
                    }
                    
                    Text(message.role.rawValue)
                        .font(.caption2)
                        .foregroundColor(message.role == .ai ? vibrantPurple : .green)
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user ?
                        LinearGradient(colors: [deepIndigo, Color(red: 0.35, green: 0.15, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [vibrantPurple.opacity(0.85), Color(red: 0.85, green: 0.35, blue: 0.28)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            }
            
            if message.role == .ai {
                Spacer(minLength: 60)
            } else {
                // 用户头像
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - AI思考指示器
struct AIThinkingIndicator: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [deepIndigo, vibrantPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(vibrantPurple.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animate ? 1.2 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animate
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            
            Spacer(minLength: 60)
        }
        .onAppear { animate = true }
    }
}
