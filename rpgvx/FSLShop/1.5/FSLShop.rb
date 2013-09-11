#===============================================================================
# ■ [VX]简易商店拓展描绘
#    [VX]FirefliesSimulation
#-------------------------------------------------------------------------------
# 【基本机能】方便商店购物选择
#  放在默认脚本之后，Main脚本之前，通过事件指令【商店处理】调用。
#
#-------------------------------------------------------------------------------
#    更新作者： wangswz DeathKing
#    许可协议： FSL
#    项目版本： 1.5.0903
#    引用网址： http://bbs.66rpg.com/thread-154915-1-1.html
#
#-------------------------------------------------------------------------------
#    - 1.5.0903  By wangswz
#      * 增加物品数值显示
#      * 增加对KGC数值破限脚本的支持
#
#    - 1.4.0830  By DeathKing
#      * 修正了item.number_limit的NoMethodError判断错误问题
#
#    - 1.3.0828  By wangswz
#      * 调整操作手感 L R 换成左右键
#
#    - 1.2.0828  By wangswz
#      * 物品 武器 防具分栏显示
#      * 现在可以在武器 防具栏内按X键（键盘默认A）来切换进行ATK DEF SPI AGI属性的
#        降序排列了
#
#    - 1.1.0825  By wangswz
#      * 兼容KGC合成脚本
#      * 增加物品描绘信息
#
#-------------------------------------------------------------------------------


#===============================================================================
#-------------------------------------------------------------------------------
# ▼ 通用配置模块
#-------------------------------------------------------------------------------
module FSL
  module SHOP
    # 无法装备的提示信息
    Shop_help = "-无法装备-"
    
    # 无法使用的提示信息
    Shop_help2 = "-无法使用-"
    
    # 设置atk def spi agi 上升 下降 相等时 图标显示 4个一组
    Shop_icon = [
    120,121,122,123,
    124,125,126,127,
      0,  0,  0,  0
    ]
  end
end
#==============================================================================
$imported = {} if $imported == nil
$fscript = {} if $fscript == nil
$fscript["FSLShop"] = "1.5.o903"
#==============================================================================

#==============================================================================
# ■ Scene_Map
#==============================================================================

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● ショップ画面への切り替え
  #--------------------------------------------------------------------------
  def call_shop
    if $imported["ComposeItem"] == true && $game_switches[KGC::ComposeItem::COMPOSE_CALL_SWITCH]
      # 合成画面に移行
      $game_temp.next_scene = nil
      $game_switches[KGC::ComposeItem::COMPOSE_CALL_SWITCH] = false
      $scene = Scene_ComposeItem.new
    else
      $game_temp.next_scene = nil
      $scene = Scene_Shop2.new
    end
  end
end
#==============================================================================
# ■ Scene_Shop
#------------------------------------------------------------------------------
# 　处理商店画面的类。
#==============================================================================

