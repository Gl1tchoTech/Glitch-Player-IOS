#!/usr/bin/env python3
"""Generate a valid Xcode project.pbxproj (JSON format) for MeloPlayerClone.

Xcode 26.4 parses project.pbxproj as JSON, not OpenStep plist.
We build a Python dict and use json.dump() for guaranteed valid output.
"""

import os, json, hashlib, sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "MeloPlayerClone.xcodeproj")
PBXPROJ_PATH = os.path.join(OUTPUT_DIR, "project.pbxproj")

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── Source Files ────────────────────────────────────────────────────────

MAIN_SOURCES = [
    "App/MeloPlayerApp.swift",
    "App/RootTabView.swift",
    "Core/Audio/AudioEngineCoordinator.swift",
    "Core/Audio/AudioSessionManager.swift",
    "Core/Audio/EqualizerManager.swift",
    "Core/Audio/RemoteCommandManager.swift",
    "Core/Data/LibraryStore.swift",
    "Core/Data/Models/Track.swift",
    "Core/Data/Models/Playlist.swift",
    "Core/Data/Models/DownloadedTrack.swift",
    "Core/Data/Models/PlayQueue.swift",
    "Core/Downloads/DownloadManager.swift",
    "Core/FileSystem/LocalFileImporter.swift",
    "Core/Network/AudioSource.swift",
    "Core/Network/GlitchiAPIClient.swift",
    "Features/Browse/AudiusSearchView.swift",
    "Features/Browse/BrowseView.swift",
    "Features/Browse/BrowseViewModel.swift",
    "Features/Browse/GenreListView.swift",
    "Features/Browse/TrackRowView.swift",
    "Features/Folders/FolderBrowserView.swift",
    "Features/Folders/FolderViewModel.swift",
    "Features/Library/AlbumsGridView.swift",
    "Features/Library/ArtistsListView.swift",
    "Features/Library/FavoritesView.swift",
    "Features/Library/LibraryView.swift",
    "Features/Library/PlaylistsView.swift",
    "Features/Player/AirPlayRouteButton.swift",
    "Features/Player/CustomSlider.swift",
    "Features/Player/EqualizerView.swift",
    "Features/Player/MiniPlayerView.swift",
    "Features/Player/NowPlayingView.swift",
    "Features/Player/PlayerViewModel.swift",
    "Features/Player/QueueView.swift",
    "Features/Player/SleepTimerSheet.swift",
    "Features/Settings/SettingsView.swift",
    "Features/Settings/ThemeManager.swift",
]

WIDGET_SOURCES = [
    "MeloWidgetExtension/MeloWidgetBundle.swift",
    "MeloWidgetExtension/NowPlayingWidget.swift",
    "MeloWidgetExtension/NowPlayingWidgetView.swift",
    "MeloWidgetExtension/WidgetIntents.swift",
]

MAIN_RESOURCES = [
    "Resources/Assets.xcassets",
]

WIDGET_RESOURCES = []

# ── UUID Generator ───────────────────────────────────────────────────────

def gen_uuid(seed):
    h = hashlib.md5(seed.encode()).hexdigest().upper()
    return h[:8] + h[8:12] + h[12:16] + h[16:20] + h[20:32]

# ── Collect & Verify Files ───────────────────────────────────────────────

all_files = []
for f in MAIN_SOURCES:
    all_files.append(("source", f, "main"))
for f in WIDGET_SOURCES:
    all_files.append(("source", f, "widget"))
for f in MAIN_RESOURCES:
    all_files.append(("resource", f, "main"))
for f in WIDGET_RESOURCES:
    all_files.append(("resource", f, "widget"))

missing = []
for _, f, _ in all_files:
    full = os.path.join(PROJECT_ROOT, f)
    if not os.path.exists(full):
        missing.append(f)

if missing:
    print("ERROR: Missing files:")
    for m in missing:
        print(f"  - {m}")
    sys.exit(1)

