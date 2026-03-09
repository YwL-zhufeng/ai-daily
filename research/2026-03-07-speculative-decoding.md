# Speculative Decoding 领域最新进展报告

> 报告日期：2026-03-07
> 整理来源：arXiv、ACL、NeurIPS、ICML、技术博客、GitHub、社交媒体等

---

## 📌 执行摘要

Speculative Decoding（推测解码）作为大语言模型推理加速的核心技术，在2024-2025年取得了显著进展。从EAGLE-3的发布到vLLM的原生集成，再到各类变体方法（SuffixDecoding、QuantSpec等）的涌现，该技术正从研究概念快速走向生产标准。**主流方法已实现2-3倍的速度提升，部分场景下可达5倍以上**。

---

## 一、最新发表的研究论文

### 1. EAGLE 系列

#### 1.1 EAGLE-3: Extrapolative Attention Guided LEarning (NeurIPS 2025)

- **标题**: EAGLE-3: Advanced Speculative Decoding with Multi-Layer Feature Fusion
- **来源**: NeurIPS 2025, LMSYS Blog, NVIDIA Blog
- **动机**: 传统speculative decoding需要维护独立的draft模型，增加了部署复杂度和资源开销。EAGLE-3旨在通过轻量级的draft head消除这些限制。
- **创新点**:
  - 将轻量级"draft head"（仅占目标模型2-5%大小）直接附加到目标模型的内部层
  - 在特征层（而非token层）进行自回归，利用低、中、高层的融合特征表示
  - 使用上下文感知的动态draft tree（继承自EAGLE-2）提出多个链式假设
  - 通过并行tree attention验证候选token，有效剪枝无效分支
- **结果**:
  - **2x-3x解码速度提升**（Llama 3.3 70B模型）
  - TPOT（Time Per Output Token）显著降低
  - 输出吞吐量大幅提升
  - 与SGLang和vLLM无缝集成

#### 1.2 EAGLE-2 (EMNLP 2024)

- **标题**: EAGLE-2: Faster Inference of Language Models with Dynamic Draft Trees
- **来源**: arXiv:2406.16858, EMNLP 2024
- **动机**: 解决特征预测中的不确定性问题，提高draft token的接受率
- **创新点**:
  - 引入时间步长提前的token序列，减少特征预测的不确定性
  - 动态draft tree结构，根据置信度自适应调整
- **结果**: 相比EAGLE-1，加速比从1.9倍提升到2.8倍

---

### 2. SuffixDecoding (NeurIPS 2025 Spotlight)

- **标题**: SuffixDecoding: Extreme Speculative Decoding for Emerging AI Applications
- **来源**: NeurIPS 2025 Spotlight, https://suffix-decoding.github.io/
- **动机**: 面向AI Agent等新兴应用，这些场景具有独特的workload特征——重复性推理请求（如多Agent管道执行相似子任务、自精炼循环），导致长且高度可预测的序列，现有speculative decoding方法未能有效利用。
- **创新点**:
  - 利用高效的后缀树（suffix trees）缓存prompt和先前输出的长token序列
  - 自适应推测：接受可能性高时推测更多token，可能性低时推测更少
  - 混合模式：SuffixDecoding + EAGLE-3结合，取长补短
- **结果**:
  - AgenticSQL任务：**最高10.41倍加速**（Enrich任务）
  - SWE-Bench任务：**2.5倍加速**
  - 比EAGLE-2/3快**1.9-2.8倍**
  - 比Token Recycling快**1.9倍**

---

### 3. Medusa: Multiple Decoding Heads (ICML 2024)

- **标题**: Medusa: Simple LLM Inference Acceleration Framework with Multiple Decoding Heads
- **来源**: ICML 2024, arXiv:2401.10774
- **动机**: 避免维护独立的draft模型，简化部署和管理复杂度
- **创新点**:
  - 在主干模型最后一层添加多个轻量级decoding heads（Medusa Heads）
  - 每个head并行预测未来不同位置的token
  - 使用**tree-based attention mechanism**同时验证多个候选continuation
  - 两种训练策略：
    - **Medusa-1**: 在冻结的backbone上微调heads，无损加速
    - **Medusa-2**: 与backbone联合训练，更高速度但需要特殊训练配方
