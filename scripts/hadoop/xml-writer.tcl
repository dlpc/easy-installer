package provide XmlWriter 1.0
package require CommonUtil
package require PropertyUtil
package require OsUtil

namespace eval XmlWriter {
  variable dfsNamenodeNameDir dfs.namenode.name.dir
  variable dfsDatanodeDataDir dfs.datanode.data.dir
}

proc ::XmlWriter::prepareDic {hadoopHome ymlDict nodeYml kn} {
  if {[dict exists $nodeYml $kn]} {
    set dic [dict merge [dict get $ymlDict $kn] [dict get $nodeYml $kn]]
  } else {
    set dic [dict get $ymlDict $kn]
  }

  set DataDirBase [dict get $ymlDict DataDirBase]
  set dnnd dfs.namenode.name.dir
  set dddd dfs.datanode.data.dir
  set localDirs yarn.nodemanager.local-dirs

  if {[dict exists $dic $dnnd]} {
    dict set dic $dnnd [file join $DataDirBase [dict get $dic $dnnd]]
  }

  if {[dict exists $dic $dddd]} {
    dict set dic $dddd [file join $DataDirBase [dict get $dic $dddd]]
  }

  if {[dict exists $dic $localDirs]} {
    dict set dic $localDirs [file join $hadoopHome [dict get $dic $localDirs]]
  }
  return $dic
}

proc ::XmlWriter::addOneProperty {lines k v} {
  upvar $lines ln
  lappend ln "<property>"
  lappend ln "<name>$k</name>"
  lappend ln "<value>$v</value>"
  lappend ln "</property>"
}

proc ::XmlWriter::write {fn lines} {
  if {[catch {open $fn w} fid o]} {
    puts $fid
    ::CommonUtil::endEasyInstall
  } else {
    foreach line $lines {
      puts $fid $line
    }
    close $fid
  }
}

proc ::XmlWriter::mapred {hadoopHome ymlDict} {
  set mapredFile [file join $hadoopHome etc hadoop mapred-site.xml]
  set lines [list]
  lappend lines {<?xml version="1.0"?>}
  lappend lines {<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>}
  lappend lines {<configuration>}
  dict for {k v} [dict get $ymlDict MapRed] {
    addOneProperty lines $k $v
  }
  lappend lines {</configuration>}
  write $mapredFile $lines
}

proc ::XmlWriter::slaves {hadoopHome ymlDict} {
  set slavesFile [file join $hadoopHome etc hadoop slaves]
  set nodes [dict get $ymlDict nodes]
  set slavesHosts [list]
  foreach n $nodes {
    set hn [dict get $n HostName]
    set role [dict get $n role]
    if {$role eq {DataNode}} {
      lappend slavesHosts $hn
    }
  }
  set slavesHosts [lsort -unique $slavesHosts]
  write $slavesFile $slavesHosts
}

proc ::XmlWriter::copyOrigin {fn} {
  if {[file exists "${fn}.origin"]} {
    exec cp "${fn}.origin" $fn
  } else {
    exec cp $fn "${fn}.origin"
  }
}
proc ::XmlWriter::createDir {hadoopHome cfdir} {
  if {[regexp {^\.\W*(\w+)$} $cfdir mh m1]} {
    set cfdir [file join $hadoopHome $m1]
  }

  if {! [file exists $cfdir]} {
    exec mkdir -p $cfdir
  }
  return [file normalize $cfdir]
}

proc ::XmlWriter::yarnSite {hadoopHome nodeYml ymlDict} {
  set yarnSiteFile [file join $hadoopHome etc hadoop yarn-site.xml]
  set siteDic [prepareDic $hadoopHome $ymlDict $nodeYml YarnSiteCfg]
  copyOrigin $yarnSiteFile
  set lines [list]
  lappend lines {<?xml version="1.0"?>}
  lappend lines {<configuration>}

  dict for {k v} $siteDic {
    addOneProperty lines $k $v
  }
  lappend lines {</configuration>}
  write $yarnSiteFile $lines
}

proc ::XmlWriter::coreSite {hadoopHome nodeYml ymlDict} {
  set coreSiteFile [file join $hadoopHome etc hadoop core-site.xml]
  set siteDic [prepareDic $hadoopHome $ymlDict $nodeYml CoreSiteCfg]
  copyOrigin $coreSiteFile
  set lines [list]
  lappend lines {<?xml version="1.0" encoding="UTF-8"?>}
  lappend lines {<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>}
  lappend lines {<configuration>}

  dict for {k v} $siteDic {
    addOneProperty lines $k $v
  }
  lappend lines {</configuration>}
  write $coreSiteFile $lines
}


proc ::XmlWriter::hdfsSite {hadoopHome nodeYml ymlDict} {
  variable dfsDatanodeDataDir
  variable dfsNamenodeNameDir

  set hdfsSiteFile [file join $hadoopHome etc hadoop hdfs-site.xml]
  set siteDic [prepareDic $hadoopHome $ymlDict $nodeYml HdfsSiteCfg]
  copyOrigin $hdfsSiteFile
  set lines [list]
  lappend lines {<?xml version="1.0" encoding="UTF-8"?>}
  lappend lines {<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>}
  lappend lines {<configuration>}

  switch -exact -- [dict get $nodeYml role] {
    NameNode {
      set normalizedDir [createDir $hadoopHome [dict get $siteDic $dfsNamenodeNameDir]]
      dict set siteDic $dfsNamenodeNameDir $normalizedDir
    }
    DataNode {
      set normalizedDir [createDir $hadoopHome [dict get $siteDic $dfsDatanodeDataDir]]
      dict set siteDic $dfsDatanodeDataDir $normalizedDir
    }
    default {}
  }

  dict for {k v} $siteDic {
    addOneProperty lines $k $v
  }

  lappend lines {</configuration>}
  write $hdfsSiteFile $lines
}