class Scene_Shop2 < Scene_Base
  #--------------------------------------------------------------------------
  # ● 开始处理
  #--------------------------------------------------------------------------
  def start
    super
    create_menu_background
    create_command_window
    create_command_window2
    @help_window = Window_Help.new
    @gold_window = Window_Gold.new(384, 56)
    @dummy_window = Window_Base.new(0, 112, 544, 304)
    @dummy_window2 = Window_Base.new(304, 112, 240, 304)
    @dummy_window3 = Window_Base.new(0, 168, 304, 248)
    @dummy_window2.visible = false
    @dummy_window3.visible = false
    @buy_window = Window_ShopBuy2.new(0, 168)
    @buy_window.active = false
    @buy_window.visible = false
    @buy_window.help_window = @help_window
    @sell_window = Window_ShopSell.new(0, 112, 544, 304)
    @sell_window.active = false
    @sell_window.visible = false
    @sell_window.help_window = @help_window
    @number_window = Window_ShopNumber.new(0, 112)
    @number_window.active = false
    @number_window.visible = false
    @actor_index = 0
    @status_window = Window_Shop_ActorStatus.new($game_party.members[@actor_index])
    @status_window.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 结束处理
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_menu_background
    dispose_command_window
    dispose_command_window2
    @help_window.dispose
    @gold_window.dispose
    @dummy_window.dispose
    @dummy_window2.dispose
    @dummy_window3.dispose
    @buy_window.dispose
    @sell_window.dispose
    @number_window.dispose
    @status_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新画面
  #--------------------------------------------------------------------------
  def update
    super
    update_menu_background
    @help_window.update
    @command_window.update
    @command_window2.update
    @gold_window.update
    @dummy_window.update
    @dummy_window2.update
    @dummy_window3.update
    @buy_window.update
    @sell_window.update
    @number_window.update
    @status_window.update
    if @command_window.active
      update_command_selection
    elsif @buy_window.active
      update_buy_selection1
    elsif @sell_window.active
      update_sell_selection
    elsif @number_window.active
      update_number_input
    elsif @command_window2.active
      update_command_selection2
    end
  end
  #--------------------------------------------------------------------------
  # ● 生成命令窗口
  #--------------------------------------------------------------------------
  def create_command_window
    s1 = Vocab::ShopBuy
    s2 = Vocab::ShopSell
    s3 = Vocab::ShopCancel
    @command_window = Window_Command.new(384, [s1, s2, s3], 3)
    @command_window.y = 56
    if $game_temp.shop_purchase_only
      @command_window.draw_item(1, false)
    end
  end
  #--------------------------------------------------------------------------
  # ● 释放命令窗口
  #--------------------------------------------------------------------------
  def dispose_command_window
    @command_window.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新命令窗口
  #--------------------------------------------------------------------------
  def update_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      $scene = Scene_Map.new
    elsif Input.trigger?(Input::C)
      case @command_window.index
      when 0  # 买入
        Sound.play_decision
        @command_window.active = false
        @dummy_window.visible = false
        @dummy_window2.visible = true
        @dummy_window3.visible = true
        @command_window2.active = true
        @command_window2.visible = true
      when 1  # 卖出
        if $game_temp.shop_purchase_only
          Sound.play_buzzer
        else
          Sound.play_decision
          @command_window.active = false
          @dummy_window.visible = false
          @sell_window.active = true
          @sell_window.visible = true
          @sell_window.refresh
        end
      when 2  # 离开
        Sound.play_decision
        $scene = Scene_Map.new
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 生成二级命令窗口
  #--------------------------------------------------------------------------
  def create_command_window2
    s1 = "物品"
    s2 = "武器"
    s3 = "防具"
    @command_window2 = Window_Command.new(304, [s1, s2, s3], 3)
    @command_window2.x = 0
    @command_window2.y = 112
    @command_window2.active = false
    @command_window2.visible = false
  end
  #--------------------------------------------------------------------------
  # ● 释放二级命令窗口
  #--------------------------------------------------------------------------
  def dispose_command_window2
    @command_window2.dispose
  end
  #--------------------------------------------------------------------------
  # ● 更新二级命令窗口
  #--------------------------------------------------------------------------
  def update_command_selection2
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @command_window2.active = false
      @command_window2.visible = false
      @dummy_window.visible = true
      @dummy_window2.visible = false
      @dummy_window3.visible = false
      @buy_window.active = false 
      @buy_window.visible = false 
      @status_window.visible = false 
      @status_window.item = nil 
      @help_window.set_text("") 
      return 
    elsif Input.trigger?(Input::C)
      case @command_window2.index
      when 0
        Sound.play_decision
        @command_window2.active = false
        @buy_window.index = 0
        @buy_window.active = true
        @buy_window.visible = true
        @buy_window.type = 0
        @buy_window.refresh
        @status_window.visible = true
      when 1
        Sound.play_decision
        @command_window2.active = false
        @buy_window.index = 0
        @buy_window.active = true
        @buy_window.visible = true
        @buy_window.type = 1
        @buy_window.refresh
        @status_window.visible = true
      when 2
        Sound.play_decision
        @command_window2.active = false
        @buy_window.index = 0
        @buy_window.active = true
        @buy_window.visible = true
        @buy_window.type = 2
        @buy_window.refresh
        @status_window.visible = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新买入选择
  #--------------------------------------------------------------------------
  def update_buy_selection1
    @status_window.item = @buy_window.item 
    if Input.trigger?(Input::B) 
      Sound.play_cancel 
      @command_window2.active = true
      @buy_window.active = false 
      @buy_window.visible = false 
      @status_window.visible = false 
      @status_window.item = nil 
      @help_window.set_text("") 
      return 
    end
    if Input.trigger?(Input::C) 
      @item = @buy_window.item 
      number = $game_party.item_number(@item) 
      if $imported["LimitBreak"] == true
        if @item == nil || @item.price > $game_party.gold || 
          number == @item.number_limit 
          Sound.play_buzzer 
        else 
          Sound.play_decision 
          max = (@item.price == 0 ? 
          @item.number_limit : $game_party.gold / @item.price) 
          max = [max, @item.number_limit - number].min 
          @buy_window.active = false 
          @buy_window.visible = false 
          @number_window.set(@item, max, @item.price) 
          @number_window.active = true 
          @number_window.visible = true 
        end
      else
        if @item == nil or @item.price > $game_party.gold or number == 99
          Sound.play_buzzer
        else
          Sound.play_decision
          max = @item.price == 0 ? 99 : $game_party.gold / @item.price
          max = [max, 99 - number].min
          @buy_window.active = false
          @buy_window.visible = false
          @number_window.set(@item, max, @item.price)
          @number_window.active = true
          @number_window.visible = true
        end
      end
    end
    if Input.trigger?(Input::RIGHT)
      Sound.play_cursor
      next_actor
    elsif Input.trigger?(Input::LEFT)
      Sound.play_cursor
      prev_actor
    end
    if Input.trigger?(Input::X)
      @buy_window.sort_item
    end
  end
  #--------------------------------------------------------------------------
  # ● 切换至下一角色画面
  #--------------------------------------------------------------------------
  def next_actor
    @actor_index += 1
    @actor_index %= $game_party.members.size
    @status_window.actor = ($game_party.members[@actor_index])
  end
  #--------------------------------------------------------------------------
  # ● 切换至上一角色画面
  #--------------------------------------------------------------------------
  def prev_actor
    @actor_index += $game_party.members.size - 1
    @actor_index %= $game_party.members.size
    @status_window.actor = ($game_party.members[@actor_index])
  end
  #--------------------------------------------------------------------------
  # ● 更新卖出选择
  #--------------------------------------------------------------------------
  def update_sell_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      @command_window.active = true
      @dummy_window.visible = true
      @sell_window.active = false
      @sell_window.visible = false
      @status_window.item = nil
      @help_window.set_text("")
    elsif Input.trigger?(Input::C)
      @item = @sell_window.item
      @status_window.item = @item
      if @item == nil or @item.price == 0
        Sound.play_buzzer
      else
        Sound.play_decision
        max = $game_party.item_number(@item)
        @sell_window.active = false
        @sell_window.visible = false
        @number_window.set(@item, max, @item.price / 2)
        @number_window.active = true
        @number_window.visible = true
        @status_window.visible = true
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新数值输入
  #--------------------------------------------------------------------------
  def update_number_input
    if Input.trigger?(Input::B)
      cancel_number_input
    elsif Input.trigger?(Input::C)
      decide_number_input
    end
  end
  #--------------------------------------------------------------------------
  # ● 取消数值输入
  #--------------------------------------------------------------------------
  def cancel_number_input
    Sound.play_cancel
    @number_window.active = false
    @number_window.visible = false
    case @command_window.index
    when 0  # 买入
      @buy_window.active = true
      @buy_window.visible = true
    when 1  # 卖出
      @sell_window.active = true
      @sell_window.visible = true
      @status_window.visible = false
    end
  end
  #--------------------------------------------------------------------------
  # ● 确认数值输入
  #--------------------------------------------------------------------------
  def decide_number_input
    Sound.play_shop
    @number_window.active = false
    @number_window.visible = false
    case @command_window.index
    when 0  # 买入
      $game_party.lose_gold(@number_window.number * @item.price)
      $game_party.gain_item(@item, @number_window.number)
      @gold_window.refresh
      @buy_window.refresh
      @status_window.refresh
      @buy_window.active = true
      @buy_window.visible = true
    when 1  # 卖出
      $game_party.gain_gold(@number_window.number * (@item.price / 2))
      $game_party.lose_item(@item, @number_window.number)
      @gold_window.refresh
      @sell_window.refresh
      @status_window.refresh
      @sell_window.active = true
      @sell_window.visible = true
      @status_window.visible = false
    end
  end
