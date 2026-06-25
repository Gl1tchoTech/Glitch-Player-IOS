#!/usr/bin/env python3
"""Generate a valid Xcode project.pbxproj for MeloPlayerClone."""

import os, uuid, hashlib, sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "MeloPlayerClone.xcodeproj")
PBXPROJ_PATH = os.path.join(OUTPUT_DIR, "project.pbxproj")

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── Files ─────────────────────────────────────────────────────────────

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
    "Resources/Info.plist",
]

WIDGET_RESOURCES = [
]

# ---- UUID generator ----
def gen_uuid(seed):
    h = hashlib.md5(seed.encode()).hexdigest().upper()
    return h[:8] + h[8:12] + h[12:16] + h[16:20] + h[20:32]

# ---- Collect all files ----
all_files = []
for f in MAIN_SOURCES:
    all_files.append(("source", f, "main"))
for f in WIDGET_SOURCES:
    all_files.append(("source", f, "widget"))
for f in MAIN_RESOURCES:
    all_files.append(("resource", f, "main"))
for f in WIDGET_RESOURCES:
    all_files.append(("resource", f, "widget"))

# Verify files exist
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

# ---- Generate IDs ----
# File reference IDs
file_refs = {}
build_files = {}

idx = 0
for kind, f, target in all_files:
    idx += 1
    fid = gen_uuid(f"PBXFileReference_{f}")
    bfid = gen_uuid(f"PBXBuildFile_{f}")
    file_refs[f] = fid
    build_files[f] = bfid

# Group IDs
groups = {}
all_groups = ["App", "Core", "Core/Audio", "Core/Network", "Core/Downloads",
              "Core/Data", "Core/Data/Models", "Core/FileSystem",
              "Features", "Features/Player", "Features/Library",
              "Features/Browse", "Features/Folders", "Features/Settings",
              "Resources", "MeloWidgetExtension"]
for g in all_groups:
    groups[g] = gen_uuid(f"PBXGroup_{g}")

# Build phase IDs
main_src_phase = gen_uuid("PBXSourcesBuildPhase_main")
main_res_phase = gen_uuid("PBXResourcesBuildPhase_main")
main_fwk_phase = gen_uuid("PBXFrameworksBuildPhase_main")
widget_src_phase = gen_uuid("PBXSourcesBuildPhase_widget")
widget_res_phase = gen_uuid("PBXResourcesBuildPhase_widget")
widget_fwk_phase = gen_uuid("PBXFrameworksBuildPhase_widget")

# Target IDs
main_target_id = gen_uuid("PBXNativeTarget_main")
widget_target_id = gen_uuid("PBXNativeTarget_widget")
product_main_id = gen_uuid("PBXFileReference_product_main")
product_widget_id = gen_uuid("PBXFileReference_product_widget")

# Project ID
project_id = gen_uuid("PBXProject")
main_group_id = gen_uuid("PBXGroup_main")  # root group

# Config list IDs
main_config_list = gen_uuid("XCConfigurationList_main")
widget_config_list = gen_uuid("XCConfigurationList_widget")
proj_config_list = gen_uuid("XCConfigurationList_project")

# Build config IDs
main_debug = gen_uuid("XCBuildConfiguration_main_debug")
main_release = gen_uuid("XCBuildConfiguration_main_release")
widget_debug = gen_uuid("XCBuildConfiguration_widget_debug")
widget_release = gen_uuid("XCBuildConfiguration_widget_release")
proj_debug = gen_uuid("XCBuildConfiguration_project_debug")
proj_release = gen_uuid("XCBuildConfiguration_project_release")

# ---- Write pbxproj ----
tab = "\t"

