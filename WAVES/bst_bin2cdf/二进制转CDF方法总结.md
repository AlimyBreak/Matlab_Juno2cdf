# Juno Waves Burst 原始二进制数据转 CDF 方法总结

**交付版本**：v1.0（2026-09-27）
**作者**：YangQiwu  alimy1990@foxmail.com
**适用数据集**：`JNO-E/J/SS-WAV-3-CDR-BSTFULL-V2.0` 的 `DATA/WAVES_BURST`（Juno Waves 爆发模式波形 CDR，PDS3 格式）

---

## 1. 任务概述与成果总账

PDS 档案中 WAVES_BURST 的每个产品是一对文件：`.lbl`（PDS3 标签，纯文本）+ `.dat`（定长二进制记录）。本项目把全部二进制波形产品转换为通用 CDF 格式，目录结构与原始数据包完全一致，仅扩展名 `.dat/.lbl → .cdf`。

| 项目 | 数量 | 备注 |
|---|---|---|
| 源 `.lbl` 产品总数 | 30,136 | 含补齐 13 个缺失文件与 3 个新轨道（ORBIT_78/79/80） |
| 成功转换 `.cdf` | **25,911**（约 76 GB） | 覆盖全部 83+3 个任务段 |
| 未转换（NBS 产品） | 4,225 | 结构性不支持，见 §2.4 |
| 转换一致性 | 100/100 严格字节级 PASS | 与 MATLAB 参考版对比，见 §5.2 |

---

## 2. 原始二进制格式解析（转换的前提）

### 2.1 PDS3 定长记录结构

`.dat` 文件 = `FILE_RECORDS` 条定长记录，每条 `RECORD_BYTES` 字节：

- **第 1 条记录**：`HEADER_TABLE`（135 字节有效数据 + 空位填充）
- **第 2..N 条**：`DATA_TABLE` 行（波形数据）

转换前必须做三重校验（任一失败即拒绝转换）：
1. `文件字节数 == RECORD_BYTES × FILE_RECORDS`；
2. header 首字段 `RECORD_LENGTH` 与标签 `RECORD_BYTES` 一致；
3. `(RECORD_BYTES − 76) % 4 == 0`（保证波形列是整数个 float32）。

### 2.2 HEADER_TABLE 字节布局（共 135 字节）

| 起始字节(1-based) | 字段 | 类型 |
|---|---|---|
| 1 | RECORD_LENGTH | u4 (LE) |
| 5 | SESSION_START_SCLK | f8 (LE) |
| 13 | SESSION_START_SCET | S23（ISO8601 `CCYY-DDDTHH:MM:SS.sss`） |
| 37 | Q_FACTOR_SCLK | f8 |
| 45 | Q_FACTOR_SCET | S23 |
| 69 | PROCESSING_SCLK | f8 |
| 77 | PROCESSING_SCET | S23 |
| 101 | Q_FACTOR | u1 |
| 105 | SESSION_STOP_SCLK | f8 |
| 113 | SESSION_STOP_SCET | S23 |

（36/68/100/102–104 为空填充字节）

### 2.3 DATA_TABLE 行布局（77 字节列区 + N×4 字节波形）

| 起始字节(1-based) | 字段 | 类型 | 说明 |
|---|---|---|---|
| 1 | CHANNEL | S14 | 通道名，如 `LFR_HI_E`、`LFR_LO_B` |
| 17 | TRIG_SCLK | f8 (LE) | 触发时刻（航天器钟） |
| 25 | TRIG_SCET | S23 | 触发时刻（地面时 `yyyy-dddTHH:MM:SS.mmm`） |
| 49 | NR_ON | u1 | 星上噪声消除可用标志 |
| 50 | NR_APPLIED | u1 | 星上噪声消除已应用标志 |
| 51 | CAL_VER_AMP | u1 | 幅度标定版本 |
| 52 | CAL_VER_ATTN | u1 | 衰减标定版本 |
| 53 | PREAMP_ATTN_SETTING | u1 | 前放衰减档 |
| 54 | RECEIVER_ATTN_SETTING | u1 | 接收机衰减档 |
| 61 | CLIPPED_FRACTION | f4 (LE) | 削波样本比例 |
| 65 | SAMPLING_INTERVAL | f4 (LE) | 采样间隔（s），采样率 = 1/该值 |
| 73 | NUM_AMPLITUDES | u4 (LE) | **有效样本数**（≤ 波形列容量） |
| 77 | WAVEFORM | N × f4 (LE) | 波形（E 通道 V/m；有效点数由 NUM_AMPLITUDES 给出，尾部为填充） |

