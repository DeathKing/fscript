
#===============================================================================
# ■ [VX] 增强开发包
#    [VX] Advanced Delevop Kit -- ADK
#-------------------------------------------------------------------------------
#    FSL ADK是FSL脚本可用的加强型开发包。他提供了一些列有效的方法。
#    
#-------------------------------------------------------------------------------
#    更新作者： DeathKing
#    许可协议： FSL
#    衍生关系:  ADK < ReadNote
#    项目版本： 1.3.0108
#    最后更新： 2011-01-08
#    引用网址：
#-------------------------------------------------------------------------------
#    - 1.3.0108 By 沉影不器
#      * 添加read_note方法，此方法区别与read_notes方法；
#
#    - 1.2.0719 By DeathKing
#      * 将read_note方法修改为read_notes，方便与沉影不器的脚本兼容；
#
#    - 1.1.0607 By DeathKing
#      * 添加兼容性检查方法；
#
#    - 1.0.0529 By DeathKing
#      * 初始版本完成；
#===============================================================================

#-------------------------------------------------------------------------------
# ▼ 登记FSL
#-------------------------------------------------------------------------------

$fscript = {} if $fscript == nil
$fscript["ADK"] = "1.3.0108"


#-------------------------------------------------------------------------------
# ▼ 通用配置模块
#-------------------------------------------------------------------------------
module FSL
  module ADK
  end
end

#-------------------------------------------------------------------------------
# ▼ FSL模块功能
#-------------------------------------------------------------------------------
module FSL
  #--------------------------------------------------------------------------
  # ● 是否存在指定脚本
  #     script  : 脚本在$fscript中的登记名
  #--------------------------------------------------------------------------
        def self.script_in?( script )
                return true if $fscript[ script.to_s ] != nil
                return false
        end
end

#-------------------------------------------------------------------------------
#
# ▼ 读取注释内容
#
#    使用read_notes方法返回了一个键值对应的哈希，read_notes会删除掉作为标记的
#    <和>符号（非破坏性方法）。默认以用空格分隔的几个数据中的第一个为键，余
#    下为值。值为一个数组对象。
#
#    注释内容               读取到的哈希的键值对应情况
#    <need_item 1 1>  -->  { "need_item" => [ "1" , "1" ] }
#    <need_item 1,1>  -->  { "need_item" => [ "1,1" ] }
#    <need_item>      -->  { "need_item" => [] }
#     need_item       -->  { "need_item" => [] }
#
#    不使用尖括号是允许的，但我们不喜欢这样。分隔多个参数请使用空格。
#
#    read_notes是返回哈希对象，因此“键”应该对大小写敏感。
#
#    使用方法：
#        obj.read_notes
#        obj是RPG::State、RPG::BaseItem、RPG::Enemy及其子类的有效对象
#
#
#-------------------------------------------------------------------------------
module RPG
  class State
    def read_notes
      result = {}
      self.note.split(/[\r\n]+/).each do |line|
        result[line.delete("<>").split[0]] = line.delete("<>").split[1..-1]
      end
      return result
    end
  end
  class BaseItem
    def read_notes
      result = {}
      self.note.split(/[\r\n]+/).each do |line|
        result[line.delete("<>").split[0]] = line.delete("<>").split[1..-1]
      end
      return result
    end
  end
  class Enemy
    def read_notes
      result = {}
      self.note.split(/[\r\n]+/).each do |line|
        result[line.delete("<>").split[0]] = line.delete("<>").split[1..-1]
      end
      return result
    end
  end
end

#-------------------------------------------------------------------------------
#
# ▼ 读取注释栏指定字段
#
#    采用沉影不器的 ReadNote -fscript 2.02.1001 脚本，请与read_notes区别
#
#    【例】在vx数据库比如1号物品的备注栏里写: 耐久度 = 10
#          读取时使用: p $data_items[1].read_note('耐久度')
#
#     几点注意:
#         ① 支持汉字,英文忽略大小写
#         ② 等号右边遵循ruby语法格式,例如:
#              test1 = 1              #=> 1
#              test2 = "a"            #=> "a"
#              test3 = true           #=> true
#              test4 = [1,2,3]        #=> [1,2,3]
#              test5 = {"orz"=>1}     #=> {"orz"=>1}
#         ③ 等号忽略空格,以下均正确:
#              test = nil; test= nil; test =nil; test=nil
#----------------------------------------------------------------------------
module RPG
  module ReadNote
    def self.read(str, section, mismatch = nil)
      str.each_line do |line|
        ## 不希望忽略大小写,则删掉下一行最后一个i
        eval("#{line}; return #{section}") if line =~ /^\s*#{section}\s*=/i
      end
      return mismatch
    end
  end
  #-------------------------------------------------------------------------
  # ○ 读取rmvx备注栏指定字段
  #     section  : 字段名
  #     mismatch : 未匹配时的返回值
  #-------------------------------------------------------------------------
  class BaseItem
    def read_note(section, mismatch = nil)
      ReadNote.read(self.note, section, mismatch)
    end
  end
  class Enemy
    def read_note(section, mismatch = nil)
      ReadNote.read(self.note, section, mismatch)
    end
  end
  class State
    def read_note(section, mismatch = nil)
      ReadNote.read(self.note, section, mismatch)
    end
  end
end