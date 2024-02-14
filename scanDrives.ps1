#script to scan shared drives for any files with names like password, pass, etc
$path = "C:\testings.csv"
$shares = #insert the drives you want to search here

$FileObjectList = @()
$search = Get-ChildItem -Path $shares -Recurse | Where-Object {($_.Name -like "*password*") -or ($_.Name -like "*pword*") -or ($_.Name -like "*credential*")} #you can play with these to finetune your search
$search | ForEach-Object {
    $FileObject = New-Object PSObject -Property @{
        FileName = $_.FullName
        FileDate = $_.LastWriteTime
    }
    $FileObjectList += $FileObject
}

$FileObjectList | Export-Csv $path