- **结果**:
  - Medusa-1: **2.2倍加速**，不损失生成质量
  - Medusa-2: **2.3-2.8倍加速**（部分报告达3.6倍）
  - 在Vicuna 7B和13B上验证

---

### 4. DistillSpec (ICLR 2024)

- **标题**: DistillSpec: Improving Speculative Decoding via Knowledge Distillation
- **来源**: ICLR 2024, arXiv:2310.08461
- **动机**: 识别与目标模型良好对齐的紧凑型draft模型具有挑战性
- **创新点**:
  - 使用知识蒸馏（KD）在应用SD前更好地对齐draft模型与目标模型
  - 关键设计选择：
    - 利用draft模型的"on-policy"数据生成
    - 根据任务和解码策略"定制散度函数"
  - 可与lossy SD结合，实现延迟与任务性能权衡的细粒度控制
- **结果**:
  - 相比标准SD，在各种基准上实现**10-45%的额外加速**
  - 结合蒸馏目标模型和DistillSpec训练的draft模型，可实现**6-10倍延迟降低**

---

### 5. Hierarchical Verification of Speculative Beams (CDSNE 2025)

- **标题**: Hierarchical Verification of Speculative Beams for Accelerating LLM Inference
- **来源**: CDSNE 2025 (3rd International Conference on Data Science and Network Engineering), arXiv
- **动机**: 传统方法顺序生成token，无法充分利用并行性
- **创新点**:
  - 分层推测解码方案，并行推测多个未来token
  - 通过分层过程验证，实现早期拒绝无效分支
  - 更快收敛，更高效生成
- **结果**:
  - 显著降低推理延迟
  - 提高吞吐量，不损害输出质量
  - 兼容广泛的Transformer架构

---

### 6. 其他重要论文

| 论文 | 会议/年份 | 核心贡献 |
|------|----------|---------|
| **Multi-Candidate Speculative Decoding** | arXiv 2024 | 每个位置采样多个候选token，提高接受率 |
| **Online Speculative Decoding** | ICML 2024 | 动态调整draft模型，在线学习适应 |
| **Token Recycling** | arXiv 2024 | 利用prompt中已有的token信息进行预测，无需额外draft模型 |
| **Cascade Speculative Drafting** | arXiv 2023 | 级联推测草拟，进一步提高速度 |
| **SpecExec** | NeurIPS 2024 | 面向消费级设备的大规模并行推测解码 |
| **Kangaroo** | NeurIPS 2024 | 通过双重早期退出实现无损自推测解码 |

---

## 二、技术博客与文章

### 1. NVIDIA 官方博客 (2025-09-17)

- **标题**: An Introduction to Speculative Decoding for Reducing Latency in AI Inference
- **来源**: https://developer.nvidia.com/blog/
- **要点**:
  - 详细解释speculative decoding的工作原理
  - 重点介绍EAGLE-3在NVIDIA GPU上的部署
  - 提供TensorRT-Model Optimizer API使用指南
  - 强调输出质量保证机制（rejection sampling）

### 2. LMSYS Blog (2025-12-01)

- **标题**: Accelerate OSS LLM with EAGLE-3 on Vertex
- **来源**: https://lmsys.org/blog/
- **要点**:
  - 在Vertex AI上部署EAGLE-3的完整工程实践
  - 数据准备挑战与解决方案（合成数据生成管道）
  - Benchmark结果：Llama 4 Scout 17B上2x-3x速度提升
  - 与SGLang集成经验

### 3. Red Hat Developer Blog (2025-07-01)

