# PARA Migration Script
$ErrorActionPreference = "Stop"
$root = "C:\Users\matheus.dias\source\l4tn_pkm\pages"

Write-Host "=== PARA Migration Starting ===" -ForegroundColor Cyan

# Backup first
$backupPath = "C:\Users\matheus.dias\source\l4tn_pkm_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "`n[BACKUP] Creating backup at: $backupPath" -ForegroundColor Yellow
Copy-Item -Path $root -Destination $backupPath -Recurse

# Migrate Projects
Write-Host "`n[1/4] Migrating Projects..." -ForegroundColor Green
Move-Item "$root\10_Work\13_Projects\Impulso" "$root\01_Projects\Impulso" -Force
Move-Item "$root\10_Work\13_Projects\Tonico" "$root\01_Projects\Tonico" -Force
Move-Item "$root\10_Work\13_Projects\WHG" "$root\01_Projects\WHG" -Force
Move-Item "$root\10_Work\14_Work_Sprints\14.01_Prisma_Sprint" "$root\01_Projects\Prisma_Sprint" -Force

# Consolidate WHG sprints
Move-Item "$root\10_Work\14_Work_Sprints\14.02_WHG_Sprints\*" "$root\01_Projects\WHG\Sprints\" -Force
Move-Item "$root\10_Work\14_Work_Sprints\Whg\*" "$root\01_Projects\WHG\" -Force

# Migrate Resources
Write-Host "`n[2/4] Migrating Resources..." -ForegroundColor Green
Move-Item "$root\10_Work\11_Strategy" "$root\03_Resources\Work_Strategy" -Force
Move-Item "$root\10_Work\12_Tech" "$root\03_Resources\Tech_Knowledge" -Force
Move-Item "$root\10_Work\10_Knowledge" "$root\03_Resources\Knowledge_Base" -Force
Move-Item "$root\10_Work\11_Literature" "$root\03_Resources\Literature" -Force

# Migrate Areas
Write-Host "`n[3/4] Migrating Areas..." -ForegroundColor Green
New-Item -ItemType Directory "$root\02_Areas\Work" -Force
New-Item -ItemType Directory "$root\02_Areas\Personal" -Force
New-Item -ItemType Directory "$root\02_Areas\Studies" -Force

Move-Item "$root\20_PersonalHobbies\*" "$root\02_Areas\Personal\" -Force -Recurse
Move-Item "$root\40_Studies\*" "$root\02_Areas\Studies\" -Force -Recurse

# Archive old travel logs
Write-Host "`n[4/4] Archiving Travel Logs..." -ForegroundColor Green
New-Item -ItemType Directory "$root\04_Archives\Travel_2025" -Force
Move-Item "$root\20_PersonalHobbies\28_Travel" "$root\04_Archives\Travel_2025\" -Force

# Cleanup empty directories
Write-Host "`n[CLEANUP] Removing empty directories..." -ForegroundColor Yellow
Remove-Item "$root\10_Work" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$root\20_PersonalHobbies" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$root\40_Studies" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n=== Migration Complete! ===" -ForegroundColor Cyan
Write-Host "Backup saved at: $backupPath" -ForegroundColor Green
