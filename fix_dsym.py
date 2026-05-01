with open("macos/Runner.xcodeproj/project.pbxproj", "r") as f:
    c = f.read()

old_str = r'dsymutil \"$BIN_OUT\" -o \"$DST_DIR.dSYM\" || true\n";'
new_str = r'dsymutil \"$BIN_OUT\" -o \"$DST_DIR.dSYM\" || true\nif [ -n \"$DWARF_DSYM_FOLDER_PATH\" ] && [ -d \"$DWARF_DSYM_FOLDER_PATH\" ]; then\n  /bin/cp -a \"$DST_DIR.dSYM\" \"$DWARF_DSYM_FOLDER_PATH/\" || true\nfi\n";'

if old_str in c:
    c = c.replace(old_str, new_str)
    with open("macos/Runner.xcodeproj/project.pbxproj", "w") as f:
        f.write(c)
    print("Replaced successfully")
else:
    print("String not found")