（15–16、48、55–60、69–72 为填充/占位字节）

### 2.4 RECORD_BYTES 变体（关键！）

同一档案存在 **三种行长**，列布局完全同构，仅波形列项数不同：

| RECORD_BYTES | 波形项数 N | 产品 |
|---|---|---|
| 24,652（标准） | 6144 | E_REC / E_BIN / B_REC / B_BIN 等绝大多数 |
| 24,908 | 6208 | BUNC_REC / EUNC_REC（未做 NR 噪声消除修正版） |
| 16,460 | 4096 | FREQ_OFFSET 类短行 E_REC 变体（与 NBS 同族，仅 16 个文件） |

**因此行 dtype 必须按每个文件的 RECORD_BYTES 动态生成**（`make_row_dtype(rec_bytes)`），不能写死 6144。

**产品类型命名**：`WAV_<时间>_E/B<产品码>_V<版本>`，产品码含义——
- `REC`：record mode，连续记录波形；
- `BIN`：binning mode，星上触发择优分箱波形；
- `UNC` 后缀（BUNC/EUNC）：未做 NR（noise removal）修正；
- `NBS`：HFR_HI 3–41 MHz 窄带边带 I/Q 谱，**行结构与波形产品完全不同**（含 FREQ_OFFSET、复数 I/Q 对），本转换器**不支持**，批量时按正则跳过（清单见 `nbs_skipped.txt`）。

### 2.5 目录结构（两种形态并存）

- 早期任务段：`DATA/WAVES_BURST/<任务段>/<日目录>/<文件>`；
- 后期 ORBIT 段：`DATA/WAVES_BURST/<任务段>/<文件>`（**文件直接平铺在任务段下，没有日目录**）。

批量扫描必须两种形态都兼容（v1 曾因只按两层目录遍历漏掉 1.95 万个平铺文件）。

---

## 3. 转换方法（juno_wav_bst2cdf.py）

单文件转换流程（`convert(lbl_path, out_dir)`）：

```
.lbl → 解析关键字段(RECORD_BYTES/FILE_RECORDS/时间/产品号)
     → 读 .dat 为 uint8 字节流, 做三重校验 (§2.1)
     → 第 1 条记录按 HEADER_DTYPE 解析 → 会话起止/Q_FACTOR → 全局属性
     → 第 2..N 条逐行按 make_row_dtype(RECORD_BYTES) 解析
     → TRIG_SCET 逐条转 CDF_EPOCH
     → cdflib 0.4.9 CDFWriter 写 zVariable (逐记录变化)
     → 输出 <同名>.cdf
```

### 3.1 写入 CDF 的变量清单