print(f"[OK] All {len(all_files)} files verified")

# ── Generate IDs ─────────────────────────────────────────────────────────

file_refs = {}
build_files = {}

for kind, f, target in all_files:
    file_refs[f] = gen_uuid(f"PBXFileReference_{f}")
    build_files[f] = gen_uuid(f"PBXBuildFile_{f}")

all_groups = ["App", "Core", "Core/Audio", "Core/Network", "Core/Downloads",
              "Core/Data", "Core/Data/Models", "Core/FileSystem",
              "Features", "Features/Player", "Features/Library",
              "Features/Browse", "Features/Folders", "Features/Settings",
              "MeloWidgetExtension"]
groups = {g: gen_uuid(f"PBXGroup_{g}") for g in all_groups}

main_src_phase   = gen_uuid("PBXSourcesBuildPhase_main")
main_res_phase   = gen_uuid("PBXResourcesBuildPhase_main")
main_fwk_phase   = gen_uuid("PBXFrameworksBuildPhase_main")
widget_src_phase = gen_uuid("PBXSourcesBuildPhase_widget")
widget_res_phase = gen_uuid("PBXResourcesBuildPhase_widget")
widget_fwk_phase = gen_uuid("PBXFrameworksBuildPhase_widget")

main_target_id    = gen_uuid("PBXNativeTarget_main")
widget_target_id  = gen_uuid("PBXNativeTarget_widget")
product_main_id   = gen_uuid("PBXFileReference_product_main")
product_widget_id = gen_uuid("PBXFileReference_product_widget")

project_id   = gen_uuid("PBXProject")
main_group_id = gen_uuid("PBXGroup_main")
products_group_id = gen_uuid("PBXGroup_Products")

main_config_list   = gen_uuid("XCConfigurationList_main")
widget_config_list = gen_uuid("XCConfigurationList_widget")
proj_config_list   = gen_uuid("XCConfigurationList_project")

main_debug     = gen_uuid("XCBuildConfiguration_main_debug")
main_release   = gen_uuid("XCBuildConfiguration_main_release")
widget_debug   = gen_uuid("XCBuildConfiguration_widget_debug")
widget_release = gen_uuid("XCBuildConfiguration_widget_release")
proj_debug     = gen_uuid("XCBuildConfiguration_project_debug")
proj_release   = gen_uuid("XCBuildConfiguration_project_release")

# ── Helpers ──────────────────────────────────────────────────────────────

def last_known_file_type(path):
    """Return the lastKnownFileType for a given file path."""
    if path.endswith(".xcassets"):
        return "folder.assetcatalog"
    ext = os.path.splitext(path)[1]
    if ext == ".swift":
        return "sourcecode.swift"
    if ext == ".plist":
        return "text.plist.xml"
    return "file"

def strip_os_quotes(v):
    """Remove manual OpenStep plist double-quoting from a string value.
    E.g. '"$(TARGET_NAME)"' -> '$(TARGET_NAME)'
         '""' -> ''
         'Normal' -> 'Normal'
    """
    if isinstance(v, str) and len(v) >= 2 and v.startswith('"') and v.endswith('"'):
        return v[1:-1]
    return v

# ── Build the objects dict ───────────────────────────────────────────────

objects = {}

# --- PBXFileReference ---

def file_ref_obj(path, name=None, explicit_file_type=None, source_tree="SOURCE_ROOT", include_in_index=None):
    """Create a PBXFileReference dict."""
    obj = {
        "isa": "PBXFileReference",
        "lastKnownFileType": last_known_file_type(path),
        "path": path,
        "sourceTree": source_tree,
    }
    if explicit_file_type:
        del obj["lastKnownFileType"]
        obj["explicitFileType"] = explicit_file_type
    if include_in_index is not None:
        obj["includeInIndex"] = include_in_index
    return obj

