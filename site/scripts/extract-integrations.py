#!/usr/bin/env python3
"""Extrait le catalogue d'intégrations depuis les sources Swift.

Sortie : JSON { slug, metrics[3], needsKey, endpoints[] } par IntegrationType.
Source de vérité : Shared/Models.swift (liste des types) et
Shared/Data/Integrations.swift (métriques réellement lues par intégration).
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else "/Users/sylvain/Specula/Specula")
MODELS = (ROOT / "Shared/Models.swift").read_text()
INTEG = (ROOT / "Shared/Data/Integrations.swift").read_text()

# Le catalogue de l'app : les aides à la saisie y sont déjà traduites dans les
# cinq langues. Les reprendre garantit que le site et l'app disent la même
# chose, mot pour mot.
XCSTRINGS = json.loads((ROOT / "Resources/Localizable.xcstrings").read_text())
LOCALES = {"en": "en", "fr": "fr", "es": "es", "zh": "zh-Hans", "ar": "ar"}


def translations(source: str):
    """{locale: chaîne} pour une chaîne source française du catalogue."""
    entry = XCSTRINGS["strings"].get(source)
    out = {"fr": source}
    if not entry:
        return out
    for short, code in LOCALES.items():
        unit = entry.get("localizations", {}).get(code, {}).get("stringUnit", {})
        if unit.get("value"):
            out[short] = unit["value"]
    return out

# --- 1. la liste des types, dans l'ordre de déclaration ---------------------
enum_body = re.search(r"enum IntegrationType[^{]*\{(.*?)\n\}", MODELS, re.S).group(1)
types = []
for line in enum_body.splitlines():
    line = line.strip()
    if not line.startswith("case "):
        continue
    types.extend(t.strip() for t in line[len("case "):].split(","))

# --- 2. découpe des switchs de métriques en blocs par case ------------------
# Deux switchs se relaient : `metricsOne` (indenté à 12) délègue son `default:`
# à `metricsMore` (indenté à 8).
case_re = re.compile(r"^ {8}(?: {4})?case ((?:\s*\.\w+,?)+):$", re.M)
blocks = {}
for func_name in ("private static func metricsOne", "static func metricsMore"):
    switch_src = INTEG[INTEG.index(func_name):]
    marks = list(case_re.finditer(switch_src))
    for i, m in enumerate(marks):
        end = marks[i + 1].start() if i + 1 < len(marks) else len(switch_src)
        body = switch_src[m.start():end]
        for name in m.group(1).split(","):
            blocks.setdefault(name.strip().lstrip("."), body)

# --- 3. corps des fonctions déléguées (case .x: return await xStats(...)) ---
func_re = re.compile(r"static func (\w+)\(.*?\n    \}", re.S)
funcs = {m.group(1): m.group(0) for m in func_re.finditer(INTEG)}

# Une cellule de métrique s'écrit `[valeur, "Libellé"]`, et la valeur est
# toujours calculée : un appel (frInt(…), frBytes(…)) ou une interpolation.
# L'exiger écarte les tableaux de chemins littéraux — ["/transmission/rpc",
# "/rpc"] — qu'un motif plus lâche prenait pour des libellés.
LABEL_RE = re.compile(
    r'\[\s*(?:[A-Za-z_]\w*\(|"[^"]*\\\()[^\[\]]*?,\s*"([^"]+)"\s*\]'
)
ENDPOINT_RE = re.compile(r'"\\\(\w*[Bb]ase\w*\)(/[^"?\\]*)')


def harvest(body, depth=0):
    """Libellés de métriques + endpoints, en suivant un appel délégué."""
    labels = LABEL_RE.findall(body)
    endpoints = ENDPOINT_RE.findall(body)
    if len(labels) < 3 and depth < 2:
        for call in re.findall(r"await (\w+)\(", body):
            if call in funcs:
                sub_labels, sub_endpoints = harvest(funcs[call], depth + 1)
                labels = labels or sub_labels
                endpoints = endpoints or sub_endpoints
                if labels:
                    break
    return labels[:3], sorted(set(endpoints))[:4]


# --- 4. l'identifiant demandé par intégration (switch `keyHint`) ------------
hint_src = INTEG[INTEG.index("static func keyHint"):INTEG.index("enum KeyStyle")]
# le `default:` du switch clôt le dernier case — sans cette coupe, les types
# explicitement sans identifiant hériteraient du libellé par défaut
hint_src = hint_src[:re.search(r"^ {8}default:$", hint_src, re.M).start()]
hints = {}
hint_marks = list(case_re.finditer(hint_src))
for i, m in enumerate(hint_marks):
    end = hint_marks[i + 1].start() if i + 1 < len(hint_marks) else len(hint_src)
    found = re.search(r'String\(localized: "([^"]+)"\)', hint_src[m.start():end])
    for name in m.group(1).split(","):
        hints[name.strip().lstrip(".")] = found.group(1) if found else None

style_src = INTEG[INTEG.index("static func keyStyle"):]
styles = {}
style_marks = list(case_re.finditer(style_src))[:3]
for i, m in enumerate(style_marks):
    end = style_marks[i + 1].start() if i + 1 < len(style_marks) else len(style_src)
    found = re.search(r"\n\s+\.(\w+)\n", style_src[m.start():end])
    for name in m.group(1).split(","):
        styles[name.strip().lstrip(".")] = found.group(1) if found else None

catalog = []
for t in types:
    body = blocks.get(t, "")
    labels, endpoints = harvest(body)
    catalog.append({
        "slug": t,
        "metrics": labels,
        "needsKey": "guard let key" in body,
        "endpoints": endpoints,
        # `default:` du switch = « Clé API du service » ; les types listés au
        # case `nil` n'en demandent aucun
        "keyHint": (lambda h: translations(h) if h else None)(
            hints.get(t, "Clé API du service")
        ),
        "keyStyle": styles.get(t, "token"),
    })

covered = [c for c in catalog if c["metrics"]]
print(f"{len(types)} types, {len(covered)} avec métriques lues", file=sys.stderr)
for c in catalog:
    if not c["metrics"] and c["slug"] != "generic":
        print(f"  sans métrique extraite : {c['slug']}", file=sys.stderr)

json.dump(catalog, sys.stdout, ensure_ascii=False, indent=2)