end
#==============================================================================
# ■ Window_Shop_ActorStatus
#------------------------------------------------------------------------------
# 　显示角色的状态窗口。
#==============================================================================

class Window_Shop_ActorStatus < Window_Base
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     actor : 角色
  #--------------------------------------------------------------------------
  def initialize(actor, item = nil, sort = 0)
    super(304, 112, 240, 304)
    @item = item
    @actor = actor
    @sort = sort
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    draw_Shopface(@actor.face_name, @actor.face_index, 84, 4)
    draw_actor_name(@actor, 4, 0)
    draw_actor_graphic(@actor, 192, 56)
    
    if @item != nil
      draw_actor_parameter_change(@actor, 4, 96)
      number = $game_party.item_number(@item)
      self.contents.font.color = system_color
      self.contents.draw_text(4, WLH * 10, 200, WLH, Vocab::Possession)
      self.contents.font.color = normal_color
      self.contents.draw_text(4, WLH * 10, 200, WLH, number, 2)
      if @item.is_a?(RPG::Item) && @item.scope > 0
        draw_item_parameter_change(4, 48)
      elsif @item.is_a?(RPG::Item)
        self.contents.font.color = system_color
        self.contents.draw_text(0, y + 24, 200, WLH, FSL::SHOP::Shop_help2, 1)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制物品效果
  #     x     : 绘制点 X 座标
  #     y     : 绘制点 Y 座标
  #--------------------------------------------------------------------------
  def draw_item_parameter_change(x, y)
    if @item.scope > 6
      draw_actor_hp(@actor, x, y)
      draw_actor_mp(@actor, x, y + 24)
      self.contents.font.color = system_color
      self.contents.draw_text(x, y + WLH * 2, 200, WLH, "hp mp 回复值/率", 2)
          
      self.contents.font.color = hp_gauge_color1
      self.contents.draw_text(x - 10, y + WLH * 3, 104, WLH, sprintf("%d", @item.hp_recovery), 2)
      self.contents.draw_text(x, y + WLH * 4, 104, WLH, sprintf("%d", @item.hp_recovery_rate)+"%", 2)
      
      self.contents.font.color = mp_gauge_color1
      self.contents.draw_text(x - 10, y + WLH * 3, 200, WLH, sprintf("%d", @item.mp_recovery), 2)
      self.contents.draw_text(x, y + WLH * 4, 200, WLH, sprintf("%d", @item.mp_recovery_rate)+"%", 2)
      
      if @item.parameter_type > 0
        self.contents.font.color = system_color
        self.contents.draw_text(x, y + WLH * 7, 200, WLH, "增加能力")
        self.contents.font.color = normal_color
        case @item.parameter_type
        when 1
          self.contents.draw_text(x, y + WLH * 7, 200, WLH, "HP", 1)
        when 2
          self.contents.draw_text(x, y + WLH * 7, 200, WLH, "MP", 1)
        when 3
          self.contents.draw_text(x, y + WLH * 7, 200, WLH, "ATK", 1)
        when 4
          self.contents.draw_text(x, y + WLH * 7, 200, WLH, "DEF", 1)
        when 5
          self.contents.draw_text(x, y + WLH * 7, 200, WLH, "SPI", 1)
        when 6
          self.contents.draw_text(x, y + WLH * 7, 200, WLH, "AGI", 1)
        end
        self.contents.draw_text(x, y + WLH * 7, 200, WLH, sprintf("%d", @item.parameter_points), 2)
      else
        self.contents.font.color = text_color(7)
        self.contents.draw_text(x, y + WLH * 7, 200, WLH, "增加能力")
      end
    else
      self.contents.font.color = normal_color
      draw_actor_parameter(@actor, x, y, 0)
      draw_actor_parameter(@actor, x, y + 24, 2)
      
      self.contents.font.color = system_color
      self.contents.draw_text(x, y + WLH * 2, 240, WLH, "伤害值 力量/精神影响")
      
      self.contents.font.color = normal_color
      self.contents.draw_text(x, y + WLH * 3, 104, WLH, sprintf("%d", @item.base_damage))
      
      self.contents.font.color = hp_gauge_color1
      self.contents.draw_text(x, y + WLH * 4, 104, WLH, sprintf("%d", @item.atk_f), 2)
      
      self.contents.font.color = mp_gauge_color1
      self.contents.draw_text(x, y + WLH * 4, 200, WLH, sprintf("%d", @item.spi_f), 2)
    end

    self.contents.font.color = system_color
    if @item.plus_state_set.size == 0
      self.contents.font.color = text_color(7)
    end
    self.contents.draw_text(x, y + WLH * 5, 200, WLH, "增益")
    self.contents.font.color = system_color
    if @item.minus_state_set.size == 0
      self.contents.font.color = text_color(7)
    end
    self.contents.draw_text(x, y + WLH * 6, 200, WLH, "削减")
    m = 48
    for i in @item.plus_state_set
      draw_icon($data_states[i].icon_index, x + m, y + WLH * 5)
      break if m == 168
      m += 24
    end
    m = 48
    for i in @item.minus_state_set
      draw_icon($data_states[i].icon_index, x + m, y + WLH * 6)
      break if m == 168
      m += 24
    end
  end 
  #--------------------------------------------------------------------------
  # ● 绘制角色当前装备和能力值
  #     actor : 角色
  #     x     : 绘制点 X 座标
  #     y     : 绘制点 Y 座标
  #--------------------------------------------------------------------------
  def draw_actor_parameter_change(actor, x, y)
    return if @item.is_a?(RPG::Item)
    enabled = actor.equippable?(@item)
    if @item.is_a?(RPG::Weapon)
      item1 = weaker_weapon(actor)
    elsif actor.two_swords_style and @item.kind == 0
      item1 = nil
    else
      if $imported["EquipExtension"] == true
        index = actor.equip_type.index(@item.kind)
        item1 = (index != nil ? actor.equips[1 + index] : nil)
      else
        item1 = actor.equips[1 + @item.kind]
      end
    end
    
    if enabled
      
      atk1 = item1 == nil ? 0 : item1.atk
      atk2 = @item == nil ? 0 : @item.atk
      change = atk2 - atk1
      shop_change(change)
      if change > 0
        draw_icon(FSL::SHOP::Shop_icon[0], 108, y + WLH)
      elsif  change < 0
        draw_icon(FSL::SHOP::Shop_icon[4], 108, y + WLH)
      else
        draw_icon(FSL::SHOP::Shop_icon[8], 108, y + WLH)
      end
      self.contents.draw_text(x, y + WLH, 200, WLH, sprintf("%d", atk2), 2)
      
      def1 = item1 == nil ? 0 : item1.def
      def2 = @item == nil ? 0 : @item.def
      change = def2 - def1
      shop_change(change)
      if change > 0
        draw_icon(FSL::SHOP::Shop_icon[1], 108, y + WLH * 2)
      elsif  change < 0
        draw_icon(FSL::SHOP::Shop_icon[5], 108, y + WLH * 2)
      else
        draw_icon(FSL::SHOP::Shop_icon[9], 108, y + WLH)
      end
      self.contents.draw_text(x, y + WLH * 2, 200, WLH, sprintf("%d", def2), 2)
      
      spi1 = item1 == nil ? 0 : item1.spi
      spi2 = @item == nil ? 0 : @item.spi
      change = spi2 - spi1
      shop_change(change)
      if change > 0
        draw_icon(FSL::SHOP::Shop_icon[2], 108, y + WLH * 3)
      elsif  change < 0
        draw_icon(FSL::SHOP::Shop_icon[6], 108, y + WLH * 3)
      else
        draw_icon(FSL::SHOP::Shop_icon[10], 108, y + WLH)
      end
      self.contents.draw_text(x, y + WLH * 3, 200, WLH, sprintf("%d", spi2), 2)
      
      agi1 = item1 == nil ? 0 : item1.agi
      agi2 = @item == nil ? 0 : @item.agi
      change = agi2 - agi1
      shop_change(change)
      if change > 0
        draw_icon(FSL::SHOP::Shop_icon[3], 108, y + WLH * 4)
      elsif  change < 0
        draw_icon(FSL::SHOP::Shop_icon[7], 108, y + WLH * 4)
      else
        draw_icon(FSL::SHOP::Shop_icon[11], 108, y + WLH)
      end
      self.contents.draw_text(x, y + WLH * 4, 200, WLH, sprintf("%d", agi2), 2)
      
      self.contents.font.color = system_color
      self.contents.draw_text(4, y - 32, 204, WLH, "当前装备")
      
      self.contents.draw_text(x + 32, y + WLH, 200, WLH, sprintf("%d", atk1))
      self.contents.draw_text(x + 32, y + WLH * 2, 200, WLH, sprintf("%d", def1))
      self.contents.draw_text(x + 32, y + WLH * 3, 200, WLH, sprintf("%d", spi1))
      self.contents.draw_text(x + 32, y + WLH * 4, 200, WLH, sprintf("%d", agi1))
      
      self.contents.draw_text(0, y + WLH, 200, WLH, "ATK")
      self.contents.draw_text(0, y + WLH * 2, 200, WLH, "DEF")
      self.contents.draw_text(0, y + WLH * 3, 200, WLH, "SPI")
      self.contents.draw_text(0, y + WLH * 4, 200, WLH, "AGI")
      
      if item1 != nil
        self.contents.draw_text(24, y, 208, WLH, item1.name)
        draw_icon(item1.icon_index, 0, y)
      else
        self.contents.draw_text(24, y, 208, WLH, "无")
      end
    else
      self.contents.font.color = normal_color
      self.contents.draw_text(0, y + 24, 200, WLH, FSL::SHOP::Shop_help, 1)
    end
  end
  #--------------------------------------------------------------------------
  # ● 判断数值颜色
  #     change : 数值
  #--------------------------------------------------------------------------
  def shop_change(change)
    if change == 0
      self.contents.font.color = normal_color
    else
      self.contents.font.color = change>0 ? power_up_color : power_down_color
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取双刀派角色所装备的武器中较弱的武器
  #     actor : 角色
  #--------------------------------------------------------------------------
  def weaker_weapon(actor)
    if actor.two_swords_style
      weapon1 = actor.weapons[0]
      weapon2 = actor.weapons[1]
      if weapon1 == nil or weapon2 == nil
        return nil
      elsif weapon1.atk < weapon2.atk
        return weapon1
      else
        return weapon2
      end
    else
      return actor.weapons[0]
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置角色
  #     actor : 角色
  #--------------------------------------------------------------------------
  def actor=(actor)
    if @actor != actor
      @actor = actor
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置物品
  #     item : 新物品
  #--------------------------------------------------------------------------
  def item=(item)
    if @item != item
      @item = item
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制头像部分图
  #     face_name  : 头像文件名
  #     face_index : 头像号码
  #     x     : 描画目标 X 坐标
  #     y     : 描画目标 Y 坐标
  #     size       : 显示大小
  #--------------------------------------------------------------------------
  def draw_Shopface(face_name, face_index, x, y, size = 96)
    bitmap = Cache.face(face_name)
    rect = Rect.new(0, 0, 0, 0)
    rect.x = face_index % 4 * 96 + (96 - size) / 2
    rect.y = face_index / 4 * 96 + (96 - size) / 2 + size / 4
    rect.width = size
    rect.height = size / 2
    self.contents.blt(x, y, bitmap, rect)
    bitmap.dispose
  end
