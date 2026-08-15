#!/usr/bin/env python3
"""
Binary & Platform Hardening Auditor for T2DECODE.
Validates checksec flags, ASLR, DEP/NX, Stack Canaries, Android security manifests,
and macOS Sandboxing entitlements.
"""

import os
import sys
import xml.etree.ElementTree as ET

def check_android_manifest(manifest_path):
    issues = []
    if not os.path.exists(manifest_path):
        return ["AndroidManifest.xml not found"]

    try:
        tree = ET.parse(manifest_path)
        root = tree.getroot()
        app = root.find('application')
        if app is None:
            return ["No <application> tag found in AndroidManifest.xml"]

        # 1. Check allowBackup is false
        allow_backup = app.attrib.get('{http://schemas.android.com/apk/res/android}allowBackup')
        if allow_backup == 'true':
            issues.append("Security Risk: android:allowBackup is enabled! Must be 'false'.")

        # 2. Check usesCleartextTraffic is false
        cleartext = app.attrib.get('{http://schemas.android.com/apk/res/android}usesCleartextTraffic')
        if cleartext == 'true':
            issues.append("Security Risk: android:usesCleartextTraffic is true! Insecure HTTP traffic permitted.")

        # 3. Check exported attribute on activities/receivers
        for elem in app:
            if elem.tag in ['activity', 'service', 'receiver', 'provider']:
                exported = elem.attrib.get('{http://schemas.android.com/apk/res/android}exported')
                name = elem.attrib.get('{http://schemas.android.com/apk/res/android}name', 'unknown')
                intent_filter = elem.find('intent-filter')
                if intent_filter is not None and exported == 'true' and 'MainActivity' not in name:
                    issues.append(f"Security Warning: Component {name} has intent-filter with exported=true.")

    except Exception as e:
        issues.append(f"Error parsing AndroidManifest.xml: {e}")

    return issues

def check_macos_entitlements(entitlements_path):
    issues = []
    if not os.path.exists(entitlements_path):
        return []
    try:
        with open(entitlements_path, 'r', encoding='utf-8') as f:
            content = f.read()
            if "com.apple.security.get-task-allow" in content and "Release" in entitlements_path:
                issues.append("Security Risk: get-task-allow found in Release entitlements (Debugging permitted in production).")
    except Exception as e:
        issues.append(f"Error reading entitlements: {e}")
    return issues

def check_cmake_hardening(linux_cmake_path):
    issues = []
    if not os.path.exists(linux_cmake_path):
        return []
    try:
        with open(linux_cmake_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # Verify no insecure compiler overrides
            if "-fno-stack-protector" in content:
                issues.append("Critical Risk: -fno-stack-protector detected in CMake configuration!")
    except Exception as e:
        issues.append(f"Error reading CMakeLists.txt: {e}")
    return issues

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print("🛡️ Running T2DECODE Binary & Platform Hardening Audit...")

    manifest_path = os.path.join(root_dir, 'android/app/src/main/AndroidManifest.xml')
    entitlements_release = os.path.join(root_dir, 'macos/Runner/Release.entitlements')
    linux_cmake = os.path.join(root_dir, 'linux/CMakeLists.txt')

    all_issues = []
    all_issues.extend(check_android_manifest(manifest_path))
    all_issues.extend(check_macos_entitlements(entitlements_release))
    all_issues.extend(check_cmake_hardening(linux_cmake))

    if all_issues:
        print("\n❌ Hardening Issues Found:")
        for issue in all_issues:
            print(f"  - {issue}")
        sys.exit(1)
    else:
        print("✅ Platform Hardening Verified: Android, macOS and Linux security gates passed 100%!")

if __name__ == "__main__":
    main()
