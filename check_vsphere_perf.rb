#!/usr/bin/ruby -Ku
###################################################
#  name:
#      check_vsphere_perf.rb
#
#  Discription:
#      check_vsphere_perf.rb ARGV[0] ARGV[1] ARGV[2]
#
#  Options:
#      ARGV[0] => vsphere IP Address
#      ARGV[1] => vsphere Login Name
#      ARGV[2] => vsphere Login Pass
#
#  Author:
#      ma2k8(2012/12/19)
#
###################################################
require 'rubygems'
require 'rbvmomi'
require 'pp'


def getPerfVal(type, vim, entity, value_list, mode)
#
# => Options:
#      type       => HostSystem or VMMachine
#      vim        => VIM Instance
#      entity     => ManagedObject
#      value_list => GetPerfCounterList
#      mode       => File Open Mode
#
    filepath = "/tmp/vsphere/"
    perfmgr = vim.serviceContent.perfManager

    if type == "HostSystem"
        head = "h_"
    elsif type == "VMMachine"
        head = "v_"
    else
        head = "other_"
    end

    entity.each do |y|
        name = y.name.gsub(/:/,"-")
        begin
            hfile = open(filepath + head + name, mode)
        rescue => exc
            p exc
            exit
        end
        if mode == "w"
            hfile.print "host-Hostname", name, "\n"
        elsif mode == "a"
            value_list.each do |x|
                perf = perfmgr.retrieve_stats(entity, x)
                if defined? perf[y][:metrics] then
                    perf[y][:metrics].each do |key, value|
                        hfile.print "#{key}:", value, "\n"
                    end
                end
            end
        end
    end
end

##############################
# - Get Value List
##############################
## チャート設定『デフォルト』の取得リスト
## ※チャート設定でチェックを入れなくても取得は可能なので好きな値を設定してください。
host_value_list = [
                ## CPU
                "cpu.usagemhz",
                "cpu.usage",

                ## vSphere Replication
                "hbr.hbrNetRx",
                "hbr.hbrNumVms",
                "hbr.hbrNetTx",

                ## System
                "sys.resourceCpuUsage",
                "sys.uptime",

                ## Storage Adapter
                "storageAdapter.totalReadLatency",
                "storageAdapter.totalWriteLatency",

                ## Storage Path
                "storagePath.totalReadLatency",
                "storagePath.totalWriteLatency",

                ## Disk
                "disk.read",
                "disk.write",
                "disk.maxTotalLatency",
                "disk.usage",

                ## DataStore
                "datastore.totalReadLatency",
                "datastore.totalWriteLatency",

                ## NetWork
                "net.usage",
                "net.received",
                "net.transmitted",

                ## Memory
                "mem.swapused",
                "mem.active",
                "mem.consumed",
                "mem.vmmemctl",
                "mem.granted",
                "mem.sharedcommon",

                ## Power
                "power.power"
]

vm_value_list = [
                ## CPU
                "cpu.usage",
                "cpu.usagemhz",

                ## System
                "sys.uptime",

                ## Disk
                "disk.write",
                "disk.read",
                "disk.maxTotalLatency",
                "disk.usage",

                ## DataStore
                "datastore.totalReadLatency",
                "datastore.totalWriteLatency",

                ## Network
                "net.usage",
                "net.received",
                "net.transmitted",

                ## Memory
                "mem.vmmemctl",
                "mem.active",
                "mem.granted",
                "mem.consumed",

                ## Virtual Disk
                "virtualDisk.totalWriteLatency",
                "virtualDisk.totalReadLatency",

                ## power
                "power.power"
]

##############################
# - Connection
##############################
begin
    vim = RbVmomi::VIM.connect :host => ARGV[0],
                               :user => ARGV[1],
                               :password => ARGV[2],
                               :insecure => true
rescue => exc
    p exc
    exit
end

##############################
# - Cennect Datacenter
##############################
begin
    dc = vim.serviceInstance.find_datacenter
rescue => exc
    p exc
    exit
end

##############################
# - Get HostSystem Perf
##############################
begin
    host = dc.hostFolder.children.first.host.grep(RbVmomi::VIM::HostSystem)
rescue => exc
    p exc
    exit
end

getPerfVal("HostSystem", vim, host, host_value_list, "w")
getPerfVal("HostSystem", vim, host, host_value_list, "a")

##############################
# - Get VMMachine Perf
##############################
begin
    vm = dc.vmFolder.childEntity.grep(RbVmomi::VIM::VirtualMachine)
rescue => exc
    p exc
    exit
end

getPerfVal("VMMachine", vim, vm, vm_value_list, "w")
getPerfVal("VMMachine", vim, vm, vm_value_list, "a")

##############################
# - END
##############################
puts 0