def pbx_file_ref(path, name=None, filetype="sourcecode.swift"):
    if name is None:
        name = os.path.basename(path)
    fid = file_refs[path]
    ext = os.path.splitext(path)[1]
    if ext == ".swift":
        lfp = "sourcecode.swift"
    elif ext == ".plist":
        lfp = "text.plist.xml"
        filetype = "text.plist.xml"
    else:
        lfp = "file"
    # For folders/asset catalogs
    if path.endswith(".xcassets"):
        lfp = "folder.assetcatalog"
        
    return f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {lfp}; path = "{name}"; sourceTree = "<group>"; }};'

def pbx_file_ref_resource(path):
    name = os.path.basename(path)
    fid = file_refs[path]
    if path.endswith(".xcassets"):
        lfp = "folder.assetcatalog"
    elif path.endswith(".plist"):
        lfp = "text.plist.xml"
    else:
        lfp = "file"
    return f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {lfp}; path = "{name}"; sourceTree = "<group>"; }};'

def pbx_build_file(file_path, kind="source"):
    bfid = build_files[file_path]
    fid = file_refs[file_path]
    return f'\t\t{bfid} /* {os.path.basename(file_path)} in {kind.capitalize()} */ = {{isa = PBXBuildFile; fileRef = {fid} /* {os.path.basename(file_path)} */; }};'

def pbx_group(gid, name, children_ids, indent=2):
    istr = tab * indent
    kids = ",\n\t\t\t\t".join(children_ids)
    return f'{istr}{gid} /* {name} */ = {{\n{istr}\tisa = PBXGroup;\n{istr}\tchildren = (\n{istr}\t\t\t\t{kids},\n{istr}\t\t\t);\n{istr}\tsourceTree = "<group>";\n{istr}}};'

def pbx_native_target(tid, name, product_id, src_phase, res_phase, fwk_phase, config_list, deps=None):
    deps_str = ""
    if deps:
        deps_str = f'\n{tab}{tab}{tab}{tab}{tab}{",\n\t\t\t\t\t".join(deps)},\n{tab}{tab}{tab}{tab}'
    return f'''{tab}{tab}{tid} /* {name} */ = {{
{tab}{tab}{tab}isa = PBXNativeTarget;
{tab}{tab}{tab}buildConfigurationList = {config_list} /* Build configuration list for PBXNativeTarget "{name}" */;
{tab}{tab}{tab}buildPhases = (
{tab}{tab}{tab}{tab}{src_phase} /* Sources */,
{tab}{tab}{tab}{tab}{fwk_phase} /* Frameworks */,
{tab}{tab}{tab}{tab}{res_phase} /* Resources */,
{tab}{tab}{tab});
{tab}{tab}{tab}buildRules = (
{tab}{tab}{tab});
{tab}{tab}{tab}dependencies = ({deps_str}
{tab}{tab}{tab});
{tab}{tab}{tab}name = {name};
{tab}{tab}{tab}productName = {name};
{tab}{tab}{tab}productReference = {product_id} /* {name}.app */;
{tab}{tab}{tab}productType = "com.apple.product-type.application";
{tab}{tab}}};'''

def pbx_native_target_widget(tid, name, product_id, src_phase, res_phase, fwk_phase, config_list):
    return f'''{tab}{tab}{tid} /* {name} */ = {{
{tab}{tab}{tab}isa = PBXNativeTarget;
{tab}{tab}{tab}buildConfigurationList = {config_list} /* Build configuration list for PBXNativeTarget "{name}" */;
{tab}{tab}{tab}buildPhases = (
{tab}{tab}{tab}{tab}{src_phase} /* Sources */,
{tab}{tab}{tab}{tab}{fwk_phase} /* Frameworks */,
{tab}{tab}{tab}{tab}{res_phase} /* Resources */,
{tab}{tab}{tab});
{tab}{tab}{tab}buildRules = (
{tab}{tab}{tab});
{tab}{tab}{tab}dependencies = (
{tab}{tab}{tab});
{tab}{tab}{tab}name = {name};
{tab}{tab}{tab}productName = {name};
{tab}{tab}{tab}productReference = {product_id} /* {name}.appex */;
{tab}{tab}{tab}productType = "com.apple.product-type.app-extension";
{tab}{tab}}};'''

