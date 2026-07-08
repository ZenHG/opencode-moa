# T2-moa-smoke-guide.ps1 — MoA 冒烟验证引导 (人工)

Write-Host "`n=== Layer 2: MoA 冒烟验证 ===" -ForegroundColor Cyan
Write-Host "`n请在 OpenCode 中依次执行以下操作：`n" -ForegroundColor White

Write-Host "[1] /moa-medium 完整流程" -ForegroundColor Yellow
Write-Host "  操作：/moa-medium 帮我写一个文件读取工具函数"
Write-Host "  预期：工具人搜材料 → 3 中级意见并行 → 融合输出`n"

Write-Host "[2] /moa-flagship 完整流程" -ForegroundColor Yellow
Write-Host "  操作：/moa-flagship 设计一个用户权限系统"
Write-Host "  预期：3 旗舰意见 → 融合 → 实现 → 质检`n"

Write-Host "[3] /moa-frontend 完整流程" -ForegroundColor Yellow
Write-Host "  操作：/moa-frontend 做一个登录表单页面"
Write-Host "  预期：还原+逻辑+动效 → 总工融合`n"

Write-Host "[4] /moa-quick 简单任务" -ForegroundColor Yellow
Write-Host "  操作：/moa-quick 把这段文字翻译成英文：Hello World"
Write-Host "  预期：闪电侠一步到位`n"

Write-Host "[5] /moa-describe 截图转文字" -ForegroundColor Yellow
Write-Host "  操作：/moa-describe [粘贴一张截图]"
Write-Host "  预期：视觉翻译官精确还原截图内容`n"

Write-Host "[6] 门童降级" -ForegroundColor Yellow
Write-Host "  操作：输入一个超长复杂需求"
Write-Host "  预期：门童走旗舰流程，失败则降级到内置 agent`n"

Write-Host "以上 6 项全部通过后 Layer 2 验证完成。" -ForegroundColor Green
