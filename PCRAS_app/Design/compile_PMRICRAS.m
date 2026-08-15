% compile_PMRICRAS.m
% =========================================================================
% Build PMRICRAS Optimization Tool — standalone .exe + Runtime-included installer
% Requires: MATLAB Compiler Toolbox
%
% Usage:
%   Option A (quick .exe only):       compile_PMRICRAS
%   Option B (exe + Runtime installer): deploytool   (GUI, recommended)
% =========================================================================

fprintf('=== PMRICRAS Optimization Tool - Compiler ===\n');
fprintf('Checking MATLAB Compiler availability...\n');

[licStatus, ~] = license('checkout', 'Compiler');
if ~licStatus
    error('MATLAB Compiler license not available. Install MATLAB Compiler Toolbox first.');
end

fprintf('MATLAB Compiler detected (R2023b).\n\n');

% =========================================================================
% Step 1: Build standalone .exe (no Runtime)
% =========================================================================
fprintf('[Step 1/2] Building standalone .exe...\n');

outDir = fullfile(pwd, 'compiled');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

mcc('-m', 'PMRICRAS_Tool.m', ...
    '-o', 'PMRICRAS_Optimization_Tool', ...
    '-d', outDir, ...
    '-v');

fprintf('  -> compiled\\PMRICRAS_Optimization_Tool.exe (standalone, needs MCR)\n\n');

% =========================================================================
% Step 2: Build Runtime-included installer (for end users without MATLAB)
% =========================================================================
fprintf('[Step 2/2] Building Runtime-included installer...\n');

installerDir = fullfile(pwd, 'compiled_installer');
if ~exist(installerDir, 'dir')
    mkdir(installerDir);
end

try
    % Use R2023b compiler API to build + package with Runtime
    appResults = compiler.build.standaloneApplication('PMRICRAS_Tool.m', ...
        'OutputDir', installerDir, ...
        'ExecutableName', 'PMRICRAS_Optimization_Tool', ...
        'AutoDetectDataFiles', 'on');

    fprintf('  Build OK. Packaging installer (this may take several minutes)...\n');

    compiler.package.installer(appResults, ...
        'OutputDir', installerDir, ...
        'InstallerName', 'PMRICRAS_Optimization_Tool_Installer', ...
        'RuntimeDelivery', 'web', ...
        'Version', '1.0.0');

    fprintf('  -> compiled_installer\\PMRICRAS_Optimization_Tool_Installer.exe\n');
    fprintf('     (self-contained, includes MATLAB Runtime download)\n');

catch ME_build
    fprintf('  NOTE: Installer build via API failed (may need newer MATLAB).\n');
    fprintf('  Error: %s\n', ME_build.message);
    fprintf('\n  === Manual Installer Creation ===\n');
    fprintf('  Run this in MATLAB command window:\n');
    fprintf('    deploytool\n');
    fprintf('  Then in the GUI:\n');
    fprintf('    1. Add PMRICRAS_Tool.m as main file\n');
    fprintf('    2. Check "Runtime included in package"\n');
    fprintf('    3. Click "Package"\n');
end

% =========================================================================
% Step 3: Sync distribution folders (Design/ and General/)
% =========================================================================
fprintf('[Step 3/3] Syncing distribution folders...\n');

% --- Sync Design/ (source code for developers) ---
designDir = fullfile(pwd, 'Design');
if ~exist(designDir, 'dir')
    mkdir(designDir);
end

srcFiles = {'PMRICRAS_Tool.m', 'P_MRICRAS_func.m', 'SFOA.m', 'mainSFOA.m', ...
            'compile_PMRICRAS.m', 'README.md', 'USER_MANUAL.md'};
for k = 1:length(srcFiles)
    srcPath = fullfile(pwd, srcFiles{k});
    dstPath = fullfile(designDir, srcFiles{k});
    if exist(srcPath, 'file')
        [status, msg] = copyfile(srcPath, dstPath, 'f');
        if status
            fprintf('  Design/ <-- %s\n', srcFiles{k});
        else
            fprintf(2, '  WARNING: Failed to copy %s: %s\n', srcFiles{k}, msg);
        end
    end
end

% Copy autosave as reference default (optional)
autosaveSrc = fullfile(pwd, 'PMRICRAS_Tool_autosave.mat');
if exist(autosaveSrc, 'file')
    copyfile(autosaveSrc, fullfile(designDir, 'PMRICRAS_Tool_autosave.mat'), 'f');
end

fprintf('  Design/ folder synced.\n\n');

% --- Sync General/ (for non-MATLAB users) ---
generalDir = fullfile(pwd, 'General');
if ~exist(generalDir, 'dir')
    mkdir(generalDir);
end

% Copy standalone .exe
standaloneExe = fullfile(outDir, 'PMRICRAS_Optimization_Tool.exe');
if exist(standaloneExe, 'file')
    copyfile(standaloneExe, fullfile(generalDir, 'PMRICRAS_Optimization_Tool.exe'), 'f');
    fprintf('  General/ <-- compiled\\PMRICRAS_Optimization_Tool.exe\n');
end

% Copy installer .exe
installerExe = fullfile(installerDir, 'PMRICRAS_Optimization_Tool_Installer.exe');
if exist(installerExe, 'file')
    copyfile(installerExe, fullfile(generalDir, 'PMRICRAS_Optimization_Tool_Installer.exe'), 'f');
    fprintf('  General/ <-- compiled_installer\\PMRICRAS_Optimization_Tool_Installer.exe\n');
end

% Copy documentation and sample data
docFiles = {'README.md', 'USER_MANUAL.md'};
for k = 1:length(docFiles)
    srcPath = fullfile(pwd, docFiles{k});
    if exist(srcPath, 'file')
        copyfile(srcPath, fullfile(generalDir, docFiles{k}), 'f');
        fprintf('  General/ <-- %s\n', docFiles{k});
    end
end

sampleSrc = fullfile(pwd, '深度浓度-清洁版数据.xlsx');
if exist(sampleSrc, 'file')
    copyfile(sampleSrc, fullfile(generalDir, 'sample_data.xlsx'), 'f');
    fprintf('  General/ <-- sample_data.xlsx\n');
end

fprintf('  General/ folder synced.\n\n');
fprintf('\n=== Build Complete ===\n');
fprintf('\nOutput files:\n');
fprintf('  1. compiled\\PMRICRAS_Optimization_Tool.exe\n');
fprintf('     -> Small (~1.2 MB) .exe, user needs MATLAB Runtime installed\n');
fprintf('  2. compiled_installer\\ (if step 2 succeeded)\n');
fprintf('     -> Full installer with Runtime (~1-2 GB download)\n');
fprintf('     -> User runs installer once, then uses the app normally\n');
fprintf('  3. Design/  <-- synced with latest source code\n');
fprintf('  4. General/ <-- synced with latest .exe + docs + sample data\n');
fprintf('\nMATLAB Runtime (free) download:\n');
fprintf('  https://www.mathworks.com/products/compiler/mcr/\n');
fprintf('  Version: R2023b (must match compilation version)\n');