for kind, path, target in all_files:
    fid = file_refs[path]
    objects[fid] = file_ref_obj(path)

# Product file references
objects[product_main_id] = {
    "isa": "PBXFileReference",
    "explicitFileType": "wrapper.application",
    "includeInIndex": 0,
    "path": "MeloPlayerClone.app",
    "sourceTree": "BUILT_PRODUCTS_DIR",
}
objects[product_widget_id] = {
    "isa": "PBXFileReference",
    "explicitFileType": "wrapper.app-extension",
    "includeInIndex": 0,
    "path": "MeloWidgetExtension.appex",
    "sourceTree": "BUILT_PRODUCTS_DIR",
}

# --- PBXBuildFile ---

for kind, path, target in all_files:
    objects[build_files[path]] = {
        "isa": "PBXBuildFile",
        "fileRef": file_refs[path],
    }

# --- PBXGroup ---

def group_obj(children, name=None, source_tree="<group>"):
    """Create a PBXGroup dict."""
    obj = {
        "isa": "PBXGroup",
        "children": children,
        "sourceTree": source_tree,
    }
    if name is not None:
        obj["name"] = name
    return obj

# File lists by group
app_files          = [file_refs[f] for _, f, _ in all_files if f.startswith("App/")]
core_audio         = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Audio/")]
core_network       = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Network/")]
core_downloads     = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Downloads/")]
core_data_models   = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Data/Models/")]
core_data          = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Data/") and not f.startswith("Core/Data/Models/")]
core_fs            = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/FileSystem/")]
features_player    = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Player/")]
features_library   = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Library/")]
features_browse    = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Browse/")]
features_folders   = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Folders/")]
features_settings  = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Settings/")]
resources_refs     = [file_refs[f] for _, f, _ in all_files if f.startswith("Resources/")]
widget_refs        = [file_refs[f] for _, f, _ in all_files if f.startswith("MeloWidgetExtension/")]

# Leaf groups
objects[groups["App"]]                  = group_obj(app_files, "App")
objects[groups["Core/Audio"]]           = group_obj(core_audio, "Audio")
objects[groups["Core/Network"]]         = group_obj(core_network, "Network")
objects[groups["Core/Downloads"]]       = group_obj(core_downloads, "Downloads")
objects[groups["Core/Data/Models"]]     = group_obj(core_data_models, "Models")
objects[groups["Core/Data"]]            = group_obj(core_data + [groups["Core/Data/Models"]], "Data")
objects[groups["Core/FileSystem"]]      = group_obj(core_fs, "FileSystem")
objects[groups["Core"]]                 = group_obj([
    groups["Core/Audio"], groups["Core/Network"], groups["Core/Downloads"],
    groups["Core/Data"], groups["Core/FileSystem"]
], "Core")
objects[groups["Features/Player"]]      = group_obj(features_player, "Player")
objects[groups["Features/Library"]]     = group_obj(features_library, "Library")
objects[groups["Features/Browse"]]      = group_obj(features_browse, "Browse")
objects[groups["Features/Folders"]]     = group_obj(features_folders, "Folders")
objects[groups["Features/Settings"]]    = group_obj(features_settings, "Settings")
objects[groups["Features"]]             = group_obj([
    groups["Features/Player"], groups["Features/Library"], groups["Features/Browse"],
    groups["Features/Folders"], groups["Features/Settings"]
], "Features")
objects[groups["MeloWidgetExtension"]]  = group_obj(widget_refs, "MeloWidgetExtension")

# Products group
objects[products_group_id] = {
    "isa": "PBXGroup",
    "children": [product_main_id, product_widget_id],
    "name": "Products",
    "sourceTree": "<group>",
}

# Root group
root_children = [groups["App"], groups["Core"], groups["Features"],
                 groups["MeloWidgetExtension"]] + resources_refs + [products_group_id]
objects[main_group_id] = group_obj(root_children)

# --- PBXNativeTarget ---

