#!/usr/bin/env python3
"""Regenerate Metrics.csv derived values from the checklist CSVs.

Usage: python3 .ui-audit/regenerate.py [--manual-xlsx Manual_Checklist_GSUSA.csv.xlsx|owner.csv]

With --manual-xlsx, the manual checklist answers are taken from the owner's
workbook; otherwise the existing CSVs are used as-is. Measured values
(browser.*, code.*, components.*, topIssues.*) are never touched.
Score formula: passed / reviewed, per phase and overall. Rows answered N/A are
not reviewed: they count toward 'notApplicable' and are excluded from every
denominator.
"""
import argparse
import collections
import csv
import re
import shutil
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).resolve().parent
ANSWER = 'Implemented? (Yes / No)'
NS = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
PHASE_KEYS = {
    'Discovery': 'discovery', 'Content Quality': 'contentQuality',
    'Internationalization': 'internationalization', 'Design': 'design',
    'User Experience': 'userExperience', 'Visual Design': 'visualDesign',
    'Setup': 'setup', 'Development': 'development',
    'Architecture & Code Review': 'architectureReview', 'Testing': 'testing',
    'Security': 'security', 'Performance': 'performance',
    'Accessibility': 'accessibility', 'Author Validation': 'authorValidation',
    'Pre-GoLive': 'preGoLive', 'Post-GoLive': 'postGoLive',
    'Process & Governance': 'processGovernance',
}
RISK_LOW, RISK_MEDIUM = 80, 60


def read_xlsx(path):
    z = zipfile.ZipFile(path)
    shared = []
    if 'xl/sharedStrings.xml' in z.namelist():
        for si in ET.fromstring(z.read('xl/sharedStrings.xml')).findall('m:si', NS):
            shared.append(''.join(t.text or '' for t in si.iter('{%s}t' % NS['m'])))
    root = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows = []
    for row in root.find('m:sheetData', NS):
        cells = {}
        for cell in row:
            col = re.match(r'[A-Z]+', cell.get('r')).group()
            value = cell.find('m:v', NS)
            if cell.get('t') == 's' and value is not None:
                cells[col] = shared[int(value.text)]
            else:
                cells[col] = value.text if value is not None else ''
        rows.append(cells)
    header = rows[0]
    return [{header[k]: r.get(k, '') for k in header} for r in rows[1:]]


def load_csv(path):
    raw = path.read_text(newline='')
    newline = '\r\n' if '\r\n' in raw else '\n'
    with path.open(newline='') as handle:
        return list(csv.DictReader(handle)), newline


def save_csv(path, rows, newline):
    with path.open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()), lineterminator=newline)
        writer.writeheader()
        writer.writerows(rows)


def fmt(value):
    return f'{value:.1f}'.rstrip('0').rstrip('.')


def pct(passed, total):
    return round(100 * passed / total, 1) if total else 0


def apply_owner_manual(xlsx_path):
    path = HERE / 'Manual_Checklist.csv'
    rows, newline = load_csv(path)
    if xlsx_path.suffix == '.xlsx':
        owner = read_xlsx(xlsx_path)
    else:
        owner = load_csv(xlsx_path)[0]
    if len(owner) != len(rows):
        sys.exit(f'row count differs: workbook {len(owner)}, csv {len(rows)}')
    flipped = 0
    for row, answer in zip(rows, owner):
        if row['Checklist Item'] != answer['Checklist Item']:
            sys.exit(f"checklist item mismatch: {row['Checklist Item'][:60]}")
        value = answer[ANSWER].strip()
        if value not in ('Yes', 'No'):
            sys.exit(f'unexpected answer {value!r}')
        if value == row[ANSWER]:
            continue
        previous = row['Comments']
        row[ANSWER] = value
        row['Comments'] = (
            'Owner attestation from Manual_Checklist_GSUSA (workbook dated 2026-10-30). '
            f'No supporting evidence attached. Earlier source review found: {previous}'
            if value == 'Yes' else f'Owner marked No. Earlier source review: {previous}'
        )
        flipped += 1
    save_csv(path, rows, newline)
    print(f'manual rows changed from workbook: {flipped}')