| CDF 变量 | CDF 类型 | 来源 | 备注 |
|---|---|---|---|
| Epoch | CDF_EPOCH | TRIG_SCET 逐条构造 | `%Y-%jT%H:%M:%S.%f` → 7 元组 → `cdfepoch.compute_epoch` |
| TRIG_SCET | CDF_CHAR(23) | 原样 | **右侧空格填充到 23 字符**（见 §7 第 1 条） |
| TRIG_SCLK | CDF_DOUBLE | f8 原值 | |
| CHANNEL | CDF_CHAR(14) | 原样 | 空格填充到 14 字符 |
| NR_ON / NR_APPLIED / CAL_VER_AMP / CAL_VER_ATTN / PREAMP_ATTN / RECEIVER_ATTN | CDF_UINT1 | u1 原值 | |
| CLIPPED_FRACTION | CDF_FLOAT | f4 原值 | |
| SAMPLING_INTERVAL | CDF_FLOAT | f4 原值 | 单位 s |
| NUM_AMPLITUDES | CDF_UINT4 | u4 原值 | 有效样本数 |
| WAVEFORM | CDF_FLOAT, dims=[N] | f4 原值 | N 按 RECORD_BYTES 动态；UNITS=V/m |

全局属性写入：Project/Source_name/Data_type/Product_id/Start_time/Stop_time/Q_factor/Session 起止 SCET/Source_file 等，保证可溯源到原始 `.dat/.lbl` 文件名。

### 3.2 两个工程要点

1. **字符串填充必须用空格（ljust）**：cdflib 0.4.9 对定长 CDF_CHAR 缺省用 NUL（`\x00`）填充尾部，与原始 `.dat` 字段的空格填充风格不一致，会导致与 MATLAB 参考版**字节级不一致**。已改为 `.strip().ljust(23)` / `.ljust(14)`，从而达成 100/100 严格字节级一致（此前仅"strip 后等值"级一致）。
2. **先删后写**：`convert()` 写 CDF 前先 `os.remove` 已存在文件，避免续跑时追加/覆盖异常。

---

## 4. 批量转换（batch_convert_all.py，多进程）

```
python batch_convert_all.py [workers=8]
```

- **任务发现**：遍历任务段，兼容一层/两层目录形态（§2.5）；
- **NBS 过滤**：用产品名正则 `WAV_\d{7}T\d{6}_([A-Z_]+?)_V\d+\.lbl` 提取产品码判断是否以 NBS 开头（**不要按文件名前缀判断**——NBS 产品名以 `WAV_` 开头，v1 曾按 `NBS_` 前缀过滤导致一个都滤不掉）；
- **多进程**：`ProcessPoolExecutor(8)`，子进程内先 `os.makedirs(outdir)`（`convert()` 不自建目录，v1 漏掉会全部报错）再转换，并屏蔽转换器的控制台打印；
- **断点续跑**：已存在的 `.cdf` 自动跳过，可随时中断重跑；
- **日志**：`convert_summary.txt`（汇总）/ `convert_errors.txt`（失败清单及异常信息）/ `nbs_skipped.txt`（跳过清单）。

实测性能：全库 2.5 万个文件、8 进程约 3.7 小时。并发下出现过 127 个瞬时 `PermissionError`（写 CDF 时的文件锁竞争，文件实际已写盘成功）——**重跑一遍续跑模式即可确认**，不要盲目重转。

---

## 5. 验证体系（交付可信度的来源）

### 5.1 单文件双路独立对比（validate_wav_bst_cdf.py）

```
python validate_wav_bst_cdf.py <xxx.lbl> <xxx.cdf>          # 单文件
python validate_wav_bst_cdf.py <目录A(含.lbl)> <目录B(含.cdf)>  # 批量
```

对同一产品做两条**独立**读取路径并逐成员对比：A 路 = cdflib 读转换出的 CDF；B 路 = 直接从 `.dat/.lbl` 按定长记录独立重解析。对比 14 个变量 + 5 个全局属性，全部一致返回码 0。

### 5.2 与 MATLAB 参考版的移植一致性测试（md5test\）

抽 100 对不同原始数据文件，分别用 MATLAB 版转换器（压缩/非压缩两版）与 Python 版（压缩）生成三个同名 CDF，**读出数据逐字节对比**：

- 修复字符串填充（NUL → 空格）后，**100/100 严格字节级 PASS**；
- 测试程序：`md5test\batch100_prepare.py`（分层抽样 + Python 转换）、`run_batch100_test.m`（MATLAB 批量，支持续跑）、`make_batch100_report.py`（报告生成）；
- 报告：`md5test\批量一致性测试报告.md`（v2，OVERALL PASS）。

