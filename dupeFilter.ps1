param (
    [Parameter(Mandatory=$false)][string]$path
)
$current_directory = "$(Get-Location)\$($path)"

$file_list = Get-ChildItem -Path $current_directory -Name

$filtered_files = @{}

echo $file_list

foreach ($file_name in $file_list) {
    $base_name = $file_name.substring(0, $file_name.length - 4)
    $ext = $file_name.substring($file_name.length - 4)

    if ($base_name -contains " - ") { continue }

    $split_name = $base_name -split " - "

    $base_name = $split_name[0]
    if ($split_name.length -gt 1) {
        $copy_txt = $split_name[$split_name.length - 1]
    } else {
        $copy_txt = ""
    }

    if ($copy_txt.length -lt 4 -or $copy_txt.substring(0, 4) -ne "Copy") { continue }

    $original_file_name = $base_name + $ext
    if ($filtered_files.ContainsKey($original_file_name)) {
        $filtered_files[$original_file_name] += $file_name
    } elseif ($file_list -contains $original_file_name) {
        $filtered_files[$original_file_name] = @($file_name)
    }
}

$dupe_table = @{}

foreach ($original in $filtered_files.keys) {
    $original_size = (Get-Item "$($current_directory)\$($original)").length
    $dupe_list = $filtered_files[$original]
    $i = 0
    $valid_dupes = @()
    while ($i -lt $dupe_list.length) {
        $possible_dupe = $dupe_list[$i]
        $dupe_size = (Get-Item "$($current_directory)\$($possible_dupe)").length
        if ($original_size -eq $dupe_size) {
            $valid_dupes += $possible_dupe
        }
        $i += 1
    }
    $dupe_table[$original] = $valid_dupes
}

if (($filtered_files.length -gt 0) -and -not (Test-Path -Path "$($current_directory)\dupe")) {
    New-Item -Path "$($current_directory)\dupe" -ItemType Directory
}

echo ""

foreach ($original in $dupe_table.keys) {
    foreach ($dupe in $dupe_table[$original]) {
        echo "src: $($current_directory)\$($dupe)"
        $destination =  "$($current_directory)\dupe\$($dupe)"
        echo "dst: $($destination)"
        echo ""
        if ($destination.Length -gt 256) {
            echo "Unable to move file '$($dupe)' because this would excede windows file path limit"
        } else {
            Move-Item -Path "$($current_directory)\$($dupe)"  -Destination "$($destination)"
        }
    }
}

