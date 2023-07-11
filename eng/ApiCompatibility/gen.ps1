#$root = 'D:\Development\dotnet-extensions\src'

Get-ChildItem -Path D:\Development\dotnet-extensions\src -Include '*.csproj' -Recurse | `
    ForEach-Object {
        $folder = $_.Directory
        #Write-Host $_
        '' | Out-File "$folder\PublicAPI.Unshipped.txt" -Encoding ascii
        '' | Out-File "$folder\PublicAPI.Shipped.txt" -Encoding ascii
    }