objects[main_target_id] = {
    "isa": "PBXNativeTarget",
    "buildConfigurationList": main_config_list,
    "buildPhases": [main_src_phase, main_fwk_phase, main_res_phase],
    "buildRules": [],
    "dependencies": [],
    "name": "MeloPlayerClone",
    "productName": "MeloPlayerClone",
    "productReference": product_main_id,
    "productType": "com.apple.product-type.application",
}

objects[widget_target_id] = {
    "isa": "PBXNativeTarget",
    "buildConfigurationList": widget_config_list,
    "buildPhases": [widget_src_phase, widget_fwk_phase, widget_res_phase],
    "buildRules": [],
    "dependencies": [],
    "name": "MeloWidgetExtension",
    "productName": "MeloWidgetExtension",
    "productReference": product_widget_id,
    "productType": "com.apple.product-type.app-extension",
}

# --- PBXProject ---

objects[project_id] = {
    "isa": "PBXProject",
    "attributes": {
        "BuildIndependentTargetsInParallel": 1,
        "LastSwiftUpdateCheck": "1600",
        "LastUpgradeCheck": "1600",
        "TargetAttributes": {
            main_target_id: {"CreatedOnToolsVersion": "16.0"},
            widget_target_id: {"CreatedOnToolsVersion": "16.0"},
        },
    },
    "buildConfigurationList": proj_config_list,
    "compatibilityVersion": "Xcode 16.0",
    "developmentRegion": "en",
    "hasScannedForEncodings": 0,
    "knownRegions": ["en", "Base"],
    "mainGroup": main_group_id,
    "productRefGroup": products_group_id,
    "projectDirPath": "",
    "projectRoot": "",
    "targets": [main_target_id, widget_target_id],
}

# --- PBXSourcesBuildPhase ---

main_src_bfs   = [build_files[f] for _, f, t in all_files if t == "main" and f.endswith(".swift")]
widget_src_bfs = [build_files[f] for _, f, t in all_files if t == "widget" and f.endswith(".swift")]

objects[main_src_phase] = {
    "isa": "PBXSourcesBuildPhase",
    "buildActionMask": 2147483647,
    "files": main_src_bfs,
    "runOnlyForDeploymentPostprocessing": 0,
}
objects[widget_src_phase] = {
    "isa": "PBXSourcesBuildPhase",
    "buildActionMask": 2147483647,
    "files": widget_src_bfs,
    "runOnlyForDeploymentPostprocessing": 0,
}

# --- PBXResourcesBuildPhase ---

main_res_bfs   = [build_files[f] for _, f, t in all_files if t == "main" and (f.endswith(".xcassets") or f.endswith(".plist"))]
widget_res_bfs = [build_files[f] for _, f, t in all_files if t == "widget" and (f.endswith(".xcassets") or f.endswith(".plist"))]

objects[main_res_phase] = {
    "isa": "PBXResourcesBuildPhase",
    "buildActionMask": 2147483647,
    "files": main_res_bfs,
    "runOnlyForDeploymentPostprocessing": 0,
}
objects[widget_res_phase] = {
    "isa": "PBXResourcesBuildPhase",
    "buildActionMask": 2147483647,
    "files": widget_res_bfs,
    "runOnlyForDeploymentPostprocessing": 0,
}

# --- PBXFrameworksBuildPhase ---

objects[main_fwk_phase] = {
    "isa": "PBXFrameworksBuildPhase",
    "buildActionMask": 2147483647,
    "files": [],
    "runOnlyForDeploymentPostprocessing": 0,
}
objects[widget_fwk_phase] = {
    "isa": "PBXFrameworksBuildPhase",
    "buildActionMask": 2147483647,
    "files": [],
    "runOnlyForDeploymentPostprocessing": 0,
}

# --- XCBuildConfiguration ---

