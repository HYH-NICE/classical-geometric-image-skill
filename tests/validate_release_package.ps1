param(
    [string]$ReleaseRoot = 'C:\Users\24901\Documents\GitHub\classical-geometric-image-skill'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-RelativeReleasePath {
    param(
        [Parameter(Mandatory)] [string]$Root,
        [Parameter(Mandatory)] [string]$Path
    )

    return [IO.Path]::GetRelativePath($Root, $Path).Replace('\', '/')
}

$releaseRootPath = [IO.Path]::GetFullPath($ReleaseRoot)
if (-not (Test-Path -LiteralPath $releaseRootPath -PathType Container)) {
    throw "Release root does not exist: $releaseRootPath"
}

$requiredFiles = @(
    'README.md',
    '.gitignore',
    'skills/generate-classical-geometric-images/SKILL.md',
    'skills/generate-classical-geometric-images/agents/openai.yaml',
    'skills/generate-classical-geometric-images/assets/style-atlas.jpg',
    'skills/generate-classical-geometric-images/references/style-dna.md',
    'skills/generate-classical-geometric-images/references/quality-gates.md',
    'skills/generate-classical-geometric-images/references/prompt-recipes.md',
    'skills/generate-classical-geometric-images/references/poster-design.md',
    'skills/generate-classical-geometric-images/references/period-style-systems.md',
    'skills/generate-classical-geometric-images/references/painting-techniques.md',
    'skills/generate-classical-geometric-images/references/normative-contracts.json',
    'skills/generate-classical-geometric-images/references/historical-surreal-collage.md',
    'skills/generate-classical-geometric-images/references/historical-dissolution.md',
    'scripts/build_style_atlas.py',
    'tests/skill_scenarios.md',
    'tests/test_build_style_atlas.py',
    'tests/validate_classical_skill.ps1',
    'tests/validate_release_package.ps1'
)

foreach ($relativePath in $requiredFiles) {
    $absolutePath = Join-Path $releaseRootPath ($relativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        throw "Missing required release file: $relativePath"
    }
}

$allowedTopLevel = @('.git', '.gitignore', 'README.md', 'scripts', 'skills', 'tests')
foreach ($entry in Get-ChildItem -LiteralPath $releaseRootPath -Force) {
    if ($entry.Name -notin $allowedTopLevel) {
        throw "Unexpected top-level release entry: $($entry.Name)"
    }
}

$forbiddenDirectoryNames = @('validation', 'docs', '__pycache__', '.pytest_cache', '.venv', 'tmp', 'temp')
$directories = Get-ChildItem -LiteralPath $releaseRootPath -Directory -Recurse -Force |
    Where-Object { (Get-RelativeReleasePath -Root $releaseRootPath -Path $_.FullName) -notmatch '^(?:\.git)(?:/|$)' }
foreach ($directory in $directories) {
    if ($directory.Name.ToLowerInvariant() -in $forbiddenDirectoryNames) {
        $relativePath = Get-RelativeReleasePath -Root $releaseRootPath -Path $directory.FullName
        throw "Forbidden release directory: $relativePath"
    }
}

$files = @(Get-ChildItem -LiteralPath $releaseRootPath -File -Recurse -Force |
    Where-Object { (Get-RelativeReleasePath -Root $releaseRootPath -Path $_.FullName) -notmatch '^(?:\.git)(?:/|$)' })

$allowedRaster = 'skills/generate-classical-geometric-images/assets/style-atlas.jpg'
$rasterExtensions = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.tif', '.tiff', '.heic', '.avif')
$rasterFiles = @($files | Where-Object { $_.Extension.ToLowerInvariant() -in $rasterExtensions })
foreach ($rasterFile in $rasterFiles) {
    $relativePath = Get-RelativeReleasePath -Root $releaseRootPath -Path $rasterFile.FullName
    if ($relativePath -cne $allowedRaster) {
        throw "Forbidden raster release file: $relativePath"
    }
}
if ($rasterFiles.Count -ne 1) {
    throw "Release must contain exactly one raster asset: $allowedRaster"
}

$forbiddenContentPatterns = [ordered]@{
    'absolute Windows user path' = '(?i)[A-Z]:\\Users\\'
    'fixed local collection path' = '(?i)D:\\Image_Collections'
    'chat message identifier' = '(?i)(MsgID=|mmwebwx|webwxgetmsgimg|crypt_)'
    'clipboard or temp attachment' = '(?i)(codex-clipboard|AppData\\Local\\Temp)'
    'personal photo folder path' = '(?i)\\(Downloads|Desktop)\\'
    'credential assignment' = '(?i)(api[_-]?key|access[_-]?token|password|secret)\s*[:=]\s*["''][^"'']{8,}["'']'
}

$textExtensions = @('.md', '.json', '.yaml', '.yml', '.py', '.ps1', '.txt')
foreach ($file in $files) {
    $relativePath = Get-RelativeReleasePath -Root $releaseRootPath -Path $file.FullName
    if ($relativePath -ceq 'tests/validate_release_package.ps1') {
        continue
    }
    if (($file.Extension.ToLowerInvariant() -notin $textExtensions) -and ($file.Name -cne '.gitignore')) {
        continue
    }

    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    foreach ($entry in $forbiddenContentPatterns.GetEnumerator()) {
        if ($content -match $entry.Value) {
            throw "Forbidden release content ($($entry.Key)) in: $relativePath"
        }
    }
}

$readmePath = Join-Path $releaseRootPath 'README.md'
$readme = Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8
$requiredReadmeText = @(
    'heyuhang1101101-commits/classical-geometric-image-skill',
    'skills/generate-classical-geometric-images',
    'Windows PowerShell',
    'macOS / Linux',
    '## Update',
    '## Invoke'
)
foreach ($requiredText in $requiredReadmeText) {
    if (-not $readme.Contains($requiredText, [StringComparison]::Ordinal)) {
        throw "README is missing required release guidance: $requiredText"
    }
}

$skillPath = Join-Path $releaseRootPath 'skills\generate-classical-geometric-images\SKILL.md'
$skill = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
$directRuntimeContract = 'For ordinary image requests, directly analyze the supplied source, compile the prompt, call built-in ImageGen, perform concise visual QA, and return the image; do not create specifications or implementation plans, run TDD or Git workflows, or dispatch subagents unless the user explicitly asks to modify, test, package, or publish the Skill itself.'
if (-not $skill.Contains($directRuntimeContract, [StringComparison]::Ordinal)) {
    throw 'Released Skill is missing the direct image-generation runtime contract.'
}

Write-Output 'Portable skill release validation passed.'
