//
//  AppViewModel.swift
//  aishuo
//
//  Created by cookie on 2026/4/16.
//

import SwiftUI
import Foundation
import Combine
import Speech
import AVFoundation

class AppViewModel: ObservableObject {
    @Published var userProfile: UserProfile
    @Published var trainingReports: [TrainingReport]
    @Published var currentSession: TrainingSession?
    @Published var selectedAgent: AgentType?
    
    // MARK: - 网络加载状态
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - 每日练习状态
    @Published var todayContent: DailyContent
    @Published var currentStep: DailyPracticeStep = .reading
    @Published var retellText: String = ""
    @Published var opinionText: String = ""
    @Published var isRecording: Bool = false
    @Published var isAISpeaking: Bool = false
    @Published var lastPracticeResult: DailyPracticeResult?
    @Published var dailyPracticeDone: Bool = false
    @Published var transcribedText: String = ""
    @Published var isEvaluating: Bool = false
    @Published var streamingFeedback: String = ""
    
    // MARK: - 场景对话状态
    @Published var dialogueSession: DialogueSession?
    @Published var isAIThinking: Bool = false
    @Published var isGeneratingScenario: Bool = false
    @Published var scenarioCaseText: String = ""
    @Published var aiStreamingText: String = ""
    @Published var isEvaluatingDialogue: Bool = false
    @Published var scenarioGenerateError: String?
    
    // MARK: - 语音识别
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // 场景对话语音
    @Published var isDialogueRecording: Bool = false
    @Published var dialogueTranscribedText: String = ""
    
    init() {
        // 从UserDefaults加载数据或创建示例数据
        self.userProfile = UserProfile.example
        self.trainingReports = [TrainingReport.example]
        // 先用本地内容作为默认值
        self.todayContent = DailyContentProvider.contentForDate(Date())
        // 异步从服务器加载每日内容
        loadTodayContentFromServer()
    }
    
    // MARK: - 训练管理
    func startTraining(type: TrainingType) {
        currentSession = TrainingSession(type: type)
    }
    
    func completeTraining(score: Double, feedback: String, improvements: [String]) {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        session.isCompleted = true
        session.score = score
        
        let report = TrainingReport(
            id: UUID(),
            date: Date(),
            trainingType: session.type,
            duration: session.endTime!.timeIntervalSince(session.startTime),
            score: score,
            feedback: feedback,
            improvements: improvements
        )
        
        trainingReports.insert(report, at: 0)
        
        // 更新用户档案
        userProfile.completedSessions += 1
        userProfile.totalTrainingTime += report.duration
        
        // 根据平均分更新技能等级
        let avgScore = trainingReports.reduce(0) { $0 + $1.score } / Double(trainingReports.count)
        userProfile.skillLevel = min(10, max(1, Int(avgScore / 10)))
        
        currentSession = nil
    }
    
    func cancelTraining() {
        currentSession = nil
    }
    
    // MARK: - 场景对话管理
    func startSceneDialogue(scene: DialogueScene) {
        isGeneratingScenario = true
        scenarioCaseText = ""
        scenarioGenerateError = nil
        errorMessage = nil
        isEvaluatingDialogue = false
        
        Task {
            do {
                let generatedCase = try await ApiService.shared.startScenarioStream(
                    sceneName: scene.name,
                    sceneDescription: scene.description,
                    difficulty: scene.difficulty
                ) { token in
                    Task { @MainActor in
                        self.scenarioCaseText += token
                    }
                }
                
                await MainActor.run {
                    dialogueSession = DialogueSession(scene: scene, initialMessage: generatedCase)
                    isGeneratingScenario = false
                    scenarioCaseText = ""
                }
            } catch {
                await MainActor.run {
                    // LLM 生成失败时使用本地预设 prompt
                    dialogueSession = DialogueSession(scene: scene)
                    isGeneratingScenario = false
                    scenarioCaseText = ""
                    scenarioGenerateError = nil
                }
            }
        }
    }
    
