<p align="center">
  <img src="docs/banner.svg" alt="MigMouse — 让 Magic Mouse 拥有触控板般的轻触体验" width="100%">
</p>

<p align="center">
  <a href="https://github.com/Eric-kbo/migMouse/actions/workflows/build.yml"><img src="https://github.com/Eric-kbo/migMouse/actions/workflows/build.yml/badge.svg" alt="构建状态"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-6e56cf.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-111827?logo=apple" alt="macOS 14+">
</p>

<p align="center">
  让 Apple Magic Mouse 的轻触体验像触控板一样自然。
  <br>
  <a href="README.md">English</a>
</p>

## 为什么做 MigMouse？

Magic Mouse 有一整块出色的多点触控表面，但 macOS 没有给它提供触控板上的「轻点来点按」选项。MigMouse 补上了这个缺口，同时保留系统原生的指针移动、滚动和手势体验。

## 功能

- 单指轻触执行左键单击
- 双指轻触或右侧区域轻触执行右键单击
- 正确的连续点击计数，双击体验自然
- 与滚动、物理按压互斥，减少误触
- 可调整点击时长、移动距离、触摸压力和右键区域
- 实时触点诊断与模拟点击测试
- 原生菜单栏应用，无联网、无统计、无账号
- 跟随系统语言，支持简繁中文、英语、日语、韩语、法语、德语、西班牙语、巴西葡萄牙语、意大利语、俄语和阿拉伯语

## 系统要求

- macOS 14 Sonoma 或更高版本
- 支持多点触控的 Apple Magic Mouse
- 辅助功能与输入监控权限
- 从源码构建需要 Xcode 16 或更高版本

## 构建与运行

1. 克隆仓库，用 Xcode 打开 `MigMouse.xcodeproj`。
2. 如果 Xcode 要求签名，请选择你的开发者团队。
3. 运行 `MigMouse` Scheme。
4. 按提示授予辅助功能和输入监控权限，然后重新启动 MigMouse。

命令行验证：

```sh
xcodebuild \
  -project MigMouse.xcodeproj \
  -scheme MigMouse \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## 技术原理

MigMouse 运行时加载 Apple 私有的 `MultitouchSupport.framework` 读取触点帧，经手势识别和滚动/物理点击仲裁后，通过 Core Graphics 发送标准鼠标事件。因此 App Sandbox 必须保持关闭；由于依赖私有 API，本项目适合源码分发，不适合上架 Mac App Store。

## 隐私

所有触点处理都在本机完成。MigMouse 不包含网络客户端、遥测、行为统计或账号系统。

## 当前进度

第一阶段已经完成并可用。轻触拖移、拖移锁定、个性化校准和更多手势会在后续阶段实现，详见 [CHANGELOG.md](CHANGELOG.md)。

项目依赖未公开的 Apple 框架，未来 macOS 更新可能需要适配。如果你提交问题，请附上 macOS 版本和 Magic Mouse 型号。

## 参与贡献

欢迎提交 Issue 和 Pull Request。开始之前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 开源许可

MigMouse 使用 [MIT License](LICENSE) 开源。
