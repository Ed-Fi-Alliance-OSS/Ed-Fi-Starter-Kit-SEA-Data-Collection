
variable "archive_name" {
  type    = string
  default = "sea-starter-kit"
}

variable "web_api" {
  type    = string
  default = "EdFi.Suite3.Installer.WebApi"
}

variable "admin_app" {
  type    = string
  default = "EdFi.Suite3.Installer.AdminApp"
}

variable "swagger_ui" {
  type    = string
  default = "EdFi.Suite3.Installer.SwaggerUI"
}

variable "databases" {
  type    = string
  default = "EdFi.Suite3.RestApi.Databases"
}

variable "box_directory" {
  type    = string
  default = "box/"
}

variable "cpus" {
  type    = string
  default = "2"
}

variable "debug_mode" {
  type    = string
  default = "0"
}

variable "disk_size" {
  type    = string
  default = "40960"
}

variable "guest_additions_url" {
  type    = string
  default = ""
}

variable "headless" {
  type    = string
  default = "false"
}

variable "hw_version" {
  type    = string
  default = "7"
}

variable "iso_checksum" {
  type    = string
  default = "549BCA46C055157291BE6C22A3AAAED8330E78EF4382C99EE82C896426A1CEE1"
}

variable "iso_url" {
  type    = string
  default = "https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "shutdown_command" {
  type    = string
  default = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
}

variable "update" {
  type    = string
  default = "true"
}

variable "version" {
  type    = string
  default = "0.1.0"
}

variable "vm_name" {
  type    = string
  default = "sea-starter-kit"
}

variable "vm_switch" {
  type    = string
  default = ""
}

variable "distribution_directory" {
    type = string
    default = "dist"
}

variable "user_name" {
    type = string
    default = "vagrant"
}

variable "password" {
    type = string
    default = "vagrant"
}

packer {
    required_plugins {
        comment = {
            version = ">=v0.2.23"
            source = "github.com/sylviamoss/comment"
        }
    }
}

source "hyperv-iso" "sea-starter-kit" {
  communicator     = "winrm"
  cpus             = "${var.cpus}"
  disk_size        = "${var.disk_size}"
  floppy_files     = ["${path.root}/mnt/Autounattend.xml"]
  headless         = "${var.headless}"
  iso_checksum     = "${var.iso_checksum}"
  iso_url          = "${var.iso_url}"
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
  sources = ["source.hyperv-iso.sea-starter-kit"]

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
        "${path.root}/build/${var.databases}.zip"
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
        "Set-ExecutionPolicy bypass -Scope CurrentUser -Force;",
        "Install-PackageProvider -Name NuGet -MinimumVersion \"2.8.5.201\" -Scope AllUsers -Force",
        "Set-Location c:/temp;",
        "Expand-Archive ./${var.archive_name}.zip -Destination ./${var.archive_name}"
      ]
  }

  provisioner "comment" {
    comment          = "Executing c:/temp/${var.archive_name}/server-setup.ps1"
    ui               = true
    bubble_text      = false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.user_name}"
    elevated_user     = "${var.password}"
    inline            = ["Set-Location c:/temp/${var.archive_name}/scripts", "./server-setup.ps1"]
  }

  provisioner "comment" {
    comment     = "Server Setup complete. Restarting...."
    ui          = true
    bubble_text =  false
  }

  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Server Setup complete. Restarting....'}\""
  }

  provisioner "comment" {
    comment     = "Installing Required Powershell Packages"
    ui          = true
    bubble_text =  false
  }

  provisioner "powershell" {
    debug_mode        = "${var.debug_mode}"
    elevated_password = "${var.user_name}"
    elevated_user     = "${var.password}"
    inline            = [ "Set-Location c:/temp",  ]
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
        "Set-Location c:/temp",
        "Expand-Archive ./${var.databases}.zip -Destination ./${var.databases}",
        "Copy-Item -Path ./${var.archive_name}/scripts/configuration.json -Destination ./${var.databases}",
        "Set-Location ./${var.databases}",
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
        "./Install-WebApi.ps1"
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
}
