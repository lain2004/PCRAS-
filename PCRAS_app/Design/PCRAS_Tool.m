function PMRICRAS_Tool()
% PMRICRAS_Tool - PMRICRAS-GDMS Parameter Optimization GUI
% Integrates mainSFOA.m + P_MRICRAS_func.m + SFOA.m into a visual interface.
% Usage: Run "PMRICRAS_Tool" in the MATLAB command window.

%#ok<*NASGU,*DEFNU,*PFUN>

% =========================================================================
% Global variable declarations (shared with P_MRICRAS_func / SFOA)
% =========================================================================
global inddis w dr lambda cons q_main startpoint endpoint ra2_ex firstlayer_c sigma_change

% =========================================================================
% Main Figure
% =========================================================================
fig = uifigure('Name', 'PMRICRAS-GDMS Parameter Optimization Tool v2.0', ...
               'Position', [60 25 1260 820], ...
               'Resize', 'on', ...
               'Color', [0.94 0.94 0.94]);

% =========================================================================
% Tab Group
% =========================================================================
tg = uitabgroup(fig, 'Position', [5 5 1250 810]);

% =========================================================================
% Tab 1: Data Import
% =========================================================================
tab1 = uitab(tg, 'Title', 'Data Import');
g1 = uigridlayout(tab1, [2 2], 'RowHeight', {'1x', '1x'}, 'ColumnWidth', {'2.5x', '1x'}, ...
                  'Padding', [12 12 12 12], 'RowSpacing', 10, 'ColumnSpacing', 12);

% Left-top: File settings
pFile = uipanel(g1, 'Title', 'Excel Data File', 'FontWeight', 'bold', 'FontSize', 12);
gFile = uigridlayout(pFile, [7 3], 'RowHeight', repmat({26}, 1, 7), ...
                      'ColumnWidth', {140, '1x', 138}, 'Padding', [10 8 10 8], 'RowSpacing', 5);

uilabel(gFile, 'Text', 'File path:', 'HorizontalAlignment', 'right');
edtFile = uieditfield(gFile, 'text', 'Value', 'Depth-Concentration Data.xlsx');
btnBrowse = uibutton(gFile, 'push', 'Text', 'Browse...', 'ButtonPushedFcn', @onBrowse);

uilabel(gFile, 'Text', 'Depth column (Z):', 'HorizontalAlignment', 'right');
edtZCol = uieditfield(gFile, 'numeric', 'Value', 1, 'Limits', [1 Inf], 'RoundFractionalValues', 'on');
uilabel(gFile, 'Text', '');

uilabel(gFile, 'Text', 'Signal column (I):', 'HorizontalAlignment', 'right');
edtICol = uieditfield(gFile, 'numeric', 'Value', 2, 'Limits', [1 Inf], 'RoundFractionalValues', 'on');
uilabel(gFile, 'Text', '');

uilabel(gFile, 'Text', 'Sheet name:', 'HorizontalAlignment', 'right');
edtSheet = uieditfield(gFile, 'text', 'Value', '');
uilabel(gFile, 'Text', '(empty=default)');

uilabel(gFile, 'Text', 'Sampling interval (inddis):', 'HorizontalAlignment', 'right');
edtInddis = uieditfield(gFile, 'numeric', 'Value', 1, 'Limits', [0.001 100]);
uilabel(gFile, 'Text', '');

uilabel(gFile, 'Text', 'Start point:', 'HorizontalAlignment', 'right');
edtStartPt = uieditfield(gFile, 'numeric', 'Value', 1, 'Limits', [1 Inf], 'RoundFractionalValues', 'on');
uilabel(gFile, 'Text', '');

uilabel(gFile, 'Text', 'End drop points:', 'HorizontalAlignment', 'right');
edtEndDrop = uieditfield(gFile, 'numeric', 'Value', 0, 'Limits', [0 Inf], 'RoundFractionalValues', 'on');
btnLoad = uibutton(gFile, 'push', 'Text', 'Load Data', 'FontWeight', 'bold', ...
                   'BackgroundColor', [0.3 0.6 0.9], 'FontColor', 'white', ...
                   'ButtonPushedFcn', @onLoadData);

% Left-bottom: Data preview
pPrev = uipanel(g1, 'Title', 'Data Preview', 'FontWeight', 'bold', 'FontSize', 12);
axPrev = uiaxes(pPrev, 'Position', [30 30 440 210]);
title(axPrev, 'Loaded Experimental Data'); xlabel(axPrev, 'Depth (nm)'); ylabel(axPrev, 'Signal Intensity');
grid(axPrev, 'on');

% Right: Reference parameters
pRef = uipanel(g1, 'Title', 'Reference Parameters (for comparison)', 'FontWeight', 'bold', 'FontSize', 12);
gRef = uigridlayout(pRef, [9 2], 'RowHeight', repmat({26}, 1, 9), ...
                     'ColumnWidth', {120, 120}, 'Padding', [10 10 10 10], 'RowSpacing', 4);

refDefaults = {'sigma_0', 3; 'sigma_k', 0; 'sigma_c', 0; 'b_FR', 5; 'p_FR', 1.5; ...
               'q_A', 8.83; 'q_B', 6.98; 'cons', 5; 'noise', 0};
refEdts = cell(size(refDefaults, 1), 1);
for i = 1:size(refDefaults, 1)
    uilabel(gRef, 'Text', [refDefaults{i,1} ':'], 'HorizontalAlignment', 'right');
    refEdts{i} = uieditfield(gRef, 'numeric', 'Value', refDefaults{i,2});
end

% =========================================================================
% Tab 2: Model Parameters (MRI & CRA)
% =========================================================================
tab2 = uitab(tg, 'Title', 'Model Params');
g2 = uigridlayout(tab2, [2 2], 'RowHeight', {'1x', '1.2x'}, 'ColumnWidth', {'1x', '1x'}, ...
                  'Padding', [12 12 12 12], 'RowSpacing', 10, 'ColumnSpacing', 12);

% MRI panel
pMRI = uipanel(g2, 'Title', 'MRI (Mixing-Roughness-Information) Parameters', 'FontWeight', 'bold', 'FontSize', 12);
gMRI = uigridlayout(pMRI, [5 2], 'RowHeight', repmat({30}, 1, 5), ...
                     'ColumnWidth', {140, 120}, 'Padding', [12 12 12 12], 'RowSpacing', 8);

uilabel(gMRI, 'Text', 'Mixing parameter w:', 'HorizontalAlignment', 'right');
edtW = uieditfield(gMRI, 'numeric', 'Value', 1, 'Limits', [0.01 100]);

uilabel(gMRI, 'Text', 'Depth resolution dr:', 'HorizontalAlignment', 'right');
edtDr = uieditfield(gMRI, 'numeric', 'Value', 1/1000, 'Limits', [1e-6 1]);

uilabel(gMRI, 'Text', 'Information depth lambda:', 'HorizontalAlignment', 'right');
edtLambda = uieditfield(gMRI, 'numeric', 'Value', 1, 'Limits', [0.01 100]);

uilabel(gMRI, 'Text', 'Sampling interval inddis:', 'HorizontalAlignment', 'right');
edtInddis2 = uieditfield(gMRI, 'numeric', 'Value', 1, 'Limits', [0.001 100], ...
                         'ValueChangedFcn', @(src,~) set(edtInddis, 'Value', src.Value));

uilabel(gMRI, 'Text', 'Truncation range cons:', 'HorizontalAlignment', 'right');
edtCons = uieditfield(gMRI, 'numeric', 'Value', 5, 'Limits', [0.1 50]);

% CRA panel
pCRA = uipanel(g2, 'Title', 'CRA (Crater Effect) Parameters [Optimized]', 'FontWeight', 'bold', 'FontSize', 12);
gCRA = uigridlayout(pCRA, [5 2], 'RowHeight', repmat({30}, 1, 5), ...
                     'ColumnWidth', {140, 120}, 'Padding', [12 12 12 12], 'RowSpacing', 8);

uilabel(gCRA, 'Text', 'b_FR initial:', 'HorizontalAlignment', 'right');
edtBfr = uieditfield(gCRA, 'numeric', 'Value', 5, 'Limits', [0.01 50]);
uilabel(gCRA, 'Text', 'b_FR lower bound:', 'HorizontalAlignment', 'right');
edtBfrLb = uieditfield(gCRA, 'numeric', 'Value', 0.01, 'Limits', [0 100]);
uilabel(gCRA, 'Text', 'b_FR upper bound:', 'HorizontalAlignment', 'right');
edtBfrUb = uieditfield(gCRA, 'numeric', 'Value', 10, 'Limits', [0.01 200]);
uilabel(gCRA, 'Text', 'p_FR initial:', 'HorizontalAlignment', 'right');
edtPfr = uieditfield(gCRA, 'numeric', 'Value', 1.5, 'Limits', [0.01 20]);
uilabel(gCRA, 'Text', 'p_FR lower bound:', 'HorizontalAlignment', 'right');
edtPfrLb = uieditfield(gCRA, 'numeric', 'Value', 0, 'Limits', [0 100]);
uilabel(gCRA, 'Text', 'p_FR upper bound:', 'HorizontalAlignment', 'right');
edtPfrUb = uieditfield(gCRA, 'numeric', 'Value', 10, 'Limits', [0.01 100]);

