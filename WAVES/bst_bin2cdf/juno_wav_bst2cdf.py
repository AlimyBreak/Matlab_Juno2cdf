# -*- coding: utf-8 -*-
"""
juno_wav_bst2cdf.py — Juno Waves Burst 模式原始数据 (.dat/.lbl) 转 CDF

适用产品: JNO-E/J/SS-WAV-3-CDR-BSTFULL-V2.0 中的 *_BIN_*/*_REC_* PDS3 表格式产品
  - 定长记录: RECORD_BYTES 字节/条, FILE_RECORDS 条
  - 第 1 条记录: HEADER_TABLE (135 字节有效数据 + 空填充)
  - 第 2..N 条: DATA_TABLE 行 (各变体同构布局, 行长随 RECORD_BYTES: 24652/24908/16460)
  - PC_REAL = 小端 IEEE 浮点; TIME = 23 字节 ISO8601 "CCYY-DDDTHH:MM:SS.sss"
  - WAVEFORM 列: (RECORD_BYTES-76)/4 × float32, 有效点数由 NUM_AMPLITUDES 给出

用法:
  python juno_wav_bst2cdf.py <xxx.lbl> <输出目录>
  python juno_wav_bst2cdf.py                # 默认处理 数据样本\ 下所有 .lbl

依赖: numpy, cdflib==0.4.9 (1.x 已移除写 CDF 功能)
"""

import os
import re
import sys
import glob
import datetime

import numpy as np
import cdflib
from cdflib import cdfepoch

# ---------------------------------------------------------------- PDS 标签解析

LBL_KEY_RE = re.compile(r'^\s*([A-Z_0-9]+)\s*=\s*(.+?)\s*$', re.M)


def parse_lbl(path):
    """从 PDS3 标签中提取关键字段(仅顶层标量)。"""
    text = open(path, 'r', encoding='utf-8', errors='replace').read()
    vals = {}
    for key, raw in LBL_KEY_RE.findall(text):
        raw = raw.strip().strip('"')
        if key in ('RECORD_BYTES', 'FILE_RECORDS', 'ROWS', 'ROW_BYTES'):
            vals[key] = int(raw)
        elif key in ('START_TIME', 'STOP_TIME', 'DATA_SET_ID', 'PRODUCT_ID',
                     'PRODUCT_VERSION_ID', 'INSTRUMENT_HOST_NAME',
                     'INSTRUMENT_NAME', 'MISSION_PHASE_NAME', 'STANDARD_DATA_PRODUCT_ID'):
            vals[key] = raw
    return vals


# ---------------------------------------------------------------- 记录结构定义

# HEADER_TABLE: 前 135 字节 (1-based 起始字节 → 0-based 偏移, Vn 为空填充)
HEADER_DTYPE = np.dtype([
    ('RECORD_LENGTH',      '<u4'),   # @1
    ('SESSION_START_SCLK', '<f8'),   # @5
    ('SESSION_START_SCET', 'S23'),   # @13
    ('_pad1',              'V1'),    # @36
    ('Q_FACTOR_SCLK',      '<f8'),   # @37
    ('Q_FACTOR_SCET',      'S23'),   # @45
    ('_pad2',              'V1'),    # @68
    ('PROCESSING_SCLK',    '<f8'),   # @69
    ('PROCESSING_SCET',    'S23'),   # @77
    ('_pad3',              'V1'),    # @100
    ('Q_FACTOR',           'u1'),    # @101
    ('_pad4',              'V3'),    # @102
    ('SESSION_STOP_SCLK',  '<f8'),   # @105
    ('SESSION_STOP_SCET',  'S23'),   # @113
])  # 共 135 字节

# DATA_TABLE 行: 前 77 字节列区 + N×4 字节 WAVEFORM。
# 各变体列布局完全同构, 仅 WAVEFORM 项数随 RECORD_BYTES 变化:
#   24652 → 6144 (标准 E_REC/E_BIN/B_REC 等)
#   24908 → 6208 (BUNC_REC/EUNC_REC)
#   16460 → 4096 (短行 E_REC 变体)
def make_row_dtype(rec_bytes):
    assert rec_bytes > 76 and (rec_bytes - 76) % 4 == 0, \
        'RECORD_BYTES=%d 不符合 77 字节列区 + 4N 波形布局' % rec_bytes
    n_amp = (rec_bytes - 76) // 4
    return np.dtype([
        ('CHANNEL',              'S14'),  # @1
        ('_pad1',                'V2'),   # @15
        ('TRIG_SCLK',            '<f8'),  # @17
        ('TRIG_SCET',            'S23'),  # @25
        ('_pad2',                'V1'),   # @48
        ('NR_ON',                'u1'),   # @49
        ('NR_APPLIED',           'u1'),   # @50
        ('CAL_VER_AMP',          'u1'),   # @51
        ('CAL_VER_ATTN',         'u1'),   # @52
        ('PREAMP_ATTN_SETTING',  'u1'),   # @53
        ('RECEIVER_ATTN_SETTING','u1'),   # @54
        ('_pad3',                'V6'),   # @55  (1 pad + 4 字节 mixer 占位 + 1 pad)
        ('CLIPPED_FRACTION',     '<f4'),  # @61
        ('SAMPLING_INTERVAL',    '<f4'),  # @65
        ('_pad4',                'V4'),   # @69  (首样本频率占位)
        ('NUM_AMPLITUDES',       '<u4'),  # @73
        ('WAVEFORM',             ('<f4', (n_amp,))),  # @77
    ])


