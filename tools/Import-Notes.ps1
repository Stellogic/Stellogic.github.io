[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [string]$DestinationRoot = (Join-Path $PSScriptRoot '..\source\_posts'),

    [string[]]$Categories,

    [string[]]$Tags,

    [datetime]$Date,

    [switch]$Force,

    [switch]$Flatten,

    [switch]$DryRun,

    [switch]$UsePathSegmentsAsTags
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-Directory {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        return (Resolve-Path -Path $Path -ErrorAction Stop).ProviderPath
    }
    return [System.IO.Path]::GetFullPath($Path)
}

function New-DirectoryIfMissing {
    param([string]$Path, [switch]$WhatIf)
    if (Test-Path -LiteralPath $Path) {
        return
    }
    if ($WhatIf) {
        Write-Verbose "[dry-run] Would create directory: $Path"
    } else {
        Write-Verbose "Creating directory: $Path"
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )
    $baseUri = New-Object System.Uri (($BasePath.TrimEnd([System.IO.Path]::DirectorySeparatorChar)) + [System.IO.Path]::DirectorySeparatorChar)
    $targetUri = New-Object System.Uri $TargetPath
    $relative = $baseUri.MakeRelativeUri($targetUri).ToString()
    $relativeDecoded = [System.Uri]::UnescapeDataString($relative)
    return ($relativeDecoded -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function ConvertTo-SafeFileName {
    param([string]$Value)
    $temp = $Value -replace '[<>:"/\\|?*]', ' '
    $temp = $temp.Trim()
    $temp = $temp -replace '\s+', '-'
    if ([string]::IsNullOrWhiteSpace($temp)) {
        return ('post-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    }
    return $temp
}
function ConvertTo-Slug {
    param([string]$Value)
    $slug = $Value.Trim()
    $slug = $slug -replace '\s+', '-'
    $slug = $slug -replace "[^0-9A-Za-z\-\u4e00-\u9fa5]", ''
    $slug = $slug.Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return ('post-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    }
    return $slug
}

function Get-TitleFromContent {
    param([string]$Content, [string]$Fallback)
    foreach ($line in $Content -split "`n") {
        $trimmed = $line.Trim()
        if ($trimmed -match '^#\s+(?<title>.+)$') {
            return $matches['title'].Trim()
        }
    }
    return $Fallback
}

function Split-FrontMatter {
    param([string]$Content)
    if ($Content.StartsWith('---')) {
        $closingIndex = $Content.IndexOf("`n---", 3, [StringComparison]::Ordinal)
        if ($closingIndex -ge 0) {
            $frontMatter = $Content.Substring(0, $closingIndex + 4)
            $body = $Content.Substring($closingIndex + 4)
            return ,$frontMatter, $body
        }
    }
    return ,$null, $Content
}

function Convert-PathToUrlStyle {
    param([string]$Path)
    return ($Path -replace '\\', '/')
}

function Update-MarkdownImages {
    param(
        [string]$Body,
        [string]$SourceDirectory,
        [string]$AssetDirectory,
        [string]$DestinationDirectory,
        [switch]$WhatIf,
        [switch]$ForceCopy
    )

    $assetDirectoryExisting = Test-Path -LiteralPath $AssetDirectory
    if (-not $assetDirectoryExisting -and -not $WhatIf) {
        New-Item -ItemType Directory -Path $AssetDirectory | Out-Null
    } elseif (-not $assetDirectoryExisting) {
        Write-Verbose "[dry-run] Would create directory: $AssetDirectory"
    }

    $copiedAssets = @()

    $pattern = '!?\[(?<alt>[^\]]*)\]\((?<target>[^)]+)\)'
    $processedBody = [regex]::Replace($Body, $pattern, {
            param($match)

            if ($match.Value.StartsWith('!') -eq $false) {
                return $match.Value
            }

            $rawTarget = $match.Groups['target'].Value.Trim()
            $titlePart = ''
            if ($rawTarget -match '^(?<link>[^\s]+)\s+(?<title>"[^"]*")$') {
                $rawLink = $matches['link']
                $titlePart = ' ' + $matches['title']
            } else {
                $rawLink = $rawTarget
            }

            $cleanLink = $rawLink.Trim('<', '>', '"', "'")
            if ([string]::IsNullOrWhiteSpace($cleanLink)) {
                return $match.Value
            }

            if ($cleanLink -match '^(https?:|data:|//)') {
                return $match.Value
            }

            if ($cleanLink.StartsWith('/')) {
                return $match.Value
            }

            $sourceCandidate = [System.IO.Path]::Combine($SourceDirectory, $cleanLink)
            try {
                $sourceFullPath = [System.IO.Path]::GetFullPath($sourceCandidate)
            } catch {
                Write-Warning "Skipping image with unresolved path: $cleanLink"
                return $match.Value
            }

            if (-not (Test-Path -LiteralPath $sourceFullPath)) {
                Write-Warning "Asset not found: $sourceFullPath"
                return $match.Value
            }

                $relativeAssetTarget = $cleanLink.TrimStart([char[]]@('.', '/', '\'))
            $targetPath = Join-Path $AssetDirectory $relativeAssetTarget
            $targetDir = Split-Path -Path $targetPath -Parent
            New-DirectoryIfMissing -Path $targetDir -WhatIf:$WhatIf

            $shouldCopy = $true
            if ((Test-Path -LiteralPath $targetPath) -and -not $ForceCopy) {
                $sourceHash = Get-FileHash -Path $sourceFullPath -Algorithm SHA256
                $targetHash = Get-FileHash -Path $targetPath -Algorithm SHA256 -ErrorAction SilentlyContinue
                if ($targetHash -and $sourceHash.Hash -eq $targetHash.Hash) {
                    $shouldCopy = $false
                }
            }

            if ($shouldCopy) {
                if ($WhatIf) {
                    Write-Verbose "[dry-run] Would copy asset: $sourceFullPath -> $targetPath"
                } else {
                    Write-Verbose "Copying asset: $sourceFullPath -> $targetPath"
                    Copy-Item -LiteralPath $sourceFullPath -Destination $targetPath -Force
                }
            }

            $fileName = [System.IO.Path]::GetFileName($targetPath)
            $altText = $match.Groups['alt'].Value
            if ([string]::IsNullOrWhiteSpace($altText)) {
                $altText = $fileName
            }
            $copiedAssets += $targetPath

            return "{{% asset_img {0} {1} %}}" -f $fileName, $altText
        })

    return [PSCustomObject]@{
        Body          = $processedBody
        CopiedAssets  = $copiedAssets
    }
}

function Update-HtmlImages {
    param(
        [string]$Body,
        [string]$SourceDirectory,
        [string]$AssetDirectory,
        [string]$DestinationDirectory,
        [switch]$WhatIf,
        [switch]$ForceCopy
    )

    $pattern = '<img\s+[^>]*src=["\''](?<src>[^"\'']+)["\'']'
    $builder = New-Object System.Text.StringBuilder
    $lastIndex = 0
    foreach ($match in [regex]::Matches($Body, $pattern, 'IgnoreCase')) {
        $builder.Append($Body.Substring($lastIndex, $match.Index - $lastIndex)) | Out-Null
        $lastIndex = $match.Index + $match.Length

        $rawLink = $match.Groups['src'].Value
        $cleanLink = $rawLink.Trim()

        if ($cleanLink -match '^(https?:|data:|//)' -or $cleanLink.StartsWith('/')) {
            $builder.Append($match.Value) | Out-Null
            continue
        }

        $sourceCandidate = [System.IO.Path]::Combine($SourceDirectory, $cleanLink)
        try {
            $sourceFullPath = [System.IO.Path]::GetFullPath($sourceCandidate)
        } catch {
            Write-Warning "Skipping <img> with unresolved path: $cleanLink"
            $builder.Append($match.Value) | Out-Null
            continue
        }

        if (-not (Test-Path -LiteralPath $sourceFullPath)) {
            Write-Warning "Asset not found: $sourceFullPath"
            $builder.Append($match.Value) | Out-Null
            continue
        }

        $relativeAssetTarget = $cleanLink.TrimStart([char[]]@('.', '/', '\'))
        $targetPath = Join-Path $AssetDirectory $relativeAssetTarget
        $targetDir = Split-Path -Path $targetPath -Parent
        New-DirectoryIfMissing -Path $targetDir -WhatIf:$WhatIf

        $shouldCopy = $true
        if ((Test-Path -LiteralPath $targetPath) -and -not $ForceCopy) {
            $sourceHash = Get-FileHash -Path $sourceFullPath -Algorithm SHA256
            $targetHash = Get-FileHash -Path $targetPath -Algorithm SHA256 -ErrorAction SilentlyContinue
            if ($targetHash -and $sourceHash.Hash -eq $targetHash.Hash) {
                $shouldCopy = $false
            }
        }

        if ($shouldCopy) {
            if ($WhatIf) {
                Write-Verbose "[dry-run] Would copy asset: $sourceFullPath -> $targetPath"
            } else {
                Write-Verbose "Copying asset: $sourceFullPath -> $targetPath"
                Copy-Item -LiteralPath $sourceFullPath -Destination $targetPath -Force
            }
        }

        $relativeFromPost = Get-RelativePath -BasePath $DestinationDirectory -TargetPath $targetPath
        $relativeForHtml = Convert-PathToUrlStyle $relativeFromPost
        $replacement = $match.Value -replace [regex]::Escape($rawLink), $relativeForHtml
        $builder.Append($replacement) | Out-Null
    }

    $builder.Append($Body.Substring($lastIndex)) | Out-Null
    return $builder.ToString()
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "SourcePath not found: $SourcePath"
}

$resolvedSource = Resolve-Directory -Path $SourcePath

if (-not (Test-Path -LiteralPath $DestinationRoot)) {
    if ($DryRun) {
        Write-Verbose "[dry-run] Would create destination root: $DestinationRoot"
    } else {
        New-Item -ItemType Directory -Path $DestinationRoot | Out-Null
    }
}

$resolvedDestination = Resolve-Directory -Path $DestinationRoot

$markdownFiles = Get-ChildItem -Path $resolvedSource -Filter '*.md' -Recurse
if ($markdownFiles.Count -eq 0) {
    Write-Warning "No markdown files found under $resolvedSource"
    return
}

Write-Verbose "Discovered $($markdownFiles.Count) markdown file(s)."

$imported = @()

foreach ($file in $markdownFiles) {
    $relativePath = Get-RelativePath -BasePath $resolvedSource -TargetPath $file.FullName
    $relativeDir = Split-Path -Path $relativePath -Parent

    $destinationDir = if ($Flatten) { $resolvedDestination } else { if ([string]::IsNullOrWhiteSpace($relativeDir)) { $resolvedDestination } else { Join-Path $resolvedDestination $relativeDir } }
    New-DirectoryIfMissing -Path $destinationDir -WhatIf:$DryRun

    $safeBaseName = ConvertTo-SafeFileName ([System.IO.Path]::GetFileNameWithoutExtension($file.Name))
    $destinationPostPath = Join-Path $destinationDir ($safeBaseName + '.md')
    $assetDir = Join-Path $destinationDir $safeBaseName

    if ((Test-Path -LiteralPath $destinationPostPath) -and -not $Force) {
        Write-Warning "Skipping existing post (use -Force to overwrite): $destinationPostPath"
        continue
    }

    $rawContent = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $frontMatterParts = Split-FrontMatter -Content $rawContent
    $bodyContent = $frontMatterParts[1]

    $title = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $slug = ConvertTo-Slug $safeBaseName

    $effectiveCategories = @()
    if ($Categories) {
        $effectiveCategories = @($Categories)
    } elseif (-not [string]::IsNullOrWhiteSpace($relativeDir)) {
        $segments = $relativeDir -split '[\\/]+'
        $effectiveCategories = $segments
    }

    $effectiveTags = @()
    if ($Tags) {
        $effectiveTags = @($Tags)
    } else {
        if ($UsePathSegmentsAsTags -and $effectiveCategories.Count -gt 0) {
            $effectiveTags += $effectiveCategories
        }
        $basenameForTags = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $effectiveTags += $basenameForTags
            $effectiveTags = @($effectiveTags | Select-Object -Unique)
    }

    $postDate = if ($Date) { $Date } else { $file.LastWriteTimeUtc }
    $updatedDate = $file.LastWriteTimeUtc

    $assetResult = Update-MarkdownImages -Body $bodyContent -SourceDirectory $file.DirectoryName -AssetDirectory $assetDir -DestinationDirectory $destinationDir -WhatIf:$DryRun -ForceCopy:$Force
    $processedBody = $assetResult.Body
    $processedBody = Update-HtmlImages -Body $processedBody -SourceDirectory $file.DirectoryName -AssetDirectory $assetDir -DestinationDirectory $destinationDir -WhatIf:$DryRun -ForceCopy:$Force

    $frontMatterLines = @()
    $frontMatterLines += '---'
    $frontMatterLines += "title: $title"
    $frontMatterLines += "date: $($postDate.ToString('yyyy-MM-dd HH:mm:ss'))"
    $frontMatterLines += "updated: $($updatedDate.ToString('yyyy-MM-dd HH:mm:ss'))"
    $frontMatterLines += "slug: $slug"
    if ($effectiveCategories.Count -gt 0) {
        $frontMatterLines += 'categories:'
        foreach ($category in $effectiveCategories) {
            $frontMatterLines += "  - $category"
        }
    }
    if ($effectiveTags.Count -gt 0) {
        $frontMatterLines += 'tags:'
        foreach ($tag in $effectiveTags) {
            $frontMatterLines += "  - $tag"
        }
    }
    $frontMatterLines += '---'
    $frontMatterLines += ''

    $finalContent = ($frontMatterLines -join "`n") + $processedBody.TrimStart("`r", "`n")

    if ($DryRun) {
        Write-Output "[dry-run] Would write post: $destinationPostPath"
    } else {
        Write-Verbose "Writing post: $destinationPostPath"
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($destinationPostPath, $finalContent, $utf8NoBom)
    }

    $imported += [PSCustomObject]@{
        Source      = $file.FullName
        Destination = $destinationPostPath
        Assets      = $assetResult.CopiedAssets
    }
}

if ($imported.Count -eq 0) {
    Write-Warning 'No posts imported. Use -Verbose for details.'
    return
}

Write-Output "Imported $($imported.Count) post(s)."
foreach ($entry in $imported) {
    $relativeDestination = Get-RelativePath -BasePath $resolvedDestination -TargetPath $entry.Destination
    Write-Output "- $relativeDestination"
}
