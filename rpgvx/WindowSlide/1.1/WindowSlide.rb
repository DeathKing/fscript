
#==============================================================================
# [VX] 窗口滑动
# [VX] WindowSlide
#----------------------------------------------------------------------------
# 使用说明:
# 创建窗口之后，可以使用调整窗口的座标，并且将窗口滑动到指定位置。
# 可用于制作华丽菜单显示效果
# * 窗口.in(方向[, 移动距离])
#     方向可以为 2(下), 4(左), 6(右), 8(上)
#     移动距离默认为 10
#    将窗口滑动至画面外。
#
# * 窗口.out(方向[, 移动距离])
#     方向可以为 2(下), 4(左), 6(右), 8(上)
#     移动距离默认为 10
#    将窗口由画面外滑动至原位。
#
# * 窗口.move_to(目标 X 座标, 目标 Y 座标[, 移动距离])
#     移动距离默认为 10
#    将窗口滑动至指定座标。
#----------------------------------------------------------------------------
#    更新作者： 雪流星(Snstar2006)
#    许可协议： FSL
#    项目版本： 1.1.0121
#----------------------------------------------------------------------------
#    - 1.1.0121 By 雪流星(Snstar2006)
#      * 修改算法，省去计算根号的步骤，稍微提高效率
#    - 1.0.0121 By 雪流星(Snstar2006)
#      * 初版
#==============================================================================
$fscript = {} if $fscript == nil
$fscript["WindowSlide"] = "1.1.0121"

class Window_Base < Window
  alias move_window_initialize initialize
  def initialize(x, y, width, height)
    move_window_initialize(x, y, width, height)
    @permanent_x = x
    @permanent_y = y
  end
  def in(direction, step=10)
    case direction
    when 2
      move_to(self.x, -self.height, step)
    when 4
      move_to(-self.width, self.y, step)
    when 6
      move_to(Graphics.width + self.width, self.y, step)
    when 8
      move_to(self.x, Graphics.height + self.height, step)
    end
    Graphics.wait(1)
  end
  def out(direction, step=10)
    case direction
    when 2, 8
      move_to(self.x, @permanent_y, step)
    when 4, 6
      move_to(@permanent_x, self.y, step)
    end
  end
  def move_to(dest_x, dest_y, move_step=10)
    dx = dest_x - self.x
    dy = dest_y - self.y
    if dx == 0
      dy_step = move_step
      dx_step = 0
    elsif dy == 0
      dx_step = move_step
      dy_step = 0
    else
      max_distance_sq = dx**2+dy**2
      angle = Math.atan(dy.abs/dx.abs)
      dy_step = move_step*Math.sin(angle)
      dx_step = max_distance_sq - dy_step**2
    end
    while (self.x != dest_x || self.y != dest_y)
      if dx > 0
        self.x = [self.x + dx_step, dest_x].min
      else
        self.x = [self.x - dx_step, dest_x].max
      end
      if dy > 0
        self.y = [self.y + dy_step, dest_x].min
      else
        self.y = [self.y - dy_step, dest_x].max
      end
      Graphics.wait(1)
    end
  end
end