% Sigma model panel
pSigma = uipanel(g2, 'Title', 'Sigma (Interface Roughness) Model [Optimized]', 'FontWeight', 'bold', 'FontSize', 12);
gSigma = uigridlayout(pSigma, [6 2], 'RowHeight', repmat({30}, 1, 6), ...
                       'ColumnWidth', {150, 130}, 'Padding', [12 12 12 12], 'RowSpacing', 8);

uilabel(gSigma, 'Text', 'Sigma model:', 'HorizontalAlignment', 'right');
ddSigma = uidropdown(gSigma, 'Items', {'Linear: sigma_0+sigma_k*(i*dz)', ...
                                       'Constant: sigma=0.1', ...
                                       'Sqrt: sqrt(sigma_0+sigma_k*(i*dz)^2)', ...
                                       'Exponential: sigma_k*sigma_0^(sigma_c*(i*dz))'}, ...
                     'Value', 'Linear: sigma_0+sigma_k*(i*dz)');

uilabel(gSigma, 'Text', 'sigma_0 lower:', 'HorizontalAlignment', 'right');
edtS0Lb = uieditfield(gSigma, 'numeric', 'Value', 0.1, 'Limits', [0 100]);
uilabel(gSigma, 'Text', 'sigma_0 upper:', 'HorizontalAlignment', 'right');
edtS0Ub = uieditfield(gSigma, 'numeric', 'Value', 10, 'Limits', [0.1 200]);
uilabel(gSigma, 'Text', 'sigma_k lower:', 'HorizontalAlignment', 'right');
edtSkLb = uieditfield(gSigma, 'numeric', 'Value', 0, 'Limits', [-10 100]);
uilabel(gSigma, 'Text', 'sigma_k upper:', 'HorizontalAlignment', 'right');
edtSkUb = uieditfield(gSigma, 'numeric', 'Value', 1, 'Limits', [0 100]);
uilabel(gSigma, 'Text', 'sigma_c lower:', 'HorizontalAlignment', 'right');
edtScLb = uieditfield(gSigma, 'numeric', 'Value', 0, 'Limits', [-100 100]);
uilabel(gSigma, 'Text', 'sigma_c upper:', 'HorizontalAlignment', 'right');
edtScUb = uieditfield(gSigma, 'numeric', 'Value', 10, 'Limits', [0 1000]);

% Sputtering rate panel
pRate = uipanel(g2, 'Title', 'Sputtering Rates & Initial Conditions', 'FontWeight', 'bold', 'FontSize', 12);
gRate = uigridlayout(pRate, [6 2], 'RowHeight', repmat({30}, 1, 6), ...
                      'ColumnWidth', {180, 105}, 'Padding', [12 8 12 8], 'RowSpacing', 8);

uilabel(gRate, 'Text', 'Sputter rate q_A:', 'HorizontalAlignment', 'right');
edtQA = uieditfield(gRate, 'numeric', 'Value', 8.83, 'Limits', [0.01 1000]);
uilabel(gRate, 'Text', 'Sputter rate q_B:', 'HorizontalAlignment', 'right');
edtQB = uieditfield(gRate, 'numeric', 'Value', 6.98, 'Limits', [0.01 1000]);
uilabel(gRate, 'Text', 'q_A bound coefficient (low):', 'HorizontalAlignment', 'right');
edtQALb = uieditfield(gRate, 'numeric', 'Value', 0.8, 'Limits', [0.01 2]);
uilabel(gRate, 'Text', 'q_A bound coefficient (high):', 'HorizontalAlignment', 'right');
edtQAUb = uieditfield(gRate, 'numeric', 'Value', 1.2, 'Limits', [0.01 5]);
uilabel(gRate, 'Text', 'q_B bound coefficient (low):', 'HorizontalAlignment', 'right');
edtQBLb = uieditfield(gRate, 'numeric', 'Value', 0.8, 'Limits', [0.01 2]);
uilabel(gRate, 'Text', 'q_B bound coefficient (high):', 'HorizontalAlignment', 'right');
edtQBUb = uieditfield(gRate, 'numeric', 'Value', 1.2, 'Limits', [0.01 5]);
uilabel(gRate, 'Text', 'First layer conc. (firstlayer_c):', 'HorizontalAlignment', 'right');
edtFirstC = uieditfield(gRate, 'numeric', 'Value', 1, 'Limits', [0 1], 'RoundFractionalValues', 'on');
uilabel(gRate, 'Text', '(0=zero-conc, 1=non-zero)');

% =========================================================================
% Tab 3: Layer Structure & Bounds
% =========================================================================
tab3 = uitab(tg, 'Title', 'Layers & Bounds');
g3 = uigridlayout(tab3, [2 2], 'RowHeight', {'1x', '1.4x'}, 'ColumnWidth', {'1x', '1.2x'}, ...
                  'Padding', [12 12 12 12], 'RowSpacing', 10, 'ColumnSpacing', 12);

% Layer settings
pLayer = uipanel(g3, 'Title', 'Layer Thickness Settings (obj_tn)', 'FontWeight', 'bold', 'FontSize', 12);
gLayer = uigridlayout(pLayer, [8 2], 'RowHeight', [30 30 26 26 26 26 26 26], ...
                       'ColumnWidth', {140, 210}, 'Padding', [12 12 12 12], 'RowSpacing', 6);

uilabel(gLayer, 'Text', 'Layer mode:', 'HorizontalAlignment', 'right');
ddLayerMode = uidropdown(gLayer, 'Items', {'Uniform layers (quick)', 'Manual array input'}, ...
                         'Value', 'Uniform layers (quick)', ...
                         'ValueChangedFcn', @onLayerModeChange);

uilabel(gLayer, 'Text', 'Number of layers:', 'HorizontalAlignment', 'right');
edtLayerN = uieditfield(gLayer, 'numeric', 'Value', 15, 'Limits', [2 200], 'RoundFractionalValues', 'on');

uilabel(gLayer, 'Text', 'Default thickness per layer:', 'HorizontalAlignment', 'right');
edtLayerTh = uieditfield(gLayer, 'numeric', 'Value', 30, 'Limits', [0.1 1000]);

uilabel(gLayer, 'Text', 'Manual thickness array:', 'HorizontalAlignment', 'right');
edtLayerArr = uieditfield(gLayer, 'text', 'Value', '30*ones(1,15)', 'Editable', 'off');
btnApplyLayer = uibutton(gLayer, 'push', 'Text', 'Apply Layer Settings', ...
                         'ButtonPushedFcn', @onApplyLayer);

uilabel(gLayer, 'Text', 'Current thickness array:', 'HorizontalAlignment', 'right');
lblLayerPreview = uilabel(gLayer, 'Text', '30*ones(1,15) = [30 30 ... 30] (15 layers)', ...
                          'WordWrap', 'on');

% Bounds panel
pBound = uipanel(g3, 'Title', 'Optimization Bound Settings', 'FontWeight', 'bold', 'FontSize', 12);
gBound = uigridlayout(pBound, [9 4], 'RowHeight', repmat({29}, 1, 9), ...
                       'ColumnWidth', {160, 65, 30, 65}, 'Padding', [12 8 12 8], 'RowSpacing', 6);

% Row 1: Bound type (dropdown spans cols 2-4)
uilabel(gBound, 'Text', 'Bound type:', 'HorizontalAlignment', 'right');
ddBound = uidropdown(gBound, 'Items', {'Percentage-relative (recommended)', 'Absolute-relative', 'Absolute'}, ...
                     'Value', 'Percentage-relative (recommended)', ...
                     'ValueChangedFcn', @onBoundChange);
ddBound.Layout.Column = [2 4];  % span columns 2 through 4

% Row 2: lb_cons (edit spans cols 2-4)
uilabel(gBound, 'Text', 'Lower coeff/offset:', 'HorizontalAlignment', 'right');
edtLbCons = uieditfield(gBound, 'numeric', 'Value', 0.8);
edtLbCons.Layout.Column = [2 4];

% Row 3: ub_cons (edit spans cols 2-4)
uilabel(gBound, 'Text', 'Upper coeff/offset:', 'HorizontalAlignment', 'right');
edtUbCons = uieditfield(gBound, 'numeric', 'Value', 1.2);
edtUbCons.Layout.Column = [2 4];

% Row 4: sigma_0 = [low, high]  (two edits side by side)
uilabel(gBound, 'Text', 'sigma_0 bound:', 'HorizontalAlignment', 'right');
edtS0Lb2 = uieditfield(gBound, 'numeric', 'Value', 0.1);
uilabel(gBound, 'Text', '~', 'HorizontalAlignment', 'center');
edtS0Ub2 = uieditfield(gBound, 'numeric', 'Value', 10);

% Row 5: sigma_k = [low, high]
uilabel(gBound, 'Text', 'sigma_k bound:', 'HorizontalAlignment', 'right');
edtSkLb2 = uieditfield(gBound, 'numeric', 'Value', 0);
uilabel(gBound, 'Text', '~', 'HorizontalAlignment', 'center');
edtSkUb2 = uieditfield(gBound, 'numeric', 'Value', 1);