def recompute():
    checklists = {}
    for key, name in (('browserAudit', 'Browser_Audit'), ('codeAudit', 'Code_Audit'),
                      ('manualAudit', 'Manual')):
        checklists[key] = load_csv(HERE / f'{name}_Checklist.csv')[0]
    everything = [row for rows in checklists.values() for row in rows]
    failed = [r for r in everything if r[ANSWER] == 'No']
    passed = sum(r[ANSWER] == 'Yes' for r in everything)
    reviewed = [r for r in everything if r[ANSWER] in ('Yes', 'No')]

    values = {}
    for key, rows in checklists.items():
        ok = sum(r[ANSWER] == 'Yes' for r in rows)
        values[f'summary.{key}.passed'] = ok
        values[f'summary.{key}.failed'] = sum(r[ANSWER] == 'No' for r in rows)
        values[f'summary.{key}.notApplicable'] = sum(r[ANSWER] not in ('Yes', 'No') for r in rows)
    values.update({
        'summary.overall.passed': passed,
        'summary.overall.failed': len(failed),
        'summary.overall.notApplicable': len(everything) - len(reviewed),
        'summary.overall.mandatoryFailed': sum(r['Mandatory'] == 'Yes' for r in failed),
        'summary.overall.criticalFailed': sum(r['Importance'] == 'Critical' for r in failed),
        'summary.overall.highFailed': sum(r['Importance'] == 'High' for r in failed),
        'summary.overall.mediumFailed': sum(r['Importance'] == 'Medium' for r in failed),
        'scores.overall': pct(passed, len(reviewed)),
    })

    phases = collections.defaultdict(lambda: [0, 0])
    for r in reviewed:
        phases[r['Phase']][0] += 1
        phases[r['Phase']][1] += r[ANSWER] == 'Yes'
    for phase, key in PHASE_KEYS.items():
        total, ok = phases[phase]
        score = pct(ok, total)
        values[f'scores.{key}'] = score
        values[f'risk.{key}'] = 'Low' if score >= RISK_LOW else 'Medium' if score >= RISK_MEDIUM else 'High'

    def pass_rate(selector):
        scope = [r for r in reviewed if selector(r)]
        return pct(sum(r[ANSWER] == 'Yes' for r in scope), len(scope))

    mandatory_failed = values['summary.overall.mandatoryFailed']
    values.update({
        'status.mandatoryPassRate': pass_rate(lambda r: r['Mandatory'] == 'Yes'),
        'status.criticalPassRate': pass_rate(lambda r: r['Importance'] == 'Critical'),
        'status.highPassRate': pass_rate(lambda r: r['Importance'] == 'High'),
        'status.totalBlockingIssues': mandatory_failed,
        'trend.totalIssues': len(failed),
        'trend.criticalIssues': values['summary.overall.criticalFailed'],
        'trend.overallCompliance': values['scores.overall'],
        'trend.accessibilityCompliance': values['scores.accessibility'],
        'trend.performanceCompliance': values['scores.performance'],
        'trend.securityCompliance': values['scores.security'],
        'trend.developmentCompliance': values['scores.development'],
    })
    if mandatory_failed == 0:
        values['status.goLiveReady'] = 'Yes'

    metrics_path = HERE / 'Metrics.csv'
    raw = metrics_path.read_text(newline='')
    newline = '\r\n' if '\r\n' in raw else '\n'
    with metrics_path.open(newline='') as handle:
        metrics = list(csv.reader(handle))

    manual_rows = checklists['manualAudit']
    manual_keys = [r for r in metrics if r and r[0].startswith('manual.')]
    # one checklist row (RTL, text expansion, locale formatting) drives three flags
    expansion = {'Internationalization': 3}
    flags, cursor = [], 0
    for row in manual_rows:
        count = expansion.get(row['Phase'], 1)
        flags.extend([row[ANSWER] != 'No'] * count)
        cursor += count
    if len(flags) != len(manual_keys):
        sys.exit(f'manual flag count {len(manual_keys)} does not match rows ({len(flags)})')
    for entry, value in zip(manual_keys, flags):
        entry[1] = '1' if value else '0'

    changed = 0
    for entry in metrics:
        if entry and entry[0] in values:
            value = values[entry[0]]
            text = fmt(value) if isinstance(value, float) else str(value)
            if entry[1] != text:
                entry[1] = text
                changed += 1
    with metrics_path.open('w', newline='') as handle:
        csv.writer(handle, lineterminator=newline).writerows(metrics)
    print(f"metrics values changed: {changed} (+ manual flags)")
    print(f"overall: {passed}/{len(reviewed)} = {values['scores.overall']}% (N/A excluded: {len(everything) - len(reviewed)})")
    for phase, key in PHASE_KEYS.items():
        print(f"  {phase:28s} {values['scores.' + key]:>5} {values['risk.' + key]}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--manual-xlsx')
    args = parser.parse_args()
    if args.manual_xlsx:
        archive = HERE / 'archive' / 'before-owner-manual-checklist'
        archive.mkdir(parents=True, exist_ok=True)
        for name in ('Manual_Checklist.csv', 'Metrics.csv'):
            target = archive / name
            if not target.exists():
                shutil.copy2(HERE / name, target)
        apply_owner_manual(HERE / args.manual_xlsx)
    recompute()
