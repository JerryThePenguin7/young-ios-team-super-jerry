#!/usr/bin/env python3
"""Grow Jenny's medicine name list from TMT, the official Thai Medicines Terminology.

1. Make a free account and download the latest TMT release zip:
   https://this.or.th/service/tmt/download/   (dataset info: https://opendata.hsri.or.th, "TMT")
2. Unzip it. If the drug list is an Excel file, open it and "Export / Save as" CSV first.
3. Run (Python 3, nothing to install):
       python3 tools/tmt_to_medicine_names.py ~/Downloads/TMTRF20261005
   It reads every .txt / .tsv / .csv file in that folder, finds trade names like
   "AUGMENTIN (amoxicillin 875 mg + clavulanic acid 125 mg) film-coated tablet" and generic names,
   and adds the ones Jenny doesn't know yet to SuperJerry/Understanding/medicine-names.json.
   Jenny's hand-made entries (herbal medicines, Thai names, friendly descriptions) are kept.
4. Build the app in Xcode again. Check the TMT license terms before sharing the data outside the team.
"""
import csv, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
NAMES_FILE = os.path.join(HERE, "..", "SuperJerry", "Understanding", "medicine-names.json")

# Trade product: an UPPERCASE name, then the generic part in brackets, then the dosage form.
TRADE = re.compile(r"^([A-Z0-9][A-Z0-9 .,'&+/\-]*?[A-Z0-9.])\s*\((.+)\)\s*(.*)$")
# Generic product: lowercase generic name(s) before the first number, e.g. "metformin 500 mg film-coated tablet".
GENERIC = re.compile(r"^([a-z][a-z \-]+?)\s+\d")

FORMS = [  # checked in order: most specific first
    ("eyeDrops", ["eye drop", "ophthalmic solution", "ophthalmic suspension"]),
    ("earDrops", ["ear drop"]),
    ("noseDrops", ["nasal drop"]),
    ("nasalSpray", ["nasal spray"]),
    ("inhaler", ["inhalation", "inhaler"]),
    ("suppository", ["suppositor"]),
    ("injection", ["injection", "infusion"]),
    ("topical", ["cream", "ointment", "gel", "lotion", "cutaneous"]),
    ("lozenge", ["lozenge", "pastille"]),
    ("liquid", ["oral solution", "syrup", "oral suspension", "oral liquid", "elixir", "mixture"]),
    ("powder", ["powder", "granules"]),
    ("capsule", ["capsule"]),
    ("tablet", ["tablet"]),
]


def dosage_form(text):
    lower = text.lower()
    for form, words in FORMS:
        if any(word in lower for word in words):
            return form
    return None


def generic_names(text):
    """'amoxicillin 875 mg + clavulanic acid 125 mg' -> 'amoxicillin + clavulanic acid'"""
    parts = [re.split(r"\s\d", part.strip())[0].strip() for part in text.split("+")]
    return " + ".join(part for part in parts if part)


def terms_in(path):
    """Every text cell in a .txt/.tsv/.csv file; uses the 'term'/'FSN' column when there is one."""
    delimiter = "," if path.lower().endswith(".csv") else "\t"
    with open(path, encoding="utf-8-sig", errors="replace", newline="") as f:
        rows = list(csv.reader(f, delimiter=delimiter))
    if not rows:
        return
    header = [cell.strip().lower() for cell in rows[0]]
    wanted = [i for i, name in enumerate(header) if name in ("term", "fsn", "fully specified name", "name", "tpu", "tp", "gp")]
    for row in rows[1:] if wanted else rows:
        cells = [row[i] for i in wanted if i < len(row)] if wanted else row
        for cell in cells:
            yield cell.strip()


def main(folders):
    with open(NAMES_FILE, encoding="utf-8") as f:
        entries = json.load(f)
    known = set()
    for entry in entries:
        for name in [entry["name"]] + entry.get("aliases", []):
            known.add(name.upper())

    found = {}  # NAME -> {"name", "thai", "forms"}
    for folder in folders:
        for root, _, files in os.walk(folder):
            for file in files:
                if file.lower().endswith((".txt", ".tsv", ".csv")):
                    for term in terms_in(os.path.join(root, file)):
                        add_term(term, found)

    added = 0
    for key, item in sorted(found.items()):
        if key in known or len(item["name"]) > 40:
            continue
        entry = {"name": item["name"]}
        if item["thai"]:
            entry["thai"] = item["thai"]
        forms = item["forms"] - {None}
        if len(forms) == 1:  # only set a form when every product with this name has the same one
            entry["form"] = forms.pop()
        entries.append(entry)
        known.add(key)
        added += 1

    with open(NAMES_FILE, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"Added {added} names. medicine-names.json now has {len(entries)} medicines.")


def add_term(term, found):
    match = TRADE.match(term)
    if match and any(c.isalpha() for c in match.group(1)):
        name, generic, rest = match.group(1).strip(" ."), match.group(2), match.group(3)
        item = found.setdefault(name.upper(), {"name": name, "thai": generic_names(generic), "forms": set()})
        item["forms"].add(dosage_form(rest))
        return
    match = GENERIC.match(term)
    if match and len(match.group(1).strip()) >= 4:
        name = match.group(1).strip()
        item = found.setdefault(name.upper(), {"name": name.capitalize(), "thai": None, "forms": set()})
        item["forms"].add(dosage_form(term))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