% Row 6: sigma_c = [low, high]
uilabel(gBound, 'Text', 'sigma_c bound:', 'HorizontalAlignment', 'right');
edtScLb2 = uieditfield(gBound, 'numeric', 'Value', -10);
uilabel(gBound, 'Text', '~', 'HorizontalAlignment', 'center');
edtScUb2 = uieditfield(gBound, 'numeric', 'Value', 10);

% Row 7: b_FR = [low, high]
uilabel(gBound, 'Text', 'b_FR bound:', 'HorizontalAlignment', 'right');
edtBfrLb2 = uieditfield(gBound, 'numeric', 'Value', 0.01);
uilabel(gBound, 'Text', '~', 'HorizontalAlignment', 'center');
edtBfrUb2 = uieditfield(gBound, 'numeric', 'Value', 10);

% Row 8: p_FR = [low, high]
uilabel(gBound, 'Text', 'p_FR bound:', 'HorizontalAlignment', 'right');
edtPfrLb2 = uieditfield(gBound, 'numeric', 'Value', 0);
uilabel(gBound, 'Text', '~', 'HorizontalAlignment', 'center');
edtPfrUb2 = uieditfield(gBound, 'numeric', 'Value', 10);

% Row 9: placeholder for spacing
uilabel(gBound, 'Text', '', 'HorizontalAlignment', 'right');
uilabel(gBound, 'Text', '', 'HorizontalAlignment', 'center');
uilabel(gBound, 'Text', '', 'HorizontalAlignment', 'center');

% Bound preview
pBoundPrev = uipanel(g3, 'Title', 'Generated Lower/Upper Bound Preview', 'FontWeight', 'bold', 'FontSize', 12);
gBoundPrev = uigridlayout(pBoundPrev, [2 1], 'RowHeight', {'1x', '1x'}, ...
                          'Padding', [8 8 8 8], 'RowSpacing', 4);
lblLbPrev = uilabel(gBoundPrev, 'Text', 'lb: (click "Refresh Preview" to update)', 'WordWrap', 'on', 'FontName', 'Consolas', 'FontSize', 9);
lblUbPrev = uilabel(gBoundPrev, 'Text', 'ub: (click "Refresh Preview" to update)', 'WordWrap', 'on', 'FontName', 'Consolas', 'FontSize', 9);

% Sync button
pSync = uipanel(g3, 'Title', 'Bound Actions', 'FontWeight', 'bold', 'FontSize', 12);
gSync = uigridlayout(pSync, [4 1], 'RowHeight', {30 30 30 30}, 'Padding', [12 12 12 12], 'RowSpacing', 6);
uibutton(gSync, 'push', 'Text', 'Sync Bounds from Model Params Tab', ...
         'ButtonPushedFcn', @onSyncBounds, ...
         'BackgroundColor', [0.5 0.5 0.5], 'FontColor', 'white');
uibutton(gSync, 'push', 'Text', 'Refresh Bound Preview', ...
         'ButtonPushedFcn', @(~,~) refreshBoundPreview(), ...
         'BackgroundColor', [0.4 0.4 0.5], 'FontColor', 'white');

% =========================================================================
% Tab 4: Optimization Settings
% =========================================================================
tab4 = uitab(tg, 'Title', 'Optimization');
g4 = uigridlayout(tab4, [2 2], 'RowHeight', {'1x', '1x'}, 'ColumnWidth', {'1x', '1x'}, ...
                  'Padding', [12 12 12 12], 'RowSpacing', 10, 'ColumnSpacing', 12);

% Algorithm
pAlgo = uipanel(g4, 'Title', 'Algorithm Settings', 'FontWeight', 'bold', 'FontSize', 12);
gAlgo = uigridlayout(pAlgo, [6 3], 'RowHeight', repmat({30}, 1, 6), ...
                      'ColumnWidth', {170, 80, 80}, 'Padding', [12 8 12 8], 'RowSpacing', 7);

uilabel(gAlgo, 'Text', 'Algorithm:', 'HorizontalAlignment', 'right');
ddAlgo = uidropdown(gAlgo, 'Items', {'SFOA (Starfish Optimization)', 'PSO (Particle Swarm)'}, ...
                    'Value', 'SFOA (Starfish Optimization)', ...
                    'ValueChangedFcn', @onAlgoChange);
ddAlgo.Layout.Column = [2 3];

uilabel(gAlgo, 'Text', 'Population size (Npop):', 'HorizontalAlignment', 'right');
edtNpop = uieditfield(gAlgo, 'numeric', 'Value', 60, 'Limits', [2 10000], 'RoundFractionalValues', 'on');
edtNpop.Layout.Column = [2 3];

uilabel(gAlgo, 'Text', 'Max iterations (Max_it):', 'HorizontalAlignment', 'right');
edtMaxit = uieditfield(gAlgo, 'numeric', 'Value', 1200, 'Limits', [10 100000], 'RoundFractionalValues', 'on');
edtMaxit.Layout.Column = [2 3];

% SFOA-only
uilabel(gAlgo, 'Text', 'SFOA: GP (explore/exploit):', 'HorizontalAlignment', 'right');
edtGP = uieditfield(gAlgo, 'numeric', 'Value', 0.5, 'Limits', [0.01 0.99]);
lblGP = uilabel(gAlgo, 'Text', '(balanced=0.5)', 'FontSize', 9);

% PSO-only
uilabel(gAlgo, 'Text', 'PSO: FunctionTolerance:', 'HorizontalAlignment', 'right');
edtFuncTol = uieditfield(gAlgo, 'numeric', 'Value', 1e-20, 'Limits', [1e-30 1], 'Editable', 'off');
lblFuncTol = uilabel(gAlgo, 'Text', '(PSO only)', 'FontSize', 9);

uilabel(gAlgo, 'Text', 'PSO: MaxStallIterations:', 'HorizontalAlignment', 'right');
edtStall = uieditfield(gAlgo, 'numeric', 'Value', 1200, 'Limits', [1 100000], 'RoundFractionalValues', 'on', 'Editable', 'off');
lblStall = uilabel(gAlgo, 'Text', '(PSO only)', 'FontSize', 9);

% Advanced
pAdv = uipanel(g4, 'Title', 'Advanced Options', 'FontWeight', 'bold', 'FontSize', 12);
gAdv = uigridlayout(pAdv, [6 3], 'RowHeight', repmat({28}, 1, 6), ...
                     'ColumnWidth', {155, 70, 85}, 'Padding', [12 8 12 8], 'RowSpacing', 7);

uilabel(gAdv, 'Text', 'b_FR/p_FR decimal places:', 'HorizontalAlignment', 'right');
edtPrecision = uieditfield(gAdv, 'numeric', 'Value', 1, 'Limits', [0 6], 'RoundFractionalValues', 'on');
edtPrecision.Layout.Column = [2 3];

uilabel(gAdv, 'Text', 'Interpolation method:', 'HorizontalAlignment', 'right');
ddInterp = uidropdown(gAdv, 'Items', {'spline', 'linear', 'pchip', 'cubic'}, 'Value', 'spline');
ddInterp.Layout.Column = [2 3];

uilabel(gAdv, 'Text', 'Signal clip upper:', 'HorizontalAlignment', 'right');
edtClipUp = uieditfield(gAdv, 'numeric', 'Value', 1, 'Limits', [0 10]);
uilabel(gAdv, 'Text', '(upper limit)', 'FontSize', 9);

uilabel(gAdv, 'Text', 'Signal clip lower:', 'HorizontalAlignment', 'right');
edtClipLo = uieditfield(gAdv, 'numeric', 'Value', 0, 'Limits', [-10 10]);
uilabel(gAdv, 'Text', '(lower limit)', 'FontSize', 9);

uilabel(gAdv, 'Text', 'Random seed (0=none):', 'HorizontalAlignment', 'right');
edtSeed = uieditfield(gAdv, 'numeric', 'Value', 0, 'Limits', [0 Inf], 'RoundFractionalValues', 'on');
edtSeed.Layout.Column = [2 3];

uilabel(gAdv, 'Text', 'Verbose console output:', 'HorizontalAlignment', 'right');
cbVerbose = uicheckbox(gAdv, 'Text', 'Show iteration details', 'Value', 0);
cbVerbose.Layout.Column = [2 3];

% Config summary
pCheck = uipanel(g4, 'Title', 'Configuration Summary', 'FontWeight', 'bold', 'FontSize', 12);
gCheck = uigridlayout(pCheck, [2 1], 'RowHeight', {'1x', 35}, 'Padding', [10 8 10 8]);
lblSummary = uilabel(gCheck, 'Text', 'Configure parameters in each tab, then click "Refresh Summary"...', 'WordWrap', 'on');
uibutton(gCheck, 'push', 'Text', 'Refresh Summary', ...
         'ButtonPushedFcn', @onRefreshSummary, ...
         'BackgroundColor', [0.4 0.4 0.4], 'FontColor', 'white');

