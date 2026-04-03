# Voice Input

[English](README.md) · [许可证：MIT](LICENSE)

![平台](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![许可证](https://img.shields.io/badge/license-MIT-green)

**Voice Input** 是一个面向 **macOS 菜单栏** 的轻量级语音输入应用，主打“**按住 `Fn` 说话，松手自动粘贴**”的键盘优先体验。

它使用 **Apple Speech Recognition** 做实时语音转文字，并可选接入 **OpenAI 兼容接口**，对转写结果做一层**非常保守**的纠错，尤其适合处理中英混说时的明显识别错误。

### 这个项目解决什么问题

很多场景下，传统听写体验并不顺手：

- 需要先点按钮或切换模式
- 说完后还要手动确认
- 在中文输入法下粘贴行为不稳定
- 中英混输时，技术词容易被识别错

`Voice Input` 的目标很简单：让语音输入像快捷键一样自然。

- **按住 `Fn` 开始说**
- **松手自动输入**
- **全程停留在当前应用里**

### 主要特性

- **Fn 按住即录音**：全局监听 `Fn`，并抑制原始按键事件，避免唤起 emoji 面板
- **实时流式转写**：基于 Apple `Speech` 框架，边说边出字
- **默认简体中文**：开箱即用，默认就是 **简体中文**
- **多语言切换**：支持英语、简体中文、繁体中文、日语、韩语
- **悬浮胶囊 HUD**：录音时在屏幕底部显示无边框浮动窗
- **真实音量波形**：波形由实时音频 RMS 驱动，而不是假动画
- **稳妥文本注入**：通过剪贴板 + 模拟 `Cmd+V` 的方式注入文本
- **兼容 CJK 输入法**：粘贴前临时切到 ASCII 输入源，完成后再恢复原输入法
- **可选 LLM 纠错**：只修正明显识别错误，不主动改写你的原句
- **纯菜单栏应用**：`LSUIElement` 模式运行，不显示 Dock 图标

### 工作流程

1. 按住 **`Fn`**
2. 应用开始录音，并显示底部悬浮胶囊窗口
3. 语音被实时转写为文本
4. 松开 **`Fn`**，结束录音
5. 如果开启了 LLM 纠错，会先进行一次可选的文本修正
6. 最终文本被粘贴到当前聚焦的输入框中

### 技术栈

- **Swift**
- **AppKit**
- **AVFoundation**
- **Speech**
- **CoreGraphics / Carbon**（用于事件监听和输入源切换）
- **OpenAI 兼容 Chat Completions API**（用于可选文本纠错）

### 运行要求

- **macOS 14+**
- **Apple Silicon (`arm64`)**
- **Xcode Command Line Tools**

> 仓库中保留了 `Package.swift`，但当前推荐的本地构建方式是使用 `Makefile`，它会直接调用 `swiftc` 编译并打包生成 `Voice Input.app`。

### 快速开始

```bash
# 克隆仓库
git clone https://github.com/xiangyingchang/voice-input.git
cd voice-input

# 构建 .app
make build

# 调试运行
make run

# 安装到 /Applications
make install
```

执行 `make build` 后，会在项目根目录生成：

```bash
./Voice Input.app
```

直接运行：

```bash
open "Voice Input.app"
```

### 首次运行需要的权限

macOS 第一次启动时需要授予以下权限：

1. **辅助功能（Accessibility）**  
   用于全局监听 `Fn` 以及模拟粘贴按键。
2. **麦克风（Microphone）**  
   用于录音。
3. **语音识别（Speech Recognition）**  
   用于实时语音转写。

可在 **系统设置 → 隐私与安全性** 中管理这些权限。

### LLM 纠错说明

这个应用**不依赖 LLM 也能正常工作**。
LLM 只是一个可选的“后处理层”，专门用于修复明显的语音识别错误。

菜单栏路径：

- **LLM Refinement → Enable LLM Refinement**
- **LLM Refinement → Settings…**

需要配置的字段：

- **API Base URL**：例如 `https://api.openai.com`
- **API Key**
- **Model**：例如 `gpt-4o-mini`

应用会自动调用 OpenAI 兼容的 **`/v1/chat/completions`** 接口。

纠错策略刻意做得很保守：

- 只修明显错误
- 优先修正中英混说里的技术词，如 `Python`、`JSON`、`API`、`Git`、`React`、`Node`
- 不主动润色、不改写、不缩写原文

### 项目结构

```text
Sources/VoiceInput/
├── App/              # 入口、生命周期、共享类型
├── Managers/         # 热键、菜单栏、语音、浮窗、设置管理
├── Services/         # 文本注入、LLM 纠错
├── Views/            # 悬浮 HUD 与设置窗口
└── Resources/        # Info.plist 等资源
```

### 构建命令

```bash
make build    # 编译并打包 Voice Input.app
make run      # 编译调试版并直接运行
make install  # 安装到 /Applications
make clean    # 清理构建产物和生成的 .app
make bundle   # 对已编译好的 release 二进制重新打包
```

### 注意事项与限制

- 当前默认构建目标为 **`arm64-apple-macosx14.0`**。
- 实时语音识别依赖 **Apple Speech Recognition**。
- LLM 更适合作为轻量纠错层，而不是改写助手。
- 某些带有特殊安全策略的应用，对模拟粘贴的响应可能与普通应用不同。

### 欢迎贡献

欢迎提 Issue 和 PR。

比较适合继续完善的方向包括：

- Intel Mac 支持
- 更完善的打包 / 公证（notarization）流程
- 更清晰的权限诊断与引导
- 首次使用引导和 UI 细节打磨
- 为粘贴与输入法切换补充自动化测试

### 许可证

MIT，详见 [`LICENSE`](LICENSE)。