# 兼容旧引用: 标准 24652 行
ROW_DTYPE = make_row_dtype(24652)


def scet_to_datetime(s):
    """'2013-282T18:05:17.532' → datetime"""
    s = s.decode('ascii').strip() if isinstance(s, bytes) else str(s).strip()
    return datetime.datetime.strptime(s, '%Y-%jT%H:%M:%S.%f')


# ---------------------------------------------------------------- 转 CDF

def convert(lbl_path, out_dir):
    lbl = parse_lbl(lbl_path)
    rec_bytes = lbl['RECORD_BYTES']
    rec_count = lbl['FILE_RECORDS']
    dat_path = lbl_path[:-4] + '.dat'
    assert os.path.exists(dat_path), '缺少数据文件: ' + dat_path

    raw = np.fromfile(dat_path, dtype=np.uint8)
    n_bytes = raw.size
    assert n_bytes == rec_bytes * rec_count, (
        '文件大小 %d ≠ RECORD_BYTES×FILE_RECORDS = %d' % (n_bytes, rec_bytes * rec_count))

    # --- header ---
    header = raw[:HEADER_DTYPE.itemsize].view(HEADER_DTYPE)[0]
    assert header['RECORD_LENGTH'] == rec_bytes, 'HEADER.RECORD_LENGTH 与标签不一致'
    sess_start = scet_to_datetime(header['SESSION_START_SCET'])
    sess_stop  = scet_to_datetime(header['SESSION_STOP_SCET'])

    # --- data rows ---
    row_dt = make_row_dtype(rec_bytes)
    rows = np.zeros(rec_count - 1, dtype=row_dt)
    buf = raw.reshape(rec_count, rec_bytes)
    for i in range(1, rec_count):
        rows[i - 1] = buf[i, :row_dt.itemsize].view(row_dt)[0]
    n_amp_dim = (rec_bytes - 76) // 4

    n_rows = rec_count - 1
    trig_dt = [scet_to_datetime(r) for r in rows['TRIG_SCET']]
    n_amps  = rows['NUM_AMPLITUDES'].astype(np.int64)
    print('  记录数: %d 行 | 会话: %s → %s | Q_FACTOR=%d'
          % (n_rows, sess_start.isoformat(), sess_stop.isoformat(), header['Q_FACTOR']))
    print('  通道: %s | 采样间隔: %s s | 有效样本: %s'
          % (sorted({r.decode().strip() for r in rows['CHANNEL']}),
             sorted({str(v) for v in rows['SAMPLING_INTERVAL']}),
             '%d ~ %d' % (n_amps.min(), n_amps.max())))

    # --- 写 CDF ---
    from cdflib.cdfwrite import CDF as CDFWriter
    base = os.path.basename(lbl_path)[:-4]
    cdf_path = os.path.join(out_dir, base + '.cdf')
    if os.path.exists(cdf_path):
        os.remove(cdf_path)
    c = CDFWriter(cdf_path)

    # 全局属性 (格式: {属性名: {条目号: 值}})
    gattrs = {
        'Project':          'JUNO',
        'Source_name':      'JUNO>Waves',
        'Discipline':       'Planetary Plasma Interactions',
        'Data_type':        'JNO-E/J/SS-WAV-3-CDR-BSTFULL-V2.0',
        'Descriptor':       'Waves burst mode waveform (calibrated)',
        'Product_id':       lbl.get('PRODUCT_ID', base),
        'Product_version':  lbl.get('PRODUCT_VERSION_ID', ''),
        'Mission_phase':    lbl.get('MISSION_PHASE_NAME', ''),
        'Start_time':       lbl.get('START_TIME', ''),
        'Stop_time':        lbl.get('STOP_TIME', ''),
        'Session_start_scet': header['SESSION_START_SCET'].decode().strip(),
        'Session_stop_scet':  header['SESSION_STOP_SCET'].decode().strip(),
        'Q_factor':         int(header['Q_FACTOR']),
        'Source_file':      os.path.basename(dat_path),
        'Source_label':     os.path.basename(lbl_path),
        'Text':             'Converted from PDS3 .dat/.lbl by juno_wav_bst2cdf.py '
                            '(cdflib 0.4.9). Waveform unit: volts/meter. '
                            'Valid samples per record given by NUM_AMPLITUDES.',
    }
    c.write_globalattrs({k: {0: v} for k, v in gattrs.items()})

    # 变量定义 (zVariable, 逐记录变化)
    epoch_comps = [[dt.year, dt.month, dt.day, dt.hour, dt.minute,
                    dt.second, dt.microsecond // 1000] for dt in trig_dt]
    epoch_vals = [float(cdfepoch.compute_epoch(ec)) for ec in epoch_comps]
    zspec = lambda name, dt, dims: {
        'Variable': name, 'Data_Type': dt, 'Num_Elements': 1,
        'Rec_Vary': True, 'Var_Type': 'zVariable', 'Dim_Sizes': dims}

    def _write(name, dt, dims, data, attrs=None, num_elems=1):
        spec = {'Variable': name, 'Data_Type': dt, 'Num_Elements': num_elems,
                'Rec_Vary': True, 'Var_Type': 'zVariable', 'Dim_Sizes': dims}
        c.write_var(spec, attrs, data)

    # 字符串变量按定长字段以空格填充 (与原始 .dat 字段风格一致,
    # cdflib 0.4.9 缺省 NUL 填充会导致与 MATLAB 版字节级不一致)
    scets = [r.decode().strip().ljust(23) for r in rows['TRIG_SCET']]
    _write('Epoch', c.CDF_EPOCH, [], epoch_vals,
           {'CATDESC': 'Trigger time, CDF_EPOCH', 'FIELDNAM': 'Epoch',
            'TIME_BASE': '0000-01-01T00:00:00.000'})
    _write('TRIG_SCET', c.CDF_CHAR, [], scets,
           {'CATDESC': 'Trigger SCET (ISO8601, CCYY-DDDTHH:MM:SS.sss)'},
           num_elems=23)
    _write('TRIG_SCLK', c.CDF_DOUBLE, [], rows['TRIG_SCLK'].astype(np.float64),
           {'CATDESC': 'Trigger SCLK'})
    _write('CHANNEL', c.CDF_CHAR, [],
           [r.decode().strip().ljust(14) for r in rows['CHANNEL']],
           {'CATDESC': 'Receiver channel name'}, num_elems=14)
    _write('NR_ON', c.CDF_UINT1, [], rows['NR_ON'].astype(np.uint8),
           {'CATDESC': 'On-board noise mitigation available'})
    _write('NR_APPLIED', c.CDF_UINT1, [], rows['NR_APPLIED'].astype(np.uint8),
           {'CATDESC': 'On-board noise mitigation applied'})
    _write('CAL_VER_AMP', c.CDF_UINT1, [], rows['CAL_VER_AMP'].astype(np.uint8),
           {'CATDESC': 'WAV_CAL_BST_DIRECT_AMP version'})
    _write('CAL_VER_ATTN', c.CDF_UINT1, [], rows['CAL_VER_ATTN'].astype(np.uint8),
           {'CATDESC': 'WAV_CAL_ATTN version'})
    _write('PREAMP_ATTN_SETTING', c.CDF_UINT1, [],
           rows['PREAMP_ATTN_SETTING'].astype(np.uint8),
           {'CATDESC': 'Preamp attenuation flag'})
    _write('RECEIVER_ATTN_SETTING', c.CDF_UINT1, [],
           rows['RECEIVER_ATTN_SETTING'].astype(np.uint8),
           {'CATDESC': 'Receiver attenuation flag'})
    _write('CLIPPED_FRACTION', c.CDF_FLOAT, [],
           rows['CLIPPED_FRACTION'].astype(np.float32),
           {'CATDESC': 'Fraction of clipped samples'})
    _write('SAMPLING_INTERVAL', c.CDF_FLOAT, [],
           rows['SAMPLING_INTERVAL'].astype(np.float32),
           {'CATDESC': 'Time between waveform samples', 'UNITS': 's'})
    _write('NUM_AMPLITUDES', c.CDF_UINT4, [],
           rows['NUM_AMPLITUDES'].astype(np.uint32),
           {'CATDESC': 'Valid samples in WAVEFORM'})
    _write('WAVEFORM', c.CDF_FLOAT, [n_amp_dim],
           rows['WAVEFORM'].astype(np.float32),
           {'CATDESC': 'Calibrated electric field waveform',
            'UNITS': 'V/m', 'FIELDNAM': 'WAVEFORM', 'DEPEND_0': 'Epoch'})

    c.close()
    print('  ✔ 已写出: %s (%.1f MB)'
          % (cdf_path, os.path.getsize(cdf_path) / 1e6))
    return cdf_path


def main():
    if len(sys.argv) >= 3:
        lbls, out_dir = sys.argv[1:2], sys.argv[2]
    else:
        here = os.path.dirname(os.path.abspath(__file__))
        lbls = glob.glob(os.path.join(here, '数据样本', '*.lbl'))
        out_dir = os.path.join(here, '输出')
    os.makedirs(out_dir, exist_ok=True)
    print('cdflib %s / numpy %s' % (cdflib.__version__, np.__version__))
    for lbl in lbls:
        print('转换: %s' % os.path.basename(lbl))
        convert(lbl, out_dir)


if __name__ == '__main__':
    main()
