"""Only approved city assembly / ambient-setting edits bypass older file hashes.
Function digests are from the untouched v0.11 ZIP, not the new implementation.
"""
from pathlib import Path
import re,json,hashlib
P=Path(__file__).resolve().parents[1]
def verify_functions(case,filename):
    source=(P/filename).read_text()
    cuts=list(re.finditer(r'^func (\w+)\(',source,re.M))
    functions={m[1]:source[m.start():cuts[i+1].start() if i+1<len(cuts) else len(source)].strip() for i,m in enumerate(cuts)}
    expected=json.loads((P/'tests/unchanged_functions_v011.json').read_text())[filename]
    for name,digest in expected.items():
        with case.subTest(file=filename,function=name):
            case.assertIn(name,functions)
            case.assertEqual(hashlib.sha256(functions[name].encode()).hexdigest(),digest)