def pbx_sources_phase(phase_id, build_file_ids):
    if build_file_ids:
        bf = ",\n\t\t\t\t".join(build_file_ids)
        inner = f"{tab}{tab}{tab}{tab}{bf},\n{tab}{tab}{tab}"
    else:
        inner = ""
    return f'''{tab}{tab}{phase_id} /* Sources */ = {{
{tab}{tab}{tab}isa = PBXSourcesBuildPhase;
{tab}{tab}{tab}buildActionMask = 2147483647;
{tab}{tab}{tab}files = (
{tab}{tab}{tab}{tab}{inner if inner else ""}{tab}{tab}{tab});
{tab}{tab}{tab}runOnlyForDeploymentPostprocessing = 0;
{tab}{tab}}};'''

def pbx_resources_phase(phase_id, build_file_ids):
    if build_file_ids:
        bf = ",\n\t\t\t\t".join(build_file_ids)
        inner = f"{tab}{tab}{tab}{tab}{bf},\n{tab}{tab}{tab}"
    else:
        inner = ""
    return f'''{tab}{tab}{phase_id} /* Resources */ = {{
{tab}{tab}{tab}isa = PBXResourcesBuildPhase;
{tab}{tab}{tab}buildActionMask = 2147483647;
{tab}{tab}{tab}files = (
{tab}{tab}{tab}{tab}{inner if inner else ""}{tab}{tab}{tab});
{tab}{tab}{tab}runOnlyForDeploymentPostprocessing = 0;
{tab}{tab}}};'''

def pbx_frameworks_phase(phase_id):
    return f'''{tab}{tab}{phase_id} /* Frameworks */ = {{
{tab}{tab}{tab}isa = PBXFrameworksBuildPhase;
{tab}{tab}{tab}buildActionMask = 2147483647;
{tab}{tab}{tab}files = (
{tab}{tab}{tab});
{tab}{tab}{tab}runOnlyForDeploymentPostprocessing = 0;
{tab}{tab}}};'''

def _needs_quoting(v):
    """NeXTSTEP plist: values with spaces, commas, or parens need double quotes."""
    if v.startswith('"') and v.endswith('"'):
        return v  # already quoted
    if v == '':
        return '""'
    # Characters that break NeXTSTEP parsing: space, comma, parens, =
    if any(c in v for c in (' ', ',', '(', ')', '=', ';')):
        return f'"{v}"'
    return v

def pbx_config(config_id, name, settings, isa="XCBuildConfiguration"):
    sets = "\n".join(
        f'{tab}{tab}{tab}{tab}{k} = {_needs_quoting(v)};'
        for k, v in settings.items()
    )
    return f'''{tab}{tab}{config_id} /* {name} */ = {{
{tab}{tab}{tab}isa = {isa};
{tab}{tab}{tab}buildSettings = {{
{sets}
{tab}{tab}{tab}}};
{tab}{tab}{tab}name = {name};
{tab}{tab}}};'''

# ── Assemble PBXProj ────────────────────────────────────────────────

lines = []
# NOTE: No "// !$*UTF8*$!" header — Xcode 26+ parses pbxproj with JSON first,
# and the // comment causes NSJSONSerialization to fail at line 1 column 0.
# Starting with { allows both OpenStep plist and JSON parsers to proceed.
lines.append("{")
lines.append(f'\tarchiveVersion = 1;')
lines.append(f'\tclasses = {{')
lines.append(f'\t}};')
lines.append(f'\tobjectVersion = 60;')
lines.append(f'\tobjects = {{')
lines.append(f'')

# PBXFileReference section
lines.append(f'\n/* Begin PBXFileReference section */')
for kind, path, target in all_files:
    if kind == "source":
        lines.append(pbx_file_ref(path))
    else:
        lines.append(pbx_file_ref_resource(path))
