$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$assetRoot = Join-Path $taskRoot 'mobile/assets/images/playable_stage'
$bindingPath = Join-Path $taskRoot 'mobile/assets/images/role_skill_effects_v002/bindings.json'
$bindings = Get-Content -LiteralPath $bindingPath -Raw | ConvertFrom-Json -AsHashtable
$roles = @('warrior','boxer','samurai','guardian','ninja','assassin','ranger','mage','gunner','spellblade','onmyoji','reaper','angel','devil','dragon_knight','berserker')
$addedEvents = @('shikigami_attack','chain_scythe_throw','holy_swords_release','curse_apply','dragon_flurry_hit','floor_release')
for ($number = 1; $number -le $roles.Count; $number++) {
    foreach ($female in @($false, $true)) {
        $key = $roles[$number - 1] + $(if ($female) { '_female' } else { '_male' })
        $source = ('character_{0:00}' -f $number) + $(if ($female) { '_female' } else { '' })
        $binding = $bindings[$key]
        $event = if ($number -gt 10) { $addedEvents[$number - 11] } else { $binding.source_event }
        $meta = Get-Content -LiteralPath (Join-Path $assetRoot "${source}_skill.json") -Raw | ConvertFrom-Json -AsHashtable
        $releases = @($meta.events | Where-Object event -eq $event | ForEach-Object { [int]$_.tick } | Sort-Object -Unique)
        if ($releases.Count -eq 0) { throw "Missing skill event $event for $source" }
        $total = $meta.timeline.Count
        $timeline = @()
        $holds = @()
        for ($tick = 0; $tick -lt $total; $tick++) {
            if ($tick -lt $releases[0]) {
                $index = [Math]::Min(2, [Math]::Floor($tick * 3 / [Math]::Max(1, $releases[0])))
            } elseif ($releases.Count -ge 3 -and $tick -lt $releases[2]) {
                $eventIndex = if ($tick -lt $releases[1]) { 0 } else { 1 }
                $index = 3 + $eventIndex * 2 + [Math]::Min(1, [Math]::Floor(($tick - $releases[$eventIndex]) * 2 / [Math]::Max(1, $releases[$eventIndex + 1] - $releases[$eventIndex])))
            } elseif ($releases.Count -ge 3) {
                $index = [Math]::Min(11, 7 + [Math]::Floor(($tick - $releases[2]) * 5 / [Math]::Max(1, $total - $releases[2])))
            } else {
                $index = [Math]::Min(11, 3 + [Math]::Floor(($tick - $releases[0]) * 9 / [Math]::Max(1, $total - $releases[0])))
            }
            $timeline += @{ tick = $tick; keyframe = [int]$index; root_offset_px = $meta.timeline[$tick].root_offset_px; file = 'frames_24fps/{0:000}.png' -f $tick }
            if ($holds.Count -gt 0 -and $holds[-1].keyframe -eq $index) { $holds[-1].ticks++ }
            else { $holds += @{ keyframe = [int]$index; ticks = 1 } }
        }
        $binding.source_motion = $source
        $binding.source_event = $event
        $binding.duration_seconds = $total / 24
        $binding.release_ticks = $releases
        $binding.timeline = $timeline
        $binding.holds = $holds
        $binding.events = $meta.events
    }
}
# Update runtime metadata only; archived effect originals and playback files stay intact.
[IO.File]::WriteAllText($bindingPath, ($bindings | ConvertTo-Json -Depth 30 -Compress), [Text.UTF8Encoding]::new($false))