def build_config_obj(name, settings):
    """Create an XCBuildConfiguration dict with all settings stripped of OS quotes."""
    clean = {k: strip_os_quotes(v) for k, v in settings.items()}
    return {
        "isa": "XCBuildConfiguration",
        "buildSettings": clean,
        "name": name,
    }

# Project-level settings
proj_debug_settings = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_CXX_LANGUAGE_STANDARD": '"gnu++20"',
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": '"DEBUG=1 $(inherited)"',
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
    "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "SWIFT_VERSION": "5.0",
}

proj_release_settings = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_CXX_LANGUAGE_STANDARD": '"gnu++20"',
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
    "ENABLE_NS_ASSERTIONS": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "GCC_OPTIMIZATION_LEVEL": "s",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "SWIFT_OPTIMIZATION_LEVEL": '"-O"',
    "VALIDATE_PRODUCT": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "SWIFT_VERSION": "5.0",
}

objects[proj_debug]   = build_config_obj("Debug", proj_debug_settings)
objects[proj_release] = build_config_obj("Release", proj_release_settings)

# Main target settings
main_target_settings = {
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": "MeloPlayer",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": '"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"',
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.meloplayer.app",
    "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": '"1,2"',
}

objects[main_debug]   = build_config_obj("Debug", main_target_settings)
objects[main_release] = build_config_obj("Release", main_target_settings)

# Widget target settings
widget_target_settings = {
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": "MeloWidget",
    "INFOPLIST_KEY_NSHumanReadableCopyright": '""',
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.meloplayer.app.widget",
    "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SKIP_INSTALL": "YES",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": '"1,2"',
}

objects[widget_debug]   = build_config_obj("Debug", widget_target_settings)
objects[widget_release] = build_config_obj("Release", widget_target_settings)

# --- XCConfigurationList ---

def config_list_obj(configs, default_name="Release"):
    return {
        "isa": "XCConfigurationList",
        "buildConfigurations": configs,
        "defaultConfigurationIsVisible": 0,
        "defaultConfigurationName": default_name,
    }

objects[proj_config_list]   = config_list_obj([proj_debug, proj_release])
objects[main_config_list]   = config_list_obj([main_debug, main_release])
objects[widget_config_list] = config_list_obj([widget_debug, widget_release])

# ── Root object ──────────────────────────────────────────────────────────

pbxproj = {
    "archiveVersion": "1",
    "classes": {},
    "objectVersion": "60",
    "objects": objects,
    "rootObject": project_id,
}

# ── Write file ───────────────────────────────────────────────────────────

with open(PBXPROJ_PATH, "w", encoding="utf-8", newline="\n") as f:
    json.dump(pbxproj, f, separators=(",", ":"))
    f.write("\n")

print(f"[OK] Wrote {PBXPROJ_PATH} ({os.path.getsize(PBXPROJ_PATH)} bytes)")

# ── Write xcscheme ──────────────────────────────────────────────────────

xcschemes_dir = os.path.join(OUTPUT_DIR, "xcshareddata", "xcschemes")
os.makedirs(xcschemes_dir, exist_ok=True)
scheme_path = os.path.join(xcschemes_dir, "MeloPlayerClone.xcscheme")

scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{main_target_id}"
               BuildableName = "MeloPlayerClone.app"
               BlueprintName = "MeloPlayerClone"
               ReferencedContainer = "container:MeloPlayerClone.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{main_target_id}"
            BuildableName = "MeloPlayerClone.app"
            BlueprintName = "MeloPlayerClone"
            ReferencedContainer = "container:MeloPlayerClone.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{main_target_id}"
            BuildableName = "MeloPlayerClone.app"
            BlueprintName = "MeloPlayerClone"
            ReferencedContainer = "container:MeloPlayerClone.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''

with open(scheme_path, "w", encoding="utf-8", newline="\n") as f:
    f.write(scheme)

print(f"[OK] Wrote {scheme_path}")
print("[OK] Xcode project generation complete!")
