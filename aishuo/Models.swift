//
//  Models.swift
//  aishuo
//
//  Created by cookie on 2026/4/16.
//

import SwiftUI

// MARK: - Agent类型
enum AgentType: String, CaseIterable, Identifiable {
    case speechCoach = "演讲教练"
    case debateJudge = "辩论裁判"
    case pronunciationTutor = "场景教练"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .speechCoach: return "mic.circle.fill"
        case .debateJudge: return "bubble.left.and.bubble.right.fill"
        case .pronunciationTutor: return "rectangle.and.text.magnifyingglass"
        }
    }
    
    var color: LinearGradient {
        switch self {
        case .speechCoach:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.3), Color(red: 1.0, green: 0.416, blue: 0.333)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .debateJudge:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.416, blue: 0.333), Color(red: 0.9, green: 0.3, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pronunciationTutor:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.75, blue: 0.40), Color(red: 1.0, green: 0.55, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var description: String {
        switch self {
        case .speechCoach: return "实时反馈与话术优化"
        case .debateJudge: return "结构化辩论训练"
        case .pronunciationTutor: return "高压场景模拟与对话训练"
        }
    }
}

// MARK: - 训练类型
enum TrainingType: String, CaseIterable, Identifiable, Codable {
    case impromptuSpeech = "即兴演讲"
    case structuredDebate = "结构化辩论"
    case sceneDialogue = "场景对话"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .impromptuSpeech: return "text.bubble.fill"
        case .structuredDebate: return "quote.bubble.fill"
        case .sceneDialogue: return "rectangle.and.text.magnifyingglass"
        }
    }
}

// MARK: - 场景对话
/// 对话场景
struct DialogueScene: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let difficulty: String
    let initialPrompt: String
    let minRounds: Int
    
    static let presets: [DialogueScene] = [
        DialogueScene(
            name: "面试挑战",
            icon: "person.fill.questionmark",
            description: "模拟高压力面试，HR步步紧逼",
            difficulty: "中等",
            initialPrompt: "您好，请先做个简短的自我介绍吧。",
            minRounds: 3
        ),
        DialogueScene(
            name: "商务谈判",
            icon: "briefcase.fill",
            description: "供应商涨价谈判，维护公司利益",
            difficulty: "困难",
            initialPrompt: "张总，考虑到原材料价格上涨，我们希望能将合同价格提高15%，您看怎么样？",
            minRounds: 4
        ),
        DialogueScene(
            name: "客户投诉",
            icon: "exclamationmark.bubble.fill",
            description: "处理愤怒客户的投诉与质疑",
            difficulty: "中等",
            initialPrompt: "你们的产品质量太差了！我用了三天就坏了，我要退货并且投诉到消费者协会！",
            minRounds: 3
        ),
        DialogueScene(
            name: "观点反驳",
            icon: "bubble.left.and.exclamationmark.bubble.right.fill",
            description: "对方抛出争议观点，请有力反驳",
            difficulty: "困难",
            initialPrompt: "我认为年轻人就该加班奋斗，没有付出哪来的回报？你觉得呢？",
            minRounds: 4
        )
    ]
}

/// 对话消息
struct DialogueMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let isPressure: Bool
    let timestamp: Date
    
    enum MessageRole: String {
        case ai = "AI"
        case user = "我"
    }
}

/// 对话会话
struct DialogueSession: Identifiable {
    let id = UUID()
    let scene: DialogueScene
    let startTime: Date
    var messages: [DialogueMessage]
    var isCompleted: Bool
    var score: Double?
    var feedback: String?
    
    var currentRound: Int {
        messages.filter { $0.role == .user }.count
    }
    
    var canEnd: Bool {
        currentRound >= scene.minRounds
    }
    
    init(scene: DialogueScene) {
        self.scene = scene
        self.startTime = Date()
        self.messages = [
            DialogueMessage(role: .ai, content: scene.initialPrompt, isPressure: false, timestamp: Date())
        ]
        self.isCompleted = false
    }
}