    func sendDialogueResponse(text: String) {
        guard var session = dialogueSession, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        
        // 追加用户消息
        let userMsg = DialogueMessage(role: .user, content: trimmedText, isPressure: false, timestamp: Date())
        session.messages.append(userMsg)
        dialogueSession = session
        
        // AI思考中，准备流式
        isAIThinking = true
        aiStreamingText = ""
        let scene = session.scene
        
        // 构建消息历史
        let allMessages: [(role: String, content: String)] = session.messages.map { msg in
            (role: msg.role == .ai ? "AI" : "user", content: msg.content)
        }
        
        Task {
            do {
                let fullResponse = try await ApiService.shared.chatScenarioStream(
                    sceneName: scene.name,
                    sceneDescription: scene.description,
                    difficulty: scene.difficulty,
                    messages: allMessages
                ) { token in
                    Task { @MainActor in
                        self.aiStreamingText += token
                    }
                }
                
                await MainActor.run {
                    let aiMsg = DialogueMessage(role: .ai, content: fullResponse, isPressure: true, timestamp: Date())
                    var updatedSession = self.dialogueSession
                    updatedSession?.messages.append(aiMsg)
                    self.dialogueSession = updatedSession
                    self.isAIThinking = false
                    self.aiStreamingText = ""
                }
            } catch {
                // LLM 调用失败时使用本地模板降级
                await MainActor.run {
                    let round = session.currentRound
                    let aiText = PressureTemplates.response(for: scene, round: round, userText: trimmedText)
                    let interruptPrefixes = ["打断一下，", "等等，", "我插一句，", "不好意思，", "且慢，"]
                    let finalText = Bool.random() ? "\(interruptPrefixes.randomElement() ?? "")\(aiText)" : aiText
                    let aiMsg = DialogueMessage(role: .ai, content: finalText, isPressure: true, timestamp: Date())
                    var updatedSession = self.dialogueSession
                    updatedSession?.messages.append(aiMsg)
                    self.dialogueSession = updatedSession
                    self.isAIThinking = false
                    self.aiStreamingText = ""
                }
            }
        }
    }
    
