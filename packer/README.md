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

Set your location in the console to the Ed-Fi-Starter-Kit-Assessments root folder.
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

Below are examples showing how to pass these two parameters to the build script.

```powershell
#default way to run build for base image to generate the base image. Folders that are created during the build process are `./build` and `./dist`.
PS> ./build-vm.ps1 -PackerFile .\win2019-eval-base.pkr.hcl -VariablesFile .\base-variables.json

```powershell
#default way to run build for starter-kit image to generate the starter-kit image. Folders that are created during the build process are `./build` and `./dist`.
PS> ./build-vm.ps1 -PackerFile .\sea-starter-kit-win2019-eval.pkr.hcl -VariablesFile .\starter-kit-variables.json

#build with vmSwitch parameter for base image
PS> ./build-vm.ps1 -PackerFile .\win2019-eval-base.pkr.hcl -VariablesFile .\base-variables.json -VMSwitch existingVMSwitchName

#build with vmSwitch parameter for starter-kit image
PS> ./build-vm.ps1 -PackerFile .\sea-starter-kit-win2019-eval.pkr.hcl -VariablesFile .\starter-kit-variables.json -VMSwitch existingVMSwitchName

```
> :exclamation: IMPORTANT: Disconnect from any VPNs. This will cause issues with Hypervisor
> connectivity.

The build will download and install Windows Server 2019 Evaluation edition, with
a license that is valid for 180 days. NuGet Package Management is installed,
followed by Chocolatey for automated software package installs of the following
software: Dot Net Framework 4.8, Dot Net Core 3.1 SDK, SQL Server 2019 Express,
SQL Server Management Studio, Google Chrome, and any of their Chocolatey package
dependencies (Windows update packages for Dot Net).

Next, the build invokes the installation for the database, ODS Tech Suite, Data
Import, and API Assessment Bridge.

When complete, the virtual machine artifacts will be created in the
`Starter-Kit-SEA-Data-Collection\packer\build\` folder for base image and
`Starter-Kit-SEA-Data-Collection\packer\dist\` folder for starter kit image and.

## Build outcome

The `Starter-Kit-SEA-Data-Collection\packer\dist\` folder will contain Hyper-V hard disk images for the
as starter kit   Virtual Machine image populated with the the latest databases; the ODS API Tech Suite with Admin App and ODS/ API with SK Extension plugin.

> To Learn more about ODS/API the directions found [here](https://techdocs.ed-fi.org/display/ODSAPIS3V520/Getting+Started)

## Testing the image

You can then use Hyper-V Manager to import the virtual machine. Point the
directory to the output folder to install. The user and password is `Administrator` and `EdFi!sCool`.

## Documentation

For further documentation around the the SQL views that are
utilized as part of the Assessment Collection in this Starter Kit, please view
the docs [here](https://techdocs.ed-fi.org/display/SK/SEA+Modernization+Starter+Kit)

## Contributing

The Ed-Fi Alliance welcomes code contributions from the community. Please read
the [Ed-Fi Contribution
Guidelines](https://techdocs.ed-fi.org/display/ETKB/Code+Contribution+Guidelines)
for detailed information on how to contribute source code.

Looking for an easy way to get started? Search for tickets  in [Tracker](https://tracker.ed-fi.org/projects/EDFI/issues/EDFI-951?filter=allopenissues);
these are nice-to-have but low priority tickets that should not require in-depth
knowledge of the code base and architecture.

## Legal Information

Copyright (c) 2021 Ed-Fi Alliance, LLC and contributors.

Licensed under the [Apache License, Version 2.0](LICENSE) (the "License").

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

See [NOTICES](NOTICES.md) for additional copyright and license notifications.