% Config management
pSave = uipanel(g4, 'Title', 'Config Management', 'FontWeight', 'bold', 'FontSize', 12);
gSaveCfg = uigridlayout(pSave, [4 1], 'RowHeight', {32 32 32 32}, 'Padding', [12 12 12 12], 'RowSpacing', 6);
uibutton(gSaveCfg, 'push', 'Text', 'Save Current Configuration', 'ButtonPushedFcn', @onSaveConfig, ...
         'BackgroundColor', [0.2 0.6 0.3], 'FontColor', 'white');
uibutton(gSaveCfg, 'push', 'Text', 'Load Configuration File', 'ButtonPushedFcn', @onLoadConfig, ...
         'BackgroundColor', [0.2 0.5 0.7], 'FontColor', 'white');
uibutton(gSaveCfg, 'push', 'Text', 'Reset to Defaults', 'ButtonPushedFcn', @onResetConfig);

% =========================================================================
% Tab 5: Run & Results
% =========================================================================
tab5 = uitab(tg, 'Title', 'Run & Results');
g5 = uigridlayout(tab5, [4 2], 'RowHeight', {54, 44, '2.3x', '1x'}, 'ColumnWidth', {'1x', '1x'}, ...
                  'Padding', [12 8 12 8], 'RowSpacing', 5, 'ColumnSpacing', 10);

% Row 1: Control buttons (span both columns)
pRun = uipanel(g5, 'Title', 'Control', 'FontWeight', 'bold', 'FontSize', 11);
pRun.Layout.Row = 1;
pRun.Layout.Column = [1 2];
gRun = uigridlayout(pRun, [1 4], 'ColumnWidth', {'1.3x', '0.7x', '0.9x', '0.9x'}, 'Padding', [8 4 8 4]);
btnRun = uibutton(gRun, 'push', 'Text', 'START OPTIMIZATION', 'FontWeight', 'bold', 'FontSize', 13, ...
                  'BackgroundColor', [0.15 0.65 0.25], 'FontColor', 'white', ...
                  'ButtonPushedFcn', @onRun);
btnStop = uibutton(gRun, 'push', 'Text', 'STOP', 'FontWeight', 'bold', ...
                   'BackgroundColor', [0.85 0.2 0.2], 'FontColor', 'white', ...
                   'Enable', 'off', 'ButtonPushedFcn', @onStop);
btnExport = uibutton(gRun, 'push', 'Text', 'Export Results', ...
                     'ButtonPushedFcn', @onExport);
btnClearRes = uibutton(gRun, 'push', 'Text', 'Clear Results', ...
                       'ButtonPushedFcn', @onClearResults);

% Row 2: Progress bar + ETA (span both columns)
pProg = uipanel(g5, 'Title', 'Progress', 'FontWeight', 'bold', 'FontSize', 11);
pProg.Layout.Row = 2;
pProg.Layout.Column = [1 2];
gProg = uigridlayout(pProg, [1 3], 'ColumnWidth', {'2x', '1x', '1x'}, 'Padding', [8 4 8 4]);
lblProgress = uilabel(gProg, 'Text', 'Iteration: 0 / 0', 'FontWeight', 'bold', 'FontSize', 12, ...
                      'HorizontalAlignment', 'left');
lblETA = uilabel(gProg, 'Text', 'ETA: --:--:--', 'FontWeight', 'bold', 'FontSize', 12, ...
                 'HorizontalAlignment', 'center');
lblElapsed = uilabel(gProg, 'Text', 'Elapsed: 00:00:00', 'FontWeight', 'bold', 'FontSize', 12, ...
                     'HorizontalAlignment', 'right');

% Row 3: Convergence curve (col 1) + Fit comparison (col 2)
pConv = uipanel(g5, 'Title', 'Convergence Curve (real-time)', 'FontWeight', 'bold', 'FontSize', 11);
pConv.Layout.Row = 3;
pConv.Layout.Column = 1;
axConv = uiaxes(pConv, 'Position', [25 25 430 260]);
xlabel(axConv, 'Iteration'); ylabel(axConv, 'Error (%)'); title(axConv, 'Convergence Curve');
grid(axConv, 'on');
hold(axConv, 'on');

pFit = uipanel(g5, 'Title', 'Fit Comparison (Experiment vs. Fitted)', 'FontWeight', 'bold', 'FontSize', 11);
pFit.Layout.Row = 3;
pFit.Layout.Column = 2;
axFit = uiaxes(pFit, 'Position', [25 25 430 260]);
xlabel(axFit, 'Data Point'); ylabel(axFit, 'Signal Intensity'); title(axFit, 'Experiment vs. Fitted');
grid(axFit, 'on');

% Row 4: Run log (col 1) + Results (col 2) — use fill-grid, no wasted space
pLog = uipanel(g5, 'Title', 'Run Log', 'FontWeight', 'bold', 'FontSize', 11);
pLog.Layout.Row = 4;
pLog.Layout.Column = 1;
gLogInner = uigridlayout(pLog, [1 1], 'Padding', [4 2 4 4], 'RowSpacing', 0, 'ColumnSpacing', 0);
txtStatus = uitextarea(gLogInner, 'Editable', 'off', ...
                       'Value', 'Ready. Configure parameters and press START.', ...
                       'FontName', 'Consolas', 'FontSize', 9);

pRes = uipanel(g5, 'Title', 'Optimization Results', 'FontWeight', 'bold', 'FontSize', 11);
pRes.Layout.Row = 4;
pRes.Layout.Column = 2;
gResInner = uigridlayout(pRes, [1 1], 'Padding', [4 2 4 4], 'RowSpacing', 0, 'ColumnSpacing', 0);
txtResult = uitextarea(gResInner, 'Editable', 'off', ...
                       'Value', 'No results yet...', 'FontName', 'Consolas', 'FontSize', 9);

% =========================================================================
% App data storage
% =========================================================================
appData = struct();
appData.stopFlag = false;
appData.loadedData = [];
appData.obj_tn_current = [];
appData.runResult = [];
guidata(fig, appData);

% Auto-save config file path
configFilePath = fullfile(fileparts(mfilename('fullpath')), 'PMRICRAS_Tool_autosave.mat');

% =========================================================================
% === CALLBACK FUNCTIONS ===================================================
% =========================================================================

% -------------------------------------------------------------------------
% Browse file
% -------------------------------------------------------------------------
    function onBrowse(~, ~)
        [file, path] = uigetfile({'*.xlsx;*.xls;*.csv', 'Excel/CSV Files (*.xlsx,*.xls,*.csv)'}, ...
                                 'Select Data File', edtFile.Value);
        if file ~= 0
            edtFile.Value = fullfile(path, file);
        end
    end

% -------------------------------------------------------------------------
% Load data
% -------------------------------------------------------------------------
    function onLoadData(~, ~)
        try
            fpath = edtFile.Value;
            zcol = round(edtZCol.Value);
            icol = round(edtICol.Value);
            sheet = strtrim(edtSheet.Value);

            if isempty(sheet)
                Cr = readtable(fpath);
            else
                Cr = readtable(fpath, 'Sheet', sheet);
            end

            ra2 = Cr{:, zcol};
            dat = Cr{:, icol};

            ra2 = ra2(isfinite(ra2));
            dat = dat(isfinite(dat));

            inddis_val = edtInddis.Value;
            ra2_new = 0:inddis_val:max(ra2);
            interp_method = ddInterp.Value;
            dat_new = interp1(ra2, dat, ra2_new, interp_method);
            dat_new(dat_new > edtClipUp.Value) = edtClipUp.Value;
            dat_new(dat_new < edtClipLo.Value) = edtClipLo.Value;
            dat_new = dat_new';

            ad = guidata(fig);
            ad.loadedData = struct('ra2', ra2_new, 'data', dat_new, 'raw_ra2', ra2, 'raw_data', dat);
            guidata(fig, ad);

            cla(axPrev);
            plot(axPrev, ra2_new, dat_new, 'b-', 'LineWidth', 1.5);
            title(axPrev, sprintf('Loaded: %d data points (inddis=%.3f)', length(ra2_new), inddis_val));
            xlabel(axPrev, 'Depth (nm)'); ylabel(axPrev, 'Signal Intensity');
            grid(axPrev, 'on');

            set(edtInddis2, 'Value', inddis_val);

            txtStatus.Value = sprintf('[%s] Data loaded: %d points\nDepth range: %.2f - %.2f\nSignal range: %.4f - %.4f', ...
                datestr(now, 'HH:MM:SS'), length(ra2_new), min(ra2_new), max(ra2_new), min(dat_new), max(dat_new));
        catch ME_ld
            uialert(fig, ['Data load failed: ' ME_ld.message], 'Error');
        end
    end

% -------------------------------------------------------------------------
% Layer mode switch
% -------------------------------------------------------------------------
    function onLayerModeChange(src, ~)
        if contains(src.Value, 'Uniform')
            edtLayerArr.Editable = 'off';
            edtLayerN.Enable = 'on';
            edtLayerTh.Enable = 'on';
        else
            edtLayerArr.Editable = 'on';
            edtLayerN.Enable = 'off';
            edtLayerTh.Enable = 'off';
        end
    end

