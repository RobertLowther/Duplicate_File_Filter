param (
    [string]$dirName
)

# Validate dest directory structure
if (-not (Test-Path -Path $dirName -IsValid))
{
    Write-Output "$($dirName) is not a valid path"
    Return $false
}

# Create full destination path
if ([IO.Path]::IsPathRooted($dirName))
{
    $new_directory = [IO.Path]::GetFullPath($dirName)
} else
{
    $joined = Join-Path $(Get-Location) $dirName
    $full_directory = [IO.Path]::GetFullPath($joined)
}

# Modify destination path such that it is a dir which doesn't exist
$i = 0
$new_directory = $full_directory
while (Test-Path -Path "$($new_directory)")
{
    if ($i -ge 255) {
        Write-Output "$($full_directory) is not a valid output location, please select another name for the output folder"
        Return $false
    }
    else {
        $new_directory = $full_directory + ++$i
    }
}

Write-Output "$($new_directory)"
New-Item -Path $new_directory -ItemType Directory | Out-Null

Return $true