# Products
lines.append(f'\t\t{product_main_id} /* MeloPlayerClone.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MeloPlayerClone.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
lines.append(f'\t\t{product_widget_id} /* MeloWidgetExtension.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = MeloWidgetExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};')
lines.append(f'/* End PBXFileReference section */')

# PBXBuildFile section
lines.append(f'\n/* Begin PBXBuildFile section */')
for kind, path, target in all_files:
    lines.append(pbx_build_file(path, kind=kind))
lines.append(f'/* End PBXBuildFile section */')

# PBXGroup section
lines.append(f'\n/* Begin PBXGroup section */')

# Assemble file group tree
app_files = [file_refs[f] for _, f, _ in all_files if f.startswith("App/")]
core_audio = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Audio/")]
core_network = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Network/")]
core_downloads = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Downloads/")]
core_data_models = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Data/Models/")]
core_data = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/Data/") and not f.startswith("Core/Data/Models/")]
core_fs = [file_refs[f] for _, f, _ in all_files if f.startswith("Core/FileSystem/")]
core_group_kids = [groups["Core/Audio"], groups["Core/Network"], groups["Core/Downloads"], groups["Core/Data"], groups["Core/FileSystem"]]

features_player = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Player/")]
features_library = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Library/")]
features_browse = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Browse/")]
features_folders = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Folders/")]
features_settings = [file_refs[f] for _, f, _ in all_files if f.startswith("Features/Settings/")]
features_group_kids = [groups["Features/Player"], groups["Features/Library"], groups["Features/Browse"], groups["Features/Folders"], groups["Features/Settings"]]

resources_refs = [file_refs[f] for _, f, _ in all_files if f.startswith("Resources/")]
widget_refs = [file_refs[f] for _, f, _ in all_files if f.startswith("MeloWidgetExtension/")]

# Root group children
root_group_kids = app_files + [groups["Core"], groups["Features"]] + resources_refs + [groups["MeloWidgetExtension"]]
root_group_kids = [x for x in root_group_kids if x]  # filter empties

# Write groups
lines.append(pbx_group(groups["App"], "App", app_files))
lines.append(pbx_group(groups["Core/Audio"], "Audio", core_audio))
lines.append(pbx_group(groups["Core/Network"], "Network", core_network))
lines.append(pbx_group(groups["Core/Downloads"], "Downloads", core_downloads))
lines.append(pbx_group(groups["Core/Data/Models"], "Models", core_data_models))
lines.append(pbx_group(groups["Core/Data"], "Data", core_data + [groups["Core/Data/Models"]]))
lines.append(pbx_group(groups["Core/FileSystem"], "FileSystem", core_fs))
lines.append(pbx_group(groups["Core"], "Core", [groups["Core/Audio"], groups["Core/Network"], groups["Core/Downloads"], groups["Core/Data"], groups["Core/FileSystem"]]))
lines.append(pbx_group(groups["Features/Player"], "Player", features_player))
lines.append(pbx_group(groups["Features/Library"], "Library", features_library))
lines.append(pbx_group(groups["Features/Browse"], "Browse", features_browse))
lines.append(pbx_group(groups["Features/Folders"], "Folders", features_folders))
lines.append(pbx_group(groups["Features/Settings"], "Settings", features_settings))
lines.append(pbx_group(groups["Features"], "Features", [groups["Features/Player"], groups["Features/Library"], groups["Features/Browse"], groups["Features/Folders"], groups["Features/Settings"]]))
lines.append(pbx_group(groups["MeloWidgetExtension"], "MeloWidgetExtension", widget_refs))

# Root group
products_group_id = gen_uuid("PBXGroup_Products")
lines.append(f'\t\t{products_group_id} /* Products */ = {{isa = PBXGroup; children = ({product_main_id} /* MeloPlayerClone.app */, {product_widget_id} /* MeloWidgetExtension.appex */,); name = Products; sourceTree = "<group>"; }};')
lines.append(pbx_group(main_group_id, "", [groups["App"], groups["Core"], groups["Features"], groups["MeloWidgetExtension"]] + resources_refs + [products_group_id]))
lines.append(f'/* End PBXGroup section */')

# PBXNativeTarget section
lines.append(f'\n/* Begin PBXNativeTarget section */')
lines.append(pbx_native_target(main_target_id, "MeloPlayerClone", product_main_id, main_src_phase, main_res_phase, main_fwk_phase, main_config_list))
lines.append(pbx_native_target_widget(widget_target_id, "MeloWidgetExtension", product_widget_id, widget_src_phase, widget_res_phase, widget_fwk_phase, widget_config_list))
lines.append(f'/* End PBXNativeTarget section */')

# PBXProject section
lines.append(f'\n/* Begin PBXProject section */')
lines.append(f'''{tab}{tab}{project_id} /* Project object */ = {{
{tab}{tab}{tab}isa = PBXProject;
{tab}{tab}{tab}attributes = {{
{tab}{tab}{tab}{tab}BuildIndependentTargetsInParallel = 1;
{tab}{tab}{tab}{tab}LastSwiftUpdateCheck = 1600;
{tab}{tab}{tab}{tab}LastUpgradeCheck = 1600;
{tab}{tab}{tab}{tab}TargetAttributes = {{
{tab}{tab}{tab}{tab}{tab}{main_target_id} = {{
{tab}{tab}{tab}{tab}{tab}{tab}CreatedOnToolsVersion = 16.0;
{tab}{tab}{tab}{tab}{tab}}};
{tab}{tab}{tab}{tab}{tab}{widget_target_id} = {{
{tab}{tab}{tab}{tab}{tab}{tab}CreatedOnToolsVersion = 16.0;
{tab}{tab}{tab}{tab}{tab}}};
{tab}{tab}{tab}{tab}}};
{tab}{tab}{tab}}};
{tab}{tab}{tab}buildConfigurationList = {proj_config_list} /* Build configuration list for PBXProject "MeloPlayerClone" */;
{tab}{tab}{tab}compatibilityVersion = "Xcode 16.0";
{tab}{tab}{tab}developmentRegion = en;
{tab}{tab}{tab}hasScannedForEncodings = 0;
{tab}{tab}{tab}knownRegions = (
{tab}{tab}{tab}{tab}en,
{tab}{tab}{tab}{tab}Base,
{tab}{tab}{tab});
{tab}{tab}{tab}mainGroup = {main_group_id};
{tab}{tab}{tab}productRefGroup = {products_group_id} /* Products */;
{tab}{tab}{tab}projectDirPath = "";
{tab}{tab}{tab}projectRoot = "";
{tab}{tab}{tab}targets = (
{tab}{tab}{tab}{tab}{main_target_id} /* MeloPlayerClone */,
{tab}{tab}{tab}{tab}{widget_target_id} /* MeloWidgetExtension */,
{tab}{tab}{tab});
{tab}{tab}}};''')
lines.append(f'/* End PBXProject section */')

# PBXSourcesBuildPhase section
lines.append(f'\n/* Begin PBXSourcesBuildPhase section */')
main_src_bfs = [build_files[f] for _, f, t in all_files if t == "main" and f.endswith(".swift")]
widget_src_bfs = [build_files[f] for _, f, t in all_files if t == "widget" and f.endswith(".swift")]
lines.append(pbx_sources_phase(main_src_phase, main_src_bfs))
lines.append(pbx_sources_phase(widget_src_phase, widget_src_bfs))
lines.append(f'/* End PBXSourcesBuildPhase section */')

# PBXResourcesBuildPhase section
lines.append(f'\n/* Begin PBXResourcesBuildPhase section */')
main_res_bfs = [build_files[f] for _, f, t in all_files if t == "main" and f.endswith((".xcassets", ".plist"))]
widget_res_bfs = [build_files[f] for _, f, t in all_files if t == "widget" and (f.endswith(".xcassets") or f.endswith(".plist"))]
lines.append(pbx_resources_phase(main_res_phase, main_res_bfs))
lines.append(pbx_resources_phase(widget_res_phase, widget_res_bfs))
lines.append(f'/* End PBXResourcesBuildPhase section */')

# PBXFrameworksBuildPhase section
lines.append(f'\n/* Begin PBXFrameworksBuildPhase section */')
lines.append(pbx_frameworks_phase(main_fwk_phase))
lines.append(pbx_frameworks_phase(widget_fwk_phase))
lines.append(f'/* End PBXFrameworksBuildPhase section */')

# XCBuildConfiguration section
lines.append(f'\n/* Begin XCBuildConfiguration section */')

# Project-level debug config
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
lines.append(pbx_config(proj_debug, "Debug", proj_debug_settings))

# Project-level release config
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
lines.append(pbx_config(proj_release, "Release", proj_release_settings))

# Main target debug
main_debug_settings = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
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
    "INFOPLIST_FILE": "Resources/Info.plist",
}
lines.append(pbx_config(main_debug, "Debug", main_debug_settings))

