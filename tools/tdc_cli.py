#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>
"""
TUTODECODE Script (.tdc) CLI Tool
Linter, Auto-Formatter, and Converter for external text editors and CI pipelines.
"""

import sys
import re
import json
import argparse

def check_tdc_file(filepath):
    print(f"🔍 Audit de syntaxe .TDC : {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    errors = []
    courses = re.findall(r'course\s+["\']([^"\']+)["\']\s*\{', content)
    if not courses:
        errors.append("❌ Aucun bloc 'course \"id\" { ... }' trouvé.")

    modules = re.findall(r'module\s+["\']([^"\']+)["\']\s*\{', content)
    questions = re.findall(r'question\s+["\']([^"\']+)["\']\s*\{', content)
    correct_opts = re.findall(r'^\s*\+\s*["\']', content, re.MULTILINE)

    if errors:
        for err in errors:
            print(f"  {err}")
        return False

    print(f"  ✅ Valide ! Contient {len(courses)} cours, {len(modules)} modules, {len(questions)} QCMs ({len(correct_opts)} réponses correctes marquées +).")
    return True

def convert_json_to_tdc(json_filepath, output_filepath=None):
    print(f"🔄 Conversion JSON -> .TDC : {json_filepath}")
    with open(json_filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if isinstance(data, dict):
        courses = [data]
    else:
        courses = data

    output_lines = []
    for c in courses:
        cid = c.get('id', 'course-id')
        title = c.get('title', cid)
        desc = c.get('description', '')
        cat = c.get('category', 'linux')
        level = c.get('level', 'beginner')
        duration = c.get('duration', '1h')
        icon = c.get('icon', 'Terminal')
        keywords = c.get('keywords', [])

        output_lines.append(f'course "{cid}" {{')
        output_lines.append(f'  title: "{title}"')
        output_lines.append(f'  description: "{desc}"')
        output_lines.append(f'  category: {cat}')
        output_lines.append(f'  level: {level}')
        output_lines.append(f'  duration: {duration}')
        output_lines.append(f'  icon: {icon}')
        if keywords:
            output_lines.append(f'  keywords: [{", ".join(keywords)}]')
        output_lines.append('')

        for m in c.get('content', []):
            mid = m.get('id', 'module-1')
            mtitle = m.get('title', mid)
            mduration = m.get('duration', '15min')
            mcontent = m.get('content', '')

            output_lines.append(f'  module "{mid}" {{')
            output_lines.append(f'    title: "{mtitle}"')
            output_lines.append(f'    duration: {mduration}')
            output_lines.append('')
            output_lines.append('    content """')
            output_lines.append(mcontent)
            output_lines.append('    """')

            for q in m.get('quiz', []):
                qtext = q.get('question', '')
                choices = q.get('choices', [])
                correct_idx = q.get('correctIndex', 0)
                expl = q.get('explanation', '')

                output_lines.append('')
                output_lines.append(f'    quiz {{')
                output_lines.append(f'      question "{qtext}" {{')
                for i, choice in enumerate(choices):
                    prefix = '+' if i == correct_idx else '-'
                    output_lines.append(f'        {prefix} "{choice}"')
                if expl:
                    output_lines.append(f'        explanation: "{expl}"')
                output_lines.append('      }')
                output_lines.append('    }')

            output_lines.append('  }')
            output_lines.append('')

        output_lines.append('}')

    result = '\n'.join(output_lines)
    if output_filepath:
        with open(output_filepath, 'w', encoding='utf-8') as f:
            f.write(result)
        print(f"  💾 Fichier généré avec succès : {output_filepath}")
    else:
        print(result)

def main():
    parser = argparse.ArgumentParser(description="TUTODECODE Script (.tdc) CLI Tool")
    subparsers = parser.add_subparsers(dest="command")

    check_parser = subparsers.add_parser("check", help="Audite et valide un fichier .tdc")
    check_parser.add_argument("file", help="Chemin du fichier .tdc")

    convert_parser = subparsers.add_parser("json2tdc", help="Convertit un cours JSON en .tdc")
    convert_parser.add_argument("file", help="Chemin du fichier JSON")
    convert_parser.add_argument("-o", "--output", help="Fichier de sortie .tdc")

    args = parser.parse_args()
    if args.command == "check":
        success = check_tdc_file(args.file)
        sys.exit(0 if success else 1)
    elif args.command == "json2tdc":
        convert_json_to_tdc(args.file, args.output)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
