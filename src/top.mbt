pub struct FallingBlock {
  mut x : Int // 掉落方块的X坐标
  mut y : Int // 掉落方块的Y坐标
  mut size : Int // 掉落方块的大小
}

pub struct Game {
  mut player_x : Int // 玩家方块的X坐标
  mut player_y : Int // 玩家方块的Y坐标
  mut player_size : Int // 玩家方块的大小
  mut blocks : Array[FallingBlock] // 掉落方块数组
  mut block_speed : Int // 掉落速度
  mut game_over : Bool // 游戏结束标志
  mut score : Int // 分数
}

let g : Game = Game::{
  player_x: 80,
  player_y: 140,
  player_size: 10,
  blocks: [FallingBlock::new(0, -10, 10)], // 初始只有一个掉落方块
  block_speed: 2,
  game_over: false,
  score: 0,
}

// FallingBlock 的构造函数
pub fn FallingBlock::new(x : Int, y : Int, size : Int) -> FallingBlock {
  { x, y, size }
}

// 随机生成函数
let random : @random.Rand = @random.new()

// 更新函数
// 更新函数
pub fn update() -> Unit {
  if g.game_over {
    display_game_over_screen()
    return
  }
  let gamepad = @wasm4.get_gamepad()

  // 控制玩家方块的移动并保持在屏幕内
  if gamepad.button_left && g.player_x > 0 {
    g.player_x -= 2
  }
  if gamepad.button_right && g.player_x + g.player_size < 160 {
    g.player_x += 2
  }

  // 更新掉落方块的位置
  for i = 0; i < g.blocks.length(); i = i + 1 {
    g.blocks[i].y += g.block_speed

    // 如果掉落方块超出屏幕底部，则重置其位置并增加分数
    if g.blocks[i].y > 160 {
      g.blocks[i].y = 0
      g.blocks[i].x = random.int(limit=150) // 确保掉落方块生成在屏幕宽度内
      g.score += 1
      play_score_sound() // 播放加分音效
    }

    // 检查与玩家方块的碰撞
    if check_collision(g.blocks[i]) {
      g.game_over = true
      play_game_over_sound()
      return
    }
  }

  // 根据分数调整难度
  adjust_difficulty()

  // 绘制游戏元素
  draw_game()
}

// 检测碰撞
fn check_collision(block : FallingBlock) -> Bool {
  return block.y + block.size > g.player_y &&
    block.x < g.player_x + g.player_size &&
    block.x + block.size > g.player_x
}

// 根据分数动态增加掉落方块数量
fn adjust_difficulty() -> Unit {
  let target_blocks = g.score / 10 + 1
  while g.blocks.length() < target_blocks {
    g.blocks.push(FallingBlock::new(random.int(limit=150), -10, 10))
  }
}

// 游戏结束显示
fn display_game_over_screen() -> Unit {
  @wasm4.text("Game Over!", 50, 70)
  @wasm4.text("Score: " + g.score.to_string(), 50, 90)
}

// 游戏绘制
fn draw_game() -> Unit {
  @wasm4.set_draw_colors(3)
  @wasm4.rect(g.player_x, g.player_y, g.player_size, g.player_size)
  @wasm4.set_draw_colors(4)
  for i = 0; i < g.blocks.length(); i = i + 1 {
    @wasm4.rect(
      g.blocks[i].x,
      g.blocks[i].y,
      g.blocks[i].size,
      g.blocks[i].size,
    )
  }
  @wasm4.text("Score: " + g.score.to_string(), 5, 5)
}

// 播放游戏结束音效
fn play_game_over_sound() -> Unit {
  @wasm4.tone(
    (200, 100),
    @wasm4.ADSR::new(20, release=5),
    @wasm4.ADSRVolume::new(50, peak=80),
    @wasm4.ToneFlag::new(),
  )
}

// 播放加分音效
fn play_score_sound() -> Unit {
  @wasm4.tone(
    (500, 600),
    @wasm4.ADSR::new(10, release=5),
    @wasm4.ADSRVolume::new(40, peak=70),
    @wasm4.ToneFlag::new(),
  )
}
