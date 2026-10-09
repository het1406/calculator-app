"""Exercise the installed release APK using Android's accessibility tree."""
import os
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADB = os.environ.get('ADB', str(Path.home() / 'Library/Android/sdk/platform-tools/adb'))
SCREENSHOTS = ROOT / 'docs/screenshots'
SCREENSHOTS.mkdir(exist_ok=True)


def adb(*args):
    return subprocess.check_output([ADB, *args])


def nodes():
    adb('shell', 'uiautomator', 'dump', '/sdcard/calculator-window.xml')
    xml = adb('exec-out', 'cat', '/sdcard/calculator-window.xml')
    return list(ET.fromstring(xml).iter('node'))


def label(node):
    return node.get('content-desc') or node.get('text') or ''


def tap(name):
    node = next((n for n in nodes() if label(n) == name), None)
    if node is None:
        raise AssertionError(f'Control not found: {name}')
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.get('bounds')))
    adb('shell', 'input', 'tap', str((x1+x2)//2), str((y1+y2)//2))
    time.sleep(0.15)


def expect(name):
    labels = [label(n) for n in nodes()]
    assert name in labels, f'{name!r} not in {labels!r}'


def capture(name):
    (SCREENSHOTS / f'{name}.png').write_bytes(adb('exec-out', 'screencap', '-p'))


results = []
for sequence, expected in [
    (['All clear', '1', '2', 'Add', '7', 'Equals'], 'Display 19'),
    (['All clear', '3', 'Subtract', '8', 'Equals'], 'Display -5'),
    (['All clear', '8', 'Multiply', '7', 'Equals'], 'Display 56'),
    (['All clear', '9', 'Divide', '2', 'Equals'], 'Display 4.5'),
]:
    for key in sequence:
        tap(key)
    expect(expected)
    results.append(f"PASS: {' → '.join(sequence)} → {expected}")
    print(results[-1], flush=True)
    if expected == 'Display 56':
        capture('result')

tap('Dark theme')
expect('Display 4.5')
capture('dark')
results.append('PASS: theme switch preserves result 4.5')
print(results[-1], flush=True)
for key in ['All clear', '7', 'Divide', '0', 'Equals']:
    tap(key)
expect('Error: Cannot divide by zero')
capture('error')
results.append('PASS: division by zero shows recoverable error')
print(results[-1], flush=True)
for key in ['3', 'Add', '2', 'Equals']:
    tap(key)
expect('Display 5')
results.append('PASS: digit after error starts fresh; 3 + 2 = 5')
print(results[-1], flush=True)
for key in ['All clear', '8', 'Add', 'Equals']:
    tap(key)
expect('Error: Enter two numbers and an operator')
tap('All clear')
expect('Display 0')
results.append('PASS: incomplete operation reports error; AC resets display')
print(results[-1], flush=True)
text = '# Release APK verification\n\nDate: October 8, 2026 (America/New_York).\n\n'
text += 'Device: Pixel_4a Android emulator, ARM64. Release APK installed using adb install -r and launched successfully.\n\n'
text += '\n\n'.join(results)
text += '\n\nScreenshots: docs/screenshots/result.png, dark.png, error.png.\n'
text += '\nTests used Android UI automation against the installed release APK. Human TalkBack listening, physical-device testing, and LMS upload have not been performed.\n'
(ROOT / 'docs/device-verification.md').write_text(text)