### 5.3 全库覆盖核验

- 30,136 对 dat/lbl 完全配对无缺；
- 25,911 个 CDF 落位与源目录树逐级比对一致；
- 未转换的仅 4,225 个 NBS（结构性不支持），零遗漏。

---

## 6. 运行环境与复现步骤

### 6.1 环境（重要）

| 项 | 要求 |
|---|---|
| Python | 3.10（实测 3.10.9 可用） |
| cdflib | **0.4.9（必须）** —— cdflib 1.x 已移除写 CDF 功能，装错版本无法运行 |
| numpy | 任意近期版本 |
| 隔离环境 | 建议独立 venv（本项目用 `cdfwrite310`，与只读用的 default 环境分开） |
| 读 CDF 的环境 | 注意 venv 的 python.exe 在 `Scripts\` 子目录下，不在根目录 |

### 6.2 复现命令

```bash
# 单文件转换
python juno_wav_bst2cdf.py  <xxx.lbl>  <输出目录>

# 全量批量 (8 进程, 断点续跑)
python batch_convert_all.py 8

# 单文件/批量验证
python validate_wav_bst_cdf.py <目录A(含.lbl)> <目录B(含.cdf)>
```

改代码后先做语法检查，再单文件转换 + validate，最后才跑批量。

---

## 7. 踩坑清单（必读，均为实测踩中）

1. **cdflib 0.4.9 定长字符串缺省 NUL 填充** → 与空格填充的原始字段字节级不一致；写入时必须 `ljust` 空格填充。
2. **RECORD_BYTES 三种变体**（24652/24908/16460）→ 行 dtype 必须按文件动态生成；16 个 16460 变体曾因写死 6144 全部失败，动态化后 16/16 补转成功。
3. **ORBIT 段文件平铺无日目录** → 目录扫描两层/一层都要覆盖，否则漏约 2 万文件。
4. **NBS 过滤别按前缀** → 产品名以 `WAV_` 开头，需正则提取产品码判断。
5. **convert() 不自建输出目录** → 子进程内先 `os.makedirs`。
6. **多进程并发瞬时 PermissionError** → 文件实际已写盘成功，续跑校验即可，勿盲目重转。
7. **PDS3 标签解析只取顶层标量** → `KEY = VALUE` 正则按行匹配，注意值可能带引号（strip 掉）。
8. **大文件内存**：`np.fromfile` 整文件读入（单个最大约 24,908 B × 数千条 ≈ 数十 MB，可接受）；逐行 `.view(row_dt)` 避免整块结构化拷贝。
9. **H 盘（外置盘）写限制**：沙箱/权限下已存在文件不可直接覆盖，需"先删（相对路径）再拷"。

---

## 8. 相关文件索引

| 路径 | 内容 |
|---|---|
| `juno_wav_bst2cdf.py` | 单文件转换器（本方法核心） |
| `validate_wav_bst_cdf.py` | 双路独立验证器 |
| `batch_compat_test.py` / `兼容性测试\` | 变体兼容性测试 |
| `md5test\` | 100 对移植一致性测试程序与报告 |
| `总验证报告.md` | 验证汇总 |
| `bstfull_lbl_list.txt` | 全量产品清单 |
| `数据样本\`、`输出\` | 单文件演示输入输出 |
| `H:\JNO-E_J_SS-WAV-3-CDR-BSTFULL-V2.0_cdf\` | 全量批量工程目录（batch_convert_all.py + 25,911 个 CDF + 各清单/日志） |

---

*本文档由 YangQiwu 整理，基于 juno_wav_bst2cdf.py（cdflib 0.4.9）实际转换与验证记录撰写。如需支持 NBS 产品或 16,460 B 以外新变体，请先按 §2.4 核对行布局再扩展 `make_row_dtype`。*
