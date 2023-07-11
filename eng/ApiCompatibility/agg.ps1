$root = 'D:\Development\dotnet-extensions';

# List of types
$typeApiMap = @();
# List of actual API
$memberApiMap = @();

Get-ChildItem -Path "$root\src" -Include 'PublicAPI.Unshipped.txt' -Recurse | `
    ForEach-Object {
        Write-Host $_
        $folder = $_.Directory
        $csproj = (Get-ChildItem -Path $folder -Filter *.csproj)[0];

        # Try to get full project name
        [xml]$csprojContent = Get-Content $csproj.FullName
        if ($csprojContent.Project.PropertyGroup.AssemblyName) {
            $csprojName = $csprojContent.Project.PropertyGroup.AssemblyName
        }
        else {
            $csprojName = $csproj.BaseName
        }

        [string[]]$lines = Get-Content $_;

        $lines | `
            ForEach-Object {
                $line = $_
                if ([string]::IsNullOrWhiteSpace($line)) {
                    return;
                }

                # https://regex101.com/
                # public const
                if ($line -match "^(?<modifier>const) (?<namespace>[A-Za-z\d.]*)\.(?<type>[^.]*)\.(?<member>[~A-Za-z<,>\s\d]*) = (?<value>.*) -> (?<returnType>.*)$") {
                    $memberApiMap += "$csprojName`t$($Matches.namespace)`t$($Matches.type)`t$($Matches.member)`t$($Matches.value)`t$($Matches.returnType)`t$($Matches.modifier)"
                }
                # public enums
                elseif ($line -match "^(?<namespace>[A-Za-z\d.]*)\.(?<type>[^.]*)\.(?<member>[A-Za-z\d]*) = (?<value>.*) -> (?<returnType>.*)$") {
                    $memberApiMap += "$csprojName`t$($Matches.namespace)`t$($Matches.type)`t$($Matches.member) $($Matches.operator)($Matches.args)`t`t$($Matches.returnType)`t$($Matches.modifier)"
                }
                # public operators
                elseif ($line -match "^(?<modifier>static) (?<namespace>[A-Za-z\d.]*)\.(?<type>[^.]*)\.(?<member>[~A-Za-z<,>\s\d]*\.((implicit|explicit) )?(operator)) (?<operator>[^(]*)\((?<args>.*)\) -> (?<returnType>.*)$") {
                    $memberApiMap += "$csprojName`t$($Matches.namespace)`t$($Matches.type)`t$($Matches.member) $($Matches.operator)($Matches.args)`t`t$($Matches.returnType)`t$($Matches.modifier)"
                }
                # public properties
                elseif ($line -match "^(?<modifier>abstract|override|static)?\s*(?<namespace>[A-Za-z\d.]*)\.(?<type>[^.]*)\.(?<member>[~A-Za-z<,>\s\d]*(\.this\[.*\])?\.(get|set)) -> (?<returnType>.*)$") {
                    $memberApiMap += "$csprojName`t$($Matches.namespace)`t$($Matches.type)`t$($Matches.member)`t`t$($Matches.returnType)`t$($Matches.modifier)"
                }
                # public events
                elseif ($line -match "^(?<namespace>[A-Za-z\d.]*)\.(?<type>[^.]*)\.(?<member>[~A-Za-z<,>\s\d]*) -> (?<returnType>.*)$") {
                    $memberApiMap += "$csprojName`t$($Matches.namespace)`t$($Matches.type)`t$($Matches.member)($Matches.args)`t`t$($Matches.returnType)`t$($Matches.modifier)"
                }
                # public methods
                elseif ($line -match "^~?(?<modifier>abstract|override|static|virtual)?\s*(?<namespace>[A-Za-z\d.]*)\.(?<type>[^.]*)\.(?<member>[~A-Za-z<,>\s\d]*)\((?<args>.*)\) -> (?<returnType>.*)$") {
                    $memberApiMap += "$csprojName`t$($Matches.namespace)`t$($Matches.type)`t$($Matches.member)($Matches.args)`t`t$($Matches.returnType)`t$($Matches.modifier)"
                }
                # public predicates
                elseif ($line -match "^(?<modifier>static readonly) (?<namespace>[A-Za-z\d.]*)\.(?<type>[^.]*)\.(?<member>[~A-Za-z<,>\s\d]*) -> (?<returnType>.*)$") {
                    $memberApiMap += "$csprojName`t$($Matches.namespace)`t$($Matches.type)`t$($Matches.member)($Matches.args)`t`t$($Matches.returnType)`t$($Matches.modifier)"
                }
                # public types
                elseif ($line -match "^(?<namespace>[A-Za-z\d.]*)\.(?<type>[A-Za-z<,>\s\d]*)$") {
                    $typeApiMap += "$csprojName`t$($Matches.namespace)`t$($Matches.type)"
                }
                # public nested types
                elseif ($line -match "^(?<namespace>[A-Za-z\d.]*)\.(?<type>[A-Za-z<,>\s\d]*)\.(?<nestedtype>[A-Za-z<,>\s\d]*)$") {
                    $typeApiMap += "$csprojName`t$($Matches.namespace)`t$($Matches.type)+$($Matches.nestedtype)"
                }
                else {
                    throw "$csprojName -> $line"
                }
            }
        }

$typeMapFile = "$root\typemap.csv"
"Project`tNamespace`tType" | Out-File $typeMapFile -Encoding ascii -Force
$typeApiMap | sort | Out-File $typeMapFile -Encoding ascii -Append

$apiMapFile = "$root\apimap.csv"
"Project`tNamespace`tType`tMember`tValue`tReturn type`tModifier" | Out-File $apiMapFile -Encoding ascii -Force
$memberApiMap | sort | Out-File $apiMapFile -Encoding ascii -Append
