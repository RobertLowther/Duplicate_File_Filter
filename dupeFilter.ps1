param (
    [string]$source,
    [string]$dest
)

if ($source -eq $null -or $dest -eq $null) {
    Write-Output "Usage:`ndupefilter.ps1 [Source Directory] [Destination Directory]"
}

# Validate target directory structure
if (-not (Test-Path -Path $source -IsValid))
{
    Write-Output "$($source) is not a valid path."
    exit
}

$source_directory = Resolve-Path $source

# Validate target directory exists
if (-not (Test-Path -Path $source_directory))
{
    Write-Output "$($source_directory) does not exist."
    exit
}

# Create destination directory
$result = .\Create-Directory.ps1 $dest

if ($result[1] -ne $true) {
    Write-Output $result[0]
    Exit
}

$dupe_directory = $result[0]

Write-Output "`nChecking for duplicated files in $($source_directory)"
Write-Output "Getting File List"
$file_list = Get-ChildItem -Path $source_directory -Recurse

# construct a dictionary of files indexed by hash
# Source $file_list
# Keys - hash
# Values - Array of files
$filtered_files = @{}

foreach ($file in $file_list)
{
    if ($file.GetType().Name -ne "FileInfo")
    {
        if ($file.GetType().Name -eq "DirectoryInfo")
        {
            New-Item -Path "$($file.FullName.Replace($source_directory, $dupe_directory))" -ItemType Directory
        }
        continue 
    }
    
    $hash = Get-FileHash $file.FullName
    $hash = $hash.hash

    if ($null -eq $hash) { continue }

    if ($filtered_files.ContainsKey($hash))
    {
        $filtered_files[$hash] += $file
        continue
    }

    $filtered_files[$hash] = @($file)
}

# go through each entry in filtered files and move the apropriate files
Write-Output "Moving Duplicates"
foreach ($key in $filtered_files.keys)
{
    $i = 0
    while ($i -lt $filtered_files[$key].Length - 1) {
        $file = $filtered_files[$key][$i]
        $final_path = $($file.FullName.Replace($source_directory, $dupe_directory))

        Write-Output "src: $($file.FullName)    dst:$($final_path)"
        if ($final_path.Length -gt 256)
        {
            Write-Output "Unable to move file '$($file.Name)' because its name would excede windows file path limit"
        }
        else
        {
            Move-Item -Path "$($file.FullName)"  -Destination "$($final_path)"
        }

        $i++
    }
}