    func endSceneDialogue() {
        guard let session = dialogueSession else { return }
        
        if !session.canEnd {
            errorMessage = "至少需要 \(session.scene.minRounds) 轮对话才能结束"
            return
        }
        
        errorMessage = nil
        
        let duration = Date().timeIntervalSince(session.startTime)
        let totalRounds = session.currentRound
        isEvaluatingDialogue = true
        
        let messages: [(role: String, content: String)] = session.messages.map { msg in
            (role: msg.role == .ai ? "AI" : "user", content: msg.content)
        }
        
        Task {
            do {
                let evaluation = try await ApiService.shared.evaluateScenario(
                    sceneName: session.scene.name,
                    sceneDescription: session.scene.description,
                    roundCount: totalRounds,
                    duration: duration,
                    messages: messages
                )
                
                await MainActor.run {
                    var updatedSession = dialogueSession
                    updatedSession?.isCompleted = true
                    updatedSession?.score = evaluation.overallScore
                    updatedSession?.feedback = evaluation.feedback
                    updatedSession?.suggestions = evaluation.suggestions
                    updatedSession?.evaluation = evaluation
                    dialogueSession = updatedSession
                    isEvaluatingDialogue = false
                    
                    // 保存训练报告
                    let report = TrainingReport(
                        id: UUID(),
                        date: Date(),
                        trainingType: .sceneDialogue,
                        duration: duration,
                        score: evaluation.overallScore,
                        feedback: evaluation.feedback,
                        improvements: evaluation.suggestions
                    )
                    trainingReports.insert(report, at: 0)
                    
                    userProfile.completedSessions += 1
                    userProfile.totalTrainingTime += duration
                    let avgScore = trainingReports.reduce(0) { $0 + $1.score } / Double(trainingReports.count)
                    userProfile.skillLevel = min(10, max(1, Int(avgScore / 10)))
                }
            } catch {
                // API 失败时使用本地降级评测
                await MainActor.run {
                    let roundScore = min(Double(totalRounds) / Double(session.scene.minRounds) * 60, 60)
                    let avgLength = session.messages
                        .filter { $0.role == .user }
                        .map { Double($0.content.count) }
                        .reduce(0, +) / max(Double(totalRounds), 1)
                    let qualityScore = min(avgLength / 30 * 40, 40)
                    let totalScore = roundScore + qualityScore
                    
                    let feedbacks = [
                        "你在对话中展现了不错的应变能力，面对施压时保持了冷静。建议在关键论据上准备更充分的数据支撑。",
                        "表达流畅，逻辑清晰，面对质疑时能迅速组织语言。可以尝试更多角度思考问题。",
                        "应对压力时略显紧张，但整体回答结构完整。建议多做实战练习，增强临场反应。",
                        "你的反驳有力度，能够抓住对方逻辑漏洞。注意控制语气，保持专业和礼貌的平衡。",
                        "对话节奏把握不错，能主动引导话题。在细节层面还可以更深入一些。"
                    ]
                    let feedback = feedbacks.randomElement() ?? "表现良好，继续加油！"
                    
                    var updatedSession = dialogueSession
                    updatedSession?.isCompleted = true
                    updatedSession?.score = totalScore
                    updatedSession?.feedback = feedback
                    dialogueSession = updatedSession
                    isEvaluatingDialogue = false
                    
                    let report = TrainingReport(
                        id: UUID(),
                        date: Date(),
                        trainingType: .sceneDialogue,
                        duration: duration,
                        score: totalScore,
                        feedback: feedback,
                        improvements: [
                            "注意在压力下保持逻辑连贯性",
                            "准备更多事实和数据进行支撑",
                            "练习主动引导对话方向",
                            "控制语气，保持专业态度"
                        ]
                    )
                    trainingReports.insert(report, at: 0)
                    
                    userProfile.completedSessions += 1
                    userProfile.totalTrainingTime += duration
                    let avgScore = trainingReports.reduce(0) { $0 + $1.score } / Double(trainingReports.count)
                    userProfile.skillLevel = min(10, max(1, Int(avgScore / 10)))
                }
            }
        }
    }
    
    func resetDialogue() {
        dialogueSession = nil
        isAIThinking = false
        aiStreamingText = ""
        isEvaluatingDialogue = false
        errorMessage = nil
        scenarioGenerateError = nil
    }
    
    // MARK: - 统计信息
    var totalTrainingHours: Double {
        return userProfile.totalTrainingTime / 3600.0
    }
    
    var averageScore: Double {
        guard !trainingReports.isEmpty else { return 0 }
        return trainingReports.reduce(0) { $0 + $1.score } / Double(trainingReports.count)
    }
    
