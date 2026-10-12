$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$assetRoot = Join-Path $taskRoot 'mobile/assets/images/playable_stage'
$attackEvents = @('slash_active','jab','draw_cut_hit','downward_hit','projectile_release','thrust_active','arrow_release','fire_release','bullet_release','sword_hit')
$femaleAttackEvents = @('attack_active','punch_hit','attack_active','attack_active','attack_active','attack_active','arrow_release','fire_release','bullet_release','sword_hit')
$skillEvents = @('wave_release','kick_hit','slash_1','sweep_hit','dagger_hit','critical_impact','arrow_release','ice_release','bullet_release','lightning_strike')
$femaleSkillEvents = @('skill_release','kick_hit','flurry_hit','skill_release','dagger_hit','skill_release','arrow_release','ice_release','bullet_release','lightning_strike')
$skillNames = @('蓄力斬撃','旋風蹴り','連続居合','蓄力薙ぎ払い','瞬身突き','蓄力クリティカル','三連射','大氷結','早撃ち','雷剣・落雷')
$lines = @("// Generated from the supplied original-frame metadata by package-focus-pixel-timing.ps1.", "// Focus normal attacks play at 30 source ticks/sec (20% shorter); skills stay at 24.", "import 'battle_state_controller.dart';", '', 'const pixelBattleTiming = <String, RunnerConfig>{')
foreach ($female in @($false, $true)) {
    for ($number = 1; $number -le 10; $number++) {
        $id = 'character_{0:00}' -f $number
        if ($female) { $id += '_female' }
        $attack = Get-Content -LiteralPath (Join-Path $assetRoot "$($id)_attack.json") -Raw | ConvertFrom-Json
        $skill = Get-Content -LiteralPath (Join-Path $assetRoot "$($id)_skill.json") -Raw | ConvertFrom-Json
        $attackEvent = if ($female) { $femaleAttackEvents[$number-1] } else { $attackEvents[$number-1] }
        $skillEvent = if ($female) { $femaleSkillEvents[$number-1] } else { $skillEvents[$number-1] }
        $hits = @($attack.events | Where-Object event -eq $attackEvent | ForEach-Object { "$($_.tick)/30" })
        $release = @($skill.events | Where-Object event -eq $skillEvent)[0].tick
        if ($hits.Count -eq 0 -or $null -eq $release) { throw "Missing combat event for $id" }
        $lines += "  '$id': RunnerConfig(attackSeconds: .44, normalAttackDurationSeconds: $($attack.timeline.Count)/30, normalAttackHitTimes: [$($hits -join ', ')], sousenDurationSeconds: $($skill.timeline.Count)/24, sousenDamageTimeSeconds: $release/24, pixelSkillName: '$($skillNames[$number-1])'),"
    }
}
$lines += '};'
[IO.File]::WriteAllLines((Join-Path $taskRoot 'mobile/lib/game/runner/pixel_battle_timing.dart'), $lines, [Text.UTF8Encoding]::new($false))
