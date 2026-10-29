#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
import subprocess
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass(frozen=True)
class Book:
    id: str
    name: str
    chapters: int
    testament: str
    ordinal: Optional[int] = None
    aliases: tuple[str, ...] = ()


BOOKS = (
    Book("mwanzo","Mwanzo",50,"Agano la Kale",aliases=("genesis",)),
    Book("kutoka","Kutoka",40,"Agano la Kale",aliases=("exodus",)),
    Book("mambo_ya_walawi","Mambo ya Walawi",27,"Agano la Kale",aliases=("walawi","leviticus")),
    Book("hesabu","Hesabu",36,"Agano la Kale",aliases=("numbers",)),
    Book("kumbukumbu_la_torati","Kumbukumbu la Torati",34,"Agano la Kale",aliases=("kumbukumbu","deuteronomy")),
    Book("yoshua","Yoshua",24,"Agano la Kale",aliases=("joshua",)),
    Book("waamuzi","Waamuzi",21,"Agano la Kale",aliases=("judges",)),
    Book("ruthu","Ruthu",4,"Agano la Kale",aliases=("ruth",)),
    Book("1_samweli","1 Samweli",31,"Agano la Kale",1,("samweli 1","1 samuel")),
    Book("2_samweli","2 Samweli",24,"Agano la Kale",2,("samweli 2","2 samuel")),
    Book("1_wafalme","1 Wafalme",22,"Agano la Kale",1,("wafalme 1","1 kings")),
    Book("2_wafalme","2 Wafalme",25,"Agano la Kale",2,("wafalme 2","2 kings")),
    Book("1_nyakati","1 Mambo ya Nyakati",29,"Agano la Kale",1,("1 nyakati","nyakati 1","1 chronicles")),
    Book("2_nyakati","2 Mambo ya Nyakati",36,"Agano la Kale",2,("2 nyakati","nyakati 2","2 chronicles")),
    Book("ezra","Ezra",10,"Agano la Kale"),
    Book("nehemia","Nehemia",13,"Agano la Kale",aliases=("nehemiah",)),
    Book("esta","Esta",10,"Agano la Kale",aliases=("esther",)),
    Book("ayubu","Ayubu",42,"Agano la Kale",aliases=("job",)),
    Book("zaburi","Zaburi",150,"Agano la Kale",aliases=("psalm","psalms")),
    Book("mithali","Mithali",31,"Agano la Kale",aliases=("proverbs",)),
    Book("mhubiri","Mhubiri",12,"Agano la Kale",aliases=("ecclesiastes",)),
    Book("wimbo_ulio_bora","Wimbo Ulio Bora",8,"Agano la Kale",aliases=("wimbo wa sulemani","song of solomon","song of songs")),
    Book("isaya","Isaya",66,"Agano la Kale",aliases=("isaiah",)),
    Book("yeremia","Yeremia",52,"Agano la Kale",aliases=("jeremiah",)),
    Book("maombolezo","Maombolezo",5,"Agano la Kale",aliases=("lamentations",)),
    Book("ezekiel","Ezekieli",48,"Agano la Kale",aliases=("ezekiel","ezekieli")),
    Book("daniel","Danieli",12,"Agano la Kale",aliases=("daniel",)),
    Book("hosea","Hosea",14,"Agano la Kale"),
    Book("yoeli","Yoeli",3,"Agano la Kale",aliases=("joel",)),
    Book("amosi","Amosi",9,"Agano la Kale",aliases=("amos",)),
    Book("obadiah","Obadia",1,"Agano la Kale",aliases=("obadiah","obadia")),
    Book("yona","Yona",4,"Agano la Kale",aliases=("jonah",)),
    Book("mika","Mika",7,"Agano la Kale",aliases=("micah",)),
    Book("nahumu","Nahumu",3,"Agano la Kale",aliases=("nahum",)),
    Book("habakuki","Habakuki",3,"Agano la Kale",aliases=("habakkuk",)),
    Book("sefania","Sefania",3,"Agano la Kale",aliases=("zephaniah",)),
    Book("hagai","Hagai",2,"Agano la Kale",aliases=("haggai",)),
    Book("zakaria","Zakaria",14,"Agano la Kale",aliases=("zekaria","zechariah")),
    Book("malaki","Malaki",4,"Agano la Kale",aliases=("malachi",)),
    Book("mathayo","Mathayo",28,"Agano Jipya",aliases=("matayo","matthew")),
    Book("marko","Marko",16,"Agano Jipya",aliases=("mark",)),
    Book("luka","Luka",24,"Agano Jipya",aliases=("luke",)),
    Book("yohana","Yohana",21,"Agano Jipya",aliases=("john","injili ya yohana")),
    Book("matendo","Matendo ya Mitume",28,"Agano Jipya",aliases=("matendo","acts")),
    Book("warumi","Warumi",16,"Agano Jipya",aliases=("romans",)),
    Book("1_wakorintho","1 Wakorintho",16,"Agano Jipya",1,("wakorintho 1","1 corinthians")),
    Book("2_wakorintho","2 Wakorintho",13,"Agano Jipya",2,("wakorintho 2","2 corinthians")),
    Book("wagalatia","Wagalatia",6,"Agano Jipya",aliases=("galatians",)),
    Book("waefeso","Waefeso",6,"Agano Jipya",aliases=("ephesians",)),
    Book("wafilipi","Wafilipi",4,"Agano Jipya",aliases=("philippians",)),
    Book("wakolosai","Wakolosai",4,"Agano Jipya",aliases=("colossians",)),
    Book("1_wathesalonike","1 Wathesalonike",5,"Agano Jipya",1,("wathesalonike 1","1 thessalonians")),
    Book("2_wathesalonike","2 Wathesalonike",3,"Agano Jipya",2,("wathesalonike 2","2 thessalonians")),
    Book("1_timotheo","1 Timotheo",6,"Agano Jipya",1,("timotheo 1","1 timothy")),
    Book("2_timotheo","2 Timotheo",4,"Agano Jipya",2,("timotheo 2","2 timothy")),
    Book("tito","Tito",3,"Agano Jipya",aliases=("titus",)),
    Book("filemoni","Filemoni",1,"Agano Jipya",aliases=("philemon",)),
    Book("waebrania","Waebrania",13,"Agano Jipya",aliases=("hebrews",)),
    Book("yakobo","Yakobo",5,"Agano Jipya",aliases=("james",)),
    Book("1_petro","1 Petro",5,"Agano Jipya",1,("petro 1","1 peter")),
    Book("2_petro","2 Petro",3,"Agano Jipya",2,("petro 2","2 peter")),
    Book("1_yohana","1 Yohana",5,"Agano Jipya",1,("yohana 1","1 john","first john")),
    Book("2_yohana","2 Yohana",1,"Agano Jipya",2,("yohana 2","2 john","second john")),
    Book("3_yohana","3 Yohana",1,"Agano Jipya",3,("yohana 3","3 john","third john")),
    Book("yuda","Yuda",1,"Agano Jipya",aliases=("jude",)),
    Book("ufunuo_wa_yohana","Ufunuo wa Yohana",22,"Agano Jipya",aliases=("ufunuo","revelation")),
)

