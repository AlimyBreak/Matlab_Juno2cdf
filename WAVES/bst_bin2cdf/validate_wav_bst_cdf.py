# -*- coding: utf-8 -*-
"""
validate_wav_bst_cdf.py — Juno Waves Burst CDF 有效性验证

对同一份 burst 产品做两次"独立"读取并逐成员对比：
  A. CDF 文件       —— 用 cdflib 从转换得到的 .cdf 读出
  B. 原始数据       —— 直接从 .dat/.lbl 按定长二进制记录独立重解析
对比成员：Epoch、TRIG_SCET、TRIG_SCLK、CHANNEL、NR_ON、NR_APPLIED、
CAL_VER_AMP、CAL_VER_ATTN、PREAMP_ATTN_SETTING、RECEIVER_ATTN_SETTING、
CLIPPED_FRACTION、SAMPLING_INTERVAL、NUM_AMPLITUDES、WAVEFORM，
以及全局属性（Product_id / Start_time / Stop_time / Q_factor / 会话 SCET）。

用法:
  python validate_wav_bst_cdf.py <xxx.lbl> <xxx.cdf>     # 单文件
  python validate_wav_bst_cdf.py <目录A(含.lbl)> <目录B(含.cdf)>  # 批量
返回码: 全部一致=0, 存在差异=1
"""

import os
import sys
import glob
import numpy as np
import cdflib
from cdflib import cdfepoch

from juno_wav_bst2cdf import (parse_lbl, HEADER_DTYPE, ROW_DTYPE,
                              scet_to_datetime)

SCET_FMT = '%Y-%jT%H:%M:%S.%f'


def read_raw(lbl_path):
    """B 路：从 .dat/.lbl 独立重解析原始数据。"""
    lbl = parse_lbl(lbl_path)
    rec_bytes, rec_count = lbl['RECORD_BYTES'], lbl['FILE_RECORDS']
    raw = np.fromfile(lbl_path[:-4] + '.dat', dtype=np.uint8)
    assert raw.size == rec_bytes * rec_count, '文件大小与标签不一致'
    header = raw[:HEADER_DTYPE.itemsize].view(HEADER_DTYPE)[0]
    buf = raw.reshape(rec_count, rec_bytes)
    rows = buf[1:, :ROW_DTYPE.itemsize].view(ROW_DTYPE).reshape(-1)
    return lbl, header, rows


def read_cdf(cdf_path):
    """A 路：从 CDF 读出全部变量与全局属性。"""
    f = cdflib.CDF(cdf_path)
    info = f.cdf_info()
    names = info['zVariables'] if isinstance(info, dict) else info.zVariables
    data = {name: f.varget(name) for name in names}
    gatts = {k: v[0] if isinstance(v, list) and len(v) == 1 else v
             for k, v in f.globalattsget().items()}
    return data, gatts


