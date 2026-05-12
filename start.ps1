#Requires -Version 5.1
# Claude OS - Start MCP Server (Windows)
# Usage: .\start.ps1
# For full services (Redis, workers, frontend), use start_all_services.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectDir = $PSScriptRoot
$VenvPython = Join-Path $ProjectDir "venv\Scripts\python.exe"
$McpServer = Join-Path $ProjectDir "mcp_server\claude_code_mcp.py"
$DataDir = Join-Path $ProjectDir "data"
$LogsDir = Join-Path $ProjectDir "logs"

# Ensure data and logs directories exist
@($DataDir, $LogsDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# Check venv exists
if (-not (Test-Path $VenvPython)) {
    Write-Host "  [XX] Virtual environment not found at $VenvPython" -ForegroundColor Red
    Write-Host "  Run .\setup-claude-os.ps1 first." -ForegroundColor Yellow
    exit 1
}

# Check MCP server file
if (-not (Test-Path $McpServer)) {
    Write-Host "  [XX] MCP server not found at $McpServer" -ForegroundColor Red
    exit 1
}

# Kill any existing MCP server on port 8051
$conn = Get-NetTCPConnection -LocalPort 8051 -State Listen -ErrorAction SilentlyContinue
if ($conn) {
    $pid = $conn | Select-Object -First 1 -ExpandProperty OwningProcess
    if ($pid -and $pid -ne 0) {
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
}

# Start MCP server (stdin/stdout mode)
Write-Host ""
Write-Host "  Claude OS MCP Server" -ForegroundColor Cyan
Write-Host ("  " + "-" * 50) -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Server: $McpServer" -ForegroundColor DarkGray
Write-Host "  Python: $VenvPython" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

$env:SQLITE_DB_PATH = Join-Path $DataDir "claude-os.db"

& $VenvPython $McpServer
