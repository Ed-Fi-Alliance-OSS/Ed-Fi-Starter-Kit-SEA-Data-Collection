# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

<#
.description
    Setup new AWS Image under 'Ed-Fi-SEA-Modernization-Starter-Kit' Name
.parameter awsPublicImageName
    Public Image Name for Ed-Fi-SEA-Modernization-Starter-Kit
.parameter awsS3KeyName
    S3 Key Name for SEA Modernization StarterKit QuickStart VM
.parameter awsNewImageId
    Aws new Image Id
#>
$params = @{

    AwsPublicImageName   = Get-ValueOrDefault   $teamcityParameters['aws.PublicImageName'] 'Ed-Fi-SEA-Modernization-Starter-Kit'
    AwsS3KeyName   = Get-ValueOrDefault   $teamcityParameters['aws.S3KeyName'] 'SEAModernizationStarterKitQuickStartVM'
    AwsNewImageId   = Get-ValueOrDefault   $teamcityParameters['aws.newimageId'] ''

}

$error.Clear()

Import-Module -Force -Scope Global "$PSScriptRoot\settings-teamcity.psm1"

$teamcityParameters = Get-TeamCityParameters
Write-Host
Write-Host "$($teamcityParameters.Count) TeamCity parameters found."
Write-Host

function Remove-OldPrivateImage {
    $ErrorActionPreference = 'Stop'
    $oldPrivateImageId =(& aws ec2 describe-images --filters "Name=name,Values=$params.AwsPublicImageName" "Name=is-public,Values=false"  "Name=owner-id,Values=258274856018"  --query "Images[*].ImageId" --output text)

    if($null -ne $oldPrivateImageId) {

        Write-Host "Old Private Image Id "$oldPrivateImageId

        $snapShotId =(& aws ec2 describe-images --filters "Name=name,Values=$params.AwsPublicImageName" "Name=is-public,Values=false"  "Name=owner-id,Values=258274856018"  --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId"  --output text)
        Write-Host "Old Private Image SnapShot Id " $snapShotId

        aws ec2 deregister-image --image-id $oldPrivateImageId
        Write-Host "The Old Private Image " $oldPrivateImageId "has been deleted successfully!"

        if($null -ne $snapShotId) {
          aws ec2 delete-snapshot --snapshot-id $snapShotId
          Write-Host "The Old Private Image SnapShot " $snapShotId "has been deleted successfully!"
        }
    }
    else
    {
        Write-Host "There is no old Private Image exist now."
    }
}

function Import-AMIImage {
    $ErrorActionPreference = 'Stop'
    $importTaskId =(& aws ec2 import-image --description "$params.AwsPublicImageName-import" --disk-containers Description="$params.AwsPublicImageName",Format="vhdx",UserBucket="{S3Bucket=edfi-starter-kits,S3Key=$params.AwsS3KeyName/ed-fi-starter-kit.vhdx}" --query "ImportTaskId" --output text)
    Write-Host " Original Import Image "$importTaskId " has been started.It will take a while to continue on next step. Please be patient. "

    $isImportImageNotCompleted =$true
    while($isImportImageNotCompleted -eq $true) {

       Start-Sleep -s 10
       $Iscompleted =(& aws ec2 describe-import-image-tasks --import-task-ids $importTaskId  --query "ImportImageTasks[*].Status" --output text)
       if($Iscompleted -eq "completed") {
            $isImportImageNotCompleted =$false
            Write-Host " Original Import Image " $importTaskId "has been completed successfully! "
       }

     }

     $originalImageId =(& aws ec2 describe-import-image-tasks  --import-task-ids $importTaskId  --query "ImportImageTasks[*].ImageId" --output text)

     $originalSnapShotId =(& aws ec2 describe-import-image-tasks  --import-task-ids $importTaskId  --query "ImportImageTasks[*].SnapshotDetails[*].SnapshotId"  --output text)

     $newimageId =(& aws ec2 copy-image --source-image-id $originalImageId  --source-region us-east-2 --region us-east-2 --name $params.AwsPublicImageName --description $params.AwsPublicImageName --query "ImageId" --output text)
     Write-Host "##teamcity[setParameter name='aws.newimageId' value='$newimageId']"

     Write-Host "Copy to new Image " $newimageId " process has been started , It will take a while to complete this step,  Basically adding  name  " $params.AwsPublicImageName " to image"

    $isNewImageNotAvailable =$true
    while($isNewImageNotAvailable -eq $true) {

       Start-Sleep -s 10
       $IsAvailable =(& aws ec2 describe-images  --image-ids  $newimageId  --filters "Name=name,Values=$params.AwsPublicImageName" "Name=state,Values=available" --query "Images[*].State"  --output text)
       if($IsAvailable -eq "available") {
            $isNewImageNotAvailable =$false
            Write-Host " New Image " $newimageId "has been copied successfully!"
       }

     }

    aws ec2 deregister-image --image-id $originalImageId
    Write-Host "The original image " $originalImageId "has been deleted successfully!"

    aws ec2 delete-snapshot --snapshot-id $originalSnapShotId
}

function Set-TagToAMI {
    $ErrorActionPreference = 'Stop'
    $newimageId ="$params.AwsNewImageId"

    aws ec2 create-tags --resources $newimageId  --tags Key=Schedule,Value=austin-office-hours
    $instanceIdFromTag =(& aws ec2 describe-tags  --filters "Name=resource-id,Values= $newimageId" --query "Tags[*].ResourceId" --output text)
    if($newimageId -eq $instanceIdFromTag){
    Write-Host "New Tag with Key=Schedule,Value=austin-office-hours has been created successfully for this image " $newimageId
    }

}

Export-ModuleMember -function Remove-OldPrivateImage,Import-AMIImage,Set-TagToAMI -Alias *