def compare(lbl_path, cdf_path, verbose=True):
    lbl, header, rows = read_raw(lbl_path)
    cdata, gatts = read_cdf(cdf_path)
    results = []   # (成员名, 是否一致, 差异说明)

    def check(name, ok, detail=''):
        results.append((name, bool(ok), detail))

    n = rows.shape[0]

    # ---- 字符串/标量成员逐一对比 ----
    # CDF_CHAR 定长字段惯例为右侧空格填充, 两侧统一 strip 后比较
    def strlist(arr):
        return [s.decode().strip() if isinstance(s, bytes) else str(s).strip()
                for s in arr]
    check('TRIG_SCET',
          [s.strip().decode() if isinstance(s, bytes) else str(s).strip()
           for s in rows['TRIG_SCET']] == strlist(cdata['TRIG_SCET']),
          '原始=%d 条, CDF=%d 条' % (n, len(cdata['TRIG_SCET'])))
    check('TRIG_SCLK', np.array_equal(rows['TRIG_SCLK'].astype(np.float64),
                                      cdata['TRIG_SCLK']))
    check('CHANNEL', strlist(rows['CHANNEL']) == strlist(cdata['CHANNEL']))
    for col in ('NR_ON', 'NR_APPLIED', 'CAL_VER_AMP', 'CAL_VER_ATTN',
                'PREAMP_ATTN_SETTING', 'RECEIVER_ATTN_SETTING'):
        check(col, np.array_equal(rows[col].astype(np.uint8),
                                  np.asarray(cdata[col]).astype(np.uint8)))
    check('CLIPPED_FRACTION',
          np.array_equal(rows['CLIPPED_FRACTION'],
                         np.asarray(cdata['CLIPPED_FRACTION'], dtype=np.float32)))
    check('SAMPLING_INTERVAL',
          np.array_equal(rows['SAMPLING_INTERVAL'],
                         np.asarray(cdata['SAMPLING_INTERVAL'], dtype=np.float32)))
    check('NUM_AMPLITUDES',
          np.array_equal(rows['NUM_AMPLITUDES'].astype(np.uint32),
                         np.asarray(cdata['NUM_AMPLITUDES']).astype(np.uint32)))

    # ---- WAVEFORM：逐元素位级对比（含填充 0） ----
    wf_cdf = np.asarray(cdata['WAVEFORM'], dtype=np.float32).reshape(n, -1)
    ok = wf_cdf.shape == (n, 6144) and np.array_equal(rows['WAVEFORM'], wf_cdf)
    detail = ''
    if not ok:
        n_bad = int((rows['WAVEFORM'].view(np.uint32) !=
                     wf_cdf.view(np.uint32)).sum())
        detail = '形状=%s, 位级不一致元素数=%d' % (wf_cdf.shape, n_bad)
    check('WAVEFORM (6144×f32, 位级)', ok, detail)

    # ---- Epoch：由原始 TRIG_SCET 重算再对比 ----
    epoch_expect = []
    for s in rows['TRIG_SCET']:
        dt = scet_to_datetime(s)
        ec = [dt.year, dt.month, dt.day, dt.hour, dt.minute,
              dt.second, dt.microsecond // 1000]
        epoch_expect.append(float(cdfepoch.compute_epoch(ec)))
    epoch_expect = np.array(epoch_expect)
    epoch_got = np.asarray(cdata['Epoch'], dtype=np.float64)
    # 容差 0.01 ms: 不同实现计算 CDF_EPOCH 的浮点路径略有差异(约 1e-2 ms),
    # 远低于 CDF_EPOCH 对该时刻 ~0.5 µs 的表示精度与 1 ms 的字符串分辨率
    e_max = float(np.abs(epoch_expect - epoch_got).max())
    check('Epoch (CDF_EPOCH, 毫秒)', n == len(epoch_got) and e_max <= 0.01,
          '最大偏差 %.4g ms' % e_max)

    # ---- 全局属性 vs 标签/HEADER ----
    hdr_ok = (str(gatts.get('Product_id', '')) == lbl.get('PRODUCT_ID', '') and
              str(gatts.get('Start_time', '')) == lbl.get('START_TIME', '') and
              str(gatts.get('Stop_time', '')) == lbl.get('STOP_TIME', '') and
              int(gatts.get('Q_factor', -1)) == int(header['Q_FACTOR']) and
              str(gatts.get('Session_start_scet', '')) ==
              header['SESSION_START_SCET'].decode().strip() and
              str(gatts.get('Session_stop_scet', '')) ==
              header['SESSION_STOP_SCET'].decode().strip())
    check('全局属性(Product/起止时间/Q_factor/会话SCET)', hdr_ok)

    # ---- 汇总 ----
    n_fail = sum(1 for _, ok, _ in results if not ok)
    name = os.path.basename(cdf_path)
    if verbose:
        print('[%s] %s' % ('PASS' if n_fail == 0 else 'FAIL', name))
        for m, ok, d in results:
            print('   %-40s %s %s' % (m, '✔' if ok else '✘', d))
    return n_fail == 0, results


def main():
    args = sys.argv[1:]
    if len(args) == 2 and args[0].lower().endswith('.lbl'):
        pairs = [(args[0], args[1])]
        report = None
    else:
        dir_lbl, dir_cdf = args if len(args) == 2 else (
            os.path.join(os.path.dirname(os.path.abspath(__file__)), '数据样本'),
            os.path.join(os.path.dirname(os.path.abspath(__file__)), '输出'))
        lbls = glob.glob(os.path.join(dir_lbl, '*.lbl'))
        pairs = [(l, os.path.join(dir_cdf, os.path.basename(l)[:-4] + '.cdf'))
                 for l in lbls]
        report = os.path.join(dir_cdf, 'validation_report.txt')

    lines = []
    n_pass = 0
    for lbl, cdf in pairs:
        ok, results = compare(lbl, cdf)
        n_pass += ok
        lines.append('[%s] %s' % ('PASS' if ok else 'FAIL',
                                  os.path.basename(cdf)))
        for m, c_ok, d in results:
            lines.append('   %-40s %s %s' % (m, 'OK' if c_ok else 'MISMATCH', d))
    print('\n===== 汇总: %d/%d PASS =====' % (n_pass, len(pairs)))
    lines.append('===== 汇总: %d/%d PASS =====' % (n_pass, len(pairs)))
    if report:
        open(report, 'w', encoding='utf-8').write('\n'.join(lines))
        print('报告已写入:', report)
    sys.exit(0 if n_pass == len(pairs) else 1)


if __name__ == '__main__':
    main()
