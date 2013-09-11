#=============================================================================
# ■ [VX] 技能消耗物品
#    [VX] Skill Need Item 
#-----------------------------------------------------------------------------
#    设定一些值，当拥有制定物品的制定个数及以上时才可发动特技。发动特技会
#    消耗掉这些物品。
#
#    在技能的“注释”中如下书写（请确保使用的是西文半角而不是全角)：
#        <need_item 物品id，对应数量 物品id，对应数量 …… >
#        <need_item 1,1 2,2 3,3>
#    
#-----------------------------------------------------------------------------
#    更新作者： DeathKing 六祈 
#    许可协议： FSL -NOS ADK
#    项目版本： 1.6.0108
#    最后更新： 2011-01-08
#    引用网址：
#-----------------------------------------------------------------------------
#    - 1.6.0108 By DeathKing
#      * 修正了有的角色无法释放技能的BUG；
#      * 修正了窗体的Z坐标，使他始终置于最上；
#      * 添加了RPG::UsabeItem::Skill#item_reqire方法，使得可以快速
#        获取道具的要求列表，这样脚本运行更为快速；
#
#    - 1.5.0726 By DeathKing
#      * 修正了按下PageDown和PageUp后无法切换角色的小BUG；
#
#    - 1.4.0725 By 六祈
#      * 修正了Game_Actor.skill_can_use?方法的错误；
#      * 修正了Window_SNItem.skill_can_use?方法的错误；
#      * 添加了对技能是否可使用的重新判定；
#
#    - 1.3.0719 By DeathKing
#      * ADK的升级，可兼容沉影不器的读取装备注释脚本；
#
#    - 1.2.0714 By DeathKing
#      * 修改了消耗物品的算法；
#
#    - 1.1.0607 By DeathKing
#      * 改变了设置方法；
#
#    - 1.0.0529 By DeathKing
#      * 初始版本完成；
#
#=============================================================================

#-----------------------------------------------------------------------------
# ▼ 登记FSL
#-----------------------------------------------------------------------------
$fscript = {} if $fscript == nil
$fscript["SkillNeedItem"] = "1.6.0108"

#-----------------------------------------------------------------------------
# ▼ 检查依赖
#-----------------------------------------------------------------------------
if $fscript["ADK"].to_s <= "1.2"
  miss = "增强开发包（ADK）"
  version = "1.2"
  print "缺少#{miss}，请下载或放在本脚本之前，并确保其版本不低于#{version}。"
end
  
#-----------------------------------------------------------------------------
# ▼ 通用配置模块
#-----------------------------------------------------------------------------
module FSL
  module SNItem
      
    # 改进后的技能消耗物品可以对物品是否足够做出判断了，不过我我们依然
    # 不能让他很清楚的现实在物品提示中
      
    # （用于提示所需物品数量的）窗口的相关配置，一般不修改
    WINDOW_X     = 272  # X  544 / 2
    WINDOW_Y     = 112  # Y  56  * 2
    WINDOW_W     = 274  # 宽
    WINDOW_H     = 640  # 高
    BACK_OPACITY = 200  # 透明度，255为不透明
      
      
    TEXT_NEED       = "需要："        # “需要：”一词的字符
    TEXT_NEED_X     = WINDOW_X - 104  # “需要：”字符的 X 坐标
    TEXT_ITEM_NUM_X = WINDOW_X - 52   # 物品数量的 X 坐标
      
  end
end

#==============================================================================
# ■ RPG::UsabeItem::Skill
#------------------------------------------------------------------------------
# 　 管理技能的类。
#==============================================================================
module RPG
  class Skill < UsableItem
    def item_require
      # 如果已定义@item_require就直接结束
      return @item_require if (defined? @item_require)
      # 获得操作数
      items = self.read_notes["need_item"]
      # 产生一个哈希
      @item_require = {} 
      # 如果获得的操作数为空
      return @item_require if items == nil
      # 生成物品的需求列表
      items.each do |e|
        t = e.split(",")
        @item_require[t[0].to_i] = t[1].to_i
      end
      # 返回物品的需求列表
      return @item_require
    end    
  end