// MARK: - AI压力回复模板
struct PressureTemplates {
    static func response(for scene: DialogueScene, round: Int, userText: String) -> String {
        let templates = sceneResponses[scene.name] ?? []
        let index = min(round - 1, templates.count - 1)
        if index >= 0, index < templates.count {
            return templates[index]
        }
        return defaultResponses.randomElement() ?? "嗯，你说的有一定道理，但是能不能说得更具体一些？"
    }
    
    private static let defaultResponses = [
        "你这样的回答太表面了，能深入一点吗？",
        "我不太认同你的观点，你能再解释一下吗？",
        "哼，这样的说法站不住脚。",
        "如果你只能说到这个程度，那我觉得还不够。",
        "你说的和刚才有什么不同？换个角度说说。",
        "这样回答太笼统了，具体一点！"
    ]
    
    private static let sceneResponses: [String: [String]] = [
        "面试挑战": [
            "你的自我介绍太模板化了。说说你过去工作中遇到的最大挑战是什么？",
            "这个挑战听起来不算什么。你有没有更失败的例子？",
            "我注意到你刚才的回答前后矛盾，你说你擅长团队合作，但又说项目中你主导了大部分决策，这怎么解释？",
            "好吧，最后一个问题：如果你的领导和你的意见冲突，但你坚信自己是对的，你会怎么做？",
            "你的回答还算诚恳，但缺乏亮点。我需要想想是否适合这个岗位。"
        ],
        "商务谈判": [
            "15%的涨幅太高了，我们最多接受5%。而且你们的质量最近也有下滑。",
            "5%我们已经很有诚意了。据我所知，你们同行A公司最近还降价了。",
            "你说成本上涨，但我看过市场报告，原材料价格明明在回落，你是不是在忽悠我？",
            "好吧，就算你们有困难，那付款周期必须延长到90天，否则没得谈。",
            "如果这两个条件都不能答应，那这个合作我们真的需要重新考虑了。"
        ],
        "客户投诉": [
            "你说三天就坏了？我同事买了一个月都没问题，你是不是使用不当？",
            "就算真的是质量问题，我们规定是7天内包退，你已经超过时间了。",
            "退一步说，如果你能拿出购买凭证，我可以帮你申请换货，但退货不可能。",
            "我们已经让步同意换货了，你还想怎么样？你要是非要投诉，那请便吧。",
            "等等，我再查一下你的购买记录……你是在第三方平台买的？那不归我们管。"
        ],
        "观点反驳": [
            "不加班就是不上进？看看北欧国家，人家不加班效率反而更高，你怎么解释？",
            "你说的'奋斗'本质上是用时间换产出，但效率思维才是关键。你认同吗？",
            "那你怎么解释那些996的公司反而创新力下降？长期疲劳工作只会适得其反。",
            "就算你说的对，那么请问：如果所有人都在加班，内卷之下你的竞争优势在哪？",
            "所以归根结底，你把'工作时间长'等同于'贡献大'，这个逻辑本身就有问题。"
        ]
    ]
}

// MARK: - 用户档案
struct UserProfile: Codable {
    var name: String
    var avatar: String
    var joinDate: Date
    var totalTrainingTime: TimeInterval // 总训练时长（秒）
    var completedSessions: Int // 完成训练次数
    var skillLevel: Int // 技能等级 1-10
    
    static let example = UserProfile(
        name: "用户",
        avatar: "person.circle.fill",
        joinDate: Date(),
        totalTrainingTime: 3600,
        completedSessions: 15,
        skillLevel: 5
    )
}

// MARK: - 训练报告
struct TrainingReport: Identifiable, Codable {
    let id: UUID
    let date: Date
    let trainingType: TrainingType
    let duration: TimeInterval
    let score: Double
    let feedback: String
    var improvements: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case trainingType
        case duration
        case score
        case feedback
        case improvements
    }
    
    static let example = TrainingReport(
        id: UUID(),
        date: Date(),
        trainingType: .impromptuSpeech,
        duration: 300,
        score: 85.5,
        feedback: "整体表现良好，语速适中，逻辑清晰",
        improvements: ["可以增加更多肢体语言", "注意停顿节奏", "加强开头吸引力"]
    )
}