- **标题**: Fly Eagle3 Fly: Faster Inference with vLLM & Speculative Decoding
- **来源**: https://developers.redhat.com/
- **要点**:
  - vLLM对EAGLE-3的原生支持
  - 实际性能测试：Llama 3.1 8B最高1.8x，Llama 3.3 70B最高1.6x（低请求率）
  - 不同任务的表现差异：代码生成、数学推理、翻译等
  - 训练数据对性能的影响分析

### 4. vLLM Blog (2025-12-13)

- **标题**: Diving into speculative decoding training support for vLLM with Speculators v0.3.0
- **来源**: https://blog.vllm.ai/
- **要点**:
  - Speculators库简化draft模型训练流程
  - 支持模型：Llama (3.1-3.3), Qwen3, GPT-OSS, Llama 4 multimodal
  - 未来计划：在线数据生成、多模态支持、验证器响应再生

### 5. 掘金中文技术文章 (2025-06-23)

- **标题**: Speculative Decoding 推测解码方案详解
- **来源**: https://juejin.cn/
- **要点**:
  - 从基础到进阶的完整技术解读
  - 涵盖Prompt Lookup Decoding、Medusa、EAGLE等方法
  - vLLM中使用speculative decoding的代码示例
  - Jacobi Decoding的数学原理解释

---

## 三、GitHub 新项目和更新

### 1. EAGLE 官方实现