% -------------------------------------------------------------------------
% Apply layer settings
% -------------------------------------------------------------------------
    function onApplyLayer(~, ~)
        if contains(ddLayerMode.Value, 'Uniform')
            n = round(edtLayerN.Value);
            th = edtLayerTh.Value;
            obj_tn = th * ones(1, n);
        else
            try
                % Use str2num instead of eval (compiler-compatible)
                obj_tn = str2num(edtLayerArr.Value); %#ok<ST2NM>
                if isempty(obj_tn)
                    error('Cannot parse thickness array. Use format: [30 8 16 25] or 30*ones(1,15)');
                end
                % Handle expressions like "30*ones(1,15)" by evaluating safely
                if isnumeric(obj_tn) && isscalar(obj_tn) && contains(edtLayerArr.Value, '*')
                    % Re-attempt: check if it's a simple scalar*ones pattern
                    str = strtrim(edtLayerArr.Value);
                    % Extract: <scalar>*ones(1,<n>)
                    tokens = regexp(str, '^([\d.]+)\s*\*\s*ones\s*\(\s*1\s*,\s*(\d+)\s*\)$', 'tokens');
                    if ~isempty(tokens)
                        val = str2double(tokens{1}{1});
                        n = str2double(tokens{1}{2});
                        obj_tn = val * ones(1, n);
                    end
                end
                if ~isnumeric(obj_tn) || ~isvector(obj_tn)
                    error('Thickness must be a numeric vector');
                end
            catch ME_ly
                uialert(fig, ['Invalid thickness array: ' ME_ly.message], 'Error');
                return;
            end
        end

        ad = guidata(fig);
        ad.obj_tn_current = obj_tn;
        guidata(fig, ad);

        nLayers = length(obj_tn);
        if nLayers <= 8
            arrStr = mat2str(obj_tn, 2);
        else
            arrStr = sprintf('[%.1f %.1f %.1f ... %.1f] (%d layers)', ...
                obj_tn(1), obj_tn(2), obj_tn(3), obj_tn(end), nLayers);
        end
        lblLayerPreview.Text = arrStr;
        refreshBoundPreview();
    end

% -------------------------------------------------------------------------
% Bound type switch
% -------------------------------------------------------------------------
    function onBoundChange(~, ~)
        refreshBoundPreview();
    end

% -------------------------------------------------------------------------
% Sync bounds from Model Params tab
% -------------------------------------------------------------------------
    function onSyncBounds(~, ~)
        set(edtS0Lb2, 'Value', edtS0Lb.Value);
        set(edtS0Ub2, 'Value', edtS0Ub.Value);
        set(edtSkLb2, 'Value', edtSkLb.Value);
        set(edtSkUb2, 'Value', edtSkUb.Value);
        set(edtScLb2, 'Value', edtScLb.Value);
        set(edtScUb2, 'Value', edtScUb.Value);
        set(edtBfrLb2, 'Value', edtBfrLb.Value);
        set(edtBfrUb2, 'Value', edtBfrUb.Value);
        set(edtPfrLb2, 'Value', edtPfrLb.Value);
        set(edtPfrUb2, 'Value', edtPfrUb.Value);
        refreshBoundPreview();
    end

% -------------------------------------------------------------------------
% Refresh bound preview — show ALL elements clearly
% -------------------------------------------------------------------------
    function refreshBoundPreview()
        ad = guidata(fig);
        obj_tn = ad.obj_tn_current;
        if isempty(obj_tn)
            obj_tn = 30 * ones(1, 15);
        end

        qA = edtQA.Value;  qB = edtQB.Value;
        lbC = edtLbCons.Value;  ubC = edtUbCons.Value;
        boundType = ddBound.Value;

        switch boundType
            case 'Percentage-relative (recommended)'
                tn_lb = lbC * obj_tn;  tn_ub = ubC * obj_tn;
                qA_lb = lbC * qA;      qA_ub = ubC * qA;
                qB_lb = lbC * qB;      qB_ub = ubC * qB;
            case 'Absolute-relative'
                tn_lb = obj_tn - lbC;  tn_ub = obj_tn + ubC;
                qA_lb = qA;            qA_ub = qA;
                qB_lb = qB;            qB_ub = qB;
            case 'Absolute'
                tn_lb = zeros(1, length(obj_tn));
                tn_ub = 50 * ones(1, length(obj_tn));
                qA_lb = qA;  qA_ub = qA;
                qB_lb = qB;  qB_ub = qB;
        end

        lb = [edtS0Lb2.Value, edtSkLb2.Value, edtScLb2.Value, edtBfrLb2.Value, edtPfrLb2.Value, qA_lb, qB_lb, tn_lb];
        ub = [edtS0Ub2.Value, edtSkUb2.Value, edtScUb2.Value, edtBfrUb2.Value, edtPfrUb2.Value, qA_ub, qB_ub, tn_ub];

        % Format element-by-element to ensure ALL values visible
        nD = length(lb);

        % Build lb string
        lbStr = 'lb = [';
        for k = 1:min(nD, 6)
            lbStr = sprintf('%s%.4g, ', lbStr, lb(k));
        end
        if nD > 6
            lbStr = sprintf('%s ... ', lbStr);
            for k = nD-2:nD
                lbStr = sprintf('%s%.4g, ', lbStr, lb(k));
            end
        end
        lbStr = [lbStr(1:end-2) sprintf(']  (%d dims)', nD)];

        % Build ub string
        ubStr = 'ub = [';
        for k = 1:min(nD, 6)
            ubStr = sprintf('%s%.4g, ', ubStr, ub(k));
        end
        if nD > 6
            ubStr = sprintf('%s ... ', ubStr);
            for k = nD-2:nD
                ubStr = sprintf('%s%.4g, ', ubStr, ub(k));
            end
        end
        ubStr = [ubStr(1:end-2) sprintf(']  (%d dims)', nD)];

        % Show as [param index]: param_name: [low, high]
        detailStr = '';
        paramNames = {'sigma_0', 'sigma_k', 'sigma_c', 'b_FR', 'p_FR', 'q_A', 'q_B'};
        for k = 1:7
            detailStr = sprintf('%s  [%d] %s: [%.4g, %.4g]\n', detailStr, k, paramNames{k}, lb(k), ub(k));
        end
        detailStr = sprintf('%s  [8-%d] obj_tn (layer thicknesses): [%s, %s]\n', ...
            detailStr, nD, mat2str(tn_lb, 3), mat2str(tn_ub, 3));

        lblLbPrev.Text = sprintf('%s\n\n--- Per-Parameter Bounds ---\n%s', lbStr, detailStr);
        lblUbPrev.Text = ubStr;
    end

% -------------------------------------------------------------------------
% Algorithm switch
% -------------------------------------------------------------------------
    function onAlgoChange(src, ~)
        isSFOA = contains(src.Value, 'SFOA');
        edtGP.Enable = isSFOA;
        lblGP.Enable = isSFOA;
        edtFuncTol.Editable = ~isSFOA;
        edtStall.Editable = ~isSFOA;
        if ~isSFOA
            edtFuncTol.Enable = 'on';
            edtStall.Enable = 'on';
        else
            edtFuncTol.Enable = 'off';
            edtStall.Enable = 'off';
        end
    end

% -------------------------------------------------------------------------
% Refresh summary
% -------------------------------------------------------------------------
    function onRefreshSummary(~, ~)
        ad = guidata(fig);
        obj_tn = ad.obj_tn_current;
        if isempty(obj_tn), obj_tn = 30 * ones(1, 15); end

        refreshBoundPreview();

        nD = 6 + length(obj_tn);
        summary = sprintf(['=== Configuration Summary ===\n', ...
            'File: %s\nData columns: Z=%d, I=%d | inddis=%.3f\n', ...
            'Layers: %d | Dimensions: %d\n', ...
            'Algorithm: %s | Pop: %d | Iter: %d\n', ...
            'Sigma model: %s\n', ...
            'Bound type: %s (lb=%.2f, ub=%.2f)\n', ...
            'q_A=%.2f, q_B=%.2f, firstlayer_c=%d\n', ...
            'w=%.2f, dr=%.4f, lambda=%.2f, cons=%.1f\n', ...
            'Interpolation: %s | Precision: %d decimal places'], ...
            edtFile.Value, round(edtZCol.Value), round(edtICol.Value), edtInddis.Value, ...
            length(obj_tn), nD, ...
            ddAlgo.Value, round(edtNpop.Value), round(edtMaxit.Value), ...
            ddSigma.Value, ...
            ddBound.Value, edtLbCons.Value, edtUbCons.Value, ...
            edtQA.Value, edtQB.Value, round(edtFirstC.Value), ...
            edtW.Value, edtDr.Value, edtLambda.Value, edtCons.Value, ...
            ddInterp.Value, round(edtPrecision.Value));

        lblSummary.Text = summary;
    end

