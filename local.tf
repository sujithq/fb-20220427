locals {
  name = "fb-20220427"
  disks = distinct(flatten([
    for key_vm, vm in var.vms : [
      for key_disk, disk in vm.disks : {
        vm   = key_vm
        disk = key_disk
        size = disk.size
      }
    ]
  ]))
}
