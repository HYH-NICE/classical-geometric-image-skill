$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$skillRoot = [System.IO.Path]::GetFullPath((Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'skills') 'generate-classical-geometric-images'))

function Get-SkillPath {
    param([Parameter(Mandatory)][string]$RelativePath)

    $path = $skillRoot
    foreach ($segment in ($RelativePath -split '/')) {
        $path = Join-Path $path $segment
    }
    return $path
}

function ConvertTo-LfText {
    param([Parameter(Mandatory)][string]$Text)

    return $Text.Replace("`r`n", "`n").Replace("`r", "`n")
}

function Get-ScenarioSection {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$StartHeading,
        [Parameter(Mandatory)][string]$EndHeading
    )

    $normalized = ConvertTo-LfText -Text $Text
    $startMatch = [regex]::Match($normalized, "(?m)^$([regex]::Escape($StartHeading))$")
    if (-not $startMatch.Success) { return $null }
    $endMatch = [regex]::Match($normalized, "(?m)^$([regex]::Escape($EndHeading))$", [System.Text.RegularExpressions.RegexOptions]::None, [TimeSpan]::FromSeconds(1))
    if (-not $endMatch.Success -or $endMatch.Index -le $startMatch.Index) { return $null }
    return $normalized.Substring($startMatch.Index, $endMatch.Index - $startMatch.Index)
}

function Get-OpenAiInterfaceYaml {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][hashtable]$ExpectedValues
    )

    $pythonCode = @'
import base64
import json
import sys

try:
    import yaml
    from yaml.constructor import ConstructorError
except Exception as exc:
    print(json.dumps({"ok": False, "error": f"PyYAML unavailable: {exc}"}, separators=(",", ":")))
    sys.exit(3)

class UniqueKeyLoader(yaml.SafeLoader):
    pass

def construct_unique_mapping(loader, node, deep=False):
    if not isinstance(node, yaml.MappingNode):
        raise ConstructorError(None, None, "expected a mapping node", node.start_mark)
    mapping = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        try:
            duplicate = key in mapping
        except TypeError as exc:
            raise ConstructorError("while constructing a mapping", node.start_mark, f"unhashable key: {exc}", key_node.start_mark)
        if duplicate:
            raise ConstructorError("while constructing a mapping", node.start_mark, f"duplicate key: {key!r}", key_node.start_mark)
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping

UniqueKeyLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_unique_mapping)

try:
    source = base64.b64decode(sys.argv[1], validate=True).decode("utf-8")
    document = yaml.load(source, Loader=UniqueKeyLoader)
    if not isinstance(document, dict):
        raise TypeError("YAML root must be a mapping")
    interface = document.get("interface")
    if not isinstance(interface, dict):
        raise TypeError("root key 'interface' must be a mapping")
    for key, value in interface.items():
        if not isinstance(key, str):
            raise TypeError(f"interface key must be a string: {key!r}")
        if not isinstance(value, str):
            raise TypeError(f"interface value for {key!r} must be a string")
    print(json.dumps({"ok": True, "interface": interface}, ensure_ascii=False, separators=(",", ":")))
except Exception as exc:
    print(json.dumps({"ok": False, "error": f"{type(exc).__name__}: {exc}"}, ensure_ascii=False, separators=(",", ":")))
    sys.exit(2)
'@
    $encodedYaml = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Text))
    try {
        $jsonOutput = & python -X utf8 -c $pythonCode $encodedYaml
        $pythonExitCode = $LASTEXITCODE
    } catch {
        return [pscustomobject]@{ Valid = $false; Error = "Python unavailable or failed to start: $($_.Exception.Message)" }
    }
    if ([string]::IsNullOrWhiteSpace(($jsonOutput -join "`n"))) {
        return [pscustomobject]@{ Valid = $false; Error = "Python/PyYAML parser returned no JSON (exit $pythonExitCode)." }
    }
    try {
        $parsed = ($jsonOutput -join "`n") | ConvertFrom-Json -Depth 20 -ErrorAction Stop
    } catch {
        return [pscustomobject]@{ Valid = $false; Error = "Python/PyYAML parser returned invalid JSON (exit $pythonExitCode): $($_.Exception.Message)" }
    }
    if ($pythonExitCode -ne 0 -or -not $parsed.ok) {
        return [pscustomobject]@{ Valid = $false; Error = "Python/PyYAML parse failed (exit $pythonExitCode): $($parsed.error)" }
    }

    $interfaceProperties = @($parsed.interface.PSObject.Properties)
    $values = @{}
    foreach ($property in $interfaceProperties) {
        $values[$property.Name] = $property.Value
    }
    foreach ($key in $ExpectedValues.Keys) {
        if (-not $values.ContainsKey($key)) {
            return [pscustomobject]@{ Valid = $false; Error = "missing interface key: $key" }
        }
        if ($values[$key] -isnot [string]) {
            return [pscustomobject]@{ Valid = $false; Error = "interface value for $key must be a string" }
        }
        if (-not [string]::Equals($values[$key], $ExpectedValues[$key], [System.StringComparison]::Ordinal)) {
            return [pscustomobject]@{ Valid = $false; Error = "wrong interface value for ${key}: '$($values[$key])'" }
        }
    }
    $unexpectedKeys = @($values.Keys | Where-Object { -not $ExpectedValues.ContainsKey($_) })
    if ($unexpectedKeys.Count -gt 0) {
        return [pscustomobject]@{ Valid = $false; Error = "unexpected interface key: $($unexpectedKeys[0])" }
    }
    return [pscustomobject]@{ Valid = $true; Error = $null }
}

function Test-ExactExpectedBehaviorBullet {
    param(
        [Parameter(Mandatory)][string]$ExpectedBehavior,
        [Parameter(Mandatory)][string]$CanonicalSentence
    )

    $expectedLine = "- $CanonicalSentence"
    foreach ($line in ((ConvertTo-LfText -Text $ExpectedBehavior) -split "`n")) {
        if ([string]::Equals($line.TrimEnd(), $expectedLine, [System.StringComparison]::Ordinal)) {
            return $true
        }
    }
    return $false
}

function Test-CanonicalPolicy {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$CanonicalSentence
    )

    $normalizedText = [regex]::Replace($Text, '\s+', ' ').Trim()
    $normalizedSentence = [regex]::Replace($CanonicalSentence, '\s+', ' ').Trim()
    return $normalizedText.IndexOf($normalizedSentence, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Test-AffirmativeCanonicalContract {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$CanonicalSentence
    )

    $normalizedText = [regex]::Replace($Text, '\s+', ' ').Trim()
    $normalizedSentence = [regex]::Replace($CanonicalSentence, '\s+', ' ').Trim()
    $offset = 0
    while ($offset -lt $normalizedText.Length) {
        $index = $normalizedText.IndexOf($normalizedSentence, $offset, [System.StringComparison]::OrdinalIgnoreCase)
        if ($index -lt 0) { return $false }
        $prefixStart = [Math]::Max(0, $index - 48)
        $prefix = $normalizedText.Substring($prefixStart, $index - $prefixStart)
        if ($prefix -notmatch '(?i)(?:\b(?:do|must|should|may|can)\s+not|\bnever)\s+$') { return $true }
        $offset = $index + $normalizedSentence.Length
    }
    return $false
}

function Get-NormativeMarkdownText {
    param([Parameter(Mandatory)][string]$Text)

    $normalized = ConvertTo-LfText -Text $Text
    $normalized = [regex]::Replace($normalized, '(?s)<!--.*?(?:-->|\z)', '')

    $keptLines = [System.Collections.Generic.List[string]]::new()
    $excludedSectionLevel = $null
    $fenceCharacter = $null
    $fenceLength = 0
    $lazyBlockquoteParagraph = $false
    foreach ($line in ($normalized -split "`n")) {
        if ($null -ne $fenceCharacter) {
            $closingFencePattern = "^\s{0,3}$([regex]::Escape(([string]$fenceCharacter))){$fenceLength,}\s*$"
            if ($line -match $closingFencePattern) {
                $fenceCharacter = $null
                $fenceLength = 0
            }
            continue
        }

        $openingFenceMatch = [regex]::Match($line, '^\s{0,3}(?<Fence>`{3,}|~{3,})')
        if ($openingFenceMatch.Success) {
            $lazyBlockquoteParagraph = $false
            $fence = $openingFenceMatch.Groups['Fence'].Value
            $fenceCharacter = $fence[0]
            $fenceLength = $fence.Length
            continue
        }

        if ($line -match '^\s*>') {
            $lazyBlockquoteParagraph = $true
            continue
        }
        if ($lazyBlockquoteParagraph) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                $lazyBlockquoteParagraph = $false
                continue
            }
            $startsBlock = $line -match '^\s{0,3}(?:#{1,6}(?:\s|$)|(?:[-+*]|\d+[.)])\s+|(?:(?:\*\s*){3,}|(?:-\s*){3,}|(?:_\s*){3,})$)'
            if ($startsBlock) {
                $lazyBlockquoteParagraph = $false
            } else {
                continue
            }
        }

        $headingMatch = [regex]::Match($line, '^\s*(?<Marks>#{1,6})\s+(?<Title>.+?)\s*$')
        if ($headingMatch.Success) {
            $headingLevel = $headingMatch.Groups['Marks'].Value.Length
            if ($null -ne $excludedSectionLevel -and $headingLevel -le $excludedSectionLevel) {
                $excludedSectionLevel = $null
            }
            if ($null -eq $excludedSectionLevel -and
                $headingMatch.Groups['Title'].Value -match '(?i)\b(?:examples?|bad examples?|negative examples?|non-normative examples?|anti-patterns?)\b') {
                $excludedSectionLevel = $headingLevel
                continue
            }
        }
        if ($null -ne $excludedSectionLevel) { continue }
        if ($line -match '^\s*(?:[-*+]\s+)?(?:\*\*)?(?:(?:bad|negative|non-normative)\s+)?example(?:\*\*)?\s*:') { continue }
        $keptLines.Add($line)
    }
    return $keptLines -join "`n"
}

function Test-NormativeMarkdownContract {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$CanonicalSentence
    )

    $normativeText = Get-NormativeMarkdownText -Text $Text
    if ([string]::IsNullOrWhiteSpace($normativeText)) { return $false }
    $inlineCodePattern = '(?s)(?<Ticks>`+)(?<Body>.*?)\k<Ticks>'
    $inlineCodeEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
        param($match)
        if (Test-CanonicalPolicy -Text $match.Groups['Body'].Value -CanonicalSentence $CanonicalSentence) {
            return ''
        }
        return $match.Value
    }
    $normativeText = [regex]::Replace($normativeText, $inlineCodePattern, $inlineCodeEvaluator)
    if ([string]::IsNullOrWhiteSpace($normativeText)) { return $false }
    return Test-AffirmativeCanonicalContract -Text $normativeText -CanonicalSentence $CanonicalSentence
}

function Test-NormativeRouteLabel {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Label
    )

    $normalized = Get-NormativeMarkdownText -Text $Text
    if ([string]::IsNullOrWhiteSpace($normalized)) { return $false }
    $normalized = [regex]::Replace($normalized, '(?s)(?<Ticks>`+).*?\k<Ticks>', '')
    $pattern = "(?m)^\s*(?:#{1,6}\s+|[-*+]\s+|\*\*)?$([regex]::Escape($Label))(?:\*\*)?\s*$"
    return [regex]::IsMatch($normalized, $pattern)
}

function Get-NormativeRouteSection {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Label
    )

    $normalized = Get-NormativeMarkdownText -Text $Text
    if ([string]::IsNullOrWhiteSpace($normalized)) { return $null }
    $normalized = [regex]::Replace($normalized, '(?s)(?<Ticks>`+).*?\k<Ticks>', '')
    $headingPattern = "(?m)^\s{0,3}(?<Hashes>#{1,6})\s+$([regex]::Escape($Label))\s*$"
    $headingMatches = [regex]::Matches($normalized, $headingPattern)
    if ($headingMatches.Count -ne 1) { return $null }
    $headingMatch = $headingMatches[0]

    $headingLevel = $headingMatch.Groups['Hashes'].Value.Length
    $sectionStart = $headingMatch.Index + $headingMatch.Length
    $nextHeadingPattern = "(?m)^\s{0,3}#{1,$headingLevel}\s+"
    $nextHeadingMatch = [regex]::new($nextHeadingPattern).Match($normalized, $sectionStart)
    $sectionEnd = if ($nextHeadingMatch.Success) { $nextHeadingMatch.Index } else { $normalized.Length }
    return $normalized.Substring($sectionStart, $sectionEnd - $sectionStart)
}

function Test-NormativeRouteBinding {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string[]]$RequiredContracts,
        [Parameter(Mandatory)][string[]]$ForbiddenContracts
    )

    $routeSection = Get-NormativeRouteSection -Text $Text -Label $Label
    if ([string]::IsNullOrWhiteSpace($routeSection)) { return $false }
    foreach ($contract in $RequiredContracts) {
        if (-not (Test-NormativeMarkdownContract -Text $routeSection -CanonicalSentence $contract)) {
            return $false
        }
    }
    foreach ($contract in $ForbiddenContracts) {
        if (Test-NormativeMarkdownContract -Text $routeSection -CanonicalSentence $contract) {
            return $false
        }
    }
    return $true
}

function Test-NormativeSectionContracts {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string[]]$RequiredContracts
    )

    $section = Get-NormativeRouteSection -Text $Text -Label $Label
    if ([string]::IsNullOrWhiteSpace($section)) { return $false }
    foreach ($contract in $RequiredContracts) {
        if (-not (Test-NormativeMarkdownContract -Text $section -CanonicalSentence $contract)) {
            return $false
        }
    }
    return $true
}

function Test-ExpectedFileCanonicalContract {
    param(
        [Parameter(Mandatory)][hashtable]$ContentsByPath,
        [Parameter(Mandatory)][string]$ExpectedPath,
        [Parameter(Mandatory)][string]$CanonicalSentence
    )

    if (-not $ContentsByPath.ContainsKey($ExpectedPath)) { return $false }
    return Test-NormativeMarkdownContract -Text $ContentsByPath[$ExpectedPath] -CanonicalSentence $CanonicalSentence
}