EXPECTED_TOTAL = 1189


def norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", s)
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    s = s.lower().strip()
    s = re.sub(r"[_\-]+", " ", s)
    s = re.sub(r"[^a-z0-9\s]", " ", s)
    return re.sub(r"\s+", " ", s).strip()


ALIAS = {}
for b in BOOKS:
    for x in (b.name, b.id.replace("_"," "), *b.aliases):
        ALIAS[norm(x)] = b


def detect_book(folder: Path) -> Optional[Book]:
    key = norm(folder.name)

    # Remove harmless organizational suffixes/prefixes that are not part
    # of the Bible-book identity, e.g.:
    #   "1 YOHANA RECORDINGS" -> "1 yohana"
    #   "Mathayo Audio"       -> "mathayo"
    generic_words = {
        "recording",
        "recordings",
        "audio",
        "audios",
        "bible",
        "biblia",
        "files",
        "file",
        "mp3",
    }

    words = [word for word in key.split() if word not in generic_words]
    cleaned_key = " ".join(words).strip()

    # Prefer exact match after cleaning.
    if cleaned_key in ALIAS:
        return ALIAS[cleaned_key]

    # Fall back to the original normalized name.
    if key in ALIAS:
        return ALIAS[key]

    # Conservative fuzzy match on the cleaned name only.
    matches = []

    for alias, book in ALIAS.items():
        if not alias:
            continue

        if alias in cleaned_key or cleaned_key in alias:
            if all(existing.id != book.id for existing in matches):
                matches.append(book)

    if len(matches) == 1:
        return matches[0]

    return None