% -------------------------------------------------------------------------
% Save/Load/Reset config
% -------------------------------------------------------------------------
    function onSaveConfig(~, ~)
        [file, path] = uiputfile({'*.mat', 'MAT Config File (*.mat)'}, 'Save Configuration');
        if file == 0, return; end
        cfg = collectConfig();
        config = cfg; %#ok<NASGU>
        save(fullfile(path, file), 'config');
        uialert(fig, 'Configuration saved!', 'Success');
    end

    function onLoadConfig(~, ~)
        [file, path] = uigetfile({'*.mat', 'MAT Config File (*.mat)'}, 'Load Configuration');
        if file == 0, return; end
        data = load(fullfile(path, file), 'config');
        if ~isfield(data, 'config')
            uialert(fig, 'Invalid config file', 'Error');
            return;
        end
        applyConfig(data.config);
        uialert(fig, 'Configuration loaded!', 'Success');
    end

    function onResetConfig(~, ~)
        answer = uiconfirm(fig, 'Reset ALL settings to defaults?', 'Reset Confirmation', 'ConfirmDeny');
        if strcmp(answer, 'Deny'), return; end
        close(fig);
        PMRICRAS_Tool();
    end

% -------------------------------------------------------------------------
% Config collect/apply
% -------------------------------------------------------------------------
    function cfg = collectConfig()
        fns = {'filePath','zCol','iCol','sheet','inddis','startPt','endDrop', ...
               'w','dr','lambda','cons','bFR','pFR','bFRLb','bFRUb','pFRLb','pFRUb', ...
               'sigmaModel','s0Lb','s0Ub','skLb','skUb','scLb','scUb', ...
               'qA','qB','qALb','qAUb','qBLb','qBUb','firstC', ...
               'layerMode','layerN','layerTh','layerArr', ...
               'boundType','lbCons','ubCons', ...
               'algo','npop','maxit','gp','funcTol','stall', ...
               'precision','interp','clipUp','clipLo','seed','verbose'};
        vals = {edtFile.Value, edtZCol.Value, edtICol.Value, edtSheet.Value, ...
                edtInddis.Value, edtStartPt.Value, edtEndDrop.Value, ...
                edtW.Value, edtDr.Value, edtLambda.Value, edtCons.Value, ...
                edtBfr.Value, edtPfr.Value, edtBfrLb.Value, edtBfrUb.Value, edtPfrLb.Value, edtPfrUb.Value, ...
                ddSigma.Value, edtS0Lb.Value, edtS0Ub.Value, edtSkLb.Value, edtSkUb.Value, edtScLb.Value, edtScUb.Value, ...
                edtQA.Value, edtQB.Value, edtQALb.Value, edtQAUb.Value, edtQBLb.Value, edtQBUb.Value, edtFirstC.Value, ...
                ddLayerMode.Value, edtLayerN.Value, edtLayerTh.Value, edtLayerArr.Value, ...
                ddBound.Value, edtLbCons.Value, edtUbCons.Value, ...
                ddAlgo.Value, edtNpop.Value, edtMaxit.Value, edtGP.Value, edtFuncTol.Value, edtStall.Value, ...
                edtPrecision.Value, ddInterp.Value, edtClipUp.Value, edtClipLo.Value, edtSeed.Value, cbVerbose.Value};
        cfg = cell2struct(vals, fns, 2);
    end

    function applyConfig(cfg)
        map = struct(...
            'filePath', edtFile, 'zCol', edtZCol, 'iCol', edtICol, 'sheet', edtSheet, ...
            'inddis', edtInddis, 'startPt', edtStartPt, 'endDrop', edtEndDrop, ...
            'w', edtW, 'dr', edtDr, 'lambda', edtLambda, 'cons', edtCons, ...
            'bFR', edtBfr, 'pFR', edtPfr, 'bFRLb', edtBfrLb, 'bFRUb', edtBfrUb, ...
            'pFRLb', edtPfrLb, 'pFRUb', edtPfrUb, ...
            's0Lb', edtS0Lb, 's0Ub', edtS0Ub, 'skLb', edtSkLb, 'skUb', edtSkUb, ...
            'scLb', edtScLb, 'scUb', edtScUb, ...
            'qA', edtQA, 'qB', edtQB, 'qALb', edtQALb, 'qAUb', edtQAUb, ...
            'qBLb', edtQBLb, 'qBUb', edtQBUb, 'firstC', edtFirstC, ...
            'layerN', edtLayerN, 'layerTh', edtLayerTh, 'layerArr', edtLayerArr, ...
            'lbCons', edtLbCons, 'ubCons', edtUbCons, ...
            'npop', edtNpop, 'maxit', edtMaxit, 'gp', edtGP, ...
            'funcTol', edtFuncTol, 'stall', edtStall, ...
            'precision', edtPrecision, 'clipUp', edtClipUp, 'clipLo', edtClipLo, ...
            'seed', edtSeed);
        fns = fieldnames(cfg);
        for i = 1:length(fns)
            fn = fns{i};
            val = cfg.(fn);
            if isfield(map, fn) && isvalid(map.(fn))
                if isa(map.(fn), 'matlab.ui.control.NumericEditField')
                    map.(fn).Value = val;
                elseif isa(map.(fn), 'matlab.ui.control.EditField')
                    map.(fn).Value = val;
                elseif isa(map.(fn), 'matlab.ui.control.CheckBox')
                    map.(fn).Value = val;
                end
            elseif strcmp(fn, 'sigmaModel'), ddSigma.Value = val;
            elseif strcmp(fn, 'layerMode'), ddLayerMode.Value = val; onLayerModeChange(ddLayerMode);
            elseif strcmp(fn, 'boundType'), ddBound.Value = val; onBoundChange(ddBound);
            elseif strcmp(fn, 'algo'), ddAlgo.Value = val; onAlgoChange(ddAlgo);
            elseif strcmp(fn, 'interp'), ddInterp.Value = val;
            elseif strcmp(fn, 'verbose'), cbVerbose.Value = val;
            end
        end
        if isfield(map, 'inddis'), edtInddis2.Value = edtInddis.Value; end
    end

% =========================================================================
% PSO shared state (written by onRun, read by psoCostWrapper / psoOutFcn)
% =========================================================================
pso_precision  = 1;
pso_fobj       = [];
pso_fit_data   = [];
pso_Curve      = [];
pso_Max_it     = 1200;
pso_verbose    = false;

% -------------------------------------------------------------------------
% PSO cost wrapper
% -------------------------------------------------------------------------
    function err = psoCostWrapper(params)
        params(3) = round(params(3), pso_precision);
        params(4) = round(params(4), pso_precision);
        I_MRI_cra = pso_fobj(params);
        err = 100 * sqrt(mean((I_MRI_cra(startpoint:endpoint) - pso_fit_data(startpoint:endpoint)).^2));
    end

% -------------------------------------------------------------------------
% PSO output function (real-time update + stop check)
% -------------------------------------------------------------------------
    function stop = psoOutFcn(optimValues, state)
        stop = false;
        ad2 = guidata(fig);
        if ad2.stopFlag, stop = true; return; end
        if strcmp(state, 'iter')
            iter = optimValues.iteration;
            if iter >= 1 && iter <= pso_Max_it
                pso_Curve(iter) = optimValues.bestfval;
                % Real-time UI update
                updateProgress(iter, pso_Max_it, optimValues.bestfval);
                if pso_verbose
                    logMsg(sprintf('Iter %d: Best=%.4f%%', iter, optimValues.bestfval));
                end
            end
        end
    end

% -------------------------------------------------------------------------
% SFOA iteration callback (real-time update + stop check)
% -------------------------------------------------------------------------
    function stop = sfoaIterCallback(T, Max_it, fvalbest, xposbest, elapsed)
        stop = false;
        ad2 = guidata(fig);
        if ad2.stopFlag, stop = true; return; end
        updateProgress(T, Max_it, fvalbest);
        if cbVerbose.Value
            logMsg(sprintf('Iter %d/%d: Best=%.4f%% | Elapsed=%.1fs', T, Max_it, fvalbest, elapsed));
        end
    end

% -------------------------------------------------------------------------
% initProgressPlot — prepare convergence axes before optimization starts
% -------------------------------------------------------------------------
    function initProgressPlot()
        cla(axConv);
        hold(axConv, 'on');
        grid(axConv, 'on');
        xlabel(axConv, 'Iteration'); ylabel(axConv, 'Error (%)');
        title(axConv, 'Convergence Curve (optimizing...)');
        % Create an empty line that we will update in-place (no flicker)
    end

