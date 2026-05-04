Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$bridgeScript = Join-Path $repoRoot "tools\memorybridge\sync_mempalace_to_contextlattice.py"

function Invoke-BridgePythonProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Code
    )

    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        throw "python command is required for MemoryBridge tests."
    }

    $script = @"
import importlib.util
import pathlib
import sys
import types

bridge_path = pathlib.Path(r"$bridgeScript")
chromadb_stub = types.ModuleType("chromadb")
chromadb_stub.PersistentClient = object
sys.modules["chromadb"] = chromadb_stub

spec = importlib.util.spec_from_file_location("bridge_module", bridge_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

$Code
"@

    return $script | python -
}

Describe "MemoryBridge retry handling" {
    It "classifies retryable connection errors without raising secondary failures" {
        $result = Invoke-BridgePythonProbe -Code @'
import errno
import json

exc = OSError(errno.ECONNREFUSED, "Connection refused")
print(json.dumps({"retryable": module._is_retryable_error(exc)}))
'@

        $LASTEXITCODE | Should Be 0
        ($result | Out-String | ConvertFrom-Json).retryable | Should Be $true
    }

    It "retries transient connection failures and succeeds when the endpoint recovers" {
        $result = Invoke-BridgePythonProbe -Code @'
import errno
import json

attempts = {"count": 0}

class FakeResponse:
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def read(self):
        return b'{"ok": true}'

def fake_urlopen(req, timeout=None):
    attempts["count"] += 1
    if attempts["count"] < 3:
        raise OSError(errno.ECONNREFUSED, "Connection refused")
    return FakeResponse()

module.request.urlopen = fake_urlopen
module.time.sleep = lambda _: None
result = module._get_json_with_retry(
    "http://example.test/status",
    "integration-test-key",
    timeout=1,
    max_retries=3,
    retry_delay=0.01,
)

print(json.dumps({"attempts": attempts["count"], "ok": result["ok"]}))
'@

        $LASTEXITCODE | Should Be 0
        $payload = $result | Out-String | ConvertFrom-Json
        $payload.attempts | Should Be 3
        $payload.ok | Should Be $true
    }
}