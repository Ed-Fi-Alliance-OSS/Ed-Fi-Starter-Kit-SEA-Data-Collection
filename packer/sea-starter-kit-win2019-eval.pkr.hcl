
variable "archive_name" {
  type    = string
}

variable "web_api" {
  type    = string
}

variable "admin_app" {
  type    = string
}

variable "swagger_ui" {
  type    = string
}

variable "databases" {
  type    = string
}

variable "sampledata" {
  type    = string
}

variable "cpus" {
  type    = string
  default = "2"
}

variable "debug_mode" {
  type    = string
}

variable "disk_size" {
  type    = string
}

variable "headless" {
  type    = string
}

variable "hw_version" {
  type    = string
}

variable "memory" {
  type    = string
}

variable "shutdown_command" {
  type    = string
}

variable "vm_name" {
  type    = string
}

variable "vm_switch" {
  type    = string
}

variable "distribution_directory" {
    type = string
}

variable "user_name" {
    type = string
}

variable "password" {
    type = string
}

variable "base_image_directory" {
    type = string
}

packer {
    required_plugins {
        comment = {
            version = ">=v0.2.23"
            source = "github.com/sylviamoss/comment"
        }
    }
}

source "hyperv-vmcx" "sea-starter-kit" {
  clone_from_vmcx_path = "${path.root}/${var.base_image_directory}/"
  communicator     = "winrm"
  cpus             = "${var.cpus}"
  headless         = "${var.headless}"
  memory           = "${var.memory}"
  shutdown_command = "${var.shutdown_command}"
  switch_name      = "${var.vm_switch}"
  vm_name          = "${var.vm_name}"
  winrm_password   = "${var.password}"
  winrm_timeout    = "10000s"
  winrm_username   = "${var.user_name}"
  output_directory = "${path.root}/${var.distribution_directory}"
}

build {
  sources = ["source.hyperv-vmcx.sea-starter-kit"]

  provisioner "comment" {
    comment     = "Copying ${var.archive_name}.zip to c:/temp"
    ui          = true
    bubble_text =  false
  }

  provisioner "file" {
    destination = "c:/temp/"
    sources     = [
        "${path.root}/build/${var.archive_name}.zip",
        "${path.root}/build/${var.web_api}.zip",
        "${path.root}/build/${var.admin_app}.zip",
        "${path.root}/build/${var.swagger_ui}.zip",
        "${path.root}/build/${var.databases}.zip",
        "${path.root}/build/${var.sampledata}.zip"
    ]
  }

  provisioner "comment" {
    comment     = "Exctacting ${var.archive_name}.zip to c:/temp/${var.archive_name}"
    ui          = true
    bubble_text = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.user_name}"
    elevated_user     = "${var.password}"
    inline            = [
        "Set-Location c:/temp",
        "Expand-Archive ./${var.archive_name}.zip -Destination ./${var.archive_name}"
    ]
  }

  provisioner "comment" {
    comment     = "Installing Databases"
    ui          = true
    bubble_text =  false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.user_name}"
    elevated_user     = "${var.password}"
    inline            = [
        "New-Item -Path c:/ -Name plugin -ItemType directory",
        "Set-Location c:/temp",
        "Expand-Archive ./${var.databases}.zip -Destination ./${var.databases}",
        "Expand-Archive ./${var.sampledata}.zip -Destination ./${var.sampledata}",
        "Copy-Item -Path ./${var.archive_name}/scripts/configuration.json -Destination ./${var.databases}",
        "Copy-Item -Path ./${var.archive_name}/scripts/sampledata.ps1 -Destination ./${var.databases}/Ed-Fi-ODS-Implementation/DatabaseTemplate/Scripts/",
        "Copy-Item -Path ./${var.archive_name}/scripts/sk.ps1 -Destination c:/plugin -Force",
        "Copy-Item -Path ./${var.archive_name}/scripts/configuration.packages.json -Destination ./${var.databases}/Ed-Fi-ODS-Implementation/logistics/scripts -Force",
        "Set-Location ./${var.databases}",
        "Import-Module -Force -Scope Global SqlServer",
        "Import-Module ./Deployment.psm1",
        "Initialize-DeploymentEnvironment"
    ]
  }

  provisioner "comment" {
    comment     = "Installing ODS/API"
    ui          = true
    bubble_text =  false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.user_name}"
    elevated_user     = "${var.password}"
    inline            = [
        "Set-Location c:/temp",
        "Expand-Archive ./${var.web_api}.zip -Destination ./${var.web_api}",
        "Set-Location c:/temp/${var.archive_name}/scripts/installers",
        "./Install-WebApi.ps1",
        "Copy-Item -Path c:/temp/${var.archive_name}/scripts/webapi.appsettings.production.json -Destination C:/inetpub/Ed-Fi/WebApi/appsettings.production.json"
    ]
  }

  provisioner "comment" {
    comment     = "Installing SwaggerUI"
    ui          = true
    bubble_text =  false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.user_name}"
    elevated_user     = "${var.password}"
    inline            = [
        "Set-Location c:/temp",
        "Expand-Archive ./${var.swagger_ui}.zip -Destination ./${var.swagger_ui}",
        "Set-Location c:/temp/${var.archive_name}/scripts/installers",
        "./Install-SwaggerUI.ps1"
    ]
  }

  provisioner "comment" {
    comment     = "Installing Admin App"
    ui          = true
    bubble_text =  false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.user_name}"
    elevated_user     = "${var.password}"
    inline            = [
        "Set-Location c:/temp",
        "Expand-Archive ./${var.admin_app}.zip -Destination ./${var.admin_app}",
        "Set-Location c:/temp/${var.archive_name}/scripts/installers",
        "./Install-AdminApp.ps1"
    ]
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.user_name}"
    elevated_user     = "${var.password}"
    inline            = [
        "Remove-item c:/temp/* -Recurse -Force",
        "Optimize-Volume -DriveLetter C"
    ]
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.user_name}"
    elevated_user     = "${var.password}"
    inline            = [
        "Write-Host (\"Web Api => https://{0}/WebApi\" -f [Environment]::MachineName)",
        "Write-Host (\"Admin App => https://{0}/AdminApp\" -f [Environment]::MachineName)",
        "Write-Host (\"SwaggerUI => https://{0}/SwaggerUI\" -f [Environment]::MachineName)"
    ]
  }
}