% -------------------------------------------------------------------------
% updateProgress — shared by SFOA and PSO for real-time UI updates
% -------------------------------------------------------------------------
    function updateProgress(iter, maxIter, bestErr)
        persistent progStartTime sfoaCurve hLine

        if iter == 1
            progStartTime = tic;
            sfoaCurve = nan(1, maxIter);
            % Create or reuse the persistent line handle (no flicker)
            if isempty(hLine) || ~isvalid(hLine)
                hLine = semilogy(axConv, nan, nan, 'b-', 'LineWidth', 1.8);
                grid(axConv, 'on');
            end
        end

        % Store this iteration's error
        sfoaCurve(iter) = bestErr;
        elapsed = toc(progStartTime);
        pct = iter / maxIter;

        % ---- Progress label with text-based bar ----
        barLen = 30;
        filled = round(pct * barLen);
        barStr = [repmat('#', 1, filled), repmat('.', 1, barLen - filled)];
        lblProgress.Text = sprintf('[%s]  Iter: %d/%d (%.1f%%)', barStr, iter, maxIter, pct * 100);

        % ---- Elapsed time ----
        h = floor(elapsed / 3600);
        m = floor(mod(elapsed, 3600) / 60);
        s = floor(mod(elapsed, 60));
        lblElapsed.Text = sprintf('Elapsed: %02d:%02d:%02d', h, m, s);

        % ---- ETA ----
        if pct > 0.001
            eta = elapsed / pct - elapsed;
            h = floor(eta / 3600);
            m = floor(mod(eta, 3600) / 60);
            s = floor(mod(eta, 60));
            lblETA.Text = sprintf('ETA: %02d:%02d:%02d', h, m, s);
        else
            lblETA.Text = 'ETA: --:--:--';
        end

        % ---- Smooth real-time plot update (no cla, no flicker) ----
        % Throttle: plot every N iterations or at boundaries
        throttleN = max(1, floor(maxIter / 150));
        if iter <= 3 || mod(iter, throttleN) == 0 || iter == maxIter
            valid = 1:iter;
            valid = valid(~isnan(sfoaCurve(1:iter)));
            if ~isempty(valid)
                set(hLine, 'XData', valid, 'YData', sfoaCurve(valid));
                % Adjust Y-axis to fit data range
                yVals = sfoaCurve(valid);
                if max(yVals) / max(1e-30, min(yVals)) > 1e6
                    set(axConv, 'YScale', 'log');
                end
            end
            title(axConv, sprintf('Convergence (Iter %d/%d, Best=%.4f%%)', iter, maxIter, bestErr));
            drawnow limitrate;
        end
    end

% -------------------------------------------------------------------------
% === CORE: Run Optimization ==============================================
% -------------------------------------------------------------------------
    function onRun(~, ~)
        % Global variables are declared at parent level;
        % this nested function shares the parent workspace.
        ad = guidata(fig);
        ad.stopFlag = false;
        guidata(fig, ad);

        btnRun.Enable = 'off';
        btnStop.Enable = 'on';
        txtStatus.Value = '';
        txtResult.Value = 'Running...';
        lblProgress.Text = 'Iteration: preparing...';
        lblETA.Text = 'ETA: --:--:--';
        lblElapsed.Text = 'Elapsed: 00:00:00';

        drawnow;

        % Pre-initialize outputs (avoid shared-variable warnings)
        xbest     = [];
        error_val = NaN;
        used_time = 0;
        AA        = [];
        Curve     = [];

        try
            % ---- Validate inputs ----
            if isempty(ad.loadedData)
                uialert(fig, 'Please load experimental data first! (Data Import tab)', 'Warning');
                btnRun.Enable = 'on'; btnStop.Enable = 'off'; return;
            end

            obj_tn = ad.obj_tn_current;
            if isempty(obj_tn)
                onApplyLayer();
                ad = guidata(fig);
                obj_tn = ad.obj_tn_current;
                if isempty(obj_tn)
                    uialert(fig, 'Please set up layer structure first! (Layers & Bounds tab)', 'Warning');
                    btnRun.Enable = 'on'; btnStop.Enable = 'off'; return;
                end
            end

            % ---- Read all UI values ----
            inddis_val  = edtInddis.Value;
            w_val       = edtW.Value;
            dr_val      = edtDr.Value;
            lambda_val  = edtLambda.Value;
            cons_val    = edtCons.Value;
            firstC_val  = round(edtFirstC.Value);
            startPt_val = round(edtStartPt.Value);

            ra2_ex_data = ad.loadedData.ra2;
            fit_data    = ad.loadedData.data;
            endDrop_val = round(edtEndDrop.Value);
            endPt_val   = max(ra2_ex_data) / max(inddis_val, 0.001) - endDrop_val;

            % Sigma model function handle
            sigmaModel = ddSigma.Value;
            if contains(sigmaModel, 'Linear')
                sigma_change_fh = @(s0, sk, i, dd, sc) s0 + sk * (i * dd);
            elseif contains(sigmaModel, 'Constant')
                sigma_change_fh = @(s0, sk, i, dd, sc) 0.1;
            elseif contains(sigmaModel, 'Sqrt')
                sigma_change_fh = @(s0, sk, i, dd, sc) sqrt(s0 + sk * (i * dd)^2);
            else
                sigma_change_fh = @(s0, sk, i, dd, sc) sk * s0^(sc * (i * dd));
            end

            % ---- Write global variables (needed by P_MRICRAS_func / SFOA) ----
            inddis       = inddis_val;
            w            = w_val;
            dr           = dr_val;
            lambda       = lambda_val;
            cons         = cons_val;
            q_main       = 0;
            startpoint   = startPt_val;
            endpoint     = endPt_val;
            ra2_ex       = ra2_ex_data;
            firstlayer_c = firstC_val;
            sigma_change = sigma_change_fh;

            % ---- Build lb/ub ----
            qA = edtQA.Value;  qB = edtQB.Value;
            lbC = edtLbCons.Value;  ubC = edtUbCons.Value;
            boundType = ddBound.Value;

            s0_lb  = edtS0Lb2.Value;  s0_ub  = edtS0Ub2.Value;
            sk_lb  = edtSkLb2.Value;  sk_ub  = edtSkUb2.Value;
            sc_lb  = edtScLb2.Value;  sc_ub  = edtScUb2.Value;
            bfr_lb = edtBfrLb2.Value; bfr_ub = edtBfrUb2.Value;
            pfr_lb = edtPfrLb2.Value; pfr_ub = edtPfrUb2.Value;

            switch boundType
                case 'Percentage-relative (recommended)'
                    tn_lb = lbC * obj_tn;  tn_ub = ubC * obj_tn;
                    qA_lb = lbC * qA;      qA_ub = ubC * qA;
                    qB_lb = lbC * qB;      qB_ub = ubC * qB;
                case 'Absolute-relative'
                    tn_lb = obj_tn - lbC;  tn_ub = obj_tn + ubC;
                    qA_lb = qA;            qA_ub = qA;
                    qB_lb = qB;            qB_ub = qB;
                case 'Absolute'
                    tn_lb = zeros(1, length(obj_tn));
                    tn_ub = 50 * ones(1, length(obj_tn));
                    qA_lb = qA;  qA_ub = qA;
                    qB_lb = qB;  qB_ub = qB;
            end

            lb = [s0_lb, sk_lb, sc_lb, bfr_lb, pfr_lb, qA_lb, qB_lb, tn_lb];
            ub = [s0_ub, sk_ub, sc_ub, bfr_ub, pfr_ub, qA_ub, qB_ub, tn_ub];

            nD     = length(lb);
            Npop   = round(edtNpop.Value);
            Max_it = round(edtMaxit.Value);

            % Random seed
            seedVal = round(edtSeed.Value);
            if seedVal > 0, rng(seedVal); end

            fobj_local = @P_MRICRAS_func;

            % ---- Log start ----
            logMsg(sprintf('=== Optimization started [%s] ===', datestr(now, 'HH:MM:SS')));
            logMsg(sprintf('Dims: %d | Pop: %d | MaxIter: %d | Layers: %d', nD, Npop, Max_it, length(obj_tn)));
            logMsg(sprintf('Algorithm: %s', ddAlgo.Value));

            precision_val = round(edtPrecision.Value);
            verbose_val   = cbVerbose.Value;
            isSFOA = contains(ddAlgo.Value, 'SFOA');

            % ---- Prepare convergence plot (creates persistent line handle) ----
            initProgressPlot();

            if isSFOA
                % ============ SFOA Algorithm ============
                logMsg('Running SFOA with real-time updates...');
                total_tic = tic;
                [xbest, error_val, used_time, AA, Curve] = SFOA(Npop, Max_it, lb, ub, nD, fobj_local, fit_data, @sfoaIterCallback);
            else
                % ============ PSO Algorithm ============
                logMsg('Running PSO (particleswarm) with real-time updates...');

                pso_precision = precision_val;
                pso_fobj      = fobj_local;
                pso_fit_data  = fit_data;
                pso_Max_it    = Max_it;
                pso_verbose   = verbose_val;
                pso_Curve     = zeros(1, Max_it);

                % Make sure PSO has at least 2 particles
                if Npop < 2, Npop = 2; end

                options = optimoptions('particleswarm', ...
                    'SwarmSize',          Npop, ...
                    'MaxIterations',      Max_it, ...
                    'Display',            'off', ...
                    'OutputFcn',          @psoOutFcn, ...
                    'FunctionTolerance',  edtFuncTol.Value, ...
                    'MaxStallIterations', edtStall.Value);

                total_tic = tic;
                [xbest, fval, exitflag, output] = particleswarm(@psoCostWrapper, nD, lb, ub, options);
                used_time = toc(total_tic);

                xbest(4) = round(xbest(4), precision_val);
                xbest(5) = round(xbest(5), precision_val);

                result_opt = fobj_local(xbest);
                error_val = 100 * sqrt(mean((result_opt(startpoint:endpoint) - fit_data(startpoint:endpoint)).^2));
                Curve     = pso_Curve;

                logMsg(sprintf('PSO done: exitflag=%d, error=%.6f%%, funccount=%d', ...
                    exitflag, error_val, output.funccount));

                x_idx = (1:length(fit_data))';
                AA = [x_idx, fit_data, result_opt, fit_data - result_opt];
            end

            logMsg(sprintf('Elapsed: %.2f s', used_time));
            logMsg(sprintf('Final error: %.6f%%', error_val));

            % ---- Display results ----
            opt_s0  = xbest(1);   opt_sk  = xbest(2);
            opt_sc  = xbest(3);
            opt_bfr = xbest(4);   opt_pfr = xbest(5);
            opt_qA  = xbest(6);   opt_qB  = xbest(7);
            opt_tn  = xbest(8:end);

            resultStr = sprintf(['====== OPTIMIZATION RESULTS ======\n', ...
                'sigma_0 = %.6f    sigma_k = %.6f\n', ...
                'sigma_c = %.6f\n', ...
                'b_FR    = %.6f    p_FR     = %.6f\n', ...
                'q_A     = %.6f    q_B      = %.6f\n', ...
                'Error   = %.6f%%   Time     = %.2f s\n', ...
                '--- Layer Thicknesses (%d layers) ---\n%s\n', ...
                '--- Comparison with Reference ---\n', ...
                '           Optimized    Reference\n', ...
                'sigma_0: %12.4f  %12.4f\n', ...
                'sigma_k: %12.4f  %12.4f\n', ...
                'sigma_c: %12.4f  %12.4f\n', ...
                'b_FR:    %12.4f  %12.4f\n', ...
                'p_FR:    %12.4f  %12.4f\n', ...
                'q_A:     %12.4f  %12.4f\n', ...
                'q_B:     %12.4f  %12.4f'], ...
                opt_s0, opt_sk, opt_sc, opt_bfr, opt_pfr, opt_qA, opt_qB, ...
                error_val, used_time, length(opt_tn), mat2str(opt_tn, 4), ...
                opt_s0, refEdts{1}.Value, opt_sk, refEdts{2}.Value, ...
                opt_sc, refEdts{3}.Value, ...
                opt_bfr, refEdts{4}.Value, opt_pfr, refEdts{5}.Value, ...
                opt_qA, refEdts{6}.Value, opt_qB, refEdts{7}.Value);

            txtResult.Value = resultStr;

            % ---- Final convergence plot ----
            cla(axConv);
            semilogy(axConv, 1:length(Curve), Curve, 'b-', 'LineWidth', 1.5);
            xlabel(axConv, 'Iteration'); ylabel(axConv, 'Error (%)');
            title(axConv, sprintf('Convergence Curve (Final Error = %.4f%%)', error_val));
            grid(axConv, 'on');

            % ---- Fit comparison plot ----
            cla(axFit);
            result_final = fobj_local(xbest);
            hold(axFit, 'on');
            plot(axFit, 1:length(fit_data), fit_data, '-b', 'LineWidth', 1.5, 'DisplayName', 'Experiment');
            plot(axFit, 1:length(result_final), result_final, '-r', 'LineWidth', 1.5, 'DisplayName', 'Fitted');
            plot(axFit, 1:length(fit_data), fit_data - result_final, '-g', 'LineWidth', 1, 'DisplayName', 'Difference');
            hold(axFit, 'off');
            xlabel(axFit, 'Data Point'); ylabel(axFit, 'Signal Intensity');
            title(axFit, sprintf('Experiment vs. Fitted (RMSE = %.4f%%)', error_val));
            legend(axFit, 'Location', 'best');
            grid(axFit, 'on');

            % ---- Store results ----
            ad.runResult = struct(...
                'xbest', xbest, 'error', error_val, 'used_time', used_time, ...
                'AA', AA, 'Curve', Curve, 'lb', lb, 'ub', ub, ...
                'fit_data', fit_data, 'result', result_final);
            guidata(fig, ad);

            % ---- Progress update ----
            lblProgress.Text = sprintf('Iteration: %d / %d (100%%) - COMPLETE', length(Curve), Max_it);
            lblETA.Text = 'ETA: 00:00:00';

            logMsg('=== Optimization complete ===');

        catch ME_run
            logMsg(sprintf('!!! ERROR: %s', ME_run.message));
            logMsg(getReport(ME_run, 'extended', 'hyperlinks', 'off'));
            uialert(fig, ['Run error: ' ME_run.message], 'Error');
        end

        btnRun.Enable = 'on';
        btnStop.Enable = 'off';
    end

