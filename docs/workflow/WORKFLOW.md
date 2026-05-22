# 开发工作流

## 开发流程

```
需求分析 → 架构设计 → 场景搭建 → 逻辑实现 → 测试验证 → 完成
```

## 开发原则

### 分阶段确认
每个阶段完成后确认进度，确保项目方向一致：
1. 需求分析与技术选型
2. 节点结构设计与实现
3. 核心逻辑实现
4. 系统整合与调试
5. 扩展性接口设计与实现
6. 测试与优化

### 代码规范
- 遵循 [PROJECT_RULES.md](../design/PROJECT_RULES.md) 中的编码规范
- 使用 `class_name` 定义全局类名
- 优先使用信号解耦组件间通信
- 新功能先在独立分支验证

### 场景规范
- 参考 [SCENE_GUIDE.md](../design/SCENE_GUIDE.md) 中的场景树结构
- 遵循渲染层级命名规范
- 使用 `uid://` 引用资源而非路径

### 提交规范
- 一个提交做一件事
- 提交信息清晰描述变更原因
- 引用相关的文档或任务编号

## 调试

### 运行项目
```bash
godot --headless --verbose --path "项目路径"
```

### 日志
- 使用 `CoreSystem` 的 logger 输出调试信息
- 日志文件位于 `user://logs/godot.log`
- Godot 4.6 项目日志目录：`%APPDATA%/Godot/app_userdata/game_rebuilt/logs/`

## 参考文档

| 文档 | 用途 |
|------|------|
| [GAME_DESIGN.md](../design/GAME_DESIGN.md) | 游戏设计理念和系统架构 |
| [PROJECT_RULES.md](../design/PROJECT_RULES.md) | 编码规范和渲染层级 |
| [SCENE_GUIDE.md](../design/SCENE_GUIDE.md) | 场景架构和组件指南 |
| [STORY.md](../design/STORY.md) | 剧情和角色设定 |
| [TASKS.md](../design/TASKS.md) | 开发任务列表 |
