# Starter-Kit-SEA-Modernization

## Steps to build Starter-Kit-SEA-Modernization Automated Machine Image

This README outlines the steps for creating a virtual hard disk image containing
an evaluation copy of Windows 2019 Server, with SQL Server 2019 Express edition,
SQL Server Management Studio, Google Chrome, Dot Net Framework 4.8, the Dot Net
Core SDK, and NuGet Package Manager.

## Quick Start

If you want to jump ahead, there are three steps

- Install the prerequisites: Hyper-V and Packer
- Clone the Starter-Kit-SEA-Modernization repository from Ed-Fi-Alliance-OSS on
  Github
- Run the build.ps1 as an Admin user

## Step by step

### Clone the repo

Clone the [Starter-Kit-SEA-Modernization repository](https://github.com/Ed-Fi-Alliance-OSS/Starter-Kit-SEA-Modernization/)

### Turn on Windows features for Hyper-V

  You will need both sub-items: Hyper-V Platform and Hyper-V Management Tools.
  For directions on enabling these features, follow the directions found
  [here](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v#enable-the-hyper-v-role-through-settings)

### Download an install Packer

```powershell
choco install Packer
```

### Open a PowerShell console (greater or equal to PSVersion 5) in elevated mode

Set your location in the console to the Starter-Kit-SEA-Data-Collection\packer folder.
Execute the build.ps1 to create your AMI.

## Optional Parameters
There are two optional parameters that you can pass to the build script for
specific scenarios. The first is if you have a Hyper-V VM Switch defined in
Hyper-V already you can add `-vmSwitch` along with the name of your Switch.
If this parameter is not specified, then a Switch with the name
`packer-hyperv-iso` will be created. The second optional parameter is for if you
run the build and see the following error output

```
hyperv-iso: Download failed unexpected EOF
hyperv-iso: error downloading ISO: [unexpected EOF]
...
Build 'hyperv-iso' errored after 10 minutes 26 seconds: error downloading ISO: [unexpected EOF]
```

If you see this, then the build is having a problem downloading the Windows
Server 2019 iso file, so you should try to manually download the iso from [this
url](https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso),
move the iso file to an easily accessible location, and then use the `-isoUrl`
parameter in the build script to specifiy where the iso file is and the build
script will use that file instead of trying to download it.


# Packer Build

| Folder | Description |
| -------- | -------- |
| `build/` | Cached artifacts and log files |
| `dist/` | Built virtual machine |
| `mnt/` | Used by packer to mount to the floppy drive |

Below are examples showing how to pass these parameters to the build script for base image build .

```powershell
#default way to run build for base image to generate the base image. Folders that are created during the build process are `./build` and `./dist`.
PS> ./build-vm.ps1 -PackerFile .\win2019-eval-base.pkr.hcl -VariablesFile .\base-variables.json

#build with vmSwitch parameter for base image
PS> ./build-vm.ps1 -PackerFile .\win2019-eval-base.pkr.hcl -VariablesFile .\base-variables.json -VMSwitch existingVMSwitchName

Below are examples showing how to pass these parameters to the build script for starter kit image build .

Note: After the base build, there is a manual step to copy the two folders from dist folder to build folder

```powershell
#default way to run build for starter-kit image to generate the starter-kit image. Folders that are created during the build process are `./build` and `./dist`.
PS> ./build-vm.ps1 -PackerFile .\sea-starter-kit-win2019-eval.pkr.hcl -VariablesFile .\starter-kit-variables.json


#build with vmSwitch parameter for starter-kit image
PS> ./build-vm.ps1 -PackerFile .\sea-starter-kit-win2019-eval.pkr.hcl -VariablesFile .\starter-kit-variables.json -VMSwitch existingVMSwitchName

```
> :exclamation: IMPORTANT: Disconnect from any VPNs. This will cause issues with Hypervisor
> connectivity.

The base image build will download and install Windows Server 2019 Evaluation edition, with
a license that is valid for 180 days. NuGet Package Management is installed,
followed by Chocolatey for automated software package installs of the following
software: Dot Net Core 3.1 SDK, SQL Server 2019 Express,
SQL Server Management Studio, Google Chrome, and any of their Chocolatey package
dependencies (Windows update packages for Dot Net).

Next, Starter-kit image build uses the base image provided in build folder and invokes the installation of ODS / API , Admin App, starter kit sample data, starter kit sample extension, sample validation and reporting artifacts..

When complete, the virtual machine artifacts will be created in the `\packer\dist\` folder for  base image and also starter kit image .
it is a manual step to move the base image build artifacts to build folder to be used in full build.

## Build outcome

The `Starter-Kit-SEA-Data-Collection\packer\dist\` folder will contain Hyper-V hard disk images for the
as starter kit   Virtual Machine image populated with the the latest databases; the ODS API Tech Suite with Admin App and ODS/ API with SK Extension plugin.

> To Learn more about ODS/API the directions found [here](https://techdocs.ed-fi.org/display/ODSAPIS3V520/Getting+Started)

## Testing the image

You can then use Hyper-V Manager to import the virtual machine. Point the
directory to the output folder to install. The user and password is `Administrator` and `EdFi!sCool`.