function Test-ManifestContract {
    param(
        [Parameter(Mandatory)][object]$Manifest,
        [Parameter(Mandatory)][string]$ExpectedPath,
        [Parameter(Mandatory)][string]$CanonicalSentence
    )

    $versionProperties = @($Manifest.PSObject.Properties | Where-Object {
        [string]::Equals($_.Name, 'version', [System.StringComparison]::Ordinal)
    })
    if ($versionProperties.Count -ne 1 -or -not [object]::Equals($versionProperties[0].Value, [long]1)) {
        return $false
    }

    $contractsProperties = @($Manifest.PSObject.Properties | Where-Object {
        [string]::Equals($_.Name, 'contracts', [System.StringComparison]::Ordinal)
    })
    if ($contractsProperties.Count -ne 1 -or $null -eq $contractsProperties[0].Value) {
        return $false
    }

    $pathProperties = @($contractsProperties[0].Value.PSObject.Properties | Where-Object {
        [string]::Equals($_.Name, $ExpectedPath, [System.StringComparison]::Ordinal)
    })
    if ($pathProperties.Count -ne 1 -or $pathProperties[0].Value -isnot [System.Array]) {
        return $false
    }

    $trimmedCanonicalSentence = $CanonicalSentence.Trim()
    foreach ($candidate in $pathProperties[0].Value) {
        if ($candidate -is [string] -and [string]::Equals(
            $candidate.Trim(),
            $trimmedCanonicalSentence,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            return $true
        }
    }

    return $false
}

function Test-ManifestContractSequence {
    param(
        [Parameter(Mandatory)][object]$Manifest,
        [Parameter(Mandatory)][string]$ExpectedPath,
        [Parameter(Mandatory)][string[]]$CanonicalSequence
    )

    $contractsProperty = @($Manifest.PSObject.Properties | Where-Object {
        [string]::Equals($_.Name, 'contracts', [System.StringComparison]::Ordinal)
    })
    if ($contractsProperty.Count -ne 1 -or $null -eq $contractsProperty[0].Value) { return $false }
    $pathProperty = @($contractsProperty[0].Value.PSObject.Properties | Where-Object {
        [string]::Equals($_.Name, $ExpectedPath, [System.StringComparison]::Ordinal)
    })
    if ($pathProperty.Count -ne 1 -or $pathProperty[0].Value -isnot [System.Array]) { return $false }

    $contracts = @($pathProperty[0].Value | ForEach-Object {
        if ($_ -is [string]) { $_.Trim() } else { $null }
    })
    $expected = @($CanonicalSequence | ForEach-Object { $_.Trim() })
    if ($expected.Count -eq 0 -or $contracts.Count -lt $expected.Count) { return $false }

    $matchingStarts = @()
    for ($start = 0; $start -le $contracts.Count - $expected.Count; $start++) {
        $matches = $true
        for ($offset = 0; $offset -lt $expected.Count; $offset++) {
            if (-not [string]::Equals($contracts[$start + $offset], $expected[$offset], [System.StringComparison]::OrdinalIgnoreCase)) {
                $matches = $false
                break
            }
        }
        if ($matches) { $matchingStarts += $start }
    }
    return $matchingStarts.Count -eq 1
}

function Test-ManifestJsonStructure {
    param([Parameter(Mandatory)][string]$RawJson)

    $document = $null
    try {
        $document = [System.Text.Json.JsonDocument]::Parse($RawJson)
        if ($document.RootElement.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
            return [pscustomobject]@{ Valid = $false; Error = 'Normative contract manifest root must be an object.' }
        }

        $rootNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $hasVersion = $false
        $hasContracts = $false
        $contractsElement = $null
        foreach ($property in $document.RootElement.EnumerateObject()) {
            if (-not $rootNames.Add($property.Name)) {
                return [pscustomobject]@{ Valid = $false; Error = "Duplicate root property '$($property.Name)'." }
            }
            if ([string]::Equals($property.Name, 'version', [System.StringComparison]::Ordinal)) {
                $hasVersion = $true
            }
            if ([string]::Equals($property.Name, 'contracts', [System.StringComparison]::Ordinal)) {
                $hasContracts = $true
                $contractsElement = $property.Value
            }
        }

        if (-not $hasVersion) {
            return [pscustomobject]@{ Valid = $false; Error = "Missing required root property 'version'." }
        }
        if (-not $hasContracts) {
            return [pscustomobject]@{ Valid = $false; Error = "Missing required root property 'contracts'." }
        }
        if ($contractsElement.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
            return [pscustomobject]@{ Valid = $false; Error = "Root property 'contracts' must be an object." }
        }

        $contractPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($property in $contractsElement.EnumerateObject()) {
            if (-not $contractPaths.Add($property.Name)) {
                return [pscustomobject]@{ Valid = $false; Error = "Duplicate contract path '$($property.Name)'." }
            }
        }

        return [pscustomobject]@{ Valid = $true; Error = $null }
    } catch {
        return [pscustomobject]@{
            Valid = $false
            Error = "Invalid normative contract manifest JSON: $($_.Exception.Message)"
        }
    } finally {
        if ($null -ne $document) {
            $document.Dispose()
        }
    }
}

function Test-SkillManifestBootstrap {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$CanonicalSentence
    )

    $lines = [regex]::Split($Text, '\r?\n')
    $index = 0
    while ($index -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$index])) {
        $index++
    }
    if ($index -ge $lines.Count -or $lines[$index] -cne '---') {
        return $false
    }

    $index++
    while ($index -lt $lines.Count -and $lines[$index] -cne '---') {
        $index++
    }
    if ($index -ge $lines.Count) {
        return $false
    }

    $index++
    while ($index -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$index])) {
        $index++
    }
    if ($index -ge $lines.Count -or $lines[$index] -cne '# Generate Classical Geometric Images') {
        return $false
    }

    $index++
    while ($index -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$index])) {
        $index++
    }
    if ($index -ge $lines.Count) {
        return $false
    }

    return [string]::Equals(
        $lines[$index].Trim(),
        $CanonicalSentence.Trim(),
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

$interfaceFixtureValues = @{
    display_name = 'Name'
    short_description = 'Description'
    default_prompt = 'Prompt'
}
$interfaceYamlFixtures = @(
    @{ Name = 'double-quoted'; Text = [string]::Join("`n", @('interface:', '  display_name: "Name"', '  short_description: "Description"', '  default_prompt: "Prompt"', '')); Expected = $true }
    @{ Name = 'single-quoted with comments'; Text = "# lead`nmetadata: 1`ninterface: # interface comment`n`n  display_name: 'Name' # key comment`n  # harmless`n  short_description: 'Description'`n  default_prompt: 'Prompt'`n"; Expected = $true }
    @{ Name = 'CRLF'; Text = "interface:`r`n  display_name: 'Name'`r`n  short_description: 'Description'`r`n  default_prompt: 'Prompt'`r`n"; Expected = $true }
    @{ Name = 'unicode escapes'; Text = [string]::Join("`n", @('interface:', '  display_name: "\u004e\u0061\u006d\u0065"', '  short_description: "Description"', '  default_prompt: "Prompt"', '')); Expected = $true }
    @{ Name = 'malformed trailing YAML'; Text = [string]::Join("`n", @('interface:', '  display_name: "Name"', '  short_description: "Description"', '  default_prompt: "Prompt"', 'broken: [')); Expected = $false }
    @{ Name = 'wrong value'; Text = [string]::Join("`n", @('interface:', '  display_name: "Wrong"', '  short_description: "Description"', '  default_prompt: "Prompt"', '')); Expected = $false }
    @{ Name = 'duplicate key'; Text = [string]::Join("`n", @('interface:', '  display_name: "Name"', '  display_name: "Name"', '  short_description: "Description"', '  default_prompt: "Prompt"', '')); Expected = $false }
    @{ Name = 'duplicate interface mapping'; Text = [string]::Join("`n", @('interface:', '  display_name: "Name"', '  short_description: "Description"', '  default_prompt: "Prompt"', 'interface:', '  display_name: "Name"', '  short_description: "Description"', '  default_prompt: "Prompt"')); Expected = $false }
    @{ Name = 'missing key'; Text = [string]::Join("`n", @('interface:', '  display_name: "Name"', '  short_description: "Description"')); Expected = $false }
    @{ Name = 'extra key'; Text = [string]::Join("`n", @('interface:', '  display_name: "Name"', '  short_description: "Description"', '  default_prompt: "Prompt"', '  extra: "No"')); Expected = $false }
    @{ Name = 'non-string value'; Text = [string]::Join("`n", @('interface:', '  display_name: 7', '  short_description: "Description"', '  default_prompt: "Prompt"')); Expected = $false }
)
foreach ($fixture in $interfaceYamlFixtures) {
    $actual = Get-OpenAiInterfaceYaml -Text $fixture.Text -ExpectedValues $interfaceFixtureValues
    if ($actual.Valid -ne $fixture.Expected) {
        throw "Internal openai.yaml semantic fixture failed: $($fixture.Name): $($actual.Error)"
    }
}

$exactBulletFixture = 'Classify the current source.'
$exactBulletFixtures = @(
    @{ Name = 'exact bullet'; Text = "- $exactBulletFixture`n"; Expected = $true }
    @{ Name = 'negated'; Text = "- Do not $exactBulletFixture`n"; Expected = $false }
    @{ Name = 'prefixed'; Text = "Prefix: - $exactBulletFixture`n"; Expected = $false }
    @{ Name = 'longer'; Text = "- $exactBulletFixture Additional text.`n"; Expected = $false }
    @{ Name = 'blockquote'; Text = "> - $exactBulletFixture`n"; Expected = $false }
    @{ Name = 'non-bullet'; Text = "$exactBulletFixture`n"; Expected = $false }
)
foreach ($fixture in $exactBulletFixtures) {
    $actual = Test-ExactExpectedBehaviorBullet -ExpectedBehavior $fixture.Text -CanonicalSentence $exactBulletFixture
    if ($actual -ne $fixture.Expected) {
        throw "Internal exact Expected behavior bullet fixture failed: $($fixture.Name)"
    }
}

$crlfScenarioFixture = "## S11 Product without motion cues`r`n**Expected behavior:**`r`nfixture`r`n### Initial RED observations`r`nfixture`r`n## S12 Existing building with period evidence`r`n"
$crlfScenarioSection = Get-ScenarioSection -Text $crlfScenarioFixture -StartHeading '## S11 Product without motion cues' -EndHeading '## S12 Existing building with period evidence'
if ($null -eq $crlfScenarioSection -or
    [regex]::Matches((ConvertTo-LfText -Text $crlfScenarioFixture), '(?m)^## S11 Product without motion cues$').Count -ne 1 -or
    $crlfScenarioSection.Contains("`r", [System.StringComparison]::Ordinal)) {
    throw 'Internal CRLF scenario section extraction/count fixture failed.'
}

$expectedFileContractFixture = 'Build a Source Fidelity Card.'
$expectedFileContractFixtures = @(
    @{ Contents = @{ 'SKILL.md' = "BUILD A`nSOURCE FIDELITY CARD." }; Path = 'SKILL.md'; Expected = $true }
    @{ Contents = @{ 'SKILL.md' = 'Do not build a Source Fidelity Card.' }; Path = 'SKILL.md'; Expected = $false }
    @{ Contents = @{ 'references/style-dna.md' = $expectedFileContractFixture; 'SKILL.md' = 'No contract here.' }; Path = 'SKILL.md'; Expected = $false }
)
foreach ($fixture in $expectedFileContractFixtures) {
    $actual = Test-ExpectedFileCanonicalContract -ContentsByPath $fixture.Contents -ExpectedPath $fixture.Path -CanonicalSentence $expectedFileContractFixture
    if ($actual -ne $fixture.Expected) {
        throw "Internal expected-file canonical fixture failed for $($fixture.Path)"
    }
}

$manifestContractFixture = 'Build a Source Fidelity Card.'
$manifestContractFixtures = @(
    @{ Name = 'valid manifest'; Manifest = [pscustomobject]@{ version = [long]1; contracts = [pscustomobject]@{ 'SKILL.md' = @($manifestContractFixture) } }; Path = 'SKILL.md'; Expected = $true }
    @{ Name = 'wrong version'; Manifest = [pscustomobject]@{ version = [long]2; contracts = [pscustomobject]@{ 'SKILL.md' = @($manifestContractFixture) } }; Path = 'SKILL.md'; Expected = $false }
    @{ Name = 'wrong path'; Manifest = [pscustomobject]@{ version = [long]1; contracts = [pscustomobject]@{ 'references/style-dna.md' = @($manifestContractFixture) } }; Path = 'SKILL.md'; Expected = $false }
    @{ Name = 'scalar instead of array'; Manifest = [pscustomobject]@{ version = [long]1; contracts = [pscustomobject]@{ 'SKILL.md' = $manifestContractFixture } }; Path = 'SKILL.md'; Expected = $false }
    @{ Name = 'sentence embedded in longer string'; Manifest = [pscustomobject]@{ version = [long]1; contracts = [pscustomobject]@{ 'SKILL.md' = @("Prefix $manifestContractFixture Suffix") } }; Path = 'SKILL.md'; Expected = $false }
    @{ Name = 'negated sentence'; Manifest = [pscustomobject]@{ version = [long]1; contracts = [pscustomobject]@{ 'SKILL.md' = @("Do not $manifestContractFixture") } }; Path = 'SKILL.md'; Expected = $false }
    @{ Name = 'wrong sentence'; Manifest = [pscustomobject]@{ version = [long]1; contracts = [pscustomobject]@{ 'SKILL.md' = @('Build a different card.') } }; Path = 'SKILL.md'; Expected = $false }
    @{ Name = 'case-insensitive exact sentence'; Manifest = [pscustomobject]@{ version = [long]1; contracts = [pscustomobject]@{ 'SKILL.md' = @('BUILD A SOURCE FIDELITY CARD.') } }; Path = 'SKILL.md'; Expected = $true }
    @{ Name = 'trim leading and trailing whitespace'; Manifest = [pscustomobject]@{ version = [long]1; contracts = [pscustomobject]@{ 'SKILL.md' = @("  $manifestContractFixture`t") } }; Path = 'SKILL.md'; Expected = $true }
    @{ Name = 'do not normalize internal whitespace'; Manifest = [pscustomobject]@{ version = [long]1; contracts = [pscustomobject]@{ 'SKILL.md' = @("Build a Source`nFidelity Card.") } }; Path = 'SKILL.md'; Expected = $false }
)
foreach ($fixture in $manifestContractFixtures) {
    $actual = Test-ManifestContract -Manifest $fixture.Manifest -ExpectedPath $fixture.Path -CanonicalSentence $manifestContractFixture
    if ($actual -ne $fixture.Expected) {
        throw "Internal normative manifest contract fixture failed: $($fixture.Name)"
    }
}

$manifestJsonStructureFixtures = @(
    @{ Name = 'valid unique JSON'; Json = '{"version":1,"contracts":{"SKILL.md":["Build a Source Fidelity Card."]}}'; Expected = $true; Error = $null }
    @{ Name = 'duplicate version'; Json = '{"version":1,"version":1,"contracts":{}}'; Expected = $false; Error = "Duplicate root property 'version'." }
    @{ Name = 'duplicate contracts'; Json = '{"version":1,"contracts":{},"contracts":{}}'; Expected = $false; Error = "Duplicate root property 'contracts'." }
    @{ Name = 'duplicate SKILL.md path'; Json = '{"version":1,"contracts":{"SKILL.md":[],"SKILL.md":[]}}'; Expected = $false; Error = "Duplicate contract path 'SKILL.md'." }
    @{ Name = 'duplicate period path'; Json = '{"version":1,"contracts":{"references/period-style-systems.md":[],"references/period-style-systems.md":[]}}'; Expected = $false; Error = "Duplicate contract path 'references/period-style-systems.md'." }
    @{ Name = 'case-variant duplicate path'; Json = '{"version":1,"contracts":{"SKILL.md":[],"skill.md":[]}}'; Expected = $false; Error = "Duplicate contract path 'skill.md'." }
    @{ Name = 'missing version'; Json = '{"contracts":{}}'; Expected = $false; Error = "Missing required root property 'version'." }
    @{ Name = 'missing contracts'; Json = '{"version":1}'; Expected = $false; Error = "Missing required root property 'contracts'." }
    @{ Name = 'contracts is not an object'; Json = '{"version":1,"contracts":[]}'; Expected = $false; Error = "Root property 'contracts' must be an object." }
)
foreach ($fixture in $manifestJsonStructureFixtures) {
    $actual = Test-ManifestJsonStructure -RawJson $fixture.Json
    if ($actual.Valid -ne $fixture.Expected) {
        throw "Internal normative manifest JSON fixture failed: $($fixture.Name)"
    }
    if (-not $fixture.Expected -and -not $actual.Error.Contains($fixture.Error, [System.StringComparison]::Ordinal)) {
        throw "Internal normative manifest JSON fixture returned the wrong error: $($fixture.Name): $($actual.Error)"
    }
}

$modeAwareRenderingContract = 'Rendering and material finish is mode-aware: photographic modes specify high-end architectural or photographic light, material response, and color; pattern, diagram, and manuscript modes specify their applicable flat, orthographic, or drafting finish, including uniform production color for a tile and paper, ink, and line hierarchy for a manuscript, and may mark photographic lighting N/A.'
$paintingRouterContract = 'Classify the source artifact before choosing a medium: photograph, sketch, plan/elevation/section, axonometric, rendering, or mixed presentation board.'
$architectureMediumContract = 'Route the painting technique from both architectural lineage and source artifact type; never choose a medium from cultural label alone.'
$unifiedMediumContract = 'A painted result must transform subject, architecture, ground, sky, light, shadow, edge language, pigment behavior, paper texture, and detail hierarchy into one coherent medium; a photorealistic subject pasted into a painted environment fails.'
$paintingPromptContract = 'For painting modes, section 3 must name substrate, line system, pigment system, edge behavior, shadow method, and style strength.'
$paintingQaContract = 'If the subject and architecture use different edge, grain, pigment, or shadow languages, the Rendering coherence check fails even when compositing is spatially plausible.'
$posterFeatureContract = 'Build a Poster Feature Card from observed source evidence and explicit user associations before writing copy.'
$posterEvidenceContract = 'Use only observed features or user-authorized associations in visible copy; never invent brands, achievements, identities, locations, or events.'
$posterCropContract = 'Poster recomposition may crop, mask, or remove non-essential areas with diagonal cuts, stepped corners, polygonal apertures, or lineage-derived geometric frames, but it must preserve the selected subject anchors and must never stretch anatomy or architecture.'
$posterSystemContract = 'Typography, palette, geometric framing, and the selected architectural lineage must form one visual system.'
$posterCopyContract = 'Visible English copy defaults to one title of one to four words and one optional microline of no more than six words; verify every character exactly.'
$posterPromptContract = 'For poster mode, section 2 must declare the crop/mask geometry and retained anchors, section 3 must declare typography and palette, and section 4 must quote every visible string verbatim.'
$posterQaContract = 'A poster fails Rendering coherence when typography, palette, geometric cuts, subject treatment, and architectural medium do not read as one designed system.'
$posterSingleRouteContract = 'Treat poster mode as one end-to-end route from the original source to one final artifact, not as a second deliverable appended after a painting draft.'
$universalSourceContract = 'Classify every readable input as person or group; object, product, vehicle, or prop; architecture, interior, exterior, or landscape; drawing, pattern, or manuscript; or mixed source before selecting anchors, copy, period, or effects.'
$periodEvidenceContract = 'Build a Period Evidence Card from user direction and visible architectural, ornamental, material, manuscript, or painting evidence; never infer period from a person''s appearance.'
$periodFallbackContract = 'When specific-period evidence is weak, use a restrained broad-lineage system; when lineage evidence is insufficient, use shared classical geometry and do not invent a historical label.'
$periodTypeContract = 'Typography must derive proportion, rhythm, stroke contrast, spacing, alignment, and ornament restraint from the selected period while keeping Latin letters legible and never fabricating Arabic-looking or Chinese-looking glyphs.'
$periodPaletteContract = 'Choose color from period materials and pigments rather than flags or generic ethnic color stereotypes; a source color may appear only as a restrained connector accent.'
$dissolutionContract = 'Historical dissolution defaults to approximately 6–10% of one trailing expendable edge and follows motion, wind, or the governing geometric axis.'
$protectedDissolutionContract = 'If no safe expendable edge exists, omit dissolution rather than damage an identity anchor, contact relationship, functional joint, structural bearing, measured line, repeat boundary, or exact visible character.'
$noLeakContract = 'Never carry a subject noun, association, palette, period, typography route, or effect from one source into an unrelated source.'
$periodConfidenceContract = 'Record period evidence confidence as specific, broad, or insufficient, and state the fallback used.'
$sourceNativeDissolutionContract = 'Route dissolution from the current source class and selected medium; drawings use graphite loss, blueprint grain, erased construction lines, or paper abrasion rather than smoke, debris, or volumetric particles.'
$currentSourceRebuildContract = 'Rebuild every Source Feature Map and Poster Feature Card from the current source; never reuse anchors, associations, copy, period, palette, typography, or effects from a prior source.'
$dissolutionPlacementContract = 'Declare the one dissolution edge, its direction, approximate percentage, and every protected anchor before generation.'
$fullHeightDissolutionContract = 'When dissolution is selected, distribute low-density loss along one consistent trailing side from top to bottom rather than concentrating it in one localized patch; skip protected segments and continue through adjacent atmosphere.'
$manifestRuntimeContract = 'Load references/normative-contracts.json before routing period typography, period palette, historical dissolution, or cross-source leakage safeguards, and obey every contract assigned to the selected files.'
$historicalSurrealThesisContract = 'Choose exactly one source-evidenced visual thesis and one memorable spatial gesture; every fragment, crop, type relationship, color accent, and effect must support them.'
$historicalSurrealIslamicContract = 'Render the source and one monumental Islamic architectural fragment as one unified historical-surreal collage; never place a complete background behind a cutout subject or add detached caption bars.'
$historicalSurrealCompositionContract = 'Use two or three source-faithful planes at most, one dominant field, one structural secondary color, and at most one high-chroma accent; reject repeated corner emblems, symmetric badge grids, frame stacks, wallpaper motifs, and arbitrary floating shapes.'
$historicalSurrealInspectionContract = 'At thumbnail size require one focal hierarchy, one governing movement, and recognizable source anchors; at full size require intentional crop edges, overlaps, textures, typography, and cultural detail.'
$historicalSurrealChineseGrammarContract = 'Express the shared collage grammar through evidenced bay rhythm, dougong, jiehua or ruled-line construction, stele or plaque proportion, woodblock, album-leaf, or mineral-pigment behavior without fake Chinese strokes.'
$historicalSurrealTopologyContract = 'Preserve the source topology, measured relationships, and semantic minimum while allowing at most two or three source-faithful planes.'
$historicalSurrealWesternGrammarContract = 'Express the shared collage grammar through evidenced orders, entablature, vault, measured section, engraving plate, fresco, manuscript, or architectural-capriccio behavior without generic luxury-ad framing.'
$historicalSurrealTypographyContract = 'Make typography participate through alignment, partial occlusion, negative space, shared geometry, or the governing motion axis.'
$historicalSurrealIslamicScopeContract = 'Apply the Islamic-fragment contract only when the Period Evidence Card selects Islamic lineage at specific or broad confidence; never apply it to Chinese, Western, shared-geometric, or insufficient-evidence routes.'
$historicalSurrealChineseScopeContract = 'Apply the Chinese-route contracts only when the Period Evidence Card selects Chinese lineage at specific or broad confidence; never apply them to Islamic, Western, shared-geometric, or insufficient-evidence routes.'
$historicalSurrealWesternScopeContract = 'Apply the Western-route contracts only when the Period Evidence Card selects Western lineage at specific or broad confidence; never apply them to Islamic, Chinese, shared-geometric, or insufficient-evidence routes.'
$historicalSurrealBroadLineageContract = 'When period evidence is broad and lineage is Islamic, Chinese, or Western, use the corresponding broad-lineage system; only insufficient lineage evidence uses shared classical geometry.'
$historicalSurrealConventionalOverrideContract = 'For a routed historical poster, collage, editorial, zine-like, or stylized architectural transformation, use the historical-surreal grammar by default; when the user explicitly requests no surrealism or a restrained conventional poster or editorial, disable the impossible spatial gesture and monumental-fragment formula while retaining source-shape linkage, anti-cutout composition, integrated typography, period evidence, and source fidelity.'
$historicalSurrealCompilerSection1Contract = 'Historical-surreal section 1 must state each source role, the semantic minimum, no more than three hard anchors, protected projection, proportions, and contacts, plus lineage and period confidence.'
$historicalSurrealCompilerSection2Contract = 'Historical-surreal section 2 must state the exact visual thesis; exactly one memorable impossible spatial gesture; exactly one monumental architectural fragment; at most two or three source-faithful planes linked to source shapes; typography that shares the source-derived shape linkage by aligning with, passing behind or through, or being occluded by the same contour, axis, or plane; active negative space, one governing axis, asymmetric crop with off-frame continuation; and, when selected, the exact dissolution side, direction, protected gaps, and atmospheric bridge behavior.'
$historicalSurrealCompilerSection3Contract = 'Historical-surreal section 3 must use one unified medium across subject and architecture; it must always state evidenced period material behavior and must also state applicable period print or paint behavior, or an explicit applicable production or mark-making behavior when print and paint are N/A; one dominant field, one structural secondary color, at most one high-chroma source- and period-compatible accent; period-native typography construction and interaction; and selective completion with lost edges.'
$historicalSurrealCompilerSection4Contract = 'Historical-surreal section 4 must quote exact visible copy and prohibit logos or extra glyphs, complete-background replacement, pasted cutout edges, detached top or bottom caption bars, repeated corner emblems, badges, borders, wallpaper motifs, arbitrary floating decoration, a second surreal gesture, normalized source projection or proportions, localized butt- or waist-only dissolution, and cultural leakage.'
$historicalSurrealConventionalCompilerContract = 'Select the evidenced Islamic, Chinese, or Western cultural route before applying either historical-surreal or conventional composition; the conventional override changes only Section 2''s impossible gesture and monumental fragment while retaining that route''s materials, typography, palette, source fidelity, exact copy, and foreign-route rejections.'
$historicalSurrealConventionalSection2Contract = 'Under an explicit conventional or no-surreal override, Section 2 must omit the impossible gesture and monumental fragment; preserve the semantic minimum and hard anchors; use one source-derived, culturally appropriate organizing structure that is neither impossible nor monumental; use at most one or two coherent planes or fields, active negative space, and a governing axis; use asymmetric crop or off-frame continuation only when compatible; and retain integrated type and anti-cutout composition.'
$historicalSurrealIslamicMechanicsContract = 'The Islamic route may build from an evidenced portal, inscription band, muqarnas, tile, manuscript, or measured geometry using mineral pigment, plaster, tile, paper, or ink; construct evidenced Latin lettering without fake Arabic, preserve source fidelity and exact copy, reject Chinese and Western mechanics, and do not default to a full tiled facade.'
$historicalSurrealChineseMechanicsContract = 'The Chinese route may build from evidenced bay rhythm, dougong, jiehua, stele, plaque, woodblock, album-leaf, or mineral-pigment behavior; preserve source fidelity and exact copy, reject Islamic and Western mechanics, and do not invent Chinese strokes, default to generic red-gold festival styling, or replace the source with a complete courtyard background.'
$historicalSurrealWesternMechanicsContract = 'The Western route may build from evidenced orders, entablature, vault, measured section, engraving, fresco, manuscript, or capriccio behavior; preserve source fidelity and exact copy, reject Islamic and Chinese mechanics, and do not use generic luxury-serif or unrequested Art Deco styling or replace the source with a complete temple backdrop.'
$historicalSurrealThumbnailGateContract = 'At thumbnail scale require one focal hierarchy, one governing movement, source recognition within three seconds, participatory but subordinate type, and an effect subordinate to source identity and meaning.'
$historicalSurrealFullSizeGateContract = 'At full size require deliberate crop edges, overlaps, material seams, and type occlusion; no cutout halo; correct contacts and projection; exact visible copy; and credible cultural construction.'
$historicalSurrealFailureGateContract = 'Fail a historical collage for a complete background behind a cutout, detached captions, repeated corner emblems, symmetric badge grids, border or frame stacks, wallpaper motifs, more than one surreal gesture, normalized source projection, a uniform medium filter, localized dissolution, or arbitrary decoration.'
$historicalSurrealVerdictContract = 'Assign the aesthetic verdict ACCEPT, REPAIR, or BLOCKED; REPAIR permits only the single highest-impact repair rebuilt from the original source and a fully recompiled four-section prompt.'
$historicalSurrealDistinctivenessContract = 'Run the structural-removal test independently on each applicable device: gesture, accent, type interaction, and monumental fragment or source-shape linkage; if removing one leaves hierarchy or meaning unchanged, that device is decorative and fails, while a conventional or no-text N/A must record the specific reason.'
$historicalSurrealTypeCollisionContract = 'Typography interaction passes only when alignment, passage, or occlusion is deliberate and legible; accidental collision, clipped letterforms, or readability damage fails.'
$historicalSurrealPeriodBindingContract = 'Bind every evidenced broad or specific route''s period-native typography and pigments to the selected collage mechanics without inventing a period; use a source accent only when it is compatible with both the source and the selected period.'
$historicalSurrealCulturalOverrideContract = 'An explicit no-surreal override remains cultural: retain the evidenced broad or specific lineage, period-native typography and pigments, source-shape linkage, and integrated type after removing the impossible gesture and monumental fragment.'
$protectedForegroundContract = 'Render the complete protected subject and every protected held object above optional coating, dissolution, abrasion, particles, glaze, enamel, and gemstone effects; those effects may continue only through adjacent background or genuine negative openings.'
$protectedUnifiedMediumContract = 'A unified base medium still applies to subject and architecture; subject protection never authorizes a photographic cutout.'
$backgroundWakeContract = 'When dissolution is selected for a protected subject, route it as a background wake in one consistent top-to-bottom direction and never erode protected subject pixels.'
$routedMaterialAccentContract = 'Route enamel, glazed ceramic, and gemstone-like accents by the selected cultural lineage, confine them to architectural or typography-linked nodes behind the subject, and keep their combined visual area approximately 5–12%.'
$materialAccentRejectionContract = 'Reject jewelry-ad, black-gold luxury, plastic-gloss, or material accents attached to the protected subject.'
$protectedEffectInspectionContract = 'Inspect the protected-subject boundary at thumbnail and 100% scale; fail any coating, dissolution, abrasion, particle, glaze, enamel, or gemstone effect that crosses onto a protected subject or held object.'
$protectedEffectRepairContract = 'If one targeted repair is allowed, rebuild it from the original source with a fully recompiled four-section prompt and correct only the highest-impact protected-effect failure.'
$historicalSurrealQualitySectionLabel = 'Historical-collage aesthetic gates'
$historicalSurrealPeriodSectionLabel = 'Historical-collage period binding'
$historicalSurrealReferencePath = 'references/historical-surreal-collage.md'
$historicalSurrealRuntimeLinkContract = 'Load references/historical-surreal-collage.md before routing an Islamic, Chinese classical, or Western classical historical-surreal collage.'
$historicalSurrealRouteLabels = @(
    'Islamic historical-surreal route'
    'Chinese classical historical-surreal route'
    'Western classical historical-surreal route'
)
$historicalSurrealRouteLabelFixtures = @(
    @{ Name = 'real normative route'; Text = "## Islamic historical-surreal route`n`nApply the route contracts."; Label = 'Islamic historical-surreal route'; Expected = $true }
    @{ Name = 'placeholder route'; Text = 'Islamic historical-surreal route: TBD'; Label = 'Islamic historical-surreal route'; Expected = $false }
    @{ Name = 'route in unclosed fence'; Text = [string]::Join("`n", @('```text', 'Islamic historical-surreal route')); Label = 'Islamic historical-surreal route'; Expected = $false }
    @{ Name = 'route in unclosed HTML comment'; Text = "<!-- unfinished example`nIslamic historical-surreal route"; Label = 'Islamic historical-surreal route'; Expected = $false }
)
foreach ($fixture in $historicalSurrealRouteLabelFixtures) {
    $actual = Test-NormativeRouteLabel -Text $fixture.Text -Label $fixture.Label
    if ($actual -ne $fixture.Expected) {
        throw "Internal historical-surreal route-label fixture failed: $($fixture.Name)"
    }
}
$historicalSurrealCanonicalFixtures = @(
    @{ Name = 'real normative contract'; Text = "## Composition contract`n`n$historicalSurrealThesisContract"; Expected = $true }
    @{ Name = 'case and whitespace normalization'; Text = "CHOOSE EXACTLY ONE SOURCE-EVIDENCED VISUAL THESIS and one memorable spatial gesture; every fragment, crop, type relationship, color accent,`nand effect must support them."; Expected = $true }
    @{ Name = 'negated contract'; Text = "Do not $historicalSurrealThesisContract"; Expected = $false }
    @{ Name = 'different contract'; Text = 'Choose several visual theses and decorative gestures.'; Expected = $false }
    @{ Name = 'HTML comment'; Text = "<!-- $historicalSurrealThesisContract -->"; Expected = $false }
    @{ Name = 'fenced code block'; Text = [string]::Join("`n", @('```text', $historicalSurrealThesisContract, '```')); Expected = $false }
    @{ Name = 'blockquote'; Text = "> $historicalSurrealThesisContract"; Expected = $false }
    @{ Name = 'bad example'; Text = "Bad example: $historicalSurrealThesisContract"; Expected = $false }
    @{ Name = 'non-normative example section'; Text = "## Examples`n`n$historicalSurrealThesisContract`n`n## Required behavior`n`nDifferent behavior."; Expected = $false }
    @{ Name = 'lazy blockquote continuation'; Text = "> Introductory example:`n$historicalSurrealThesisContract`n`nNormative prose resumes here."; Expected = $false }
    @{ Name = 'unclosed backtick fence'; Text = [string]::Join("`n", @('```text', $historicalSurrealThesisContract)); Expected = $false }
    @{ Name = 'unclosed tilde fence'; Text = [string]::Join("`n", @('~~~text', $historicalSurrealThesisContract)); Expected = $false }
    @{ Name = 'plain example prefix'; Text = "Example: $historicalSurrealThesisContract"; Expected = $false }
    @{ Name = 'inline code example'; Text = "Example syntax: ``$historicalSurrealThesisContract``"; Expected = $false }
    @{ Name = 'unclosed HTML comment'; Text = "<!-- unfinished example`n$historicalSurrealThesisContract"; Expected = $false }
    @{ Name = 'ATX heading ends lazy blockquote'; Text = "> quoted example`n## Required behavior`n$historicalSurrealThesisContract"; Expected = $true }
)
foreach ($fixture in $historicalSurrealCanonicalFixtures) {
    $actual = Test-NormativeMarkdownContract -Text $fixture.Text -CanonicalSentence $historicalSurrealThesisContract
    if ($actual -ne $fixture.Expected) {
        throw "Internal historical-surreal affirmative-contract fixture failed: $($fixture.Name)"
    }
}
$historicalSurrealRouteBindingFixtures = @(
    @{
        Name = 'Islamic route permits shared contracts'
        Text = "## Islamic historical-surreal route`n`n$historicalSurrealIslamicScopeContract`n`n$historicalSurrealIslamicContract`n`n$historicalSurrealTopologyContract"
        Label = $historicalSurrealRouteLabels[0]
        Required = @($historicalSurrealIslamicScopeContract, $historicalSurrealIslamicContract)
        Forbidden = @($historicalSurrealChineseGrammarContract, $historicalSurrealWesternGrammarContract)
        Expected = $true
    }
    @{
        Name = 'Islamic route rejects Chinese body mutation'
        Text = "## Islamic historical-surreal route`n`n$historicalSurrealIslamicScopeContract`n`n$historicalSurrealIslamicContract`n`n$historicalSurrealChineseGrammarContract"
        Label = $historicalSurrealRouteLabels[0]
        Required = @($historicalSurrealIslamicScopeContract, $historicalSurrealIslamicContract)
        Forbidden = @($historicalSurrealChineseGrammarContract, $historicalSurrealWesternGrammarContract)
        Expected = $false
    }
    @{
        Name = 'Chinese route rejects Islamic body mutation'
        Text = "## Chinese classical historical-surreal route`n`n$historicalSurrealChineseScopeContract`n`n$historicalSurrealChineseGrammarContract`n`n$historicalSurrealIslamicContract"
        Label = $historicalSurrealRouteLabels[1]
        Required = @($historicalSurrealChineseScopeContract, $historicalSurrealChineseGrammarContract)
        Forbidden = @($historicalSurrealIslamicContract, $historicalSurrealWesternGrammarContract)
        Expected = $false
    }
    @{
        Name = 'Western route rejects Chinese body mutation'
        Text = "## Western classical historical-surreal route`n`n$historicalSurrealWesternScopeContract`n`n$historicalSurrealWesternGrammarContract`n`n$historicalSurrealChineseGrammarContract"
        Label = $historicalSurrealRouteLabels[2]
        Required = @($historicalSurrealWesternScopeContract, $historicalSurrealWesternGrammarContract)
        Forbidden = @($historicalSurrealIslamicContract, $historicalSurrealChineseGrammarContract)
        Expected = $false
    }
    @{
        Name = 'Sibling route body does not contaminate target section'
        Text = "## Islamic historical-surreal route`n`n$historicalSurrealIslamicScopeContract`n`n$historicalSurrealIslamicContract`n`n## Chinese classical historical-surreal route`n`n$historicalSurrealChineseScopeContract`n`n$historicalSurrealChineseGrammarContract"
        Label = $historicalSurrealRouteLabels[0]
        Required = @($historicalSurrealIslamicScopeContract, $historicalSurrealIslamicContract)
        Forbidden = @($historicalSurrealChineseGrammarContract, $historicalSurrealWesternGrammarContract)
        Expected = $true
    }
    @{
        Name = 'Duplicate Islamic route heading rejects hidden Chinese mechanics'
        Text = "## Islamic historical-surreal route`n`n$historicalSurrealIslamicScopeContract`n`n$historicalSurrealIslamicContract`n`n## Islamic historical-surreal route`n`n$historicalSurrealChineseGrammarContract"
        Label = $historicalSurrealRouteLabels[0]
        Required = @($historicalSurrealIslamicScopeContract, $historicalSurrealIslamicContract)
        Forbidden = @($historicalSurrealChineseGrammarContract, $historicalSurrealWesternGrammarContract)
        Expected = $false
    }
)
foreach ($fixture in $historicalSurrealRouteBindingFixtures) {
    $actual = Test-NormativeRouteBinding -Text $fixture.Text -Label $fixture.Label -RequiredContracts $fixture.Required -ForbiddenContracts $fixture.Forbidden
    if ($actual -ne $fixture.Expected) {
        throw "Internal historical-surreal route-binding fixture failed: $($fixture.Name)"
    }
}
$historicalSurrealCompilerSectionLabels = @(
    'Historical-surreal compiler section 1 — source fidelity'
    'Historical-surreal compiler section 2 — poster direction'
    'Historical-surreal compiler section 3 — rendering, material, and type'
    'Historical-surreal compiler section 4 — guardrails'
    'Historical-surreal conventional override'
)

function Remove-NormativeCanonicalSentence {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$CanonicalSentence
    )

    $tokens = @([regex]::Split($CanonicalSentence.Trim(), '\s+') | ForEach-Object { [regex]::Escape($_) })
    if ($tokens.Count -eq 0) { return $Text }
    $pattern = $tokens -join '\s+'
    return [regex]::Replace($Text, $pattern, '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

function Get-HistoricalSurrealAssertionClauses {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Sentence)

    if ([string]::IsNullOrWhiteSpace($Sentence)) { return @() }
    $explicitModeSubject = '(?:(?:the\s+)?historical-surreal\s+route|conventional(?:\s+(?:mode|composition|override))?|(?:the\s+)?override)'
    $marked = [regex]::Replace(
        $Sentence,
        "(?is),\s*unlike\s+$explicitModeSubject\s*,\s*",
        ' '
    )
    $marked = [regex]::Replace(
        $marked,
        '(?is)(?:,\s*)?\b(?:whereas|while|but|although)\b\s*',
        "`n"
    )
    $marked = [regex]::Replace(
        $marked,
        "(?is),\s*(?=(?:$explicitModeSubject|unlike\s+conventional(?:\s+(?:mode|composition|override))?)\b)",
        "`n"
    )
    return @($marked -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Test-ForbiddenConceptDirectlyAbsent {
    param(
        [Parameter(Mandatory)][string]$Sentence,
        [Parameter(Mandatory)][System.Text.RegularExpressions.Match]$Concept
    )

    $prefix = $Sentence.Substring(0, $Concept.Index)
    $suffix = $Sentence.Substring($Concept.Index + $Concept.Length)
    $negatedOmissionPatterns = @(
        '(?is)\b(?:does|do|must|should|may|can|will)\s+not\s+(?:omit|remove|exclude|prohibit)\b.{0,40}$'
        '(?is)\b(?:omit|omits|remove|removes|exclude|excludes|prohibit|prohibits)\s+(?:neither|no)\s+(?:(?:an?|one|any|the)\s+)?$'
    )
    foreach ($pattern in $negatedOmissionPatterns) {
        if ([regex]::IsMatch($prefix, $pattern)) { return $false }
    }

    $directAbsencePrefixPatterns = @(
        '(?is)\b(?:no|without|neither|nor)\s+(?:(?:an?|one|any|the)\s+)?$'
        '(?is)\b(?:does|do|must|should|may|can|will)\s+not\s+(?:still\s+)?(?:contain|include|retain|allow|preserve)\b(?:\s+(?:an?|one|any|the))?\s*$'
        '(?is)\b(?:omit|omits|exclude|excludes|remove|removes|prohibit|prohibits)\s+(?:(?:an?|one|any|the)\s+)?$'
    )
    foreach ($pattern in $directAbsencePrefixPatterns) {
        if ([regex]::IsMatch($prefix, $pattern)) { return $true }
    }

    $directAbsenceSuffixPatterns = @(
        '(?is)^\s+(?:is|are)\s+(?:forbidden|prohibited|excluded|omitted|removed)\b'
        '(?is)^\s+(?:is|are)\s+not\s+(?:contained|included|retained|allowed|preserved)\b'
    )
    foreach ($pattern in $directAbsenceSuffixPatterns) {
        if ([regex]::IsMatch($suffix, $pattern)) { return $true }
    }
    return $false
}

function Test-HistoricalSurrealConventionalOverride {
    param([Parameter(Mandatory)][AllowNull()][AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    $label = $historicalSurrealCompilerSectionLabels[4]
    $required = @($historicalSurrealConventionalCompilerContract, $historicalSurrealConventionalSection2Contract)
    if (-not (Test-NormativeSectionContracts -Text $Text -Label $label -RequiredContracts $required)) {
        return $false
    }

    $section = Get-NormativeRouteSection -Text $Text -Label $label
    $residual = Get-NormativeMarkdownText -Text $section
    $residual = Remove-NormativeCanonicalSentence -Text $residual -CanonicalSentence $historicalSurrealConventionalCompilerContract
    $residual = Remove-NormativeCanonicalSentence -Text $residual -CanonicalSentence $historicalSurrealConventionalSection2Contract
    $formulaPattern = '(?:(?:impossible|surreal|reality[- ]breaking)\s+(?:spatial\s+)?(?:gesture|move)|(?:monumental|oversized|enormous)\s+(?:architectural\s+)?(?:fragment|shard|ruin))'
    $modeSubjectPattern = '(?i)(?<Historical>(?:the\s+)?historical-surreal\s+route)|(?<Conventional>conventional(?:\s+(?:mode|composition|override))?|(?:the\s+)?override)'
    foreach ($sentence in [regex]::Split($residual, '[;\r\n.!?]+')) {
        $inheritedMode = $null
        foreach ($clause in @(Get-HistoricalSurrealAssertionClauses -Sentence $sentence)) {
            $subjects = @([regex]::Matches($clause, $modeSubjectPattern))
            foreach ($concept in [regex]::Matches($clause, "(?i)\b$formulaPattern\b")) {
                $conceptCenter = $concept.Index + ($concept.Length / 2)
                $nearestMode = $inheritedMode
                $nearestDistance = [double]::PositiveInfinity
                foreach ($subject in $subjects) {
                    $subjectCenter = $subject.Index + ($subject.Length / 2)
                    $distance = [Math]::Abs($conceptCenter - $subjectCenter)
                    if ($distance -lt $nearestDistance) {
                        $nearestDistance = $distance
                        $nearestMode = if ($subject.Groups['Historical'].Success) { 'Historical' } else { 'Conventional' }
                    }
                }
                if ($nearestMode -eq 'Conventional' -and
                    -not (Test-ForbiddenConceptDirectlyAbsent -Sentence $clause -Concept $concept)) {
                    return $false
                }
            }
            if ($subjects.Count -gt 0) {
                $lastSubject = $subjects[$subjects.Count - 1]
                $inheritedMode = if ($lastSubject.Groups['Historical'].Success) { 'Historical' } else { 'Conventional' }
            }
        }
    }
    return $true
}

$historicalSurrealCompilerSectionFixtures = @(
    @{
        Name = 'complete compiler sections'
        Text = "### $($historicalSurrealCompilerSectionLabels[0])`n`n$historicalSurrealCompilerSection1Contract`n`n### $($historicalSurrealCompilerSectionLabels[1])`n`n$historicalSurrealCompilerSection2Contract`n`n### $($historicalSurrealCompilerSectionLabels[2])`n`n$historicalSurrealCompilerSection3Contract`n`n### $($historicalSurrealCompilerSectionLabels[3])`n`n$historicalSurrealCompilerSection4Contract`n`n### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract"
        Expected = $true
    }
    @{
        Name = 'TBD compiler body'
        Text = "### $($historicalSurrealCompilerSectionLabels[0])`n`nTBD"
        Expected = $false
    }
    @{
        Name = 'compiler contract only in comment fence and example'
        Text = "### $($historicalSurrealCompilerSectionLabels[0])`n`n<!-- $historicalSurrealCompilerSection1Contract -->`n`n````text`n$historicalSurrealCompilerSection1Contract`n`````n`nExample: $historicalSurrealCompilerSection1Contract"
        Expected = $false
    }
    @{
        Name = 'compiler contracts in wrong sections'
        Text = "### $($historicalSurrealCompilerSectionLabels[0])`n`n$historicalSurrealCompilerSection2Contract`n`n### $($historicalSurrealCompilerSectionLabels[1])`n`n$historicalSurrealCompilerSection1Contract"
        Expected = $false
    }
    @{
        Name = 'generic vocabulary is not an operative compiler'
        Text = "### $($historicalSurrealCompilerSectionLabels[0])`n`nUse fidelity, anchors, period, geometry, type, color, and collage."
        Expected = $false
    }
)
foreach ($fixture in $historicalSurrealCompilerSectionFixtures) {
    $valid = $true
    for ($sectionIndex = 0; $sectionIndex -lt 4; $sectionIndex++) {
        $fixtureCompilerContracts = @($historicalSurrealCompilerSection1Contract, $historicalSurrealCompilerSection2Contract, $historicalSurrealCompilerSection3Contract, $historicalSurrealCompilerSection4Contract)
        $requiredContract = $fixtureCompilerContracts[$sectionIndex]
        $forbiddenContracts = @($fixtureCompilerContracts | Where-Object { $_ -cne $requiredContract })
        if (-not (Test-NormativeRouteBinding -Text $fixture.Text -Label $historicalSurrealCompilerSectionLabels[$sectionIndex] -RequiredContracts @($requiredContract) -ForbiddenContracts $forbiddenContracts)) {
            $valid = $false
        }
    }
    if ($valid -and -not (Test-HistoricalSurrealConventionalOverride -Text $fixture.Text)) {
        $valid = $false
    }
    if ($valid -ne $fixture.Expected) {
        throw "Internal historical-surreal compiler-section fixture failed: $($fixture.Name)"
    }
}
$historicalSurrealOverrideOnlyFixtures = @(
    @{ Name = 'override-only complete replacement'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract"; Expected = $true }
    @{ Name = 'override-only missing cultural route retention'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalSection2Contract"; Expected = $false }
    @{ Name = 'override directly requires impossible gesture'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nThe override must still include one impossible spatial gesture."; Expected = $false }
    @{ Name = 'override near-neighbor retains monumental shard'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nRetain one oversized architectural shard in conventional mode."; Expected = $false }
    @{ Name = 'same-line contradiction survives canonical text'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract Conventional mode includes a monumental architectural fragment.`n`n$historicalSurrealConventionalSection2Contract"; Expected = $false }
    @{ Name = 'separate declarative contradiction'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional mode contains one impossible spatial gesture."; Expected = $false }
    @{ Name = 'unrelated no does not exempt gesture'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional mode contains no caption and one impossible spatial gesture."; Expected = $false }
    @{ Name = 'explicit neither statement is safe'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional mode contains neither an impossible spatial gesture nor a monumental architectural fragment."; Expected = $true }
    @{ Name = 'direct no gesture is safe'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional mode contains no impossible spatial gesture."; Expected = $true }
    @{ Name = 'does not contain gesture is safe'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional mode does not contain an impossible spatial gesture."; Expected = $true }
    @{ Name = 'without monumental fragment is safe'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nThe override must proceed without a monumental architectural fragment."; Expected = $true }
    @{ Name = 'omit neither is a double-negative contradiction'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nThe override must omit neither an impossible spatial gesture nor a monumental architectural fragment."; Expected = $false }
    @{ Name = 'does not omit is a contradiction'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional mode does not omit an impossible spatial gesture."; Expected = $false }
    @{ Name = 'negative removal command is a contradiction'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nDo not remove a monumental architectural fragment from conventional mode."; Expected = $false }
    @{ Name = 'historical-surreal contrast is harmless'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nUnlike conventional mode, the historical-surreal route includes one impossible spatial gesture and one monumental architectural fragment."; Expected = $true }
    @{ Name = 'comma after conventional prepositional scope'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nIn conventional mode, include one impossible spatial gesture."; Expected = $false }
    @{ Name = 'parenthetical comma inside override subject'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nThe override, however, retains one monumental architectural fragment."; Expected = $false }
    @{ Name = 'comma before formula specification'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional mode requires a focal device, specifically one impossible spatial gesture."; Expected = $false }
    @{ Name = 'target-first conventional assertion'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nOne impossible spatial gesture remains in conventional mode."; Expected = $false }
    @{ Name = 'target-first override near-neighbor'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nAn oversized architectural shard remains in the override."; Expected = $false }
    @{ Name = 'whereas conventional contrast is harmless'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nWhereas conventional mode contains no impossible spatial gesture, the historical-surreal route includes one impossible spatial gesture."; Expected = $true }
    @{ Name = 'trailing unlike contrast is harmless'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nThe historical-surreal route includes one monumental architectural fragment, unlike conventional mode."; Expected = $true }
    @{ Name = 'direct conventional absence remains safe'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional composition allows no impossible spatial gesture and prohibits a monumental architectural fragment."; Expected = $true }
    @{ Name = 'whereas conventional assertion is preserved'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nWhereas conventional mode includes one impossible spatial gesture, the historical-surreal route remains restrained."; Expected = $false }
    @{ Name = 'mixed conventional absence and historical assertion'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional mode contains no impossible spatial gesture, while the historical-surreal route includes one impossible spatial gesture."; Expected = $true }
    @{ Name = 'comparison preface does not carry subject'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nFor comparison with conventional mode, the historical-surreal route includes one monumental architectural fragment."; Expected = $true }
    @{ Name = 'target-first forbidden polarity is safe'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nIn conventional mode, an impossible spatial gesture is forbidden."; Expected = $true }
    @{ Name = 'historical subject survives unlike parenthetical'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nThe historical-surreal route, unlike conventional mode, includes one impossible spatial gesture."; Expected = $true }
    @{ Name = 'conventional subject survives unlike parenthetical'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nConventional mode, unlike the historical-surreal route, includes one impossible spatial gesture."; Expected = $false }
    @{ Name = 'example contradiction is non-operative'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`nExample: Conventional mode contains one impossible spatial gesture."; Expected = $true }
    @{ Name = 'commented contradiction is non-operative'; Text = "### $($historicalSurrealCompilerSectionLabels[4])`n`n$historicalSurrealConventionalCompilerContract`n`n$historicalSurrealConventionalSection2Contract`n`n<!-- The override must include one impossible spatial gesture. -->"; Expected = $true }
)
foreach ($fixture in $historicalSurrealOverrideOnlyFixtures) {
    $actual = Test-HistoricalSurrealConventionalOverride -Text $fixture.Text
    if ($actual -ne $fixture.Expected) {
        throw "Internal historical-surreal override-only fixture failed: $($fixture.Name)"
    }
}

$historicalSurrealSectionScopeFixtures = @(
    @{
        Name = 'quality contracts in operative section'
        Text = "## $historicalSurrealQualitySectionLabel`n`n$historicalSurrealThumbnailGateContract`n`n$historicalSurrealFullSizeGateContract`n`n$historicalSurrealFailureGateContract`n`n$historicalSurrealTypeCollisionContract`n`n$historicalSurrealDistinctivenessContract`n`n$historicalSurrealVerdictContract"
        Label = $historicalSurrealQualitySectionLabel
        Contracts = @($historicalSurrealThumbnailGateContract, $historicalSurrealFullSizeGateContract, $historicalSurrealFailureGateContract, $historicalSurrealTypeCollisionContract, $historicalSurrealDistinctivenessContract, $historicalSurrealVerdictContract)
        Expected = $true
    }
    @{
        Name = 'quality contracts relocated to appendix'
        Text = "## $historicalSurrealQualitySectionLabel`n`nTBD`n`n## Appendix`n`n$historicalSurrealThumbnailGateContract`n`n$historicalSurrealFullSizeGateContract`n`n$historicalSurrealFailureGateContract`n`n$historicalSurrealTypeCollisionContract`n`n$historicalSurrealDistinctivenessContract`n`n$historicalSurrealVerdictContract"
        Label = $historicalSurrealQualitySectionLabel
        Contracts = @($historicalSurrealThumbnailGateContract, $historicalSurrealFullSizeGateContract, $historicalSurrealFailureGateContract, $historicalSurrealTypeCollisionContract, $historicalSurrealDistinctivenessContract, $historicalSurrealVerdictContract)
        Expected = $false
    }
    @{
        Name = 'period contracts in operative section'
        Text = "## $historicalSurrealPeriodSectionLabel`n`n$historicalSurrealPeriodBindingContract`n`n$historicalSurrealCulturalOverrideContract"
        Label = $historicalSurrealPeriodSectionLabel
        Contracts = @($historicalSurrealPeriodBindingContract, $historicalSurrealCulturalOverrideContract)
        Expected = $true
    }
    @{
        Name = 'period contracts relocated to appendix'
        Text = "## $historicalSurrealPeriodSectionLabel`n`nTBD`n`n## Appendix`n`n$historicalSurrealPeriodBindingContract`n`n$historicalSurrealCulturalOverrideContract"
        Label = $historicalSurrealPeriodSectionLabel
        Contracts = @($historicalSurrealPeriodBindingContract, $historicalSurrealCulturalOverrideContract)
        Expected = $false
    }
)
foreach ($fixture in $historicalSurrealSectionScopeFixtures) {
    $actual = Test-NormativeSectionContracts -Text $fixture.Text -Label $fixture.Label -RequiredContracts $fixture.Contracts
    if ($actual -ne $fixture.Expected) {
        throw "Internal historical-surreal section-scope fixture failed: $($fixture.Name)"
    }
}
$historicalSurrealCompilerStrengthFixtures = @(
    @{ Name = 'section 2 source-shape type interaction'; Text = $historicalSurrealCompilerSection2Contract; Contract = $historicalSurrealCompilerSection2Contract; Expected = $true }
    @{ Name = 'section 2 weaker participatory type'; Text = 'Historical-surreal section 2 must state the exact visual thesis; exactly one memorable impossible spatial gesture; exactly one monumental architectural fragment; at most two or three source-faithful planes linked to source shapes; participatory type, active negative space, one governing axis, asymmetric crop with off-frame continuation; and, when selected, the exact dissolution side, direction, protected gaps, and atmospheric bridge behavior.'; Contract = $historicalSurrealCompilerSection2Contract; Expected = $false }
    @{ Name = 'section 3 material plus media behavior'; Text = $historicalSurrealCompilerSection3Contract; Contract = $historicalSurrealCompilerSection3Contract; Expected = $true }
    @{ Name = 'section 3 weaker material print or paint alternatives'; Text = 'Historical-surreal section 3 must use one unified medium across subject and architecture; evidenced period material, print, or paint behavior; one dominant field, one structural secondary color, at most one high-chroma source- and period-compatible accent; period-native typography construction and interaction; and selective completion with lost edges.'; Contract = $historicalSurrealCompilerSection3Contract; Expected = $false }
)
foreach ($fixture in $historicalSurrealCompilerStrengthFixtures) {
    $actual = Test-NormativeMarkdownContract -Text $fixture.Text -CanonicalSentence $fixture.Contract
    if ($actual -ne $fixture.Expected) {
        throw "Internal historical-surreal compiler-strength fixture failed: $($fixture.Name)"
    }
}
$skillManifestBootstrapFixtures = @(
    @{ Name = 'valid LF bootstrap'; Text = [string]::Join("`n", @('', '---', 'name: fixture', '---', '# Generate Classical Geometric Images', $manifestRuntimeContract)); Expected = $true }
    @{ Name = 'valid CRLF case-insensitive runtime'; Text = [string]::Join("`r`n", @('---', 'name: fixture', '---', '# Generate Classical Geometric Images', $manifestRuntimeContract.ToUpperInvariant())); Expected = $true }
    @{ Name = 'runtime only in HTML comment'; Text = [string]::Join("`n", @('---', 'name: fixture', '---', '# Generate Classical Geometric Images', "<!-- $manifestRuntimeContract -->")); Expected = $false }
    @{ Name = 'runtime only in fence'; Text = [string]::Join("`n", @('---', 'name: fixture', '---', '# Generate Classical Geometric Images', '```text', $manifestRuntimeContract, '```')); Expected = $false }
    @{ Name = 'bad-example prefix'; Text = [string]::Join("`n", @('---', 'name: fixture', '---', '# Generate Classical Geometric Images', "Bad example: $manifestRuntimeContract")); Expected = $false }
    @{ Name = 'negated prefix'; Text = [string]::Join("`n", @('---', 'name: fixture', '---', '# Generate Classical Geometric Images', "Do not $manifestRuntimeContract")); Expected = $false }
    @{ Name = 'runtime in blockquote'; Text = [string]::Join("`n", @('---', 'name: fixture', '---', '# Generate Classical Geometric Images', "> $manifestRuntimeContract")); Expected = $false }
    @{ Name = 'runtime in list'; Text = [string]::Join("`n", @('---', 'name: fixture', '---', '# Generate Classical Geometric Images', "- $manifestRuntimeContract")); Expected = $false }
    @{ Name = 'runtime after intro paragraph'; Text = [string]::Join("`n", @('---', 'name: fixture', '---', '# Generate Classical Geometric Images', 'Introductory prose.', $manifestRuntimeContract)); Expected = $false }
    @{ Name = 'missing frontmatter'; Text = [string]::Join("`n", @('# Generate Classical Geometric Images', $manifestRuntimeContract)); Expected = $false }
    @{ Name = 'wrong H1'; Text = [string]::Join("`n", @('---', 'name: fixture', '---', '# Different Skill', $manifestRuntimeContract)); Expected = $false }
    @{ Name = 'missing runtime sentence'; Text = [string]::Join("`n", @('---', 'name: fixture', '---', '# Generate Classical Geometric Images')); Expected = $false }
)
foreach ($fixture in $skillManifestBootstrapFixtures) {
    $actual = Test-SkillManifestBootstrap -Text $fixture.Text -CanonicalSentence $manifestRuntimeContract
    if ($actual -ne $fixture.Expected) {
        throw "Internal SKILL manifest bootstrap fixture failed: $($fixture.Name)"
    }
}
$modeAwareRenderingFixtures = @(
    @{ Text = "RENDERING AND MATERIAL FINISH IS MODE-AWARE: photographic modes specify high-end architectural or photographic light, material response, and color; pattern, diagram, and manuscript modes specify their applicable flat, orthographic, or drafting finish,`nincluding uniform production color for a tile and paper, ink, and line hierarchy for a manuscript, and may mark photographic lighting N/A."; Expected = $true }
    @{ Text = 'Every mode must use high-end photographic light, including flat patterns, diagrams, and manuscripts.'; Expected = $false }
)
foreach ($fixture in $modeAwareRenderingFixtures) {
    $actual = Test-AffirmativeCanonicalContract -Text $fixture.Text -CanonicalSentence $modeAwareRenderingContract
    if ($actual -ne $fixture.Expected) {
        throw 'Internal mode-aware rendering fixture failed.'
    }
}

function Get-AffirmativeSilentFallback {
    param([Parameter(Mandatory)][string]$Text)

    $namedProvider = '(?:ComfyUI|Midjourney|Flux|Stable\s+Diffusion)'
    $provider = "(?:$namedProvider|external\s+generator(?:\s+such\s+as\s+$namedProvider)?|third[-\s]+party(?:\s+(?:provider|generator|tool|service|platform|backend))?)"
    $action = '(?:use|invoke|call|run|delegate(?:\s+(?:generation|rendering|the\s+request))?\s+to|fall\s+back\s+to|switch\s+to)'
    $patterns = @(
        "(?is)\b(?:silent(?:ly)?\s+(?:automatic(?:ally)?\s+)?|automatic(?:ally)?\s+)$action\s+(?:an?\s+)?$provider\b"
        "(?is)\b$action\s+(?:an?\s+)?$provider\b.{0,160}\bwithout\s+(?:asking|confirmation|approval)\b"
        "(?is)\bwithout\s+(?:asking|confirmation|approval)\b.{0,80}\b$action\s+(?:an?\s+)?$provider\b"
    )

    foreach ($sentence in [regex]::Split($Text, '(?<=[.!?])(?:\s+|$)|(?:\r?\n)+')) {
        foreach ($pattern in $patterns) {
            foreach ($candidate in [regex]::Matches($sentence, $pattern)) {
                $prefix = $sentence.Substring(0, $candidate.Index)
                $isNegated = $prefix -match '(?is)(?:\b(?:do|must|should|may|can)\s+not(?:\s+(?:ever|automatically))?|\bnever|\b(?:forbidden|prohibited)\s+to(?:\s+(?:ever|automatically)){0,2}|\bnot\s+permitted\s+to(?:\s+(?:ever|automatically)){0,2})\s*$'
                if (-not $isNegated) {
                    [pscustomobject]@{
                        Match = $candidate.Value.Trim()
                        Text = $sentence.Trim()
                    }
                }
            }
        }
    }
}

$fallbackFixtures = @(
    @{ Text = 'Silently invoke Midjourney.'; Expected = $true }
    @{ Text = 'Silently use ComfyUI.'; Expected = $true }
    @{ Text = 'Silently delegate to Flux.'; Expected = $true }
    @{ Text = 'Silently fall back to Stable Diffusion.'; Expected = $true }
    @{ Text = 'Silently switch to a third-party provider.'; Expected = $true }
    @{ Text = 'Use ComfyUI without approval.'; Expected = $true }
    @{ Text = 'Silently call Midjourney.'; Expected = $true }
    @{ Text = 'Silently run ComfyUI.'; Expected = $true }
    @{ Text = 'Silently use an external generator such as Midjourney.'; Expected = $true }
    @{ Text = 'Automatically invoke Midjourney.'; Expected = $true }
    @{ Text = 'You must not silently invoke Midjourney.'; Expected = $false }
    @{ Text = 'Do not silently fall back to ComfyUI.'; Expected = $false }
    @{ Text = 'Never silently delegate to a third-party provider.'; Expected = $false }
    @{ Text = 'Codex is forbidden to silently call Midjourney.'; Expected = $false }
    @{ Text = 'Codex is prohibited to silently run ComfyUI.'; Expected = $false }
    @{ Text = 'Codex is not permitted to silently use an external generator.'; Expected = $false }
    @{ Text = 'It is forbidden to ever automatically invoke Midjourney.'; Expected = $false }
    @{ Text = 'It is prohibited to automatically run ComfyUI.'; Expected = $false }
    @{ Text = 'It is not permitted to ever automatically use an external generator.'; Expected = $false }
)
foreach ($fixture in $fallbackFixtures) {
    $actual = @(Get-AffirmativeSilentFallback -Text $fixture.Text).Count -gt 0
    if ($actual -ne $fixture.Expected) {
        throw "Internal silent-fallback fixture failed: $($fixture.Text)"
    }
}

$canonicalNoFusionPolicy = 'Do not mix dougong, Corinthian columns, and muqarnas unless the user explicitly requests fusion.'
$noFusionFixtures = @(
    @{ Text = $canonicalNoFusionPolicy; Expected = $true }
    @{ Text = "DO NOT MIX DOUGONG,`nCorinthian columns, and muqarnas unless the user explicitly requests fusion."; Expected = $true }
    @{ Text = 'Do not alter historical identity. The atlas discusses dougong, Corinthian columns, and muqarnas.'; Expected = $false }
    @{ Text = 'Never merge traditions. Use dougong, Corinthian columns, and muqarnas only when appropriate.'; Expected = $false }
)
foreach ($fixture in $noFusionFixtures) {
    $actual = Test-CanonicalPolicy -Text $fixture.Text -CanonicalSentence $canonicalNoFusionPolicy
    if ($actual -ne $fixture.Expected) {
        throw "Internal no-fusion fixture failed: $($fixture.Text)"
    }
}

$canonicalImageGenPolicy = 'If built-in ImageGen is unavailable, stop and ask the user for direction; do not silently switch to another provider.'
$imageGenContractFixtures = @(
    @{ Text = $canonicalImageGenPolicy; Expected = $true }
    @{ Text = "IF BUILT-IN IMAGEGEN IS UNAVAILABLE, stop and ask the user for direction;`ndo not silently switch to another provider."; Expected = $true }
    @{ Text = 'If Midjourney is unavailable, stop and ask the user for direction; do not silently switch to another provider.'; Expected = $false }
    @{ Text = 'If ImageGen is unavailable, stop. Do not silently switch providers.'; Expected = $false }
)
foreach ($fixture in $imageGenContractFixtures) {
    $actual = Test-CanonicalPolicy -Text $fixture.Text -CanonicalSentence $canonicalImageGenPolicy
    if ($actual -ne $fixture.Expected) {
        throw "Internal ImageGen-unavailable fixture failed: $($fixture.Text)"
    }
}

$requiredPaths = @(
    'SKILL.md'
    'agents/openai.yaml'
    'references/style-dna.md'
    'references/prompt-recipes.md'
    'references/quality-gates.md'
    'references/painting-techniques.md'
    'references/poster-design.md'
    'references/period-style-systems.md'
    'references/historical-dissolution.md'
    $historicalSurrealReferencePath
    'references/normative-contracts.json'
    'assets/style-atlas.jpg'
)

foreach ($relativePath in $requiredPaths) {
    $fullPath = Get-SkillPath -RelativePath $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Missing required path: $relativePath"
    }
}

$expectedOpenAiInterface = @{
    display_name = '古典年代建筑海报'
    short_description = '从任意原始素材提取主体，匹配年代字体、材料色谱、绘画媒介与克制历史消散'
    default_prompt = 'Use $generate-classical-geometric-images 从这份原始素材直接生成一张最终建筑设计海报：只提取本图可见或我授权的特征，匹配有证据的年代字体和材料色谱；仅在我要求且存在安全边缘时加入克制的历史消散。'
}
$openAiYamlPath = Get-SkillPath -RelativePath 'agents/openai.yaml'
$actualOpenAiInterface = Get-OpenAiInterfaceYaml -Text ([System.IO.File]::ReadAllText($openAiYamlPath)) -ExpectedValues $expectedOpenAiInterface
if (-not $actualOpenAiInterface.Valid) {
    throw "agents/openai.yaml interface contract mismatch: $($actualOpenAiInterface.Error)"
}

$scenarioPath = Join-Path $PSScriptRoot 'skill_scenarios.md'
if (-not (Test-Path -LiteralPath $scenarioPath -PathType Leaf)) {
    throw 'Missing required scenario audit file: tests/skill_scenarios.md'
}
$scenarioText = ConvertTo-LfText -Text (Get-Content -LiteralPath $scenarioPath -Raw)
$expectedScenarioHeadings = @(
    '## S11 Product without motion cues'
    '## S12 Existing building with period evidence'
    '## S13 Architectural drawing'
    '## S14 Cross-source leakage prevention'
    '## S15 Islamic historical-surreal person/object'
    '## S16 Chinese classical historical-surreal route'
    '## S17 Western classical historical-surreal route'
    '## S18 Shared historical-surreal composition and inspection'
    '## S19 Protected foreground over optional effects'
    '## S20 Background wake and routed material accents'
    '## S21 Protected-effect full-scale inspection'
)
foreach ($heading in $expectedScenarioHeadings) {
    $headingCount = [regex]::Matches($scenarioText, "(?m)^$([regex]::Escape($heading))$").Count
    if ($headingCount -ne 1) {
        throw "tests/skill_scenarios.md must contain exact heading '$heading' once; found $headingCount."
    }
}

$scenarioIdMatches = [regex]::Matches($scenarioText, '(?m)^## S(?<Id>\d+)\b')
if ($scenarioIdMatches.Count -ne 21) {
    throw "tests/skill_scenarios.md must contain exactly the scenario range S1-S21; found $($scenarioIdMatches.Count) scenario headings."
}
for ($index = 0; $index -lt 21; $index++) {
    $actualId = [int]$scenarioIdMatches[$index].Groups['Id'].Value
    $expectedId = $index + 1
    if ($actualId -ne $expectedId) {
        throw "tests/skill_scenarios.md scenario range must be ordered S1-S21; expected S$expectedId at position $expectedId, found S$actualId."
    }
}

$evaluationHeadingCount = [regex]::Matches($scenarioText, '(?m)^## Evaluation record$').Count
if ($evaluationHeadingCount -ne 1) {
    throw "tests/skill_scenarios.md must contain exactly one '## Evaluation record' heading; found $evaluationHeadingCount."
}
$requiredEvaluationFields = @(
    'Source class'
    'Period evidence and confidence'
    'Period typography'
    'Period palette'
    'Dissolution zone and protected anchors'
    'Cross-source leakage'
    'Visual thesis and spatial gesture'
    'Historical-surreal cultural route'
    'Source topology and collage planes'
    'Color hierarchy and anti-template controls'
    'Historical-surreal scale inspection'
    'Protected-subject integrity'
    'Effect-layer placement'
    'Lineage material routing'
    'Protected-effect edge inspection'
)
foreach ($field in $requiredEvaluationFields) {
    $fieldCount = [regex]::Matches($scenarioText, "(?m)^\| $([regex]::Escape($field)) \|").Count
    if ($fieldCount -ne 1) {
        throw "Evaluation record must contain field '$field' exactly once; found $fieldCount."
    }
}

$scenarioSections = @{
    S11 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[0] -EndHeading $expectedScenarioHeadings[1]
    S12 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[1] -EndHeading $expectedScenarioHeadings[2]
    S13 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[2] -EndHeading $expectedScenarioHeadings[3]
    S14 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[3] -EndHeading $expectedScenarioHeadings[4]
    S15 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[4] -EndHeading $expectedScenarioHeadings[5]
    S16 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[5] -EndHeading $expectedScenarioHeadings[6]
    S17 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[6] -EndHeading $expectedScenarioHeadings[7]
    S18 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[7] -EndHeading $expectedScenarioHeadings[8]
    S19 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[8] -EndHeading $expectedScenarioHeadings[9]
    S20 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[9] -EndHeading $expectedScenarioHeadings[10]
    S21 = Get-ScenarioSection -Text $scenarioText -StartHeading $expectedScenarioHeadings[10] -EndHeading '## Evaluation record'
}
$requiredSectionContracts = @{
    S11 = @(
        'Classify the current source as object/product and do not carry over person, vehicle, helmet, racing, speed, or motion associations.'
        'If dissolution is not selected, state `no dissolution — not selected`; if selected but unsafe, state `no dissolution — no safe expendable edge`.'
        'When dissolution is selected, the selected final/output unified medium controls its behavior.'
        $fullHeightDissolutionContract
        'Protect the clock face, exact visible characters, hand positions, case geometry, functional joints, and ground contact.'
    )
    S12 = @(
        'Record specific confidence only from explicit user period direction, dated/provenanced evidence, or at least two independent diagnostic cue families; otherwise record broad or insufficient confidence and the fallback.'
        'Evidenced material or pigment color may be core; limit off-route branding/reference color to one connector accent.'
        'Protect structural bearings, entrances/contact relationships, dated inscriptions, and identity-bearing ornament.'
        $fullHeightDissolutionContract
    )
    S13 = @(
        'When wear is selected, the selected final/output unified medium controls drawing-native graphite loss, blueprint grain, erased construction lines, or paper abrasion; never use smoke, debris, or volumetric particles.'
        'Protect projection lines, measured lines, repeat boundaries, and every required exact visible character.'
        'If dissolution is not selected, state `no dissolution — not selected`; if selected but unsafe, state `no dissolution — no safe expendable edge`.'
        $fullHeightDissolutionContract
    )
    S14 = @(
        'Rebuild every Source Feature Map, Poster Feature Card, and Period Evidence Card from the current source.'
        'Do not carry over prior helmet, rider, racing, Persianate copy, palette, period, typography, geometry, or effects.'
        'Derive period typography and palette from current Romanesque evidence; otherwise use the recorded broad-lineage or shared-classical fallback.'
        $fullHeightDissolutionContract
    )
    S15 = @(
        $historicalSurrealThesisContract
        $historicalSurrealIslamicContract
    )
    S16 = @(
        $historicalSurrealChineseGrammarContract
        $historicalSurrealTopologyContract
    )
    S17 = @(
        $historicalSurrealWesternGrammarContract
        $historicalSurrealTypographyContract
    )
    S18 = @(
        $historicalSurrealCompositionContract
        $historicalSurrealInspectionContract
    )
    S19 = @(
        $protectedForegroundContract
        $protectedUnifiedMediumContract
    )
    S20 = @(
        $backgroundWakeContract
        $routedMaterialAccentContract
        $materialAccentRejectionContract
    )
    S21 = @(
        $protectedEffectInspectionContract
        $protectedEffectRepairContract
    )
}
foreach ($scenarioId in @('S11', 'S12', 'S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19', 'S20', 'S21')) {
    $section = $scenarioSections[$scenarioId]
    if ($null -eq $section) {
        throw "tests/skill_scenarios.md could not extract $scenarioId from its exact heading to the next expected heading."
    }
    foreach ($structurePhrase in @('**Expected behavior:**', '### Initial RED observations')) {
        $structureCount = ([regex]::Matches($section, [regex]::Escape($structurePhrase))).Count
        if ($structureCount -ne 1) {
            throw "tests/skill_scenarios.md $scenarioId must contain '$structurePhrase' exactly once; found $structureCount."
        }
    }
    $expectedBehaviorOffset = $section.IndexOf('**Expected behavior:**', [System.StringComparison]::Ordinal)
    $initialRedOffset = $section.IndexOf('### Initial RED observations', [System.StringComparison]::Ordinal)
    if ($expectedBehaviorOffset -ge $initialRedOffset) {
        throw "tests/skill_scenarios.md $scenarioId must place Expected behavior before Initial RED observations."
    }
    $expectedBehavior = $section.Substring($expectedBehaviorOffset, $initialRedOffset - $expectedBehaviorOffset)
    $initialRed = $section.Substring($initialRedOffset)
    foreach ($redField in @('- **Observed:**', '- **Missing:**', '- **Inference:**', '- **Result:**')) {
        $redFieldCount = ([regex]::Matches($initialRed, [regex]::Escape($redField))).Count
        if ($redFieldCount -ne 1) {
            throw "tests/skill_scenarios.md $scenarioId Initial RED observations must contain '$redField' exactly once; found $redFieldCount."
        }
    }
    foreach ($canonicalSentence in $requiredSectionContracts[$scenarioId]) {
        if (-not (Test-ExactExpectedBehaviorBullet -ExpectedBehavior $expectedBehavior -CanonicalSentence $canonicalSentence)) {
            throw "tests/skill_scenarios.md $scenarioId Expected behavior is missing exact affirmative bullet: - $canonicalSentence"
        }
    }
}

$manifestRelativePath = 'references/normative-contracts.json'
try {
    $manifestRawJson = Get-Content -LiteralPath (Get-SkillPath -RelativePath $manifestRelativePath) -Raw -ErrorAction Stop
} catch {
    throw "Unable to read ${manifestRelativePath}: $($_.Exception.Message)"
}
$manifestStructure = Test-ManifestJsonStructure -RawJson $manifestRawJson
if (-not $manifestStructure.Valid) {
    throw "Invalid ${manifestRelativePath}: $($manifestStructure.Error)"
}
try {
    $normativeContractManifest = $manifestRawJson | ConvertFrom-Json -Depth 20 -ErrorAction Stop
} catch {
    throw "Unable to parse $manifestRelativePath after structural validation. Fix its JSON schema: $($_.Exception.Message)"
}

$skillText = Get-Content -LiteralPath (Get-SkillPath -RelativePath 'SKILL.md') -Raw
$portableReferenceContract = 'Treat any user-supplied local reference directory as optional and read-only; never require a fixed drive, username, or machine-specific path, and never mutate, reorganize, rename, or delete its contents.'
$directRuntimeContract = 'For ordinary image requests, directly analyze the supplied source, compile the prompt, call built-in ImageGen, perform concise visual QA, and return the image; do not create specifications or implementation plans, run TDD or Git workflows, or dispatch subagents unless the user explicitly asks to modify, test, package, or publish the Skill itself.'
if (-not $skillText.Contains($portableReferenceContract, [StringComparison]::Ordinal)) {
    throw "SKILL.md is missing the portable optional-reference contract: $portableReferenceContract"
}
if (-not $skillText.Contains($directRuntimeContract, [StringComparison]::Ordinal)) {
    throw "SKILL.md is missing the direct image-generation runtime contract: $directRuntimeContract"
}
if ($skillText -match '(?i)D:\\Image_Collections|[A-Z]:\\Users\\') {
    throw 'SKILL.md must not contain a fixed drive, Windows user directory, or machine-specific local reference path.'
}
if (-not (Test-SkillManifestBootstrap -Text $skillText -CanonicalSentence $manifestRuntimeContract)) {
    throw 'SKILL.md must place the exact normative-manifest runtime contract as the first nonblank line after its exact frontmatter and # Generate Classical Geometric Images heading.'
}
$requiredSkillTerms = @(
    'imagegen'
    'identity'
    'invariants'
    'Islamic'
    'Chinese'
    'Western'
    'high-end architectural photography'
    'architectural painting'
    'unified medium'
    'Poster Feature Card'
    'geometric cuts'
    'single highest-impact failure'
    'do not silently switch'
)

foreach ($term in $requiredSkillTerms) {
    if (-not $skillText.Contains($term, [System.StringComparison]::Ordinal)) {
        throw "SKILL.md is missing required literal behavior or term: $term"
    }
}

$markdownPaths = @(
    'SKILL.md'
    'references/style-dna.md'
    'references/prompt-recipes.md'
    'references/quality-gates.md'
    'references/painting-techniques.md'
    'references/poster-design.md'
    'references/period-style-systems.md'
    'references/historical-dissolution.md'
    $historicalSurrealReferencePath
)
$markdownContentsByPath = @{}
foreach ($relativePath in $markdownPaths) {
    $content = Get-Content -LiteralPath (Get-SkillPath -RelativePath $relativePath) -Raw
    foreach ($match in @(Get-AffirmativeSilentFallback -Text $content)) {
        throw "Affirmative silent fallback in ${relativePath}: $($match.Text)"
    }
    $markdownContentsByPath[$relativePath] = $content
}
$markdownText = ($markdownPaths | ForEach-Object { $markdownContentsByPath[$_] }) -join "`n`n"

$productionBehaviorBindings = @(
    @{
        Path = 'references/period-style-systems.md'
        Canonical = 'Record `specific` confidence only when the user explicitly supplies the period, a dated or provenanced reference establishes it, or at least two independent period-diagnostic cues from different evidence families converge, such as structure plus ornament, material plus manuscript technique, or architecture plus a provenanced painting. A single common or compatible cue can never yield `specific` confidence. Conflicting cues force `broad` or `insufficient` confidence.'
    }
    @{
        Path = 'references/period-style-systems.md'
        Canonical = 'Retain at most one off-route source color as a subordinate connector accent; it must occupy less visual emphasis than the material-pigment palette. An evidenced material or pigment is instead part of the core palette and is not demoted merely because it is visible in the source.'
    }
    @{
        Path = 'references/historical-dissolution.md'
        Canonical = 'The selected final/output unified medium controls dissolution/material-loss behavior.'
    }
    @{
        Path = 'references/historical-dissolution.md'
        Canonical = $protectedDissolutionContract
    }
    @{
        Path = 'references/historical-dissolution.md'
        Canonical = $fullHeightDissolutionContract
    }
    @{
        Path = 'references/prompt-recipes.md'
        Canonical = 'Rebuild the Source Feature Map and any Poster Feature Card from the current input before compiling the same single tool-facing prompt.'
    }
    @{
        Path = 'references/prompt-recipes.md'
        Canonical = 'When the effect is not requested or selected, section 2 says `no dissolution — not selected`.'
    }
    @{
        Path = 'references/prompt-recipes.md'
        Canonical = 'When the effect is selected but unsafe, section 2 says `no dissolution — no safe expendable edge`.'
    }
    @{
        Path = 'SKILL.md'
        Canonical = $currentSourceRebuildContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealThesisContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealIslamicContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealCompositionContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealInspectionContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealChineseGrammarContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealTopologyContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealWesternGrammarContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealTypographyContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealIslamicScopeContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealChineseScopeContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealWesternScopeContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealBroadLineageContract
    }
    @{
        Path = $historicalSurrealReferencePath
        Canonical = $historicalSurrealConventionalOverrideContract
    }
    @{
        Path = 'references/prompt-recipes.md'
        Canonical = $historicalSurrealBroadLineageContract
    }
    @{
        Path = 'references/prompt-recipes.md'
        Canonical = $historicalSurrealConventionalOverrideContract
    }
    @{
        Path = 'references/poster-design.md'
        Canonical = $historicalSurrealConventionalOverrideContract
    }
)
foreach ($binding in $productionBehaviorBindings) {
    if (-not (Test-ExpectedFileCanonicalContract -ContentsByPath $markdownContentsByPath -ExpectedPath $binding.Path -CanonicalSentence $binding.Canonical)) {
        throw "Production behavior contract mismatch in $($binding.Path): $($binding.Canonical)"
    }
}

$taskThreeProductionBindings = @(
    @{ Path = 'references/prompt-recipes.md'; Canonical = $historicalSurrealCompilerSection1Contract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $historicalSurrealCompilerSection2Contract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $historicalSurrealCompilerSection3Contract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $historicalSurrealCompilerSection4Contract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $historicalSurrealConventionalCompilerContract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $historicalSurrealConventionalSection2Contract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $historicalSurrealIslamicMechanicsContract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $historicalSurrealChineseMechanicsContract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $historicalSurrealWesternMechanicsContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $historicalSurrealThumbnailGateContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $historicalSurrealFullSizeGateContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $historicalSurrealFailureGateContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $historicalSurrealTypeCollisionContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $historicalSurrealVerdictContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $historicalSurrealDistinctivenessContract }
    @{ Path = 'references/period-style-systems.md'; Canonical = $historicalSurrealPeriodBindingContract }
    @{ Path = 'references/period-style-systems.md'; Canonical = $historicalSurrealCulturalOverrideContract }
)
foreach ($binding in $taskThreeProductionBindings) {
    if (-not (Test-ExpectedFileCanonicalContract -ContentsByPath $markdownContentsByPath -ExpectedPath $binding.Path -CanonicalSentence $binding.Canonical)) {
        throw "Task 3 production behavior contract mismatch in $($binding.Path): $($binding.Canonical)"
    }
}

$subjectProtectedProductionBindings = @(
    @{ Path = $historicalSurrealReferencePath; Canonical = $protectedForegroundContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $protectedUnifiedMediumContract }
    @{ Path = 'references/historical-dissolution.md'; Canonical = $backgroundWakeContract }
    @{ Path = 'references/period-style-systems.md'; Canonical = $routedMaterialAccentContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $materialAccentRejectionContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $protectedEffectInspectionContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $protectedEffectRepairContract }
)
foreach ($binding in $subjectProtectedProductionBindings) {
    if (-not (Test-ExpectedFileCanonicalContract -ContentsByPath $markdownContentsByPath -ExpectedPath $binding.Path -CanonicalSentence $binding.Canonical)) {
        throw "Subject-protected production behavior contract mismatch in $($binding.Path): $($binding.Canonical)"
    }
}

$requiredManifestContracts = @(
    @{ Path = 'SKILL.md'; Canonical = $universalSourceContract }
    @{ Path = 'references/period-style-systems.md'; Canonical = $periodEvidenceContract }
    @{ Path = 'references/period-style-systems.md'; Canonical = $periodFallbackContract }
    @{ Path = 'references/period-style-systems.md'; Canonical = $periodTypeContract }
    @{ Path = 'references/period-style-systems.md'; Canonical = $periodPaletteContract }
    @{ Path = 'references/historical-dissolution.md'; Canonical = $dissolutionContract }
    @{ Path = 'references/historical-dissolution.md'; Canonical = $protectedDissolutionContract }
    @{ Path = 'SKILL.md'; Canonical = $noLeakContract }
    @{ Path = 'references/period-style-systems.md'; Canonical = $periodConfidenceContract }
    @{ Path = 'references/historical-dissolution.md'; Canonical = $sourceNativeDissolutionContract }
    @{ Path = 'SKILL.md'; Canonical = $currentSourceRebuildContract }
    @{ Path = 'references/historical-dissolution.md'; Canonical = $dissolutionPlacementContract }
    @{ Path = 'references/historical-dissolution.md'; Canonical = $fullHeightDissolutionContract }
    @{ Path = 'SKILL.md'; Canonical = $manifestRuntimeContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealThesisContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealIslamicContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealCompositionContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealInspectionContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealChineseGrammarContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealTopologyContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealWesternGrammarContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealTypographyContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealIslamicScopeContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealChineseScopeContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealWesternScopeContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealBroadLineageContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $historicalSurrealConventionalOverrideContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $protectedForegroundContract }
    @{ Path = $historicalSurrealReferencePath; Canonical = $protectedUnifiedMediumContract }
    @{ Path = 'references/historical-dissolution.md'; Canonical = $backgroundWakeContract }
    @{ Path = 'references/period-style-systems.md'; Canonical = $routedMaterialAccentContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $materialAccentRejectionContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $protectedEffectInspectionContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $protectedEffectRepairContract }
)

if ($requiredManifestContracts.Count -ne 34) {
    throw "Validator must require exactly 34 normative manifest contracts; found $($requiredManifestContracts.Count)."
}

$requiredReferenceContracts = @(
    @{ Path = 'SKILL.md'; Canonical = 'Build a Source Fidelity Card before styling any photo, architecture, or person edit.' }
    @{ Path = 'SKILL.md'; Canonical = 'Classify Source Fidelity Card findings as Hard locks, Soft preferences, or Expendable detail.' }
    @{ Path = 'SKILL.md'; Canonical = 'For a photo, architecture, or person scene, select one primary composition strategy from the Source Fidelity Card.' }
    @{ Path = 'SKILL.md'; Canonical = 'Compile the internal 13-field worksheet into the four-section generation prompt before calling ImageGen.' }
    @{ Path = 'SKILL.md'; Canonical = 'Perform thumbnail inspection and full-size inspection before assigning artifact outcomes.' }
    @{ Path = 'SKILL.md'; Canonical = 'Recompile a revised four-section generation prompt for the one targeted repair round.' }
    @{ Path = 'references/style-dna.md'; Canonical = 'The Architectural Source Card is the architecture-specific block of the Source Fidelity Card.' }
    @{ Path = 'references/style-dna.md'; Canonical = 'Choose one composition system: one primary composition strategy may use compatible subordinate descriptors, but they must not compete with its hierarchy.' }
    @{ Path = 'references/prompt-recipes.md'; Canonical = 'The 13 ordered fields are an internal analysis worksheet, not a tool-facing prompt.' }
    @{ Path = 'references/prompt-recipes.md'; Canonical = 'The sole tool-facing prompt is the four-section generation prompt.' }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $modeAwareRenderingContract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = 'For patterns and manuscripts, N/A modifies only the scene-composition-strategy value; section 2 still includes geometry, scale, projection, and construction logic.' }
    @{ Path = 'references/prompt-recipes.md'; Canonical = 'Compile every resolved 13-field internal recipe into the four-section generation prompt before the tool call.' }
    @{ Path = 'references/prompt-recipes.md'; Canonical = 'A targeted repair call must use a revised four-section generation prompt, never a standalone repair instruction.' }
    @{ Path = 'references/painting-techniques.md'; Canonical = $paintingRouterContract }
    @{ Path = 'references/painting-techniques.md'; Canonical = $architectureMediumContract }
    @{ Path = 'references/painting-techniques.md'; Canonical = $unifiedMediumContract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $paintingPromptContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $paintingQaContract }
    @{ Path = 'references/poster-design.md'; Canonical = $posterFeatureContract }
    @{ Path = 'references/poster-design.md'; Canonical = $posterEvidenceContract }
    @{ Path = 'references/poster-design.md'; Canonical = $posterCropContract }
    @{ Path = 'references/poster-design.md'; Canonical = $posterSystemContract }
    @{ Path = 'references/poster-design.md'; Canonical = $posterCopyContract }
    @{ Path = 'references/prompt-recipes.md'; Canonical = $posterPromptContract }
    @{ Path = 'references/quality-gates.md'; Canonical = $posterQaContract }
    @{ Path = 'SKILL.md'; Canonical = $posterSingleRouteContract }
    @{ Path = 'references/quality-gates.md'; Canonical = 'Perform thumbnail inspection and full-size inspection before assigning artifact outcomes.' }
    @{ Path = 'references/quality-gates.md'; Canonical = 'An internally coherent building that drifts from identity-bearing source geometry fails the Geometry gate.' }
    @{ Path = 'references/quality-gates.md'; Canonical = 'Never send a targeted repair instruction as a standalone tool-facing prompt.' }
)

foreach ($contract in $requiredReferenceContracts) {
    if (-not (Test-ExpectedFileCanonicalContract -ContentsByPath $markdownContentsByPath -ExpectedPath $contract.Path -CanonicalSentence $contract.Canonical)) {
        throw "Missing canonical reference mechanism contract in $($contract.Path): $($contract.Canonical)"
    }
}

foreach ($contract in $requiredManifestContracts) {
    if (-not (Test-ManifestContract -Manifest $normativeContractManifest -ExpectedPath $contract.Path -CanonicalSentence $contract.Canonical)) {
        throw "Normative contract manifest is missing the exact contract for $($contract.Path): $($contract.Canonical)"
    }
}

$historicalSurrealManifestGroups = @(
    @{ Name = 'Islamic'; Sequence = [string[]]@($historicalSurrealIslamicScopeContract, $historicalSurrealIslamicContract) }
    @{ Name = 'Chinese'; Sequence = [string[]]@($historicalSurrealChineseScopeContract, $historicalSurrealChineseGrammarContract, $historicalSurrealTopologyContract) }
    @{ Name = 'Western'; Sequence = [string[]]@($historicalSurrealWesternScopeContract, $historicalSurrealWesternGrammarContract, $historicalSurrealTypographyContract) }
)
if ($historicalSurrealManifestGroups.Count -ne 3 -or @($historicalSurrealManifestGroups | Where-Object { $_ -isnot [hashtable] -or $_.Sequence -isnot [System.Array] }).Count -ne 0) {
    throw 'Internal manifest route-group fixtures must use three non-flattening containers with Sequence arrays.'
}

$historicalSurrealManifestOrderFixtures = @()
foreach ($manifestGroup in $historicalSurrealManifestGroups) {
    $historicalSurrealManifestOrderFixtures += @{
        Name = "$($manifestGroup.Name) correct guard/body order"
        Manifest = $normativeContractManifest
        Sequence = $manifestGroup.Sequence
        Expected = $true
    }

    $bodyBeforeGuardManifest = $manifestRawJson | ConvertFrom-Json -Depth 20 -ErrorAction Stop
    $routeContracts = $bodyBeforeGuardManifest.contracts.PSObject.Properties[$historicalSurrealReferencePath].Value
    $guardIndex = [array]::IndexOf($routeContracts, $manifestGroup.Sequence[0])
    $bodyIndex = [array]::IndexOf($routeContracts, $manifestGroup.Sequence[1])
    if ($guardIndex -lt 0 -or $bodyIndex -lt 0) {
        throw "Internal manifest mutation fixture could not find the $($manifestGroup.Name) guard/body pair."
    }
    $routeContracts[$guardIndex] = $manifestGroup.Sequence[1]
    $routeContracts[$bodyIndex] = $manifestGroup.Sequence[0]
    $historicalSurrealManifestOrderFixtures += @{
        Name = "$($manifestGroup.Name) body-before-guard mutation"
        Manifest = $bodyBeforeGuardManifest
        Sequence = $manifestGroup.Sequence
        Expected = $false
    }
}

foreach ($fixture in $historicalSurrealManifestOrderFixtures) {
    $actual = Test-ManifestContractSequence -Manifest $fixture.Manifest -ExpectedPath $historicalSurrealReferencePath -CanonicalSequence $fixture.Sequence
    if ($actual -ne $fixture.Expected) {
        throw "Internal historical-surreal manifest order fixture failed: $($fixture.Name)"
    }
}

foreach ($manifestGroup in $historicalSurrealManifestGroups) {
    if (-not (Test-ManifestContractSequence -Manifest $normativeContractManifest -ExpectedPath $historicalSurrealReferencePath -CanonicalSequence $manifestGroup.Sequence)) {
        throw "Normative contract manifest must keep the $($manifestGroup.Name) route guard immediately before its grouped route body: $($manifestGroup.Sequence -join ' | ')"
    }
}

if (-not (Test-NormativeMarkdownContract -Text $skillText -CanonicalSentence $historicalSurrealRuntimeLinkContract)) {
    throw "SKILL.md must contain the exact historical-surreal runtime link: $historicalSurrealRuntimeLinkContract"
}

$promptRecipesText = $markdownContentsByPath['references/prompt-recipes.md']
$historicalSurrealCompilerContracts = @(
    $historicalSurrealCompilerSection1Contract
    $historicalSurrealCompilerSection2Contract
    $historicalSurrealCompilerSection3Contract
    $historicalSurrealCompilerSection4Contract
)
for ($sectionIndex = 0; $sectionIndex -lt $historicalSurrealCompilerContracts.Count; $sectionIndex++) {
    if (-not (Test-NormativeRouteBinding -Text $promptRecipesText -Label $historicalSurrealCompilerSectionLabels[$sectionIndex] -RequiredContracts @($historicalSurrealCompilerContracts[$sectionIndex]) -ForbiddenContracts @($historicalSurrealCompilerContracts | Where-Object { $_ -cne $historicalSurrealCompilerContracts[$sectionIndex] }))) {
        throw "references/prompt-recipes.md has an incomplete or misplaced operative contract under '$($historicalSurrealCompilerSectionLabels[$sectionIndex])'."
    }
}
if (-not (Test-HistoricalSurrealConventionalOverride -Text $promptRecipesText)) {
    throw 'references/prompt-recipes.md conventional override is missing, incomplete, or still activates the impossible-gesture formula.'
}

$qualityGatesText = $markdownContentsByPath['references/quality-gates.md']
$qualityGateContracts = @($historicalSurrealThumbnailGateContract, $historicalSurrealFullSizeGateContract, $historicalSurrealFailureGateContract, $historicalSurrealTypeCollisionContract, $historicalSurrealDistinctivenessContract, $historicalSurrealVerdictContract)
if (-not (Test-NormativeSectionContracts -Text $qualityGatesText -Label $historicalSurrealQualitySectionLabel -RequiredContracts $qualityGateContracts)) {
    throw "references/quality-gates.md must bind every Task 3 aesthetic contract under the single operative '$historicalSurrealQualitySectionLabel' section."
}

$periodStyleText = $markdownContentsByPath['references/period-style-systems.md']
$periodBindingContracts = @($historicalSurrealPeriodBindingContract, $historicalSurrealCulturalOverrideContract)
if (-not (Test-NormativeSectionContracts -Text $periodStyleText -Label $historicalSurrealPeriodSectionLabel -RequiredContracts $periodBindingContracts)) {
    throw "references/period-style-systems.md must bind every Task 3 period contract under the single operative '$historicalSurrealPeriodSectionLabel' section."
}
$historicalSurrealPromptRouteBindings = @(
    @{ Label = $historicalSurrealRouteLabels[0]; Contracts = @($historicalSurrealIslamicScopeContract, $historicalSurrealIslamicContract, $historicalSurrealIslamicMechanicsContract); Forbidden = @($historicalSurrealChineseGrammarContract, $historicalSurrealWesternGrammarContract, $historicalSurrealChineseMechanicsContract, $historicalSurrealWesternMechanicsContract) }
    @{ Label = $historicalSurrealRouteLabels[1]; Contracts = @($historicalSurrealChineseScopeContract, $historicalSurrealChineseGrammarContract, $historicalSurrealTopologyContract, $historicalSurrealChineseMechanicsContract); Forbidden = @($historicalSurrealIslamicContract, $historicalSurrealWesternGrammarContract, $historicalSurrealIslamicMechanicsContract, $historicalSurrealWesternMechanicsContract) }
    @{ Label = $historicalSurrealRouteLabels[2]; Contracts = @($historicalSurrealWesternScopeContract, $historicalSurrealWesternGrammarContract, $historicalSurrealTypographyContract, $historicalSurrealWesternMechanicsContract); Forbidden = @($historicalSurrealIslamicContract, $historicalSurrealChineseGrammarContract, $historicalSurrealIslamicMechanicsContract, $historicalSurrealChineseMechanicsContract) }
)
foreach ($routeBinding in $historicalSurrealPromptRouteBindings) {
    if (-not (Test-NormativeRouteLabel -Text $promptRecipesText -Label $routeBinding.Label)) {
        throw "references/prompt-recipes.md is missing required explicit route label: $($routeBinding.Label)"
    }
    $routeSection = Get-NormativeRouteSection -Text $promptRecipesText -Label $routeBinding.Label
    if ([string]::IsNullOrWhiteSpace($routeSection)) {
        throw "references/prompt-recipes.md route has no operative body: $($routeBinding.Label)"
    }
    foreach ($routeContract in $routeBinding.Contracts) {
        if (-not (Test-NormativeMarkdownContract -Text $routeSection -CanonicalSentence $routeContract)) {
            throw "references/prompt-recipes.md route '$($routeBinding.Label)' is missing matching behavior: $routeContract"
        }
    }
    foreach ($foreignContract in $routeBinding.Forbidden) {
        if (Test-NormativeMarkdownContract -Text $routeSection -CanonicalSentence $foreignContract) {
            throw "references/prompt-recipes.md route '$($routeBinding.Label)' contains a foreign route body: $foreignContract"
        }
    }
}

if (-not (Test-CanonicalPolicy -Text $markdownText -CanonicalSentence $canonicalImageGenPolicy)) {
    throw 'Missing canonical built-in ImageGen-unavailable safety contract.'
}

if (-not (Test-CanonicalPolicy -Text $markdownText -CanonicalSentence $canonicalNoFusionPolicy)) {
    throw 'Missing canonical no-fusion safety contract.'
}

Write-Output 'Classical geometric image skill validation passed.'