end

#==============================================================================
# ■ Window_SNItem
#------------------------------------------------------------------------------
# 　 需要的物品的窗口。
#==============================================================================

class Window_SNItem < Window_Base
  
  include FSL::SNItem
  
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     x      : 窗口 X 座标
  #     y      : 窗口 Y 座标
  #     width  : 窗口宽度
  #     height : 窗口高度
  #--------------------------------------------------------------------------
  def initialize(x=WINDOW_X, y=WINDOW_Y, width=WINDOW_W, height=WINDOW_H)
    super(x, y, width, height)
    self.back_opacity = BACK_OPACITY
    self.visible = false
    self.z = 9999
  end  
  #--------------------------------------------------------------------------
  # ● 判定技能可否使用（需要的物品是否满足）
  #     skill  : 技能
  #
  #    在Game_Actor#skill_can_use?方法中调用时可传递self.index给第二个参数
  #--------------------------------------------------------------------------
  def self.skill_can_use?(skill,actor_id)
    # 如果传递过来的skill为空
    return false if skill == nil
    # 读取need_item项的参数
    item_need = skill.item_require
    # need_item参数为空的话返回true
    return true if item_need.empty?
    # 产生一个队伍物品的哈希克隆(item_id => number)
    party_items = {}
    $game_party.items.each do |it|
      party_items[it.id] = $game_party.item_number(it)
    end
    # 如果是第一个行动的角色或者不在战斗中则跳过
    unless actor_id == 0 or $game_temp.in_battle == false
      # 计算到前一个角色技能消耗为止的剩余物品数量哈希
      0.upto( actor_id - 1 ) do |ai|
        action = $game_party.members[ai].action
        next if action.kind != 1
        temp_cost = $data_skills[action.skill_id].item_require
        next if temp_cost.empty?
        temp_cost.each do |key, value|
          party_items[key] -= value
        end
      end
    end
    # 判定剩余物品是否足够使用技能
    item_need.each do |key, value|
      return false unless party_items.has_key?(key)
      return false if (party_items[key] < value)
    end
    return true
   end
  #--------------------------------------------------------------------------
  # ● 刷新窗口
  #     skill  : 技能
  #     index  : 技能在技能窗口的索引，用来判定本
  #              窗口应该显示在左边还是右边
  #--------------------------------------------------------------------------
  def refresh( skill, index = 0)
    # 清除之前产生的位图
    self.contents.clear
    # 如果skill为空就返回false
    return false if skill == nil
    # 先让需要窗口不可见
    self.visible = false
    # 读取参数
    need_item = skill.item_require
    # 如果参数为空，就将其隐藏并返回false
    return false if need_item.empty?
    # 判定索引以决定窗口位置
    self.x = index % 2 == 0 ? WINDOW_X : 0
    # 改变窗口大小
    self.height = need_item.size * 24 + 32
    # 将窗口置为可见
    self.visible = true
    create_contents
    # 遍历用参数
    i = 0
    # 遍历参数列表
    need_item.each do |key, value|
      # 生成物品
      item = $data_items[key]
      # 判定物品是否足够
      enabled = $game_party.item_number(item) >= value ? true : false
      # 绘制文字
      draw_item_name(item, 0, WLH * i, enabled)
      self.contents.font.color.alpha = enabled ? 255 : 128
      self.contents.draw_text(TEXT_NEED_X, WLH * i, 96, WLH, TEXT_NEED)
      self.contents.draw_text(TEXT_ITEM_NUM_X,  WLH * i, 32, WLH, value)
      i += 1
    end # need_item.each
  end 
  #--------------------------------------------------------------------------
  # ● 执行对物品消耗
  #     skill  : 技能
  #--------------------------------------------------------------------------
  def self.exec_cost( skill )
    # 传递错误就直接返回false
    return false if skill == nil
    # 读取need_item项的参数
    need_item = skill.item_require#read_notes["need_item"]
    # 如果参数为空就直接返回
    return true if need_item.empty?
    need_item.each do |key, value|
      $game_party.gain_item($data_items[key], -value)
    end
  end
  
