#==============================================================================
# ■ [VX] 按键跳跃
#    [VX] Jump Skill
#------------------------------------------------------------------------------
# 　 让角色拥有跳跃的能力，这个功能类似于《暗黑破坏神II》中野蛮人的技能。
#    这个脚本是友好的，在作者公开的白皮书下，你可以实现很多效果！
#
#    当玩家按下键时，主角就会执行跳跃，根据配置的不同，可以做出“跳跃技能”
#    为生活技能的效果。
#
#------------------------------------------------------------------------------
#    更新作者： DeathKing
#    许可协议： FSL
#    项目版本： 1.1.0107
#    最后更新： 2011-01-07
#    引用网址：
#------------------------------------------------------------------------------
#    - 1.1.0107 By DeathKing
#      * 整理配置模块；
#      * 优化算法，使他运行更为流畅；
#
#    - 1.0.0613 By DeathKing
#      * 初始版本完成；
#
#==============================================================================
 
#------------------------------------------------------------------------------
# ▼ 登记FSL
#------------------------------------------------------------------------------
$fscript = {} if $fscript == nil
$fscript["JumpSkill"] = "1.1.0107"
 
#------------------------------------------------------------------------------
# ▼ 通用配置模块
#------------------------------------------------------------------------------
#  在游戏中你可以修改这些常量！
#  记得使用::解析域！
#  FSL::JumpSkill::常量 = ***
#------------------------------------------------------------------------------
module FSL
  module JumpSkill
     
    # 允许跳跃，当这个为false时则不允许跳跃
    JUMP_ALLOWED = true
    # 每次跳跃的距离
    JUMP_LENGTH = 2
    # 跳跃对应按键，可以配合全键盘脚本使用
    JUMP_BUTTON = Input::L
       
    # 如果这个id不为0的话，只有在制定id的角色在
    # 队伍中且MP足够、会跳跃技能才可施放。
    # 如果JUMP_SKILL_ID为0，则指需要满足指定角色
    # 在队伍中
       
    # 跳跃技能对应主角编号
    JUMP_ACTOR_ID = 0
    # 跳跃技能对应编号，一个开关属性，
    # 要求跳跃技能对应主角习得此技能才可跳跃
    JUMP_SKILL_ID = 0
    # 每次跳跃消耗的MP
    JUMP_COST_MP  = 1
       
    # 如果不想听见烦人的音乐，请让他等于一个空字符串
    # 一个SE文件示范："Audio/SE/Jump1"
       
    # 跳跃技能SE音效文件名（可跳跃的场合）
    JUMP_ABLE_SE       = ""  #"Audio/SE/Jump1"
    # 跳跃技能SE音效文件名（不可跳跃的场合）
    JUMP_DISABLE_SE    = ""  #"Audio/SE/Buzzer1"
       
  end # JumpSkill
end # FSL
 
#==============================================================================
# ■ Game_Player
#------------------------------------------------------------------------------
# 　处理主角的类。事件启动的判定、以及地图的滚动等功能。
# 本类的实例请参考 $game_player。
#==============================================================================
 
class Game_Player < Game_Character
   
  include FSL::JumpSkill
   
  alias jump_skill_update update
   
  #---------------------------------------------------------------------------
  # ● 刷新画面
  #---------------------------------------------------------------------------
  def update
    jump_by_input
    jump_skill_update
  end
  #---------------------------------------------------------------------------
  # ● 是否按下跳跃键
  #---------------------------------------------------------------------------
  def jump_by_input
    # 判断是否按下了跳跃键
    return false unless Input.trigger?( JUMP_BUTTON )
    # 判断是否可跳跃
    if jumpable?
      # 是的话就执行跳跃
      # 播放跳跃SE
      Audio.se_play( JUMP_ABLE_SE ) if JUMP_ABLE_SE != ""
      # 扣除MP
      unless JUMP_ACTOR_ID == 0
        $game_actors[JUMP_ACTOR_ID].mp -= JUMP_COST_MP
      end
      # 执行跳跃
      sjump
      return true
    else
      # 否的话就播放无法跳跃的音效
      Audio.se_play( JUMP_DISABLE_SE ) if JUMP_DISABLE_SE != ""
      return false
    end
  end
  #---------------------------------------------------------------------------
  # ● 是否可跳跃
  #---------------------------------------------------------------------------
  #     此方法不会检查跳跃目的地是否可以通行，关于跳跃目的地是否可以通行，
  #     是由sjump方法完成的。
  #---------------------------------------------------------------------------
  def jumpable?
    # 不允许跳跃就返回false
    return false unless JUMP_ALLOWED
    jump_skill_actor = $game_actors[JUMP_ACTOR_ID]
    jump_skill = $data_skills[JUMP_SKILL_ID]
    # 获得主角是否有跳跃技能
    unless JUMP_ACTOR_ID == 0
      unless JUMP_SKILL_ID == 0
        # 如果角色不在队伍中就无法使用
        unless $game_party.members.include?( jump_skill_actor )
          return false
        else
          # 如果指定角色不会改技能就无法使用
          return false unless jump_skill_actor.skill_learn?( jump_skill )
          # 如果角色的MP不够就无法使用
          return false unless jump_skill_actor.mp >= JUMP_COST_MP
          return true
        end
      else
        return true
      end
    else
      return true
    end
  end
  #---------------------------------------------------------------------------
  # ● 超级跳跃
  #     x_plus : X 座标增值
  #     y_plus : Y 座标增值
  #---------------------------------------------------------------------------
  #     此跳跃可以搜寻跳跃能力内的最大跳跃限度，遗憾的是，这个只能搜寻一条
  #     直线。
  #---------------------------------------------------------------------------
  def sjump
    # 数据初始化
    x_plus = y_plus = 0
    # 获得主角朝向，使用逆推搜寻
    case @direction
    when 2
      JUMP_LENGTH.downto(1) do |i|
        if passable?( x , y + i )
          x_plus, y_plus = 0, i
          break
        end
      end
    when 4
      JUMP_LENGTH.downto(1) do |i|
        if passable?( x - i , y )
          x_plus, y_plus = -i, 0
          break
        end
      end
    when 6
      JUMP_LENGTH.downto(1) do |i|
        if passable?( x + i , y )
          x_plus, y_plus = i, 0
          break
        end
      end
    when 8
      JUMP_LENGTH.downto(1) do |i|
        if passable?( x , y - i )
          x_plus, y_plus = 0, -i
          break
        end
      end
    end # case @direction
    if x_plus.abs > y_plus.abs            # 横向距离较大
      x_plus < 0 ? turn_left : turn_right
    elsif x_plus.abs > y_plus.abs         # 纵向距离较大
      y_plus < 0 ? turn_up : turn_down
    end
    @x += x_plus
    @y += y_plus
    distance = Math.sqrt(x_plus * x_plus + y_plus * y_plus).round
    @jump_peak = 10 - @move_speed + distance
    @jump_count = @jump_peak * 2
    @stop_count = 0
    straighten
  end 
end
