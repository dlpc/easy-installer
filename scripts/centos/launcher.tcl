package require Configer
package require CommonUtil
package require OsUtil
package require AddNewDisk
package require DesktopInstaller

set action [dict get $::rawParamDict action]

catch {
  switch $action {
    disableIpv6 {
      ::Configer::disableIpv6
    }
    setupResolver {
      ::OsUtil::disableNetworkManager
      ::Configer::setupResolver [dict get $::rawParamDict nameserver]
    }
    addNewDisk {
      ::AddNewDisk::add $::ymlDict $::rawParamDict
    }
    jps {
      ::CommonUtil::spawnCommand jps
    }
    noop {
      puts "noop"
    }
    fixRepo {
      set paExists [dict exists $::rawParamDict fixRepoTo]
      if {$paExists} {
        set fixRepoTo [dict get $::rawParamDict fixRepoTo]
      } else {
        set fixRepoTo aliyun
      }
      ::Configer::fixRepoTo $fixRepoTo
    }
    desktop {
      ::DesktopInstaller::install $::ymlDict $::rawParamDict
    }
    eclipse {
      ::DesktopInstaller::installApp  eclipse $::ymlDict
    }
    ant {
      ::DesktopInstaller::installApp  ant $::ymlDict
    }
  }
} msg o

if {[dict get $o -code] > 0} {
  puts $msg
}

::CommonUtil::endEasyInstall
