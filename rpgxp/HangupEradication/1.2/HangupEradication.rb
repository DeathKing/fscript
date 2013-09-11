
#==============================================================================
# ■  Hangup 异常根除
#    Hangup Exception Eradication
#----------------------------------------------------------------------------
#
#    Hangup 异常是 RMXP 底层引擎内置的一个异常类，游戏进程会在 Graphics.update
#    没有调用超过 10 秒时抛出这个异常。这个脚本使用了 Windows API 暴力地解除
#    了这个限制。
#    使用方法：Hangup 异常根除脚本必须插入到脚本编辑器的最顶端，所有脚本之前，无
#    例外。
#
#----------------------------------------------------------------------------
#
#    更新作者： 紫苏
#    许可协议： FSL -MEE
#    项目版本： 1.2.0827
#    引用网址：
#    http://bbs.66rpg.com/forum.php?mod=viewthread&tid=134316
#    http://szsu.wordpress.com/2010/08/09/hangup_eradication
#
#----------------------------------------------------------------------------
#
#    - 1.2.0827 By 紫苏
#      * 更改了配置模块名
#      * 更改了 FSL 注释信息
#
#    - 1.2.0805 By 紫苏
#      * 脚本开始遵循 FSL
#      * 全局范围内改变了脚本结构
#
#    - 1.1.1101 By 紫苏
#      * 修正了脚本在 Windows XP 平台下失效的问题
#
#    - 1.0.0927 By 紫苏
#      * 初始版本完成
#
#==============================================================================

$__jmp_here.call if $__jmp_here

#----------------------------------------------------------------------------
# ● 登记 FSL。
#----------------------------------------------------------------------------
$fscript = {} if !$fscript
$fscript['HangupEradication'] = '1.2.0827'

#==============================================================================
# ■ FSL
#------------------------------------------------------------------------------
# 　自由RGSS脚本通用公开协议的功能模块。
#==============================================================================

module FSL
  module HangupEradication
    #------------------------------------------------------------------------
    # ● 定义需要的 Windows API。
    #------------------------------------------------------------------------
    OpenThread = Win32API.new('kernel32', 'OpenThread', 'LIL', 'L')
    CloseHandle = Win32API.new('kernel32', 'CloseHandle', 'L', 'I')
    Thread32Next = Win32API.new('kernel32', 'Thread32Next', 'LP', 'I')
    ResumeThread = Win32API.new('kernel32', 'ResumeThread', 'L', 'L')
    SuspendThread = Win32API.new('kernel32', 'SuspendThread', 'L', 'L')
    Thread32First = Win32API.new('kernel32', 'Thread32First', 'LP', 'I')
    GetCurrentProcessId = Win32API.new('kernel32', 'GetCurrentProcessId', 'V', 'L')
    CreateToolhelp32Snapshot = Win32API.new('kernel32', 'CreateToolhelp32Snapshot', 'LL', 'L')
  end
end

#==============================================================================
# ■ HangupEradication
#------------------------------------------------------------------------------
# 　处理根除 Hangup 异常的类。
#==============================================================================

class HangupEradication
  include FSL::HangupEradication
  #--------------------------------------------------------------------------
  # ● 初始化对像。
  #--------------------------------------------------------------------------
  def initialize
    @hSnapShot = CreateToolhelp32Snapshot.call(4, 0)
    @hLastThread = OpenThread.call(2, 0, self.getLastThreadId)
    #@hLastThread = OpenThread.call(2097151, 0, threadID)
    ObjectSpace.define_finalizer(self, self.method(:finalize))
  end
  #--------------------------------------------------------------------------
  # ● 获取当前进程创建的最后一个线程的标识。
  #--------------------------------------------------------------------------
  def getLastThreadId
    threadEntry = [28, 0, 0, 0, 0, 0, 0].pack("L*")
    threadId = 0                                          # 线程标识
    found = Thread32First.call(@hSnapShot, threadEntry)   # 准备枚举线程
    while found != 0
      arrThreadEntry = threadEntry.unpack("L*")           # 线程数据解包
      if arrThreadEntry[3] == GetCurrentProcessId.call    # 匹配进程标识
        threadId = arrThreadEntry[2]                      # 记录线程标识
      end
      found = Thread32Next.call(@hSnapShot, threadEntry)  # 下一个线程
    end
    return threadId
  end
  #--------------------------------------------------------------------------
  # ● 根除 Hangup 异常。
  #     2       : “暂停和恢复线程访问权限”代码；
  #     2097151 : “所有可能的访问权限”代码（Windows XP 平台下无效）。
  #--------------------------------------------------------------------------
  def eradicate
    SuspendThread.call(@hLastThread)
  end
  #--------------------------------------------------------------------------
  # ● 恢复 Hangup 异常。
  #--------------------------------------------------------------------------
  def resume
    while ResumeThread.call(@hLastThread) > 1; end        # 恢复最后一个线程
  end
  #--------------------------------------------------------------------------
  # ● 最终化对像。
  #--------------------------------------------------------------------------
  def finalize
    CloseHandle.call(@hSnapShot)
    CloseHandle.call(@hLastThread)
  end
end

hangupEradication = HangupEradication.new
hangupEradication.eradicate

callcc { |$__jmp_here| }                                  # F12 后的跳转标记

#==============================================================================
# ■ 游戏主过程
#------------------------------------------------------------------------------
# 　游戏脚本的解释从这个外壳开始。
#==============================================================================

for subscript in 1...$RGSS_SCRIPTS.size
  begin
    eval(Zlib::Inflate.inflate($RGSS_SCRIPTS[subscript][2]))
  rescue Exception => ex
    # 异常发生并抛出给解释器时恢复线程。
    hangupEradication.resume unless defined?(Reset) and ex.class == Reset
    raise ex
  end
end

hangupEradication.resume
exit