// MARK: - 训练会话
struct TrainingSession: Identifiable {
    let id: UUID
    let type: TrainingType
    let startTime: Date
    var endTime: Date?
    var isCompleted: Bool
    var score: Double?
    
    init(type: TrainingType) {
        self.id = UUID()
        self.type = type
        self.startTime = Date()
        self.isCompleted = false
    }
}

// MARK: - 每日练习内容
struct DailyContent: Identifiable, Codable {
    let id: String
    let title: String
    let category: String
    let content: String
    let keyPoints: [String]
    let source: String

    enum CodingKeys: String, CodingKey {
        case id, title, category, content
        case keyPoints = "keyPoints"
        case source
    }
}

// MARK: - 每日练习步骤
enum DailyPracticeStep: String, CaseIterable {
    case reading = "阅读内容"
    case retelling = "复述练习"
    case opinion = "发表看法"
    case completed = "练习完成"
}

// MARK: - 每日练习评分维度
struct RetellScores {
    let fluency: Double    // 流畅度 0-100
    let accuracy: Double   // 准确性 0-100
    let completeness: Double // 完整性 0-100
}

struct OpinionScores {
    let depth: Double      // 思考深度 0-100
    let expression: Double // 表达能力 0-100
    let criticalThinking: Double // 思辨能力 0-100
}

// MARK: - 每日练习结果
struct DailyPracticeResult: Identifiable {
    let id = UUID()
    let contentId: String
    let date: Date
    let retellScores: RetellScores
    let opinionScores: OpinionScores
    let retellFeedback: String
    let opinionFeedback: String
    let combinedFeedback: String
    let retellSuggestions: [String]  // LLM返回的提升建议
}

// MARK: - LLM复述评测响应
struct RetellEvaluationResponse: Codable {
    let fluency: Double
    let accuracy: Double
    let completeness: Double
    let feedback: String
    let suggestions: [String]
}