end
#==============================================================================
# ■ Window_ShopBuy2
#------------------------------------------------------------------------------
# 　商店画面、浏览显示可以购买的商品的窗口。
#==============================================================================

class Window_ShopBuy2 < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #     x      : 窗口 X 座标
  #     y      : 窗口 Y 座标
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, 304, 248)
    @shop_goods = $game_temp.shop_goods
    @type = 0
    @sort = 0
    refresh
    self.index = 0
  end
  #--------------------------------------------------------------------------
  # ● 商品类型
  #--------------------------------------------------------------------------
  def type=(type)
    if @type != type
      @type = type
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取商品
  #--------------------------------------------------------------------------
  def item
    if @type == 0
      return @data1[self.index]
    elsif @type == 1
      return @data2[self.index]
    else
      return @data3[self.index]
    end
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    @data1 = []
    @data2 = []
    @data3 = []
    for goods_item in @shop_goods
      case goods_item[0]
      when 0
        item = $data_items[goods_item[1]]
        if item != nil
          @data1.push(item)
        end
      when 1
        item = $data_weapons[goods_item[1]]
        if item != nil
          @data2.push(item)
        end
      when 2
        item = $data_armors[goods_item[1]]
        if item != nil
          @data3.push(item)
        end
      end
    end
    for i in 0...@data2.size
      for j in i...@data2.size
        if @data2[i].atk < @data2[j].atk
          m = @data2[i]
          @data2[i] = @data2[j]
          @data2[j] = m
        end
      end
    end
    for i in 0...@data3.size
      for j in i...@data3.size
        if @data3[i].atk < @data3[j].atk
          m = @data3[i]
          @data3[i] = @data3[j]
          @data3[j] = m
        end
      end
    end
    @sort = 1
    if    @type == 0
      @item_max = @data1.size
    elsif @type == 1
      @item_max = @data2.size
    else
      @item_max = @data3.size
    end
    
    create_contents
    for i in 0...@item_max
      draw_item1(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制商品
  #     index : 商品索引
  #--------------------------------------------------------------------------
  def draw_item1(index)
    if    @type == 0
      item = @data1[index]
    elsif @type == 1
      item = @data2[index]
    else
      item = @data3[index]
    end 
    number = $game_party.item_number(item) 
    if $imported["LimitBreak"] == true
      enabled = (item.price <= $game_party.gold && number < item.number_limit) 
    else
      enabled = (item.price <= $game_party.gold and number < 99)
    end
    rect = item_rect(index)
    self.contents.clear_rect(rect)
    draw_item_name(item, rect.x, rect.y, enabled)
    rect.width -= 4
    self.contents.draw_text(rect, item.price, 2)
  end
  #--------------------------------------------------------------------------
  # ● 顺位排序
  #--------------------------------------------------------------------------
  def sort_item
    case @sort
    when 0
      for i in 0...@data2.size
        for j in i...@data2.size
          if @data2[i].atk < @data2[j].atk
            m = @data2[i]
            @data2[i] = @data2[j]
            @data2[j] = m
          end
        end
      end
      for i in 0...@data3.size
        for j in i...@data3.size
          if @data3[i].atk < @data3[j].atk
            m = @data3[i]
            @data3[i] = @data3[j]
            @data3[j] = m
          end
        end
      end
      @sort = 1
    when 1
      for i in 0...@data2.size
        for j in i...@data2.size
          if @data2[i].def < @data2[j].def
            m = @data2[i]
            @data2[i] = @data2[j]
            @data2[j] = m
          end
        end
      end
      for i in 0...@data3.size
        for j in i...@data3.size
          if @data3[i].def < @data3[j].def
            m = @data3[i]
            @data3[i] = @data3[j]
            @data3[j] = m
          end
        end
      end
      @sort = 2
    when 2
      for i in 0...@data2.size
        for j in i...@data2.size
          if @data2[i].spi < @data2[j].spi
            m = @data2[i]
            @data2[i] = @data2[j]
            @data2[j] = m
          end
        end
      end
      for i in 0...@data3.size
        for j in i...@data3.size
          if @data3[i].spi < @data3[j].spi
            m = @data3[i]
            @data3[i] = @data3[j]
            @data3[j] = m
          end
        end
      end
      @sort = 3
    when 3
      for i in 0...@data2.size
        for j in i...@data2.size
          if @data2[i].agi < @data2[j].agi
            m = @data2[i]
            @data2[i] = @data2[j]
            @data2[j] = m
          end
        end
      end
      for i in 0...@data3.size
        for j in i...@data3.size
          if @data3[i].agi < @data3[j].agi
            m = @data3[i]
            @data3[i] = @data3[j]
            @data3[j] = m
          end
        end
      end
      @sort = 0
    end
    if    @type == 0
      @item_max = @data1.size
    elsif @type == 1
      @item_max = @data2.size
    else
      @item_max = @data3.size
    end
    
    create_contents
    for i in 0...@item_max
      draw_item1(i)
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新帮助窗口文字
  #--------------------------------------------------------------------------
  def update_help
    @help_window.set_text(item == nil ? "" : item.description)
  end
end