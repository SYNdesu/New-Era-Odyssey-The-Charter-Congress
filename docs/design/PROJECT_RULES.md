# 项目代码规范指南

## 目录
1. [GDScript 代码风格](#gdscript-代码风格)
2. [项目目录结构](#项目目录结构)
3. [状态机编写规范](#状态机编写规范)
4. [场景创建规范](#场景创建规范)
5. [渲染层级规范](#渲染层级规范)

---

## GDScript 代码风格

### 命名规范

#### 类与文件
- 类名使用 `PascalCase`，例如 `Player`, `World`
- 文件名与类名一致，例如 `player.gd`, `world.gd`
- 使用 `class_name` 定义全局类名

```gdscript
class_name Player
extends CharacterBody2D
```

#### 变量与函数
- 局部变量使用 `snake_case`，例如 `move_speed`, `current_health`
- 私有成员使用 `_` 前缀，例如 `_menu_stack`, `_current_sub_scene`
- 信号使用 `snake_case`，例如 `resume_requested`, `settings_requested`
- 函数使用 `snake_case`，例如 `_setup_state_machine()`, `update_facing_direction()`
- 常量使用 `UPPER_SNAKE_CASE`，例如 `MAX_HEALTH`, `DEFAULT_SPEED`

#### 枚举
- 枚举类型使用 `PascalCase`
- 枚举值使用 `UPPER_SNAKE_CASE`

```gdscript
enum GameState {
    MAIN_MENU,
    PLAYING,
    PAUSED
}
```

### 缩进与格式
- 使用制表符（Tab）缩进
- 函数之间空一行
- 逻辑块之间适当空行以提高可读性
- 运算符两侧加空格：`a = b + c` 而非 `a=b+c`

### 注释规范
- 使用 `##` 编写文档注释（用于生成文档）
- 复杂逻辑使用 `#` 添加单行注释
- 避免注释显而易见的代码

```gdscript
## 世界根节点 — 驱动 WorldHSM，管理玩家/子场景/菜单堆栈
class_name World
extends Node2D
```

### 导出变量
- 使用 `@export` 暴露可在编辑器中配置的变量
- 为导出变量添加注释说明用途

```gdscript
@export var move_speed: float = 200.0
@export var debug_enabled: bool = true
```

### 信号使用
- 优先使用信号而非直接函数调用进行组件间通信
- 信号名应清晰描述事件

```gdscript
signal resume_requested
signal settings_requested
```

---

## 项目目录结构

```
game-rebuilt/
├── addons/                  # 插件目录
│   ├── godot_core_system/   # 核心系统插件
│   └── limboai/            # LimboAI 插件
├── assets/                  # 资源文件
│   ├── audio/              # 音频资源
│   ├── sprites/            # 精灵图
│   └── tileset/            # 图块集
├── docs/                    # 项目文档
│   ├── README.md           # 文档索引
│   └── design/             # 设计文档
├── scenes/                  # 场景文件
│   ├── menu/               # 菜单场景
│   ├── player/             # 玩家相关场景
│   └── world/              # 世界和区域场景
├── scripts/                 # 脚本文件
│   ├── combat/             # 战斗系统脚本
│   ├── game/               # 游戏通用脚本
│   │   └── menu/           # 菜单脚本
│   ├── player/             # 玩家脚本
│   │   ├── animation/      # 动画处理
│   │   ├── input/          # 输入处理
│   │   └── states/         # 玩家状态
│   └── world/              # 世界脚本
│       ├── components/     # 世界组件
│       └── states/         # 世界状态
├── project.godot           # 项目配置
└── icon.svg                # 项目图标
```

### 目录规范
- 脚本文件放在 `scripts/` 下按功能分类
- 场景文件放在 `scenes/` 下
- 资源文件放在 `assets/` 下
- 保持脚本与场景的对应关系

---

## 状态机编写规范

### 基本结构
本项目使用 LimboAI 的 Hierarchical State Machine (HSM)。

### 状态机初始化流程
1. 获取所有子状态和子 HSM
2. 添加状态间过渡
3. 调用 `initialize()` 设置 agent
4. 设置 `initial_state`
5. 调用 `set_active(true)` 激活

```gdscript
func _setup_state_machine() -> void:
    var hsm = $PlayerHSM as LimboHSM
    # 1. 获取状态
    var idle = hsm.get_node_or_null("IdleState") as LimboState
    var move = hsm.get_node_or_null("MoveState") as LimboState
    # 2. 添加过渡
    if idle and move:
        hsm.add_transition(idle, move, &"move")
        hsm.add_transition(move, idle, &"stop")
    # 3. 初始化
    hsm.initialize(self)
    # 4. 设置初始状态
    hsm.initial_state = idle
    # 5. 激活
    hsm.set_active(true)
```

### 过渡事件命名
- 使用 `StringName` 类型（`&"event_name"`）
- 事件名使用小写加下划线
- 事件名应描述触发的动作：`&"move"`, `&"interact"`, `&"pause"`

### 状态脚本
- 每个状态对应一个独立脚本
- 状态脚本继承 `LimboState`
- 实现 `_enter()`、`_physics_update()`、`_exit()` 等方法

---

## 场景创建规范

### 场景树结构
- 根节点使用描述性名称
- 状态机节点命名为 `XxxHSM`
- 状态节点命名为 `XxxState`
- 使用唯一 ID（`unique_id`）便于引用

### 节点命名
- 根节点：场景名（PascalCase）
- 子节点：描述性名称（snake_case 或 PascalCase）
- 状态机：`[Name]HSM`
- 状态：`[Name]State`

### 外部资源
- 给外部资源设置有意义的 ID，例如 `id="1_player"`, `id="2_idle"`
- 使用 `uid://` 引用资源而非路径

### 场景实例化
- 通过 `preload()` 预加载常用场景
- 实例化后设置 `name` 属性
- 正确处理父子关系

```gdscript
var scene: PackedScene = load("res://scenes/player/player.tscn")
var player = scene.instantiate()
player.name = "Player"
add_child(player)
```

### 信号连接
- 优先在编辑器中连接信号
- 复杂连接可在代码中使用 `connect()`
- 连接函数命名为 `_on_[node]_[signal]`

```gdscript
func _connect_pause_signals() -> void:
    if not _pause_menu:
        return
    _pause_menu.resume_requested.connect(_on_pause_resume)
```

---

## 渲染层级规范

### 核心原则

使用**节点树顺序**控制渲染层级。节点在场景树中越靠后（越靠下），渲染层级越高（越靠前）。不需要 `z_index` 或额外脚本。

### 十个渲染层级

| 层级 | 前缀命名 | 说明 | 示例 |
|------|---------|------|------|
| 1 | `BACKGROUND` | 最底层背景 | `BACKGROUND_0_sky` |
| 2 | `GROUND` | 地面层 | `GROUND_0_base`, `GROUND_1_surface` |
| 3 | `OBJECT` | 对象层 | `OBJECT_0_objects`, `OBJECT_1_object2` |
| 4 | `DECO_LOW` | 低装饰层 | `DECO_LOW_0_bush`, `DECO_LOW_1_rock` |
| 5 | `CHARACTER` | 角色层 | `Player`, `NPC_Quest` |
| 6 | `DECO_HIGH` | 高装饰层（在角色上方） | `DECO_HIGH_0_trees` |
| 7 | `EFFECT` | 特效层 | `EFFECT_0_particles` |
| 8 | `UI` | UI 层 | `UI_0_hud`, `UI_1_dialog` |
| 9 | `OVERLAY` | 覆盖层 | `OVERLAY_0_transition` |

### 命名规范

```
层级前缀_序号_描述名称
```

- **层级前缀**：大写英文，如 `GROUND`、`DECO_HIGH`
- **序号**：数字，从 0 开始递增，同层级内数字越大渲染越靠前
- **描述名称**：小写英文，表示具体用途

#### 正确示例

```
GROUND_0_base
GROUND_1_surface
OBJECT_0_objects
DECO_HIGH_0_trees
EFFECT_0_particles
```

#### 错误示例

```
ground_0_base        ← 前缀必须大写
GROUND_base          ← 缺少序号
```

### 场景树结构规范

```
SceneRoot (Node2D)
├── BACKGROUND_0_xxx      ← 最底层
├── GROUND_0_xxx
├── GROUND_1_xxx
├── OBJECT_0_xxx
├── OBJECT_1_xxx
├── DECO_LOW_0_xxx
├── CHARACTER_Player      ← 角色节点
├── CHARACTER_NPC_xxx
├── DECO_HIGH_0_xxx       ← 装饰在角色上方
├── DECO_HIGH_1_xxx
├── EFFECT_0_xxx
├── UI_0_xxx
├── UI_1_xxx
└── OVERLAY_0_xxx         ← 最顶层
```

### 子场景与多人游戏

- **子场景**作为整体参与节点顺序排序，放置在对应层级的节点位置即可
- **多人游戏**：所有玩家角色的节点放在 `CHARACTER` 层级内，使用 `YSort` 自动处理玩家之间的遮挡关系。无需为不同玩家分配不同的 `z_index`

### 迁移指南

对于现有场景：
1. 按命名规范重命名 TileMapLayer 节点
2. 调整节点在场景树中的顺序
3. 将 Player 等角色节点移动到 CHARACTER 层级位置
4. 无需修改任何脚本代码
