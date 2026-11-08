#!/usr/bin/env python3
"""BM25 code index for Neovim (SQLite FTS5).

Usage:
  bm25.py index  <root> <db>
  bm25.py search <db> <query> [limit]

Indexes text files (line by line) into an FTS5 table; `search` returns JSON
lines {path, line, content, score}, ordered by BM25 (best first).
"""

import json
import os
import sqlite3
import subprocess
import sys

MAX_FILE = 2_000_000  # skip files larger than 2 MB
BATCH = 5000


def list_files(root):
    try:
        out = subprocess.check_output(
            ["rg", "--files", "--hidden",
             "-g", "!.git/*", "-g", "!node_modules/*",
             "-g", "!vendor/*", "-g", "!dist/*", "-g", "!build/*",
             root],
            text=True,
        )
        return [p for p in out.splitlines() if p]
    except Exception:
        files = []
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in
                           (".git", "node_modules", "vendor", "dist", "build")]
            for name in filenames:
                files.append(os.path.join(dirpath, name))
        return files


def is_text(path):
    try:
        with open(path, "rb") as fh:
            chunk = fh.read(4096)
        return b"\x00" not in chunk
    except Exception:
        return False


def index(root, db):
    con = sqlite3.connect(db)
    con.execute(
        "CREATE VIRTUAL TABLE IF NOT EXISTS docs_fts USING fts5("
        "path UNINDEXED, line UNINDEXED, content, tokenize='unicode61')"
    )
    con.execute("DELETE FROM docs_fts")

    rows = []
    count = 0
    for path in list_files(root):
        try:
            if os.path.getsize(path) > MAX_FILE or not is_text(path):
                continue
            rel = os.path.relpath(path, root)
            with open(path, encoding="utf-8", errors="ignore") as fh:
                for lineno, line in enumerate(fh, 1):
                    line = line.rstrip("\n")
                    if not line.strip():
                        continue
                    rows.append((rel, lineno, line))
                    if len(rows) >= BATCH:
                        con.executemany(
                            "INSERT INTO docs_fts(path, line, content) VALUES (?, ?, ?)",
                            rows,
                        )
                        count += len(rows)
                        rows = []
        except Exception:
            continue
    if rows:
        con.executemany(
            "INSERT INTO docs_fts(path, line, content) VALUES (?, ?, ?)", rows
        )
        count += len(rows)

    con.execute("INSERT INTO docs_fts(docs_fts) VALUES ('optimize')")
    con.commit()
    con.close()
    print(f"indexed {count} lines from {root}")


def search(db, query, limit=200):
    terms = []
    for term in query.split():
        term = term.replace('"', '""')
        terms.append(f'"{term}"')
    if not terms:
        return
    match = " OR ".join(terms)

    con = sqlite3.connect(db)
    try:
        rows = con.execute(
            "SELECT path, line, content, bm25(docs_fts) AS score "
            "FROM docs_fts WHERE docs_fts MATCH ? "
            "ORDER BY score LIMIT ?",
            (match, limit),
        ).fetchall()
    except sqlite3.OperationalError:
        rows = []
    con.close()

    for path, line, content, score in rows:
        print(json.dumps(
            {"path": path, "line": line, "content": content, "score": score},
            ensure_ascii=False,
        ))


def main(argv):
    if len(argv) < 2:
        sys.stderr.write(__doc__)
        return 2
    cmd = argv[1]
    if cmd == "index" and len(argv) >= 4:
        index(argv[2], argv[3])
        return 0
    if cmd == "search" and len(argv) >= 4:
        limit = int(argv[4]) if len(argv) > 4 else 200
        search(argv[2], argv[3], limit)
        return 0
    sys.stderr.write(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
