#!/usr/bin/env node
// moa-loop MCP server — 长程自完善状态控制面
// 暴露 state/roadmap/blockers/足迹 读写工具，供门童在会话内经 MCP 维护状态机
// 状态文件: <MOA_LOOP_DIR 或 cwd>/.moa/longloop/state.json + 足迹.md
// 协议: stdio newline-delimited JSON-RPC 2.0 (MCP)

const fs = require("fs");
const path = require("path");

const baseDir = process.env.MOA_LOOP_DIR || process.cwd();
const stateDir = path.join(baseDir, ".moa", "longloop");
const stateFile = path.join(stateDir, "state.json");
const footprintFile = path.join(stateDir, "足迹.md");
const lockFile = path.join(stateDir, ".lock");

const VALID_STATUS = ["open", "in_progress", "done", "blocked"];

function readState() {
  if (!fs.existsSync(stateFile)) {
    throw new Error(`state.json 不存在: ${stateFile}（先用 long-loop.ps1 初始化）`);
  }
  return JSON.parse(fs.readFileSync(stateFile, "utf8"));
}

function writeState(state) {
  state.updated_at = new Date().toISOString();
  const tmp = stateFile + ".tmp";
  fs.writeFileSync(tmp, JSON.stringify(state, null, 2), "utf8");
  fs.renameSync(tmp, stateFile);
}

function withLock(fn) {
  for (let i = 0; i < 50; i++) {
    try {
      const fd = fs.openSync(lockFile, "wx");
      try { return fn(); } finally { fs.closeSync(fd); fs.unlinkSync(lockFile); }
    } catch (e) {
      if (e.code !== "EEXIST") throw e;
      const wait = new Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 100);
      if (!wait) { /* sleep fallback */ }
    }
  }
  throw new Error("moa-loop: 状态文件被占用（并发写），请稍后重试");
}

function ok(text) { return { content: [{ type: "text", text }] }; }
function err(text) { return { content: [{ type: "text", text }], isError: true }; }

const tools = [
  {
    name: "moa_state_read",
    description: "读取长程自完善状态文件全文（goal/phase/roadmap/blockers/finished）。每轮取证第一步。",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "moa_roadmap_add",
    description: "按 goal 新开一项 roadmap 任务（status=open）。返回新任务 id（t1、t2…）。",
    inputSchema: {
      type: "object",
      properties: { title: { type: "string", description: "任务标题（含验收要点）" } },
      required: ["title"], additionalProperties: false,
    },
  },
  {
    name: "moa_roadmap_update",
    description: "更新 roadmap 任务状态与现场笔记（in_progress/done/blocked + note 保留进度）。",
    inputSchema: {
      type: "object",
      properties: {
        id: { type: "string", description: "任务 id（如 t1）" },
        status: { type: "string", enum: VALID_STATUS },
        note: { type: "string", description: "进度现场：做到哪/下一步/验证结果" },
      },
      required: ["id"], additionalProperties: false,
    },
  },
  {
    name: "moa_blockers_add",
    description: "挂起一个拦路虎（要人决策/外部凭证/破坏性操作）。任务保持 open 换别的做。question 三段式：具体阻塞条件+已尝试的诊断+精确恢复条件（等谁/等什么）。",
    inputSchema: {
      type: "object",
      properties: {
        question: { type: "string", description: "三段式：①具体阻塞条件（因为什么）②已尝试的诊断 ③恢复条件（得到什么/谁答复后恢复）" },
        context: { type: "string", description: "背景证据（简短）" },
        attempted: { type: "string", description: "已尝试的诊断（可选，缺失时兜底为未尝试）" },
        resume: { type: "string", description: "精确恢复条件（可选，等什么信号恢复）" },
      },
      required: ["question"], additionalProperties: false,
    },
  },
  {
    name: "moa_blockers_resolve",
    description: "移除拦路虎（用户答复或已解决）。移除后若全部任务 done/blocked 且 blockers 空，应置 finished。",
    inputSchema: {
      type: "object",
      properties: { index: { type: "number", description: "blockers 数组下标" } },
      required: ["index"], additionalProperties: false,
    },
  },
  {
    name: "moa_footprint_append",
    description: "足迹.md 追加一行（append-only 历史，防遗忘）。格式: 任务/做了什么/验证/结果。evidence 用 ref（commit:/smoke:/pr:/run:），不用散文。",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "roadmap id + 标题" },
        did: { type: "string", description: "一句话：做了什么" },
        verify: { type: "string", description: "验证命令+结果，或「未验证」" },
        result: { type: "string", enum: ["done", "blocked", "partial"], description: "结果（partial 需 note 保留进度）" },
        evidence: { type: "string", description: "证据 ref（可选）：commit:<sha> / smoke:<用例名> / pr:<编号> / run:<运行id>；todo 完成/自述不算证据" },
      },
      required: ["task", "did", "result"], additionalProperties: false,
    },
  },
  {
    name: "moa_heartbeat",
    description: "心跳判定：读取状态并给出本轮建议（应跑/等待用户/该停止/下个候选任务）。loopx 式 should-run。",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "moa_finish",
    description: "终态收官：仅当 roadmap 全部 done/blocked 且 blockers 为空才置 finished=true。任何 open 任务或未决 blocker 都会被拒绝（防提前收尾）。",
    inputSchema: {
      type: "object",
      properties: { note: { type: "string", description: "收尾理由（可选，写入足迹）" } },
      required: [], additionalProperties: false,
    },
  },
];