end # Window_SNItem

#==============================================================================
# ■ Game_Actor
#------------------------------------------------------------------------------
# 　 处理角色的类。本类在 Game_Actors 类 ($game_actors) 的内部使用、
# Game_Party 类请参考 ($game_party) 。
#==============================================================================

class Game_Actor
  
  alias snitem_skill_can_use? skill_can_use?
  
  #--------------------------------------------------------------------------
  # ● 可用技能判断
  #     skill : 技能
  #--------------------------------------------------------------------------
  def skill_can_use?(skill)
    return false unless Window_SNItem.skill_can_use?(skill, self.index)
    snitem_skill_can_use?(skill)
  end
end

#==============================================================================
# ■ Scene_Skill
#------------------------------------------------------------------------------
# 　 处理特技画面的类。
#==============================================================================

class Scene_Skill < Scene_Base

  alias snitem_initialize          initialize
  alias snitem_terminate           terminate
  alias snitem_update              update
  alias snitem_use_skill_nontarget use_skill_nontarget

  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     actor_index : 角色位置
  #--------------------------------------------------------------------------
  def initialize( actor_index = 0, equip_index = 0 )
    snitem_initialize( actor_index, equip_index )
    @snitem_window = Window_SNItem.new
  end
  #--------------------------------------------------------------------------
  # ● 结束处理
  #--------------------------------------------------------------------------
  def terminate
    snitem_terminate
    @snitem_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update
    snitem_update
    @snitem_window.refresh( @skill_window.skill, @skill_window.index )
  end
  
  #--------------------------------------------------------------------------
  # ● 非同伴目标使用物品
  #--------------------------------------------------------------------------
  def use_skill_nontarget
    # 执行对物品的消耗
    Window_SNItem.exec_cost(@skill)
    # 调用原方法
    snitem_use_skill_nontarget
  end
  
end # Scene_Skill

#==============================================================================
# ■ Scene_Battle
#------------------------------------------------------------------------------
# 　 处理战斗画面的类。
#=============================================================================

class Scene_Battle < Scene_Base
  
  include FSL::SNItem
  
  alias snitem_update_skill_selection update_skill_selection
  alias snitem_start_skill_selection  start_skill_selection
  alias snitem_end_skill_selection    end_skill_selection
  alias snitem_execute_action_skill   execute_action_skill
  
  #--------------------------------------------------------------------------
  # ● 开始技能选择
  #--------------------------------------------------------------------------
  def start_skill_selection
    snitem_start_skill_selection
    # 创建需要道具窗口，并把y坐标上移
    @snitem_window = Window_SNItem.new(272,56)
  end
  #--------------------------------------------------------------------------
  # ● 结束技能选择
  #--------------------------------------------------------------------------
  def end_skill_selection
    if @skill_window != nil
      @snitem_window.dispose
      @snitem_window = nil
    end
    snitem_end_skill_selection
  end
  #--------------------------------------------------------------------------
  # ● 更新技能选择
  #--------------------------------------------------------------------------
  def update_skill_selection
    # 刷新技能
    @snitem_window.refresh( @skill_window.skill, @skill_window.index )
    # 调用原方法内容
    snitem_update_skill_selection
  end
  #--------------------------------------------------------------------------
  # ● 执行战斗行动：使用技能
  #--------------------------------------------------------------------------
  def execute_action_skill
    # 执行原内容
    snitem_execute_action_skill
    # 生成skill
    skill = @active_battler.action.skill
    Window_SNItem.exec_cost( skill )
  end
  
end # Scene_Battle

