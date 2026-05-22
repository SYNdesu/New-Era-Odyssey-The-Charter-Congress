# 项目文档

## 文档结构

```
docs/
├── README.md                  # 本文档 - 文档索引
├── design/                    # 设计文档
│   ├── GAME_DESIGN.md         # 游戏设计文档（核心定位、系统架构）
│   ├── PROJECT_RULES.md       # 编码规范 + 渲染层级规范
│   ├── SCENE_GUIDE.md         # 场景架构指南
│   ├── STORY.md               # 剧情、势力与角色设定
│   ├── TASKS.md               # 开发任务列表
│   └── design_notes.md        # 早期设计决策记录
└── workflow/                  # 工作流文档
    └── WORKFLOW.md            # 开发工作流和调试指南
```

## 快速导航

### 设计文档
| 文档 | 说明 |
|------|------|
| [GAME_DESIGN.md](design/GAME_DESIGN.md) | 游戏类型、核心定位、状态机、战斗、交互、存档、故事、联机系统 |
| [PROJECT_RULES.md](design/PROJECT_RULES.md) | GDScript 编码规范、目录结构、渲染层级规范、状态机/场景编写规范 |
| [SCENE_GUIDE.md](design/SCENE_GUIDE.md) | World/Player/菜单/区域场景架构、组件化设计 |
| [STORY.md](design/STORY.md) | 剧情大纲、四大势力、主要人物、重要地点设定 |
| [TASKS.md](design/TASKS.md) | 按优先级排列的开发任务清单 |
| [design_notes.md](design/design_notes.md) | 项目早期需求文档和技术决策记录 |

### 工作流文档
| 文档 | 说明 |
|------|------|
| [WORKFLOW.md](workflow/WORKFLOW.md) | 开发流程、调试方法、提交规范 |

## 快速开始

### 新开发者
1. 阅读 [GAME_DESIGN.md](design/GAME_DESIGN.md) 理解游戏是什么
2. 阅读 [PROJECT_RULES.md](design/PROJECT_RULES.md) 了解怎么写代码
3. 阅读 [SCENE_GUIDE.md](design/SCENE_GUIDE.md) 了解场景怎么搭
4. 浏览 [STORY.md](design/STORY.md) 了解世界观

### 开始开发
1. 查看 [TASKS.md](design/TASKS.md) 选择任务
2. 参考 [WORKFLOW.md](workflow/WORKFLOW.md) 了解开发流程和调试方法
3. 有疑问查阅 [design_notes.md](design/design_notes.md) 了解历史决策

## 文档维护

- 添加新文档时更新此索引
- 保持文档链接有效
- 定期审查和更新过时内容
