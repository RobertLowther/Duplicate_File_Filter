param (
    [string]$path,
    [switch]$check = $false
)

$target_directory = "$(Get-Location)\$($path)"

if (-not (Test-Path -Path $target_directory)) {
    Write-Output "Location '$($target_directory)' does not exist"
    exit
}

Write-Output "`nChecking for possible duplicated files in $($target_directory)"

$file_list = Get-ChildItem -Path $target_directory

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

if (($dupe_table.Keys.Length -gt 0) -and -not (Test-Path -Path "$($target_directory)\dupe")) {
    New-Item -Path "$($target_directory)\dupe" -ItemType Directory
}

if ($test) {
    Write-Output "The following itmes have been identified as possible duplicates:`n"
    foreach ($original in $dupe_table.keys) {
        foreach ($dupe in $dupe_table[$original]) {
            Write-Output "`t$($dupe)"
        }
    }
    Write-Output "`nThese items would be moved to $($target_directory)\dupe\`n"
    exit
}

foreach ($original in $dupe_table.keys) {
    foreach ($dupe in $dupe_table[$original]) {
        Write-Output "src: $($target_directory)\$($dupe)"
        $destination =  "$($target_directory)\dupe\$($dupe)"
        Write-Output "dst: $($destination)"
        Write-Output ""
        if ($destination.Length -gt 256) {
            Write-Output "Unable to move file '$($dupe)' because this would excede windows file path limit"
        } else {
            Move-Item -Path "$($target_directory)\$($dupe)"  -Destination "$($destination)"
        }
    }
}