% -------------------------------------------------------------------------
% Stop
% -------------------------------------------------------------------------
    function onStop(~, ~)
        ad = guidata(fig);
        ad.stopFlag = true;
        guidata(fig, ad);
        logMsg('!!! STOP requested — optimization will halt at next iteration !!!');
        btnStop.Enable = 'off';
        lblProgress.Text = [lblProgress.Text ' (stopping...)'];
        drawnow;
    end

% -------------------------------------------------------------------------
% Export results
% -------------------------------------------------------------------------
    function onExport(~, ~)
        ad = guidata(fig);
        if isempty(ad.runResult)
            uialert(fig, 'Please run optimization first!', 'Warning');
            return;
        end

        [file, path] = uiputfile({'*.xlsx', 'Excel File (*.xlsx)'; '*.mat', 'MAT File (*.mat)'}, ...
                                 'Export Results', 'PMRICRAS_Results.xlsx');
        if file == 0, return; end

        res = ad.runResult;
        fpath = fullfile(path, file);

        [~, ~, ext] = fileparts(file);
        if strcmpi(ext, '.mat')
            result = res; %#ok<NASGU>
            save(fpath, 'result');
        else
            T1 = array2table(res.AA, 'VariableNames', {'Index', 'Experiment', 'Fitted', 'Difference'});
            writetable(T1, fpath, 'Sheet', 'FitComparison');

            xb = res.xbest;
            T2 = table({'sigma_0'; 'sigma_k'; 'sigma_c'; 'b_FR'; 'p_FR'; 'q_A'; 'q_B'}, ...
                       xb(1:7)', 'VariableNames', {'Parameter', 'OptimizedValue'});
            writetable(T2, fpath, 'Sheet', 'OptimizedParams');

            T3 = array2table(xb(8:end)', 'VariableNames', {'LayerThickness'});
            writetable(T3, fpath, 'Sheet', 'LayerThicknesses');

            T4 = array2table(res.Curve', 'VariableNames', {'Error_per_Iteration'});
            writetable(T4, fpath, 'Sheet', 'ConvergenceCurve');
        end

        uialert(fig, ['Results exported to: ' fpath], 'Success');
    end

% -------------------------------------------------------------------------
% Clear results
% -------------------------------------------------------------------------
    function onClearResults(~, ~)
        ad = guidata(fig);
        ad.runResult = [];
        guidata(fig, ad);

        cla(axConv); cla(axFit);
        title(axConv, 'Convergence Curve'); xlabel(axConv, 'Iteration'); ylabel(axConv, 'Error (%)');
        grid(axConv, 'on');
        title(axFit, 'Experiment vs. Fitted'); xlabel(axFit, 'Data Point'); ylabel(axFit, 'Signal Intensity');
        grid(axFit, 'on');
        txtResult.Value = 'No results yet...';
        txtStatus.Value = 'Ready. Configure parameters and press START.';
        lblProgress.Text = 'Iteration: 0 / 0';
        lblETA.Text = 'ETA: --:--:--';
        lblElapsed.Text = 'Elapsed: 00:00:00';
    end

% -------------------------------------------------------------------------
% Log message to status area
% -------------------------------------------------------------------------
    function logMsg(msg)
        current = txtStatus.Value;
        % uitextarea.Value may return cell array — convert to char
        if iscell(current)
            current = strjoin(current, '\n');
        end
        if isempty(current) || isequal(current, {'Ready. Configure parameters and press START.'})
            txtStatus.Value = msg;
        elseif strcmp(strtrim(current), 'Ready. Configure parameters and press START.')
            txtStatus.Value = msg;
        else
            txtStatus.Value = sprintf('%s\n%s', current, msg);
        end
        drawnow;
    end

% =========================================================================
% Initialization
% =========================================================================
onAlgoChange(ddAlgo);
onLayerModeChange(ddLayerMode);
onBoundChange(ddBound);

% ---- Auto-load saved config on startup ----
if isfile(configFilePath)
    try
        data = load(configFilePath, 'config');
        if isfield(data, 'config')
            applyConfig(data.config);
        end
    catch
        % If load fails, just use defaults silently
    end
end

% ---- Auto-save config on close ----
fig.CloseRequestFcn = @(src, evt) onAppClose();

    function onAppClose()
        try
            cfg = collectConfig();
            config = cfg; %#ok<NASGU>
            save(configFilePath, 'config');
        catch
            % If save fails, still close gracefully
        end
        delete(fig);
    end

end
