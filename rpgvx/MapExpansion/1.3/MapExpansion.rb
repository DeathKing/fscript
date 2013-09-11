#===============================================================================
# ■  VX 简易地图扩张
#-------------------------------------------------------------------------------
#    脚本说明及使用方法请参考“引用网址”
#-------------------------------------------------------------------------------
#    更新作者： 铃仙·优昙华院·因幡
#    许可协议： FSL -DNR
#    项目版本： 1.3.0614
#    引用网址： http://bbs.66rpg.com/thread-155105-1-1.html
#-------------------------------------------------------------------------------
#    - 1.0.0828  By 铃仙·优昙华院·因幡
#      * 更新内容: 1.基本脚本组件
#
#    - 1.1.0829  By 铃仙·优昙华院·因幡
#      * 更新内容: 1.添加 A系列模块替换功能
#                  2.添加自动执行功能
#
#    - 1.2.0913  By 铃仙·优昙华院·因幡
#      * 更新内容: 1.优化脚本结构
#                  2.添加动态修改B C D E中某图块通行度功能
#                  3.添加动态修改针对某地图坐标的通行度功能
#                  4.附赠送查看地图图块ID脚本插件，详细请查阅《图块ID查看》
#
#    - 1.3.0614  By 铃仙·优昙华院·因幡
#      * 更新内容: 1.修正在多次切换同一张地图后,出现图块读取错误的 BUG
#                  2.优化整体甲苯结构
#                  3.优化使用方法
#===============================================================================

$fscript = {} if $fscript == nil
$fscript["MapExpansion"] = "1.3.0614"
   
#==============================================================================
# ■ reisen_module
#------------------------------------------------------------------------------
# 　配置模块
#==============================================================================

module FSL
  module ReisenMapExpansion
    
    ALL_MAP   = "A1A2A3A4A5BCDE"
    A_MAP     = "A1A2A3A4A5"
    NOT_A_MAP = "BCDE"
    
    # 地图自动切换设定
    MAP_DATA = {
    # 地图ID => 方案
        2    => 2,
    }
    
    CAN     = 0x06
    NOT_CAN = 0x0f
    HIGH    = 0x16
    
    # 单块地图通行设定
    MAP_TILE_ID_PASSAGE = {
    # [地图ID,x,y] => [通行度]
      [ 1, 5, 5]   => [NOT_CAN],
    }
  end
  
  module Timap_id
    TIMAPID = ["TileA1", "TileA2", "TileA3", "TileA4", "TileA5", "TileB",
      "TileC", "TileD", "TileE"]
  end
    
end

#==============================================================================
# ■ Game_Map
#------------------------------------------------------------------------------
# 　处理地图的类。包含卷动以及可以通行的判断功能。本类的实例请参考 $game_map 。
#==============================================================================

class Game_Map
  #--------------------------------------------------------------------------
  # ● 定义实例变量
  #--------------------------------------------------------------------------
  attr_accessor :game_timap_need_refresh
  attr_reader   :game_timap_id
  CAN     = FSL::ReisenMapExpansion::CAN
  NOT_CAN = FSL::ReisenMapExpansion::NOT_CAN
  HIGH    = FSL::ReisenMapExpansion::HIGH
  #--------------------------------------------------------------------------
  # ● 初始化对像
  #--------------------------------------------------------------------------
  alias reisen_map_expansion_initialize initialize
  def initialize
    @game_timap_id = nil
    @game_timap_need_refresh = false
    @map_tile_xy_passage = FSL::ReisenMapExpansion::MAP_TILE_ID_PASSAGE
    reisen_map_expansion_initialize
  end
  #--------------------------------------------------------------------------
  # ● 可以通行判定
  #     x : X 坐标
  #     y : Y 坐标
  #     flag : 通行度标志（非交通工具时，一般为 0x01）
  #--------------------------------------------------------------------------
  alias reisen_map_expansion_passable? passable?
  def passable?(x, y, flag = 0x01)
    return false if @map_tile_xy_passage[[@map_id, x, y]] == [NOT_CAN]
    reisen_map_expansion_passable?(x, y, flag)
  end
  #--------------------------------------------------------------------------
  # ● 设置
  #     map_id : 地图 ID
  #--------------------------------------------------------------------------
  alias reisen_map_expansion_setup setup
  def setup(map_id)
    reisen_map_expansion_setup(map_id)
    if FSL::ReisenMapExpansion::MAP_DATA[map_id] != nil
      reisen_map_data = FSL::ReisenMapExpansion::MAP_DATA[map_id]
      change_tilemap(reisen_map_data)
    end
  end
  #--------------------------------------------------------------------------
  # ● 设置单个坐标通行度
  #--------------------------------------------------------------------------
  def set_tile_id_passages(map_id, x, y, flag)
    @map_tile_xy_passage[[map_id, x, y]] = flag
  end
  #--------------------------------------------------------------------------
  # ● 获取通行度
  #--------------------------------------------------------------------------
  def get_passages
    unless @game_timap_id
      @passages = $data_system.passages
    else
      @passages = (load_data("Data/System_#{@game_timap_id}.rvdata")).passages
    end
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    if @map_id > 0
      get_passages
      for event in @events.values
        event.refresh
      end
      for common_event in @common_events.values
        common_event.refresh
      end
    end
    @need_refresh = false
  end
  #--------------------------------------------------------------------------
  # ● 更改单个地图元件通行度
  #--------------------------------------------------------------------------
  def chang_tile_passage(tile_id, flag)
    if tile_id <= 2000
      @passages[tile_id] = flag
    end
  end
  #--------------------------------------------------------------------------
  # ● 更改地图元件与通行度
  #--------------------------------------------------------------------------
  def change_tilemap(index)
    if $scene.is_a?(Scene_Map)
      @game_timap_id = index
      get_passages
      @game_timap_need_refresh = true
    end
  end