def looks_mp3(path: Path) -> bool:
    try:
        h = path.read_bytes()[:3]
        return h == b"ID3" or (len(h) >= 2 and h[0] == 0xFF and (h[1] & 0xE0) == 0xE0)
    except OSError:
        return False


def chapter_from_filename(path: Path, book: Book) -> Optional[int]:
    s = norm(path.stem)

    # Strong explicit patterns always win.
    for pat in (
        r"\bsura(?:\s+ya)?\s*(\d{1,3})\b",
        r"\bchapter\s*(\d{1,3})\b",
        r"\bchap\s*(\d{1,3})\b",
    ):
        m = re.search(pat, s)
        if m:
            return int(m.group(1))

    nums = [int(x) for x in re.findall(r"\d{1,3}", s)]

    # Single-chapter numbered books: "2 Yohana.mp3" and "3 Yohana.mp3"
    # refer to chapter 1, not chapters 2/3.
    if book.chapters == 1:
        if len(nums) == 0:
            return 1
        if len(nums) == 1 and book.ordinal is not None and nums[0] == book.ordinal:
            return 1

    # Numbered books: remove the leading book ordinal when it is present.
    if book.ordinal is not None and len(nums) >= 2 and nums[0] == book.ordinal:
        nums = nums[1:]

    if not nums:
        return 1 if book.chapters == 1 else None

    # Last numeric token is safest for names like "1 Yohana 5".
    return nums[-1]