- **仓库**: https://github.com/haotian-liu/EAGLE
- **更新**:
  - EAGLE-1 (ICML'24) 官方实现
  - EAGLE-2 (EMNLP'24) 官方实现
  - EAGLE-3 (NeurIPS'25) 官方实现
- **特点**: 支持Llama、Vicuna等主流模型，提供预训练draft head

### 2. Medusa

- **仓库**: https://github.com/FasterDecoding/Medusa
- **特点**:
  - 多头解码框架实现
  - 支持tree-based attention
  - 提供Medusa-1和Medusa-2两种训练模式

### 3. vLLM Speculators

- **仓库**: https://github.com/vllm-project/speculators
- **更新**: v0.3.0发布
- **特点**:
  - 与vLLM紧密集成的speculative decoding训练库
  - 支持EAGLE-1/2/3
  - 提供端到端数据生成和训练脚本

### 4. SuffixDecoding

- **网站**: https://suffix-decoding.github.io/
- **特点**:
  - 针对Agent场景优化的speculative decoding
  - 使用后缀树缓存机制
  - 支持混合模式（SuffixDecoding + EAGLE-3）

### 5. TensorRT-Model-Optimizer

- **仓库**: https://github.com/NVIDIA/TensorRT-Model-Optimizer
- **更新**: 新增speculative decoding模块
- **特点**:
  - NVIDIA官方支持的EAGLE-3实现
  - 提供模型转换API
  - 针对NVIDIA GPU优化

### 6. 其他相关项目

| 项目名称 | GitHub地址 | 说明 |
|---------|-----------|------|
| **SpecInfer** | https://github.com/hao-ai-lab/SpecInfer | 基于树的推测推理和验证 |
| **REST** | https://github.com/hemingkx/Rest | 基于检索的speculative decoding |
| **LayerSkip** | https://github.com/facebookresearch/LayerSkip | 早期退出推理和自speculative decoding |
| **Prompt Lookup Decoding** | https://github.com/apoorvumang/prompt-lookup-decoding | 基于n-gram匹配的快速解码 |

---

## 四、社交媒体讨论

### 1. Hacker News 讨论要点

- **话题**: "Speculative decoding will be recorded" (CUDA MODE workshop)
- **讨论焦点**:
  - 不同speculative decoding方法的实际性能对比
  - vLLM集成经验分享
  - 在生产环境中部署的挑战和解决方案
  - 成本效益分析（计算vs内存带宽的权衡）

### 2. Twitter/X 讨论

- **热门话题**:
  - `#SpeculativeDecoding` 技术分享
  - `Prompt lookup decoding` 获得2-4倍延迟降低的讨论
  - Cursor的speculative decoding模型（每秒千token编辑速度）
  - OpenAI "Predictive Outputs"使用speculative decoding加速

### 3. Reddit r/LocalLLaMA

- **讨论主题**:
  - 消费级GPU上speculative decoding的实际效果
  - EAGLE-3 vs Medusa的性能对比
  - 不同draft模型的接受率分析
  - 量化对speculative decoding的影响

### 4. 行业应用动态

- **Cursor**: 发布专用speculative decoding模型，文件编辑速度达1000 token/秒
- **OpenAI**: 推出"Predictive Outputs"功能，使用speculative decoding加速模型输出
- **Codebuff**: 集成speculative decoding实现近10倍成本降低

---

## 五、技术趋势与展望

### 1. 2024-2025年关键趋势

1. **从研究到生产**: Speculative decoding已从研究概念转变为生产标准，vLLM、TensorRT-LLM等主流框架原生支持
2. **方法多样化**: 从传统的draft-target模式发展到EAGLE、Medusa、SuffixDecoding等多种变体
3. **硬件优化**: NVIDIA H200 GPU上实现3.6倍吞吐量提升
4. **Agent场景优化**: SuffixDecoding等方法专门针对AI Agent的重复性workload优化

### 2. 2025年发展方向

1. **在线自适应**: 动态调整draft策略，根据实时接受率优化
2. **多模态扩展**: 将speculative decoding应用于视觉-语言模型
3. **更长上下文**: 支持超长序列的speculative decoding
4. **边缘设备**: 针对移动设备和边缘场景的轻量化实现

### 3. 选择建议

根据JarvisLabs的benchmark建议：

| 使用场景 | 推荐技术 | 理由 |
|---------|---------|------|
| 通用聊天机器人 | EAGLE/EAGLE-3 | 在流畅对话场景表现最佳 |
| 代码助手（小模型）| Suffix Decoding | 低开销，利用代码重复模式 |
| 代码助手（大模型）| EAGLE-3 | 准确预测减少目标模型访问 |
| 严格硬件限制 | Suffix Decoding | 无需额外权重和训练 |

---

## 六、关键性能数据汇总

| 方法 | 速度提升 | 适用模型 | 质量损失 | 额外资源需求 |
|-----|---------|---------|---------|------------|
| EAGLE-3 | 2x-3x | Llama系列 | 无 | 2-5%模型大小的draft head |
| SuffixDecoding | 最高10x | 通用 | 无 | 后缀树缓存 |
| Medusa-1 | 2.2x | Vicuna等 | 无 | 多个decoding heads |
| Medusa-2 | 2.3-2.8x | Vicuna等 | 微小 | heads + 联合训练 |
| DistillSpec | +10-45% | 通用 | 可控 | 蒸馏训练 |
| Prompt Lookup | 2x-4x | 通用 | 无 | n-gram匹配 |

---

## 参考文献

1. Leviathan et al., "Fast Inference from Transformers via Speculative Decoding", ICML 2023
2. Chen et al., "Accelerating Large Language Model Decoding with Speculative Sampling", arXiv 2023
3. Li et al., "EAGLE: Speculative Sampling Requires Rethinking Feature Uncertainty", ICML 2024
4. Li et al., "EAGLE-2: Faster Inference of Language Models with Dynamic Draft Trees", EMNLP 2024
5. Cai et al., "Medusa: Simple LLM Inference Acceleration Framework with Multiple Decoding Heads", ICML 2024
6. Zhou et al., "DistillSpec: Improving Speculative Decoding via Knowledge Distillation", ICLR 2024
7. Snowflake AI Research, "SuffixDecoding: Extreme Speculative Decoding for Emerging AI Applications", NeurIPS 2025
8. Sen et al., "Hierarchical Verification of Speculative Beams for Accelerating LLM Inference", CDSNE 2025

---

*报告完成时间：2026-03-07*
*数据来源：arXiv, ACL Anthology, NeurIPS, ICML proceedings, 官方博客, GitHub仓库*
