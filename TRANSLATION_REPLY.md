# Réponse type — Candidature bénévole traduction anglais

Copier-coller ce message (anglais) pour répondre à Emmanuel ou à tout autre locuteur natif souhaitant traduire T2DECODE.

---

Subject: Re: Volunteer Translation Inquiry – English Localization for TutoDeCode

Hi Emmanuel,

Thank you for reaching out and for your interest in TutoDeCode / T2DECODE.

We are absolutely open to community contributions for localization. Our project is a 100% offline, sovereign Flutter application built by the French non-profit association TUTODECODE. All learning content is written in our own pedagogical format, **TUTODECODE Script (`.tdc`)**, which is designed to be readable, lintable, and easy to translate.

## How to contribute as a translator

1. **Repository**  
   Everything is on GitLab: https://gitlab.com/tutodecode-org/T2DECODE

2. **What to translate**  
   We need translations for three types of assets:
   - **UI strings** → `assets/locales/en.tdc` (from `assets/locales/fr.tdc`)
   - **Cheat sheets** → `assets/cheat_sheets_en.tdc` (from `assets/cheat_sheets.tdc`)
   - **Courses** → `assets/courses_en.tdc` (from `assets/courses.tdc`)

3. **Rules**  
   - Do **not** change identifiers: `course "linux-basics"`, `entry "ip-link-show"`, `menu.home`, etc.
   - Translate only the visible text after the colon (`:`).
   - One language = one branch/MR, e.g. `feat/translation-en`.

4. **Tools**  
   - **TDC Studio App** (desktop IDE) lets you edit cheat sheets and UI strings with a form and export directly to the `assets/` folder.  
   - **VS Code extension** `vscode-tdc` provides syntax highlighting and snippets.  
   - The GitLab CI validates every `.tdc` file automatically.

5. **License**  
   T2DECODE and the TDC-SDK are GPLv3. Translations and learning contents are published under a free license (CC BY-SA 4.0 or GPLv3) so they remain accessible to the community.

If you are comfortable with GitHub, GitLab works almost the same way: fork, branch, edit, merge request. We will review and merge your contributions.

Welcome aboard!

Best regards,

The TUTODECODE team
contact@tutodecode.org
https://tutodecode.org