def ffprobe_ms(path: Path) -> Optional[int]:
    exe = shutil.which("ffprobe")
    if not exe:
        return None
    try:
        r = subprocess.run(
            [exe, "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", str(path)],
            capture_output=True, text=True, check=True
        )
        return round(float(r.stdout.strip()) * 1000)
    except Exception:
        return None


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            block = f.read(1024 * 1024)
            if not block:
                break
            h.update(block)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("source", type=Path)
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument("--hash", action="store_true")
    args = ap.parse_args()

    source = args.source.resolve()
    output = args.output.resolve()
    prod = output / "v1" / "sw"

    if not source.is_dir():
        print("ERROR: source folder not found:", source)
        return 2

    # Rebuild prepared copy cleanly; original recordings are untouched.
    if prod.exists():
        shutil.rmtree(prod)
    prod.mkdir(parents=True, exist_ok=True)

    found = {}
    unknown = []
    duplicate_folders = []

    for folder in sorted(p for p in source.iterdir() if p.is_dir()):
        b = detect_book(folder)
        if b is None:
            unknown.append(folder.name)
        elif b.id in found:
            duplicate_folders.append(f"{b.name}: {found[b.id].name} AND {folder.name}")
        else:
            found[b.id] = folder

    manifest_books = []
    inventory = []
    missing = []
    duplicates = []
    no_number = []
    out_of_range = []
    malformed = []
    non_mp3_audio_files = []
    total_bytes = 0
    prepared = 0

    print("Preparing into:", prod)

    for book in BOOKS:
        folder = found.get(book.id)
        by_chapter = {}

        if folder:
            # Report audio-like files that are not MP3 because the production
            # library currently only accepts MP3 delivery files.
            audio_like_extensions = {
                ".wav", ".m4a", ".aac", ".flac", ".ogg", ".opus", ".mp4", ".wma"
            }

            for other in sorted(p for p in folder.rglob("*") if p.is_file()):
                if other.suffix.lower() in audio_like_extensions:
                    non_mp3_audio_files.append(f"{book.name}: {other.name}")

            for f in sorted(p for p in folder.rglob("*") if p.is_file() and p.suffix.lower() == ".mp3"):
                ch = chapter_from_filename(f, book)
                if ch is None:
                    no_number.append(f"{book.name}: {f.name}")
                    continue
                if not 1 <= ch <= book.chapters:
                    out_of_range.append(f"{book.name}: detected chapter {ch} from {f.name}")
                    continue
                by_chapter.setdefault(ch, []).append(f)

        out_book = prod / book.id
        out_book.mkdir(parents=True, exist_ok=True)
        chapters = []

        for ch in range(1, book.chapters + 1):
            files = by_chapter.get(ch, [])
            if len(files) == 0:
                missing.append(f"{book.name} {ch}")
                continue
            if len(files) > 1:
                duplicates.append(f"{book.name} {ch}: " + ", ".join(x.name for x in files))
                continue

            src = files[0]
            if not looks_mp3(src):
                malformed.append(str(src))
                continue

            dst = out_book / f"{ch:03d}.mp3"
            shutil.copy2(src, dst)
            size = dst.stat().st_size
            dur = ffprobe_ms(dst)
            digest = sha256(dst) if args.hash else None

            entry = {
                "number": ch,
                "path": f"v1/sw/{book.id}/{ch:03d}.mp3",
                "bytes": size,
            }
            if dur is not None:
                entry["durationMs"] = dur
            if digest:
                entry["sha256"] = digest
            chapters.append(entry)

            inventory.append({
                "bookId": book.id,
                "bookName": book.name,
                "chapter": ch,
                "path": entry["path"],
                "bytes": size,
                "durationMs": dur or "",
                "sha256": digest or "",
                "source": str(src),
            })
            prepared += 1
            total_bytes += size

        manifest_books.append({
            "id": book.id,
            "name": book.name,
            "testament": book.testament,
            "chapterCount": book.chapters,
            "availableChapterCount": len(chapters),
            "chapters": chapters,
        })
        print(f"{book.name:<24} {len(chapters)}/{book.chapters}")

    output.mkdir(parents=True, exist_ok=True)
    manifest = {
        "schemaVersion": 1,
        "audioVersion": "v1",
        "language": "sw",
        "format": "mp3",
        "expectedBooks": 66,
        "expectedChapters": EXPECTED_TOTAL,
        "availableBooks": sum(1 for b in manifest_books if b["availableChapterCount"]),
        "availableChapters": prepared,
        "totalBytes": total_bytes,
        "books": manifest_books,
    }
    (output / "audio_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    with (output / "upload_inventory.csv").open("w", newline="", encoding="utf-8-sig") as f:
        fields = ["bookId","bookName","chapter","path","bytes","durationMs","sha256","source"]
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(inventory)

    report = []
    def sec(title, vals):
        report.append(title)
        report.append("-" * len(title))
        if vals:
            report.extend("- " + x for x in vals)
        else:
            report.append("None")
        report.append("")

    report += [
        "JIFUNZE BIBLIA - AUDIO LIBRARY AUDIT",
        "=" * 44,
        f"Recognized book folders: {len(found)}/66",
        f"Prepared chapters: {prepared}/{EXPECTED_TOTAL}",
        f"Prepared bytes: {total_bytes}",
        "",
    ]
    sec("Missing book folders", [b.name for b in BOOKS if b.id not in found])
    sec("Unknown folders", unknown)
    sec("Duplicate book folders", duplicate_folders)
    sec("Missing chapters", missing)
    sec("Duplicate chapter recordings", duplicates)
    sec("Files with no detectable chapter number", no_number)
    sec("Chapter numbers outside expected range", out_of_range)
    sec("Files that do not look like MP3", malformed)
    sec("Audio-like files ignored because they are not MP3", non_mp3_audio_files)

    passed = (
        len(found) == 66 and prepared == EXPECTED_TOTAL and
        not unknown and not duplicate_folders and not missing and
        not duplicates and not no_number and not out_of_range and
        not malformed and not non_mp3_audio_files
    )
    report += ["RESULT: PASS" if passed else "RESULT: REVIEW REQUIRED"]

    (output / "audio_audit_report.txt").write_text("\n".join(report), encoding="utf-8")

    print()
    print("Prepared", f"{prepared}/{EXPECTED_TOTAL}", "chapters.")
    print("Report:", output / "audio_audit_report.txt")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
