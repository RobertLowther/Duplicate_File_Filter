param (
    [string]$path,
    [string]$dest,
    [switch]$check = $false
)

############### Validate Target ################
# Validate target directory structure
if (-not (Test-Path -Path $path -IsValid)) {
    Write-Output "$($target_directory) is not a valid path."
    exit
}

$target_directory = [IO.Path]::GetFullPath($path)

# Validate target directory exists
if (-not (Test-Path -Path $target_directory)) {
    Write-Output "$($target_directory) does not exist."
    exit
}

################ Validate destination ################
# Validate dest directory structure
if (-not (Test-Path -Path $dest -IsValid)) {
    Write-Output "$($dest) is not a valid path"
}

# Create full destination path
if ([IO.Path]::IsPathRooted($dest)) {
    $dupe_directory = [IO.Path]::GetFullPath($dest)
} else {
    $joined = Join-Path $target_directory $dest
    $dupe_directory = [IO.Path]::GetFullPath($joined)
}

# Modify destination path such that it is a dir which doesn't exist
if (Test-Path -Path "$($dupe_directory)"){
    $i = 0

    while ($true) {
        $i++

        if (-not (Test-Path -Path "$($dupe_directory)$($i)")) {
            $dupe_directory += $i
            break
        }

        if ($i -ge 255) 
        {
            Write-Output "$($dupe_directory) is not a valid output location, please select another name for the output folder"
        }
    }
}

Write-Output "`nChecking for possible duplicated files in $($target_directory)"

$file_list = Get-ChildItem -Path $target_directory

# construct a dictionary of file whos names suggest that they may be duplicates
# Source $file_list
# Keys - Suspected original
# Values - Array of suspected duplicates
$filtered_files = @{}

foreach ($file in $file_list) {
    if ($file.GetType().Name -eq "DirectoryInfo") { continue }
    $ext = $file.Extension
    $base_name = $file.BaseName
    
    $split_name = $base_name -split " - ", -2
    
    $base_name = $split_name[0]
    if ($split_name.length -eq 2) {
        $copy_txt = $split_name[1]
    } else {
        $copy_txt = ""
    }
    
    if ($copy_txt.length -lt 4 -or $copy_txt.substring(0, 4) -ne "Copy") { continue }
    
    $original_file_name = $base_name + $ext
    if ($filtered_files.ContainsKey($original_file_name)) {
        $filtered_files[$original_file_name] += $file.Name
        continue
    }

    foreach ($stored_file in $file_list) {
        if ($stored_file.name -eq $original_file_name) {
            $filtered_files[$original_file_name] = @($file.Name)
            break
        }
    }
}

# Create a dictionary of files whos length suggests they might be duplicates
# Source - $filterd_files
# Keys - Suspected original
# Values - Suspected duplicates
$dupe_table = @{}

foreach ($original in $filtered_files.keys) {
    $original_size = (Get-Item "$($target_directory)\$($original)").length
    $dupe_list = $filtered_files[$original]
    
    $valid_dupes = @()
    
    foreach ($possible_dupe in $dupe_list) {
        $dupe_size = (Get-Item "$($target_directory)\$($possible_dupe)").Length
        if ($original_size -eq $dupe_size) {
            $valid_dupes += $possible_dupe
        }
    }
    
    if ($valid_dupes.Length -gt 0) {
        $dupe_table[$original] = $valid_dupes
    }
}

if ($dupe_table.Count -eq 0) {
    Write-Output "No potential duplicates found"
    exit
}

if ($check) {
    Write-Output "The following itmes have been identified as possible duplicates:`n"
    foreach ($original in $dupe_table.keys) {
        foreach ($dupe in $dupe_table[$original]) {
            Write-Output "`t$($dupe)"
        }
    }
    Write-Output "`nThese items would be moved to $dupe_directory`n"
    exit
}

New-Item -Path $dupe_directory -ItemType Directory

foreach ($original in $dupe_table.keys) {
    foreach ($dupe in $dupe_table[$original]) {
        Write-Output "src: $($target_directory)\$($dupe)"
        $destination =  "$($dupe_directory)\$($dupe)"
        Write-Output "dst: $($destination)"
        Write-Output ""
        if ($destination.Length -gt 256) {
            Write-Output "Unable to move file '$($dupe)' because this would excede windows file path limit"
        } else {
            Move-Item -Path "$($target_directory)\$($dupe)"  -Destination "$($destination)"
        }
    }
}
