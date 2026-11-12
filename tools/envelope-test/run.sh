#!/bin/zsh
# Makes fake Thai medicine envelopes and scores Jenny's label reader on them.
# Usage (from the project folder):  tools/envelope-test/run.sh [count] [seed]
# Runs on a Mac only (it uses Vision on the Mac). Nothing is added to the app.
set -e
cd "$(dirname "$0")/../.."

COUNT=${1:-300}
SEED=${2:-1}
OUT=tools/envelope-test/out
mkdir -p $OUT/bin

echo "Building the envelope maker…"
swiftc -O tools/envelope-test/MakeEnvelopes/main.swift -o $OUT/bin/make-envelopes

echo "Building the scorer with Jenny's own reader code…"
swiftc -O tools/envelope-test/ScoreEnvelopes/main.swift \
    SuperJerry/Understanding/LabelParser.swift \
    SuperJerry/Understanding/LabelReader.swift \
    SuperJerry/Understanding/MedicineNames.swift \
    SuperJerry/Understanding/DosageForm.swift \
    SuperJerry/Understanding/PillInfo+Jenny.swift \
    SuperJerry/Models/PillInfo.swift \
    SuperJerry/Models/Medicine.swift \
    SuperJerry/Models/TimeSlot.swift \
    SuperJerry/Models/MedicineGroup.swift \
    SuperJerry/Models/AppLanguage.swift \
    -o $OUT/bin/score-envelopes

rm -rf $OUT/envelopes
$OUT/bin/make-envelopes $OUT/envelopes $COUNT $SEED
JENNY_MEDICINE_NAMES=SuperJerry/Understanding/medicine-names.json \
    $OUT/bin/score-envelopes $OUT/envelopes $OUT/report.md
