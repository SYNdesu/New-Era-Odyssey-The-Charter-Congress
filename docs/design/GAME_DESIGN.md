# 游戏设计文档

## 目录

1. [游戏核心玩法](#游戏核心玩法)
2. [状态机设计理念](#状态机设计理念)
3. [战斗系统设计](#战斗系统设计)
4. [交互系统设计](#交互系统设计)
5. [存档系统设计](#存档系统设计)
6. [故事与任务系统](#故事与任务系统)
7. [联机系统（设计方向）](#联机系统设计方向)
8. [参考文档](#参考文档)

***

## 游戏核心玩法

### 游戏类型

3D 俯视角像素风格角色扮演游戏，类似《博德之门》系列。

### 核心定位

- **3D 俯视角** — 使用 3D 渲染但保持俯视角控制和像素风格美术
- **类博德之门玩法** — 多名角色在自由探索时平面全向自由移动，在战斗中为回合制战棋
- **嵌套式大世界** — 大地图 > 城市 > 房间的嵌套关系，支持自由探索
- **联机功能** — 支持多名玩家操纵数名角色（角色数量 >= 玩家数量）
- **丰富的故事和任务系统** — 多势力、多结局的叙事结构
- **Roguelike 元素** — 一定的随机性确保重复游玩价值

### 核心循环

1. **探索** - 在嵌套世界中移动，发现新区域和 NPC
2. **交互** - 与 NPC、物体互动，推进剧情（不含推箱子类解密）
3. **战斗** - 明雷触发、在世界中进行回合制战棋战斗
4. **成长** - 收集装备，提升能力

### 核心特色

- 层次化状态机驱动的游戏流程
- 灵活的场景切换系统（嵌套世界）
- 支持存档/读档
- 可扩展的组件化设计
- 8 向移动四边形网格
- 多层菜单堆栈系统

***

## 状态机设计理念

### 设计原则

使用 **层次化状态机 (Hierarchical State Machine, HSM)** 管理游戏流程，优势：

- 状态逻辑模块化
- 支持状态嵌套
- 过渡清晰可追踪
- 易于扩展和维护

### WorldHSM 设计

`World` 节点作为游戏的根控制器，管理全局状态：

```
WorldHSM
├── LoadingState      - 加载/初始化阶段
├── MainMenuState     - 主菜单
├── GameplayHSM       - 游戏进行中（子状态机）
│   ├── ExplorationState  - 探索模式
│   ├── CombatState       - 战斗模式
│   └── PausedState       - 暂停状态
├── SavingState       - 存档中
└── ExitingState      - 退出游戏
```

### PlayerHSM 设计

`Player` 节点管理玩家角色状态：

```
PlayerHSM
├── RoamingHSM        - 漫游模式（子状态机）
│   ├── IdleState        - 待机
│   ├── MoveState        - 移动
│   ├── InteractState    - 交互
│   ├── DialogState      - 对话
│   └── FollowState      - 跟随
└── CombatHSM         - 战斗模式（子状态机）
    ├── WaitTurnState    - 等待回合
    ├── SelectTurnState  - 选择移动和行动（合并）
    ├── ExecuteActionState-执行行动
    └── EndTurnState     - 结束回合
```

### 状态过渡事件

使用 `StringName` 类型的事件名，格式为 `&"event_name"`：

- `&"move"` / `&"stop"` - 移动控制
- `&"interact"` / `&"dialog"` - 交互
- `&"pause"` / `&"resume"` - 暂停
- `&"enter_combat"` / `&"exit_combat"` - 战斗切换
- `&"save"` / `&"load"` - 存档相关

***

## 战斗系统设计

### 战斗模式

回合制战棋战斗，在世界场景中直接进行（非独立战斗场景）。

### 战斗触发

**明雷系统**：敌人可见于世界地图上，接触后触发战斗。触发系统细节留待后续设计。

### 战斗流程

1. **进入战斗** - 从探索模式切换到战斗模式
2. **回合循环**
   - 玩家回合：选择移动和行动 → 执行 → 结束
   - 敌人回合：AI 决策 → 执行
3. **战斗结束** - 返回探索模式

### CombatHSM 状态

- **WaitTurnState** - 等待玩家输入
- **SelectTurnState** - 选择移动位置和战斗行动（合并状态）
- **ExecuteActionState** - 执行动画和效果
- **EndTurnState** - 回合结算，切换到下一方

### Reaction 系统（预留）

战斗中保留 Reaction 系统接口，作为未来扩展内容：
- 角色可配置触发条件（受击、敌人移动、队友行动等）
- 触发时自动执行预设动作
- 当前阶段预留接口，不实现具体逻辑

### 战斗属性

玩家基础属性：

- `max_health` - 最大生命值
- `current_health` - 当前生命值
- `is_invincible` - 无敌状态

***

## 交互系统设计

### 交互类型

1. **NPC 对话** - 触发对话状态
2. **物体交互** - 宝箱、门、机关等
3. **传送门** - 切换区域/房间
4. **存档点** - 触发保存

### InteractableObject 组件

可交互物体的基类组件，提供：

- 交互范围检测
- 交互触发信号
- 可扩展的交互逻辑

### 交互流程

```
玩家按交互键
    ↓
检测范围内可交互物体
    ↓
发送交互信号
    ↓
切换到 InteractState
    ↓
执行交互逻辑
    ↓
返回 IdleState
```

***

## 存档系统设计

### 存档内容

使用 `godot_core_system` 的 SaveSystem，保存：

- **World 状态** - 当前子场景、菜单状态
- **Player 状态** - 位置、朝向、属性、装备
- **游戏进度** - 任务、解锁内容

### 存档接口

可保存节点实现：

```gdscript
func save() -> Dictionary:
    return {
        "key": value,
        ...
    }

func load_data(data: Dictionary) -> void:
    value = data.get("key", default)
```

### 存档时机

- 主菜单：新游戏 / 加载游戏
- 暂停菜单：保存 / 加载
- 存档点：交互时自动保存

### 保存状态流

```
GameplayHSM
    ↓ (save / save_and_quit)
SavingState
    ├── save_done → GameplayHSM
    └── save_done_quit → ExitingState
```

***

## 故事与任务系统

### 故事背景

帝国皇帝在一场巨龙天灾中身亡，中央政府崩溃。各大势力割据，即将召开制宪大会决定帝国未来。玩家扮演佣兵小队，在乱世中崛起，最终影响历史走向。

详见 [STORY.md](STORY.md)。

### 任务系统（设计方向）

- 多势力任务线，玩家选择影响势力关系和结局
- 主线任务驱动制宪大会主线剧情
- 支线任务提供角色背景、装备奖励和世界探索
- 任务状态通过 `godot_core_system` 的 SaveSystem 持久化

***

## 联机系统（设计方向）

### 目标

支持多名玩家操纵数名角色（角色数量 >= 玩家数量）。

### 技术预留

- 输入系统已支持多人输入（`multiplayer_input_system.gd`）
- 角色与玩家解耦，支持动态分配
- 网络同步方案留待后续技术选型

***

## 参考文档

- [PROJECT_RULES.md](PROJECT_RULES.md) — 编码规范和渲染层级
- [SCENE_GUIDE.md](SCENE_GUIDE.md) — 场景架构和组件指南
- [STORY.md](STORY.md) — 剧情、势力与角色设定
- [design_notes.md](design_notes.md) — 早期设计决策记录
- [TASKS.md](TASKS.md) — 开发任务列表

