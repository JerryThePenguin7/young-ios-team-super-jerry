"""Fill Jenny in a simulator with made-up medicines, for design reviews and screenshots.

Usage: python3 seed_sample_medicines.py <simulator UDID> <bundle id>

Only synthetic data (PDPA). This replaces the app's saved medicines on that simulator,
so never point it at a device with data you want to keep. Install the app first.
"""

import datetime
import json
import pathlib
import subprocess
import sys
import uuid

# Swift's JSONEncoder stores dates as seconds since 1 Jan 2001.
REFERENCE_DATE = datetime.datetime(2001, 1, 1, tzinfo=datetime.timezone.utc)


def seconds(date):
    return (date - REFERENCE_DATE).total_seconds()


def medicine(name, strength, amount, slots, meal, added, warnings=()):
    return {
        "id": str(uuid.uuid4()).upper(),
        "name": name,
        "strength": strength,
        "amount": amount,
        "unit": "เม็ด",
        "slots": slots,
        "meal": meal,
        "asNeeded": False,
        "warnings": list(warnings),
        "scannedText": f"(ตัวอย่าง) {name} {strength}",
        "photoFile": None,
        "addedAt": added,
    }


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    udid, bundle_id = sys.argv[1], sys.argv[2]

    container = subprocess.run(
        ["xcrun", "simctl", "get_app_container", udid, bundle_id, "data"],
        check=True, capture_output=True, text=True,
    ).stdout.strip()

    today = datetime.datetime.now().astimezone().replace(hour=0, minute=0, second=0, microsecond=0)
    added = seconds(today - datetime.timedelta(days=3))

    medicines = [
        medicine("Metformin", "500 mg", 1, ["morning", "evening"], "หลังอาหาร", added),
        medicine("Amlodipine", "5 mg", 1, ["morning"], "หลังอาหาร", added),
        medicine("Simvastatin", "20 mg", 0.5, ["bedtime"], "", added, ["ห้ามทานกับน้ำเกรพฟรุต"]),
    ]
    # Amlodipine was taken this morning, so the Log shows a mix of states.
    records = [{
        "id": str(uuid.uuid4()).upper(),
        "medicineID": medicines[1]["id"],
        "time": {"hour": 8, "minute": 0},
        "day": seconds(today),
        "takenAt": seconds(today.replace(hour=8, minute=12)),
    }]

    documents = pathlib.Path(container) / "Documents"
    documents.mkdir(parents=True, exist_ok=True)
    saved = {"medicines": medicines, "records": records, "remindersEnabled": False}
    (documents / "jenny-medicines.json").write_text(json.dumps(saved, ensure_ascii=False))
    print(f"Added {len(medicines)} made-up medicines. Relaunch the app to see them.")


if __name__ == "__main__":
    main()