end

#==============================================================================
# ■ Spriteset_Map
#------------------------------------------------------------------------------
# 　处理地图画面活动块和元件的类。本类在 Scene_Map 类的内部使用。
#==============================================================================

class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 生成地图元件
  #--------------------------------------------------------------------------
  def create_tilemap
    @tilemap = Tilemap.new(@viewport1)
    @titlemap_name = []
    load_tilemap
  end
  #--------------------------------------------------------------------------
  # ● 加载 原件
  #--------------------------------------------------------------------------
  def load_tilemap
    (0..8).each do |i|
      filename = "#{FSL::Timap_id::TIMAPID[i]}_#{$game_map.game_timap_id}"
      if @titlemap_name[i] != filename
        if FileTest.exist?("Graphics/System/" + filename + ".png") 
          @tilemap.bitmaps[i].dispose if @tilemap.bitmaps[i]
          @tilemap.bitmaps[i] = Cache.system(filename)
          @titlemap_name[i] = filename
        else
          @tilemap.bitmaps[i].dispose if @tilemap.bitmaps[i]
          @tilemap.bitmaps[i] = Cache.system(FSL::Timap_id::TIMAPID[i])
          @titlemap_name[i] = FSL::Timap_id::TIMAPID[i] + "_"
        end
      end
    end
    @tilemap.map_data = $game_map.data
    @tilemap.passages = $game_map.passages
  end
  #--------------------------------------------------------------------------
  # ● 更新地图元件
  #--------------------------------------------------------------------------
  alias reisen_update_tilemap update_tilemap
  def update_tilemap
    if $game_map.game_timap_need_refresh
      load_tilemap
      $game_map.game_timap_need_refresh = false
    end
    reisen_update_tilemap
  end
  #--------------------------------------------------------------------------
  # ● 更改地图元件
  #--------------------------------------------------------------------------
  def change_tilemap
    load_tilemap
  end
end
#==============================================================================
# ■ Scene_Map
#------------------------------------------------------------------------------
# 　处理地图画面的类。
#==============================================================================

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ● 定义实例变量
  #--------------------------------------------------------------------------
  attr_accessor :spriteset
end

#==============================================================================
# ■ Game_Interpreter
#------------------------------------------------------------------------------
# 　执行事件命令的解释器。本类在 Game_Map 类、Game_Troop 类、与
# Game_Event 类的内部使用。
#==============================================================================

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 常量
  #--------------------------------------------------------------------------
  CAN     = FSL::ReisenMapExpansion::CAN
  NOT_CAN = FSL::ReisenMapExpansion::NOT_CAN
  HIGH    = FSL::ReisenMapExpansion::HIGH
  #--------------------------------------------------------------------------
  # ● 更改单个地图元件通行度
  #--------------------------------------------------------------------------
  def chang_tile_passage(tile_id, flag)
    $game_map.chang_tile_passage(tile_id, flag)
  end
  #--------------------------------------------------------------------------
  # ● 切换地图元件与通行度
  #--------------------------------------------------------------------------
  def change_tilemap(index)
    $game_map.change_tilemap(index)
  end
  #--------------------------------------------------------------------------
  # ● 设置单个坐标通行度
  #--------------------------------------------------------------------------
  def set_id_passages(map_id, x, y, flag)
    $game_map.set_tile_id_passages(map_id, x, y, flag)
  end
end