// MARK: - 每日内容提供者
struct DailyContentProvider {
    static let contents: [DailyContent] = [
        DailyContent(
            id: "local-1",
            title: "狐狸与葡萄",
            category: "寓言故事",
            content: "一只饥饿的狐狸路过一个葡萄园，看见架子上挂着一串串晶莹剔透的葡萄。它垂涎欲滴，想方设法要吃到葡萄。可是葡萄架太高了，狐狸跳了好多次都够不着。最后，狐狸喘着气说：\"这葡萄肯定是酸的，不好吃。\"说完便头也不回地走了。\n\n这个故事告诉我们，有些人能力不足，做不成事情，却借口说时机还没有成熟。他们用自欺欺人的方式掩饰自己的失败，这就是所谓的\"酸葡萄心理\"。",
            keyPoints: ["狐狸想吃葡萄但够不着", "狐狸说葡萄是酸的", "讽刺自欺欺人的心态"],
            source: "伊索寓言"
        ),
        DailyContent(
            id: "local-2",
            title: "龟兔赛跑",
            category: "寓言故事",
            content: "兔子和乌龟决定赛跑。兔子自恃跑得快，比赛开始后不久就远远领先。它回头看看，乌龟才爬了一小段路。兔子心想：\"我睡一觉再跑也能赢。\"于是它躺在大树下呼呼大睡。\n\n乌龟知道自己跑得慢，但一刻不停地向前爬。当兔子醒来时，发现乌龟已经快到终点了。兔子拼命追赶，但还是晚了一步，乌龟率先到达了终点。\n\n这个故事告诉我们，骄傲使人落后，坚持就是胜利。天赋再好，如果不努力，也可能会被勤奋的人超越。",
            keyPoints: ["兔子骄傲自满中途睡觉", "乌龟坚持不懈最终获胜", "骄傲导致失败，坚持才能胜利"],
            source: "伊索寓言"
        ),
        DailyContent(
            id: "local-3",
            title: "北风与太阳",
            category: "寓言故事",
            content: "北风和太阳争论谁更强大。他们决定比赛：谁能先让路上的行人脱掉衣服，谁就获胜。\n\n北风首先发力，它使劲地吹，刮起一阵凛冽的寒风。可是行人却把衣服裹得更紧了。北风吹得越猛，行人裹得越紧。\n\n接着，太阳出场了。它发出温暖的光芒，不紧不慢地照耀着大地。行人感到暖和了，便主动脱下了外套。\n\n这个故事告诉我们，温和友善往往比强硬的手段更有效。劝说比强迫更容易让人接受。",
            keyPoints: ["北风用强力反而让人裹紧衣服", "太阳用温暖让人主动脱衣", "温和比强硬更有效"],
            source: "伊索寓言"
        ),
        DailyContent(
            id: "local-4",
            title: "三个工匠",
            category: "寓言故事",
            content: "一位老师傅带着三个徒弟建造一座石桥。\n\n第一个工匠说：\"我就是在凿石头，每天重复同样的事情。\"\n第二个工匠说：\"我在砌桥墩，这是我的工作。\"\n第三个工匠却笑着说：\"我在建造一座让子孙后代都能受益的桥梁。\"\n\n多年后，第一个工匠仍然在凿石头，第二个工匠成为了普通建筑工人，而第三个工匠却成为了一位著名的桥梁设计师。\n\n这个故事告诉我们，看待工作的态度决定了你未来的高度。拥有远大的目标和使命感，才能成就伟大的事业。",
            keyPoints: ["三个工匠对待工作有不同的态度", "态度决定了每个人的成就", "使命感和远大目标的重要性"],
            source: "民间故事"
        ),
        DailyContent(
            id: "local-5",
            title: "国王的奖赏",
            category: "寓言故事",
            content: "一位国王要在三个儿子中选一个继承人。他给了每个儿子一粒种子，说：\"谁能种出最美丽的花，谁就继承王位。\"\n\n大儿子和二儿子精心挑选了花盆和土壤，每天都浇水施肥。可是到了比赛那天，他们的花盆里都没有开花。只有三儿子的花盆里开出了绚丽的花朵。\n\n国王宣布三儿子获胜，并告诉大家：\"我给他们的种子都是煮过的，根本不可能发芽。所以只有三儿子诚实，他换了新的种子。\"\n\n这个故事告诉我们，诚实是最宝贵的品质。有时候，看似聪明的人反而被自己的小聪明所误。",
            keyPoints: ["国王给的是煮过的种子", "只有三儿子诚实地换了新种子", "诚实比聪明更可贵"],
            source: "民间故事"
        ),
        DailyContent(
            id: "local-6",
            title: "人工智能正在如何改变我们的生活",
            category: "科技时事",
            content: "人工智能已经渗透到我们生活的方方面面。从智能手机中的语音助手，到推荐你看什么视频的算法，再到医院里辅助医生诊断病情的系统，AI正在悄无声息地改变着世界。\n\n在教育领域，AI可以根据每个学生的学习进度和特点，提供个性化的学习方案。在医疗领域，AI可以分析医学影像，帮助医生更早地发现疾病。在交通领域，自动驾驶技术正在逐步成熟。\n\n然而，AI的发展也带来了新的挑战。比如，如何保护个人隐私？如何确保AI决策的公平性？哪些工作会被AI取代？这些问题都需要我们认真思考。\n\n面对AI时代，我们不应该恐惧，而是要学会与AI协作，发挥人类的创造力和情感智慧，让技术真正造福人类社会。",
            keyPoints: ["AI已渗透到教育、医疗、交通等领域", "AI带来便利的同时也有挑战", "人类应学会与AI协作"],
            source: "科技日报"
        ),
        DailyContent(
            id: "local-7",
            title: "全球气候行动：我们还有多少时间？",
            category: "时事新闻",
            content: "近年来，极端天气事件越来越频繁：创纪录的热浪、毁灭性的洪水、大面积的森林火灾。科学家们警告，全球气温正在以前所未有的速度上升。\n\n巴黎协定的目标是限制全球升温在1.5摄氏度以内，但按照目前的趋势，我们可能在未来十年内就会突破这个临界点。各国正在加速推进碳中和目标，发展可再生能源，减少温室气体排放。\n\n作为个人，我们也可以为气候行动贡献力量：减少浪费、选择绿色出行、节约用电、支持环保产品。每个人的小小改变，汇聚起来就是巨大的力量。\n\n保护地球家园，不仅是为了我们自己，更是为了子孙后代。行动的最佳时机是现在。",
            keyPoints: ["极端天气日益频繁", "各国加速碳中和目标", "个人行动也能贡献力量"],
            source: "环保新闻网"
        ),
        DailyContent(
            id: "local-8",
            title: "太空探索新纪元：月球基地与火星计划",
            category: "科技时事",
            content: "人类对太空的探索从来没有停止过。近年来，多个国家和私营企业都在加速推进太空计划。\n\n月球成为新一轮太空竞争的焦点。各国计划在月球建立长期基地，作为深空探索的中转站。与此同时，火星探索也在稳步推进，无人探测器已经多次成功登陆火星，为未来的载人任务做准备。\n\n太空探索不仅仅是科学事业，它还推动了无数技术的进步。从卫星导航到天气预报，从通信技术到材料科学，太空技术已经深度融入了我们的日常生活。\n\n人类探索太空的意义，不仅仅是到达新的地方，更是拓展我们对宇宙的认知，激发下一代的科学梦想。",
            keyPoints: ["月球基地成为新焦点", "火星探索稳步推进", "太空技术已深入日常生活"],
            source: "太空探索杂志"
        ),
        DailyContent(
            id: "local-9",
            title: "数字阅读时代：纸质书会消失吗？",
            category: "社会文化",
            content: "随着智能手机和平板电脑的普及，越来越多的人选择数字阅读。电子书、有声书、在线阅读平台蓬勃发展。\n\n数字阅读的优势显而易见：方便携带、存储量大、可以随时购买和下载。但纸质书也有不可替代的魅力：翻页的触感、油墨的香气、书架上的成就感。\n\n有趣的是，调查显示很多人在通勤时使用电子设备阅读，但在家中放松时仍然偏爱纸质书。这说明数字阅读和纸质阅读并不是非此即彼的关系，而是互为补充。\n\n无论选择哪种阅读方式，重要的是保持阅读的习惯。在信息爆炸的时代，深度阅读和独立思考的能力比以往任何时候都更加珍贵。",
            keyPoints: ["数字阅读快速普及","纸质书有不可替代的魅力","两者互为补充而非相互替代"],
            source: "文化观察报"
        ),
        DailyContent(
            id: "local-10",
            title: "绿色能源革命：太阳能的未来",
            category: "科技时事",
            content: "太阳能正在经历一场革命。过去十年，太阳能电池板的成本下降了90%以上，效率却不断提高。在很多地区，太阳能已经成为最便宜的电力来源。\n\n新型太阳能技术不断涌现：可以弯曲的薄膜太阳能电池、可以安装在窗户上的透明太阳能板、甚至可以用太阳能涂料给建筑物发电。\n\n储能技术的发展也在同步推进。大容量电池可以储存白天多余的太阳能，供夜间使用。这样就能解决太阳能\"看天吃饭\"的问题。\n\n专家预测，到2050年，太阳能可能成为全球最大的电力来源。清洁、可持续的能源未来，正在从梦想变成现实。",
            keyPoints: ["太阳能成本大幅下降","新型太阳能技术不断涌现","储能技术解决间歇性问题"],
            source: "能源前沿"
        )
    ]
    
    static func contentForDate(_ date: Date) -> DailyContent {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % contents.count
        return contents[index]
    }
}
