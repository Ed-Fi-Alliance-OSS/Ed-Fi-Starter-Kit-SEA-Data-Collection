
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
        "Install-Module -Name PackageManagement -Force -MinimumVersion \"1.4.6\" -Scope CurrentUser -AllowClobber -Repository PSGallery",
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
    inline            = ["Set-Location c:/temp"]
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
        "Write-Host (\"Web Api => https://{0}/WebApi\" -f [Environment]::MachineName)",
        "Write-Host (\"Admin App => https://{0}/AdminApp\" -f [Environment]::MachineName)",
        "Write-Host (\"SwaggerUI => https://{0}/SwaggerUI\" -f [Environment]::MachineName)"
    ]
  }
}
