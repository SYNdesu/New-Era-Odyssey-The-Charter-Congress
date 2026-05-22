# 场景架构指南

## 目录
1. [世界场景架构](#世界场景架构)
2. [玩家场景架构](#玩家场景架构)
3. [菜单场景架构](#菜单场景架构)
4. [区域与房间场景](#区域与房间场景)
5. [组件化设计](#组件化设计)

---

## 世界场景架构

### World.tscn 结构
```
World (Node2D)
├── AnimationPlayer
└── WorldHSM (LimboHSM)
    ├── LoadingState (LimboState)
    ├── MainMenuState (LimboState)
    ├── GameplayHSM (LimboHSM)
    │   ├── ExplorationState (LimboState)
    │   ├── CombatState (LimboState)
    │   └── PausedState (LimboState)
    ├── SavingState (LimboState)
    └── ExitingState (LimboState)
```

### WorldHSM 状态转换图
```
LoadingState
    ├── loading_done → MainMenuState
    └── game_loaded → GameplayHSM

MainMenuState
    ├── start_new_game → LoadingState
    ├── load_game → LoadingState
    └── quit → ExitingState

GameplayHSM
    ├── ExplorationState
    │   ├── enter_combat → CombatState
    │   └── pause → PausedState
    ├── CombatState
    │   └── exit_combat → ExplorationState
    └── PausedState
        └── resume → ExplorationState

GameplayHSM
    ├── save → SavingState
    └── return_main → MainMenuState

SavingState
    ├── save_done → GameplayHSM
    └── save_done_quit → ExitingState
```

### 世界脚本职责 (world.gd)
- 管理 WorldHSM 状态机
- 玩家生成与移除
- 子场景加载与切换
- 菜单堆栈管理
- 存档/读档接口
- 输入事件分发

---

## 玩家场景架构

### Player.tscn 结构
```
Player (CharacterBody2D)
├── AnimatedSprite2D
├── AnimationPlayer
├── CollisionShape2D
├── PlayerHSM (LimboHSM)
│   ├── RoamingHSM (LimboHSM)
│   │   ├── IdleState (LimboState)
│   │   ├── MoveState (LimboState)
│   │   ├── InteractState (LimboState)
│   │   ├── DialogState (LimboState)
│   │   └── FollowState (LimboState)
│   └── CombatHSM (LimboHSM)
│       ├── WaitTurnState (LimboState)
│       ├── SelectTurnState (LimboState)
│       ├── ExecuteActionState (LimboState)
│       └── EndTurnState (LimboState)
└── Camera2D
```

### PlayerHSM 状态转换
```
RoamingHSM
    ├── combat_start → CombatHSM

CombatHSM
    └── combat_end → RoamingHSM

RoamingHSM - IdleState
    ├── move → MoveState
    ├── interact → InteractState
    ├── dialog → DialogState
    └── follow → FollowState

RoamingHSM - MoveState
    ├── stop → IdleState
    └── interact → InteractState

CombatHSM
    ├── WaitTurnState
    │   └── select_turn → SelectTurnState
    ├── SelectTurnState
    │   └── turn_selected → ExecuteActionState
    ├── ExecuteActionState
    │   └── action_done → EndTurnState
    └── EndTurnState
        └── next_turn → WaitTurnState
```

### 玩家脚本职责 (player.gd)
- 管理 PlayerHSM 状态机
- 输入处理与分发
- 移动控制
- 朝向管理
- 动画播放
- 战斗属性
- 存档接口

---

## 菜单场景架构

### 菜单层级结构
1. **主菜单** (main_menu.tscn) - 游戏入口
2. **暂停菜单** (pause_menu.tscn) - 游戏中暂停
3. **设置面板** (settings_panel.tscn) - 游戏设置
4. **背包面板** (inventory_panel.tscn) - 物品管理

### 菜单堆栈系统
世界脚本维护一个菜单堆栈 `_menu_stack`，支持：
- `push_menu(panel)` - 压入新菜单
- `pop_menu()` - 弹出当前菜单
- `close_all_menus()` - 关闭所有菜单

菜单显示/隐藏通过 CanvasLayer 的子 Control 节点控制。

---

## 区域与房间场景

### 区域场景结构 (例：town_01.tscn)
```
Area_Town01 (Node2D)
├── TileMap
├── Marker2D (Spawn Points)
│   ├── spawn_default
│   └── spawn_from_shop
├── AreaPortal(s)
└── InteractableObject(s)
```

### 房间场景结构 (例：room_shop.tscn)
```
Room_Shop (Node2D)
├── TileMap
├── Marker2D (Spawn Points)
├── AreaPortal(s)
├── InteractableObject(s)
└── ChestStorage
```

### 区域传送
- 使用 `AreaPortal` 组件
- 传送触发调用 `world._on_portal_entered()`
- 包含目标场景路径和目标传送点 ID

### 出生点 (Spawn Points)
- 使用 `Marker2D` 节点
- 可选 `portal_id` 元数据/属性
- 世界脚本自动查找并放置玩家

---

## 组件化设计

### 可复用组件
项目采用组件化设计，以下是核心组件：

#### 1. AreaPortal (area_portal.gd)
- 区域传送门
- 检测玩家进入
- 发送传送信号

#### 2. InteractableObject (interactable_object.gd)
- 可交互物体基类
- 交互检测
- 交互触发

#### 3. ChestStorage (chest_storage.gd)
- 宝箱/存储容器
- 物品管理
- 交互接口

#### 4. SpawnPoint
- 使用 Marker2D 实现
- 标记玩家出生位置
- 支持 portal_id 匹配

### 组件通信原则
- 优先使用信号解耦
- 组件通过 World 或 Player 中介通信
- 避免组件间直接引用

### 渲染层级
场景节点顺序即渲染层级。详见 [PROJECT_RULES.md 渲染层级规范](PROJECT_RULES.md#渲染层级规范)。

### 添加新组件
1. 在 `scripts/world/components/` 创建脚本
2. 继承适当的基类
3. 定义需要的信号
4. 在场景中实例化并配置