# Main target release
main_release_settings = dict(main_debug_settings)
lines.append(pbx_config(main_release, "Release", main_release_settings))

# Widget debug
widget_debug_settings = {
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
lines.append(pbx_config(widget_debug, "Debug", widget_debug_settings))

# Widget release
widget_release_settings = dict(widget_debug_settings)
lines.append(pbx_config(widget_release, "Release", widget_release_settings))

lines.append(f'/* End XCBuildConfiguration section */')

# XCConfigurationList section
lines.append(f'\n/* Begin XCConfigurationList section */')
lines.append(f'''{tab}{tab}{proj_config_list} /* Build configuration list for PBXProject "MeloPlayerClone" */ = {{
{tab}{tab}{tab}isa = XCConfigurationList;
{tab}{tab}{tab}buildConfigurations = (
{tab}{tab}{tab}{tab}{proj_debug} /* Debug */,
{tab}{tab}{tab}{tab}{proj_release} /* Release */,
{tab}{tab}{tab});
{tab}{tab}{tab}defaultConfigurationIsVisible = 0;
{tab}{tab}{tab}defaultConfigurationName = Release;
{tab}{tab}}};''')
lines.append(f'''{tab}{tab}{main_config_list} /* Build configuration list for PBXNativeTarget "MeloPlayerClone" */ = {{
{tab}{tab}{tab}isa = XCConfigurationList;
{tab}{tab}{tab}buildConfigurations = (
{tab}{tab}{tab}{tab}{main_debug} /* Debug */,
{tab}{tab}{tab}{tab}{main_release} /* Release */,
{tab}{tab}{tab});
{tab}{tab}{tab}defaultConfigurationIsVisible = 0;
{tab}{tab}{tab}defaultConfigurationName = Release;
{tab}{tab}}};''')
lines.append(f'''{tab}{tab}{widget_config_list} /* Build configuration list for PBXNativeTarget "MeloWidgetExtension" */ = {{
{tab}{tab}{tab}isa = XCConfigurationList;
{tab}{tab}{tab}buildConfigurations = (
{tab}{tab}{tab}{tab}{widget_debug} /* Debug */,
{tab}{tab}{tab}{tab}{widget_release} /* Release */,
{tab}{tab}{tab});
{tab}{tab}{tab}defaultConfigurationIsVisible = 0;
{tab}{tab}{tab}defaultConfigurationName = Release;
{tab}{tab}}};''')
lines.append(f'/* End XCConfigurationList section */')

# Root objects
lines.append(f'\n/* Root object */')
lines.append(f'\trootObject = {project_id} /* Project object */;')
lines.append(f'}}')

# ── Write file ──────────────────────────────────────────────────────
content = "\n".join(lines)
with open(PBXPROJ_PATH, "w", encoding="utf-8", newline="\n") as f:
    f.write(content)

print(f"[OK] Wrote {PBXPROJ_PATH} ({len(content)} bytes)")

# Also create a simple xcscheme for the main target
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
