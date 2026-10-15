#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
image=chako-artefact
engine=${ENGINE:-$(command -v podman > /dev/null && echo podman || echo docker)}
if [ "$engine" = podman ]; then
    user_mapping=(--userns=keep-id:uid=1000,gid=1000)
else
    user_mapping=(--user "$(id -u):$(id -g)" -e HOME=/tmp)
fi

in_container() {
    mkdir -p "$here/work"
    local tty=(-i)
    if [ -t 0 ]; then tty=(-it); fi
    "$engine" run --rm "${tty[@]}" --network=none "${user_mapping[@]}" \
        -v "$here:/artefact" -w /artefact "$image" "$@"
}

fetch() {
    mkdir -p "$here/vendor/files"
    grep -v '^#' "$here/vendor.tsv" | while IFS=$'\t' read -r name sha256 url; do
        local file="$here/vendor/files/$name"
        if [ -f "$file" ] && echo "$sha256  $file" | sha256sum -c --quiet - 2>/dev/null; then
            continue
        fi
        echo "fetching $name"
        curl -sSfL -o "$file.part" "$url"
        if ! echo "$sha256  $file.part" | sha256sum -c --quiet -; then
            echo "$name: SHA-256 mismatch" >&2
            rm -f "$file.part"
            exit 1
        fi
        mv "$file.part" "$file"
    done
}

build() {
    local name
    name=$(awk -F'\t' '/^chako-lean-/ { print $1 }' "$here/vendor.tsv")
    rm -rf "$here/work/chako-lean" && mkdir -p "$here/work/chako-lean"
    tar xzf "$here/vendor/files/$name" -C "$here/work/chako-lean" --strip-components=1
    in_container sh -c 'cd work/chako-lean && lake build'
}

set_file() {
    case $1 in
    sound) echo Sound ;;
    perf) echo Perf ;;
    sound-quick) echo SoundQuick ;;
    perf-quick) echo PerfQuick ;;
    *) return 1 ;;
    esac
}

evaluate() {
    local set=${1:-} file
    file=$(set_file "$set") || { echo "usage: run.sh evaluate sound|perf|sound-quick|perf-quick" >&2; exit 1; }
    in_container sh -c 'cd work/chako-lean && mkdir -p "results/artefacts/$1" &&
        lake lean "Test/Eval/$2.lean" -- -Dchako.eval.parallel="$3"' sh "$set" "$file" "${PARALLEL:-4}"
}

report() {
    local set results="$here/work/chako-lean/results"
    mkdir -p "$here/generated"
    for set in sound perf sound-quick perf-quick; do
        if compgen -G "$results/artefacts/$set/*.csv" > /dev/null; then
            rm -rf "$here/generated/$set" && mkdir -p "$here/generated/$set"
            cp "$results/artefacts/$set"/*.csv "$here/generated/$set/"
            echo "generated/$set: $(ls "$here/generated/$set" | wc -l) CSV files"
        fi
    done
    if [ -d "$here/generated/sound" ] && [ -d "$here/generated/perf" ]; then
        in_container sh -c 'cd work/chako-lean/results &&
            python3 statistics.py /artefact/generated > /artefact/generated/tables.tex &&
            python3 statistics.py . > /artefact/generated/tables-repository.tex'
        cat "$here/generated/tables.tex"
    else
        echo "no tables: they need both sound and perf evaluated" >&2
    fi
}

case ${1:-} in
fetch) fetch ;;
image) "$engine" build -t "$image" -f "$here/Containerfile" "$here" ;;
build) build ;;
test) in_container sh -c 'cd work/chako-lean && lake test' ;;
evaluate) shift; evaluate "$@" ;;
report) report ;;
shell) in_container bash ;;
*) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