    var thisWeekSessions: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return trainingReports.filter { $0.date >= weekAgo }.count
    }
    
    // MARK: - 从服务器加载每日内容
    func loadTodayContentFromServer() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await loadContent {
                try await ApiService.shared.fetchTodayContent()
            }
        }
    }
    
    /// 加载下一条内容（强制刷新）
    func fetchNextContent() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await loadContent {
                try await ApiService.shared.fetchNextContent()
            }
        }
    }
    
    /// 通用的内容加载方法
    private func loadContent(from fetchTask: () async throws -> DailyContent) async {
        do {
            let content = try await fetchTask()
            await MainActor.run {
                self.todayContent = content
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - 每日练习管理
    func startDailyPractice() {
        currentStep = .reading
        retellText = ""
        opinionText = ""
        transcribedText = ""
        lastPracticeResult = nil
        dailyPracticeDone = false
    }
    
    func startAISpeaking() {
        isAISpeaking = true
        // 模拟AI朗读（1.5秒后完成，停留在阅读视图等待用户手动进入复述）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isAISpeaking = false
        }
    }
    
    func proceedToRetelling() {
        currentStep = .retelling
    }
    
    func goBackToStep(_ step: DailyPracticeStep) {
        currentStep = step
        switch step {
        case .reading:
            retellText = ""
            opinionText = ""
            transcribedText = ""
            lastPracticeResult = nil
            dailyPracticeDone = false
        case .retelling:
            opinionText = ""
            transcribedText = ""
        case .opinion, .completed:
            break
        }
    }
    
    // MARK: - 语音识别
    func startRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else { return }
                self.beginRecording()
            }
        }
    }
    
    private func beginRecording() {
        guard let speechRecognizer = speechRecognizer else { return }
        
        // 取消之前的识别任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
                
                if isFinal {
                    // 将识别的文本赋给对应的字段
                    if self.currentStep == .retelling {
                        self.retellText = self.transcribedText
                    } else if self.currentStep == .opinion {
                        self.opinionText = self.transcribedText
                    }
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            isRecording = false
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        
        // 将当前识别的文本赋给对应字段
        if currentStep == .retelling {
            retellText = transcribedText
        } else if currentStep == .opinion {
            opinionText = transcribedText
        }
    }
    
    // MARK: - 场景对话语音识别
    func startDialogueRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else { return }
        
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else { return }
                
                self.recognitionTask?.cancel()
                self.recognitionTask = nil
                self.dialogueTranscribedText = ""
                
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch { return }
                
                self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = self.recognitionRequest else { return }
                recognitionRequest.shouldReportPartialResults = true
                
                let inputNode = self.audioEngine.inputNode
                
                self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                    if let result = result {
                        self.dialogueTranscribedText = result.bestTranscription.formattedString
                    }
                    if error != nil || result?.isFinal == true {
                        self.audioEngine.stop()
                        inputNode.removeTap(onBus: 0)
                        self.recognitionRequest = nil
                        self.recognitionTask = nil
                        self.isDialogueRecording = false
                    }
                }
                
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    self.recognitionRequest?.append(buffer)
                }
                
                self.audioEngine.prepare()
                do {
                    try self.audioEngine.start()
                    self.isDialogueRecording = true
                } catch {
                    self.isDialogueRecording = false
                }
            }
        }
    }
    
    func stopDialogueRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isDialogueRecording = false
        // transcribedText 已经在回调中更新，无需额外赋值
    }
    
    // MARK: - 提交评分
    func submitRetelling() {
        isEvaluating = true
        streamingFeedback = ""
        
        Task {
            do {
                let response = try await ApiService.shared.evaluateRetellStream(
                    contentId: todayContent.id,
                    originalTitle: todayContent.title,
                    originalContent: todayContent.content,
                    keyPoints: todayContent.keyPoints,
                    retellText: retellText
                ) { token in
                    Task { @MainActor in
                        self.streamingFeedback += token
                    }
                }
                
                let scores = RetellScores(
                    fluency: response.fluency,
                    accuracy: response.accuracy,
                    completeness: response.completeness
                )
                
                await MainActor.run {
                    let result = DailyPracticeResult(
                        contentId: todayContent.id,
                        date: Date(),
                        retellScores: scores,
                        opinionScores: OpinionScores(depth: 0, expression: 0, criticalThinking: 0),
                        retellFeedback: response.feedback,
                        opinionFeedback: "",
                        combinedFeedback: "",
                        retellSuggestions: response.suggestions
                    )
                    lastPracticeResult = result
                    transcribedText = ""
                    isEvaluating = false
                    streamingFeedback = ""
                }
            } catch {
                // SSE 流失败时降级为非流式
                await MainActor.run {
                    self.streamingFeedback = ""
                }
                await fallbackRetelling()
            }
        }
    }
    
    /// SSE 流失败时的降级方案
    private func fallbackRetelling() async {
        do {
            let response = try await ApiService.shared.evaluateRetell(
                contentId: todayContent.id,
                originalTitle: todayContent.title,
                originalContent: todayContent.content,
                keyPoints: todayContent.keyPoints,
                retellText: retellText
            )
            
            let scores = RetellScores(
                fluency: response.fluency,
                accuracy: response.accuracy,
                completeness: response.completeness
            )
            
            await MainActor.run {
                let result = DailyPracticeResult(
                    contentId: todayContent.id,
                    date: Date(),
                    retellScores: scores,
                    opinionScores: OpinionScores(depth: 0, expression: 0, criticalThinking: 0),
                    retellFeedback: response.feedback,
                    opinionFeedback: "",
                    combinedFeedback: "",
                    retellSuggestions: response.suggestions
                )
                lastPracticeResult = result
                currentStep = .opinion
                transcribedText = ""
                isEvaluating = false
            }
        } catch {
            await MainActor.run {
                // API 完全失败时使用本地模拟评分
                let scores = generateRetellScores(text: retellText)
                let feedback = generateRetellFeedback(scores: scores)
                let result = DailyPracticeResult(
                    contentId: todayContent.id,
                    date: Date(),
                    retellScores: scores,
                    opinionScores: OpinionScores(depth: 0, expression: 0, criticalThinking: 0),
                    retellFeedback: feedback,
                    opinionFeedback: "",
                    combinedFeedback: "",
                    retellSuggestions: ["尝试在复述中加入更多原文的具体数据和细节", "注意文章的逻辑结构", "多用连接词使表达更加流畅自然"]
                )
                lastPracticeResult = result
                currentStep = .opinion
                transcribedText = ""
                isEvaluating = false
                streamingFeedback = ""
                errorMessage = "评测服务暂时不可用，已使用本地评分"
            }
        }
    }
    
    func submitOpinion() {
        guard var result = lastPracticeResult else { return }
        let scores = generateOpinionScores(text: opinionText)
        let feedback = generateOpinionFeedback(scores: scores)
        let combined = "今日练习完成！"
        
        result = DailyPracticeResult(
            contentId: todayContent.id,
            date: Date(),
            retellScores: result.retellScores,
            opinionScores: scores,
            retellFeedback: result.retellFeedback,
            opinionFeedback: feedback,
            combinedFeedback: combined,
            retellSuggestions: result.retellSuggestions
        )
        
        lastPracticeResult = result
        currentStep = .completed
        dailyPracticeDone = true
    }
    
    // MARK: - 模拟评分
    private func generateRetellScores(text: String) -> RetellScores {
        let wordCount = text.count
        let baseScore = Double.random(in: 65...90)
        
        // 根据内容长度调整分数
        let contentLengthBonus = min(Double(wordCount) / Double(todayContent.content.count) * 100, 100)
        
        return RetellScores(
            fluency: min(baseScore + Double.random(in: -5...5), 100),
            accuracy: min(contentLengthBonus * 0.9 + Double.random(in: -10...10), 100),
            completeness: min(contentLengthBonus * 0.85 + Double.random(in: -10...10), 100)
        )
    }
    
    private func generateOpinionScores(text: String) -> OpinionScores {
        return OpinionScores(
            depth: Double.random(in: 60...95),
            expression: Double.random(in: 65...95),
            criticalThinking: Double.random(in: 55...90)
        )
    }
    
    private func generateRetellFeedback(scores: RetellScores) -> String {
        let avgScore = (scores.fluency + scores.accuracy + scores.completeness) / 3
        if avgScore >= 85 {
            return "复述非常出色！你准确抓住了原文的核心要点，表达流畅自然。"
        } else if avgScore >= 70 {
            return "复述表现良好，基本覆盖了主要内容。建议在细节准确性和结构完整性上继续加强。"
        } else {
            return "复述有待提高，建议多关注原文的关键信息点，尝试用自己的话完整地表达出来。"
        }
    }
    
    private func generateOpinionFeedback(scores: OpinionScores) -> String {
        let avgScore = (scores.depth + scores.expression + scores.criticalThinking) / 3
        if avgScore >= 85 {
            return "你的观点非常有见地！思考深入、表达有力，展现了优秀的批判性思维能力。"
        } else if avgScore >= 70 {
            return "观点表达清晰，有一定的思考深度。建议尝试从更多角度分析问题。"
        } else {
            return "在发表观点时，建议先明确自己的立场，然后围绕核心论点展开论述。多练习会越来越好！"
        }
    }
}