function callTool(name, args) {
  switch (name) {
    case "moa_state_read": {
      return ok(JSON.stringify(readState(), null, 2));
    }
    case "moa_roadmap_add": {
      return withLock(() => {
        const s = readState();
        const next = s.roadmap.length + 1;
        const id = "t" + next;
        s.roadmap.push({ id, title: args.title, status: "open", note: "" });
        writeState(s);
        return ok(`已新增任务 ${id}: ${args.title}`);
      });
    }
    case "moa_roadmap_update": {
      return withLock(() => {
        const s = readState();
        const t = s.roadmap.find((x) => x.id === args.id);
        if (!t) throw new Error(`任务 ${args.id} 不存在`);
        if (args.status) t.status = args.status;
        if (args.note !== undefined) t.note = args.note;
        writeState(s);
        return ok(`已更新 ${args.id}: status=${t.status}`);
      });
    }
    case "moa_blockers_add": {
      return withLock(() => {
        const s = readState();
        s.blockers.push({
          question: args.question,
          context: args.context || "",
          attempted: args.attempted || "",
          resume: args.resume || "",
          since: new Date().toISOString(),
        });
        writeState(s);
        return ok(`已挂起拦路虎: ${args.question}`);
      });
    }
    case "moa_blockers_resolve": {
      return withLock(() => {
        const s = readState();
        if (args.index < 0 || args.index >= s.blockers.length) throw new Error(`blockers 下标 ${args.index} 越界`);
        const [removed] = s.blockers.splice(args.index, 1);
        writeState(s);
        return ok(`已移除拦路虎: ${removed.question}`);
      });
    }
    case "moa_footprint_append": {
      const line = [
        `## ${args.task}（${new Date().toISOString()}）`,
        `- 做了什么：${args.did}`,
        `- 验证：${args.verify || "未验证"}`,
        `- 证据：${args.evidence || "无 ref（todo 完成/自述不算证据）"}`,
        `- 结果：${args.result}${args.result === "partial" ? "（note 保留进度）" : ""}`,
      ].join("\n");
      fs.mkdirSync(stateDir, { recursive: true });
      fs.appendFileSync(footprintFile, "\n" + line + "\n", "utf8");
      return ok(`已追加足迹: ${args.task} → ${args.result}`);
    }
    case "moa_finish": {
      return withLock(() => {
        const s = readState();
        const open = s.roadmap.filter((t) => t.status === "open" || t.status === "in_progress");
        if (open.length > 0) throw new Error(`拒绝收官：仍有 ${open.length} 个 open/in_progress 任务（${open.map((t) => t.id).join(",")}）`);
        if (s.blockers.length > 0) throw new Error(`拒绝收官：仍有 ${s.blockers.length} 个未决拦路虎`);
        s.finished = true;
        s.phase = "finished";
        writeState(s);
        if (args.note) {
          fs.mkdirSync(stateDir, { recursive: true });
          fs.appendFileSync(footprintFile, `\n## 终态收官（${new Date().toISOString()}）\n- 理由：${args.note}\n`, "utf8");
        }
        return ok(`已收官：roadmap 全 done/blocked + blockers 空 → finished=true。循环将在下轮停止。`);
      });
    }
    case "moa_heartbeat": {
      const s = readState();
      const open = s.roadmap.filter((t) => t.status === "open" || t.status === "in_progress");
      const next = open.length > 0 ? `${open[0].id} ${open[0].title}` : "无 open 任务";
      let recommendation = "run";
      if (s.finished || s.phase === "finished") recommendation = "stop";
      else if (s.phase === "waiting_user") recommendation = "wait_user";
      else if (open.length === 0) recommendation = "new_task";
      return ok(JSON.stringify({
        phase: s.phase,
        finished: s.finished,
        open_tasks: open.length,
        total_tasks: s.roadmap.length,
        blockers: s.blockers.length,
        next_candidate: next,
        recommendation,
      }, null, 2));
    }
    default:
      return err(`未知工具: ${name}`);
  }
}

// ── stdio JSON-RPC 循环 ──
const readline = require("readline");
const rl = readline.createInterface({ input: process.stdin, terminal: false });
rl.on("line", (line) => {
  if (!line.trim()) return;
  let msg;
  try { msg = JSON.parse(line); } catch { return; }
  if (msg.method === "initialize") {
    respond(msg.id, {
      protocolVersion: msg.params?.protocolVersion || "2024-11-05",
      capabilities: { tools: { listChanged: false } },
      serverInfo: { name: "moa-loop", version: "1.0.0" },
    });
    return;
  }
  if (msg.method === "notifications/initialized" || msg.method === "notifications/cancelled") return;
  if (msg.method === "ping") { respond(msg.id, {}); return; }
  if (msg.method === "tools/list") {
    respond(msg.id, { tools });
    return;
  }
  if (msg.method === "tools/call") {
    const name = msg.params?.name;
    const args = msg.params?.arguments || {};
    try {
      respond(msg.id, callTool(name, args));
    } catch (e) {
      respond(msg.id, err(String(e.message || e)));
    }
    return;
  }
  respond(msg.id, err(`未知方法: ${msg.method}`));
});
function respond(id, result) {
  process.stdout.write(JSON.stringify({ jsonrpc: "2.0", id, result }) + "\n");
}
