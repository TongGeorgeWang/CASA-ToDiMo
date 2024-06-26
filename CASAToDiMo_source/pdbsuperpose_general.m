function [dist, rmsd, transf, pdb2tx] = pdbsuperpose_general(PDB1, PDB2, varargin)
%PDBSUPERPOSE superposes the 3-D structures of two proteins.
%   GW - modified to recognize more than protein pdbs. (This is a MATLAB
%       function written by Mathworks; documentation below).
%       Got rid of a lot of stuff....
%       Removed stuff about chains and sequences. 
%       No longer has sequence alignment functionality.
%
%   PDBSUPERPOSE(PDB1, PDB2) computes and applies a linear transformation
%   to superpose the coordinates of the protein structure represented in
%   PDB2 to the coordinates of the protein structure represented in PDB1. 
%   PDB1 and PDB2 can be valid identifiers in the PDB database, names of
%   variables containing PDB-formatted MATLAB structures, or names of
%   PDB-formatted files. Alpha Carbon atom coordinates of single chains for
%   each structure are considered to compute the linear transformation
%   (translation, reflection, orthogonal rotation, and scaling). By
%   default, the first chain in each structure is considered to compute the
%   transformation, and the transformation is applied to the entire
%   molecule. By default, the original PDB1 structure and the resulting
%   transformed PDB2 structure are displayed as separate models using
%   MOLVIEWER.
%
%   DIST = PDBSUPERPOSE(PDB1, PDB2) returns a dissimilarity measure given
%   by the sum of the squared errors between PDB1 and PDB2.  See PROCRUSTES
%   for more information.
%
%   [DIST, RMSD] = PDBSUPERPOSE(PDB1, PDB2) also returns the root mean square
%   distance between PDB1 and the transformed PDB2 coordinates, considering
%   only the atoms used to compute the linear transformation.
%
%   [DIST, RMSD, TRANSF] = PDBSUPERPOSE(PDB1, PDB2) also returns TRANSF,
%   the linear transformation used to superpose PDB2 to PDB1. TRANSF is a
%   MATLAB structure with the following fields:
%      T: orthogonal rotation and reflection component 
%      b: scale component
%      c: translation component
%   Only alpha Carbon atom coordinates are used to compute the linear
%   transformation.
%
%   [DIST, RMSD, TRANSF, PDB2TX] = PDBSUPERPOSE(PDB1, PDB2) also returns a
%   PDB-formatted MATLAB structure PDB2TX, representing the coordinates in
%   the transformed PDB2 structure.   
%
%   PDBSUPERPOSE(..., 'MODEL', MODELNUM) specifies the models to consider
%   in the superposition when PDB1 or PDB2 contain multiple models.
%   MODELNUM must be a numeric array whose elements correspond to the
%   models in PDB1 and PDB2 respectively. By default, the first model in
%   each structure is considered.
%
%   PDBSUPERPOSE(..., 'SCALE', TF) specifies whether to include a scaling
%   component in the linear transformation. Default is false.
%
%   PDBSUPERPOSE(..., 'TRANSLATE', TF) specifies whether to include a
%   translation component in the linear transformation. Default is true.
%
%   PDBSUPERPOSE(..., 'REFLECTION', REFLECTIONVALUE) specifies whether to
%   include a reflection component in the linear transformation. Valid
%   choices for REFLECTIONVALUE are: true (include reflection component),
%   false (exclude reflection component), 'best' (may or may not include
%   the reflection component, depending on the best fit solution). Default
%   is 'best'.
%
%   PDBSUPERPOSE(..., 'SEQALIGN', TF) specifies whether to perform a local
%   sequence alignment and use only the portions of the structures
%   corresponding to the segments that align to compute the linear
%   transformation. Default is true.
%
%   PDBSUPERPOSE(..., 'SEGMENT', SEGMENTVALUE) specifies the boundaries and
%   the chain of two subsequences to consider for computing the linear
%   transformation. SEGMENTVALUE is a cell array of strings with the
%   following format: {'start1-stop1:chain1', 'start2-stop2:chain2'}. The
%   boundaries can be omitted to indicate the entire chain, such as in
%   {'chain1', 'start2-stop2:chain2'}. Only one pair of segments can be
%   specified at any given time and the specified segments are assumed to
%   contain the same number of Alpha Carbon atoms. 
%
%   PDBSUPERPOSE(..., 'APPLY', APPLYVALUE) specifies the extent to which
%   the linear transformation should be applied. Valid choices for
%   APPLYVALUE are: 'all' (apply the linear transformation to the entire
%   PDB2 structure), 'chain' (apply the linear transformation to the
%   specified chain only) or 'segment' (apply the linear transformation to
%   the specified segment only). Default is 'all'.
% 
%   PDBSUPERPOSE(..., 'DISPLAY', TF) specifies whether to display the
%   original PDB1 structure and the resulting transformed PDB2TX structure
%   using MOLVIEWER. Each structure is represented as a separate model.
%   Default is false.
%
%   The DISPLAY name-value argument will be removed in a future release.
%
%   The remaining input parameters are analogous to those for SWALIGN and
%   are used when SEQALIGN is true. See help on SWALIGN for more info.
%
%   PDBSUPERPOSE(..., 'SCORINGMATRIX', matrix) 
%   PDBSUPERPOSE(..., 'GAPOPEN', penalty)
%   PDBSUPERPOSE(..., 'EXTENDGAP', penalty) 
%
%   See also GETPDB, MOLVIEWER, PDBREAD, PDBTRANSFORM, PROCRUSTES, SWALIGN.

%   Copyright 2008-2023 The MathWorks, Inc.

%=== input checking and parsing
if nargin > 0
    PDB1 = convertStringsToChars(PDB1);
end

if nargin > 1
    PDB2 = convertStringsToChars(PDB2);
end

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

bioinfochecknargin(nargin,2,mfilename);
[model, start, stop, chain, apply, doScale, doTransl, doReflect, ...
    doAlign, swalignArgs, doDisplay, doHetero] = parse_inputs(varargin{:});

%=== read the pdb entries (structures, PDB files, or valid PDB IDs)
pdbStruct1 = localReadInput(PDB1);
pdbStruct2 = localReadInput(PDB2);

% %=== set default chain (first chain in each PDB)
% chainList1 = {pdbStruct1.Sequence.ChainID}; % all chains
% chainList2 = {pdbStruct2.Sequence.ChainID}; % all chains
% 
% if isempty(chain{1})
%     chain(1) = chainList1(1);
% end
% 
% if isempty(chain{2})
%     chain(2) = chainList2(1);
% end
% 
% %=== check validity of selected chains
% c1 = strmatch(chain(1), chainList1, 'exact');
% c2 = strmatch(chain(2), chainList2, 'exact');
% 
% if isempty(c1) || isempty(c2)
%     error(message('bioinfo:pdbsuperpose:InvalidChain'));
% end

%=== get specified model
modelStruct1 = pdbStruct1.Model(model(1));
modelStruct2 = pdbStruct2.Model(model(2));

%=== initialize coords of transformed pdb
if doDisplay || nargout > 3
    doCoord = true; % keep track of transformed coordinates
    atomCoordsTx = [[modelStruct2.Atom.X];  [modelStruct2.Atom.Y];  [modelStruct2.Atom.Z]]'; % coordinates of ALL atoms in the model
else
    doCoord = false;
end

% %=== determine range of residue positions in specified chains
% isChain1Atom = [modelStruct1.Atom.chainID]' == chain{1}; % atoms in chain1
% isChain2Atom = [modelStruct2.Atom.chainID]' == chain{2}; % atoms in chain2
% 
% chain1Atoms = modelStruct1.Atom(isChain1Atom); % data for atoms in chain1
% chain2Atoms = modelStruct2.Atom(isChain2Atom); % data for atoms in chain2
% 
% %=== retrieve sequence represented in the file (cannot always rely on pdbStruct1.Sequence(c1).Sequence)
% chain1BkAtoms = chain1Atoms(strmatch('CA', {chain1Atoms.AtomName}, 'exact')); 
% chain2BkAtoms = chain2Atoms(strmatch('CA', {chain2Atoms.AtomName}, 'exact')); 
% [~, i] = unique([chain1BkAtoms.resSeq], 'first');
% chain1BkAtoms = chain1BkAtoms(i); % select only one CA per residue (conformers issue)
% [~, i] = unique([chain2BkAtoms.resSeq], 'first');
% chain2BkAtoms = chain2BkAtoms(i); % select only one CA per residue (conformers issue)

molecule1 = modelStruct1.Atom;
molecule2 = modelStruct2.Atom;


%=== compute transformation
[dist, rmsd, ~, transf] = localDoTransform(molecule1, ...
	molecule2, doScale, doTransl, doReflect);

%=== compute transformed coordinates (apply transformation as needed)
if doCoord

    if apply == 1 % entire structure
        allAtomCoords = [[modelStruct2.Atom.X]; [modelStruct2.Atom.Y]; [modelStruct2.Atom.Z]]';
        n = size(allAtomCoords, 1);
        atomCoordsTx = transf.b * allAtomCoords * transf.T + repmat(transf.c(1,:), n, 1);
        
    elseif apply == 2 % specified chain
        chain2AtomCoords = [[chain2Atoms.X]; [chain2Atoms.Y]; [chain2Atoms.Z]]'; % nx3
        n = size(chain2AtomCoords, 1);
        atomCoordsTx(isChain2Atom,:) =  transf.b * chain2AtomCoords * transf.T + repmat(transf.c(1,:), n, 1);
        
    else % apply  == 3, only segment
        isSeg2Atom = isChain2Atom;
		isSelected2Atom = ismember([chain2Atoms.resSeq], selectedRes2);
        isSeg2Atom(isSeg2Atom) = isSelected2Atom; % logical w.r.t. the entire structure

        seg2Atoms = chain2Atoms(isSelected2Atom);
        seg2AtomCoords = [[seg2Atoms.X]; [seg2Atoms.Y]; [seg2Atoms.Z]]'; % nx3
        n = size(seg2AtomCoords, 1);
        atomCoordsTx(isSeg2Atom,:) =  transf.b * seg2AtomCoords * transf.T + repmat(transf.c(1,:), n, 1);
    end
          
    %=== write newly transformed coordinates
    for i = 1:size(atomCoordsTx,1)
        modelStruct2.Atom(i).X = atomCoordsTx(i,1);
        modelStruct2.Atom(i).Y = atomCoordsTx(i,2);
        modelStruct2.Atom(i).Z = atomCoordsTx(i,3);
    end

    %=== apply transformation to hetero atoms if wanted (UNDOCUMENTED)
    if doHetero > 0

        hetCoords = [[modelStruct2.HeterogenAtom.X]; ...
            [modelStruct2.HeterogenAtom.Y]; ...
            [modelStruct2.HeterogenAtom.Z]]';
        nh = size(hetCoords, 1);
        hetCoordsTx =  transf.b * hetCoords * transf.T + repmat(transf.c(1,:), nh, 1);

        for i = 1:nh
            modelStruct2.HeterogenAtom(i).X = hetCoordsTx(i,1);
            modelStruct2.HeterogenAtom(i).Y = hetCoordsTx(i,2);
            modelStruct2.HeterogenAtom(i).Z = hetCoordsTx(i,3);
        end
    end

    pdb2tx = pdbStruct2;
    pdb2tx.Model(model(2)) = modelStruct2;
end

if doDisplay
       
    %=== make sure that the two structures are similar
    f1 = fieldnames(modelStruct1);
    f2 = fieldnames(modelStruct2);
    
    if ~isequal(f1, f2)
        missingFrom1 = ~isfield(modelStruct1, f2);
        missingFrom2 = ~isfield(modelStruct2, f1);
        if any(missingFrom1)
            fields = f2(missingFrom1);
            for i = 1:numel(fields)
                modelStruct1.(fields{i}) = '';
            end
        end
        if any(missingFrom2)
           fields = f1(missingFrom2); 
           for i = 1:numel(fields)
               modelStruct2.(fields{i}) = '';
           end
        end
    end
    
    %=== write PDB struct for combo
    pdbCombo = rmfield(pdbStruct1, 'Model'); % in case there are many models
    pdbCombo.Model(1) = modelStruct1;
   
    f1 = fieldnames(modelStruct1);
    pdbCombo.Model(2) = orderfields(modelStruct2, f1);
    pdbCombo = orderfields(pdbCombo, pdbStruct1);
    
    if isfield(pdbCombo.Model(1), 'MDLSerNo')
        pdbCombo.Model(1).MDLSerNo = 1;
        pdbCombo.Model(2).MDLSerNo = 2;
    end
    
    h = molviewer(pdbCombo);
    evalrasmolscript(h, 'select all; wireframe off; spacefill off;');
    evalrasmolscript(h, 'color chain; cartoon on;');
end


%--------------------------------------------------------------------------
function [d, rmsd, z, tr] = localDoTransform(chain1BkAtoms, chain2BkAtoms, doScale, doTransl, doReflect)
% Compute linear transformation using the backbone atoms coordinates

% NOTE: if there are confomers, there will be at least 2 CA for some
% residues. Thus even though the # of positions considered is the same, the
% number of backbone atoms will not be the same (e.g. 2trx and 3trx, HIS6
% has 2 conformers. In order for PROCRUSTES to work, the number of
% coordinates to compare must be the same, therefore only one conformer is
% considered.

%=== check that backbone atoms are in the same number
if numel(chain1BkAtoms) ~= numel(chain2BkAtoms)
    error(message('bioinfo:pdbsuperpose:DifferentBkAtomNumber'));
end

%=== get backbone atom coordinates (M x 3 matrix)
bk1AtomCoords = [chain1BkAtoms.X; chain1BkAtoms.Y; chain1BkAtoms.Z]';
bk2AtomCoords = [chain2BkAtoms.X; chain2BkAtoms.Y; chain2BkAtoms.Z]';

%=== determine linear transformation using backbone atoms
[d, z, tr] = procrustes(bk1AtomCoords, bk2AtomCoords, 'reflection', doReflect, 'scaling', doScale);
n = size(bk2AtomCoords, 1);

%=== compute rmsd
rmsd = sqrt((sum((bk1AtomCoords(:) - z(:)).^2) / n));

%=== correct untraslated version
if ~doTransl
    tr.c = [0 0 0];
    z =  tr.b * bk2AtomCoords * tr.T;
    d = sum((z(:) - bk1AtomCoords(:)).^2) / sum(sum((bk1AtomCoords - repmat(mean(bk1AtomCoords,1), n, 1)).^2, 1));
end

%--------------------------------------------------------------------------
function pdbStruct = localReadInput(PDB)
% Read input

try
    if (~isstruct(PDB))
        if exist(PDB,'file')
            pdbStruct = pdbread(PDB);
        else
            pdbStruct = getpdb(PDB);
        end
    else
        pdbStruct = convertpdbstruct(PDB);            
    end
catch theErr
    if ~isempty(strfind(theErr.identifier,'getpdb')) 
        rethrow(theErr)
    end
    error(message('bioinfo:pdbsuperpose:InvalidInput'));
end

%--------------------------------------------------------------------------
function [model, start, stop, chain, apply, doScale, doTransl, doReflect, ...
    doAlign, swalignArgs, doDisplay, doHetero] = parse_inputs(varargin)
% Parse input PV pairs.
     
%=== Check for the right number of inputs
if rem(nargin,2) == 1
    error(message('bioinfo:pdbsuperpose:IncorrectNumberOfArguments', mfilename));
end

%=== Allowed options 
okargs = {'model', 'segment', 'scale', 'translate', 'reflection', 'seqalign', ...
   'display', 'apply', 'scoringmatrix', 'gapopen', 'extendgap', 'hetero'};

%=== Defaults
model = ones(1,2);    % model to consider
start = zeros(1,2);   % start boundaries of segments
stop = zeros(1,2);    % stop boundaries of segments
chain = cell(1,2);    % chains to which segments belong
apply = 1;            % apply to the entire struct (1), the chain (2) or the segment (3)
doScale = false;      % compute (possibly) scaled transformation
doTransl = true;      % compute (possibly) translated transformation
doReflect = 'best';   % compute (possibly) reflected transformation
doAlign = true;       % perform local alignment
swalignArgs = {};     % arguments to pass to swalign
doDisplay = false;     % show in molviewer
doHetero = false;     % apply transformation to hetero atoms (undocumented)

for j=1:2:nargin
    [k, pval] = bioinfoprivate.pvpair(varargin{j}, varargin{j+1}, okargs, mfilename);
    switch(k)
     
        case 1 % model    
            if isnumeric(pval) &&  numel(pval) == 2
                model = pval;
            else
                error(message('bioinfo:pdbsuperpose:InvalidModelOption'));
            end
         
        case 2 % segment
            if iscell(pval) &&  numel(pval) == 2
                               
                %=== validate syntax for first segment
                s1 = regexpi(pval{1}, '^(\d+)-(\d+):(\w+)$', 'tokens');
                               
                if ~isempty(s1) 
                    start(1) = str2double(s1{1}{1});
                    stop(1) = str2double(s1{1}{2});
                    chain{1} = s1{1}{3};
                    
                else % must be chain only
                    s1 = regexpi(pval{1}, '^\w+$', 'match'); % assume chain are one alphanumeric char
                    
                    if ~isempty(s1)
                        chain{1} = s1{1};
                    else
                        error(message('bioinfo:pdbsuperpose:InvalidSegmentOneOption'));
                    end
                    
                end

                %=== validate syntax for second segment
                s2 = regexpi(pval{2}, '^(\d+)-(\d+):(\w+)$', 'tokens');
                
                if ~isempty(s2)
                    start(2) = str2double(s2{1}{1});
                    stop(2) = str2double(s2{1}{2});
                    chain{2} = s2{1}{3};
                    
                else % must be chain only
                    s2 = regexpi(pval{2}, '^\w+$', 'match'); % assume chain are one alphanumeric char
                    
                    if ~isempty(s2)
                        chain{2} = s2{1};
                    else
                        error(message('bioinfo:pdbsuperpose:InvalidSegmentTwoOption'));
                    end
                    
                end

                %=== validate boundaries
                v = start > stop;
                if any(v)
                    error(message('bioinfo:pdbsuperpose:InvalidSegmentBoundaries'));
                end
                            
            else
                 error(message('bioinfo:pdbsuperpose:InvalidSegmentOption'));
            end
            
        case 3 % scale
            doScale = bioinfoprivate.opttf(pval, okargs{k}, mfilename);
            
        case 4 % translate
            doTransl = bioinfoprivate.opttf(pval, okargs{k}, mfilename);
            
        case 5 % reflection
            if strcmpi(pval, 'best')
                doReflect = 'best';
            else
                try
                    doReflect = bioinfoprivate.opttf(pval, okargs{k}, mfilename);
                catch theErr
                    error(message('bioinfo:pdbsuperpose:InvalidReflectionOption'));
                end
            end
            
        case 6 % seqalign
            doAlign = bioinfoprivate.opttf(pval, okargs{k}, mfilename);
                                    
        case 7 % display
             warning(message('bioinfo:pdbsuperpose:DisplayToBeRemoved'));
             doDisplay = bioinfoprivate.opttf(pval, okargs{k}, mfilename);
        case 8 % apply
            if strcmpi(pval,'all')
                apply = 1;
            elseif strcmpi(pval, 'chain')
                apply = 2;
            elseif strcmpi(pval, 'segment')
                apply = 3;
            else
                error(message('bioinfo:pdbsuperpose:InvalidApplyOption'));
            end
                    
        case 9 % scoringmatrix
            if isnumeric(pval)
                ScoringMatrix = pval;
            else
                if ischar(pval)
                    pval = lower(pval);
                end
                try
                    [ScoringMatrix,ScoringMatrixInfo] = feval(pval); %#ok
                catch theErr
                    error(message('bioinfo:pdbsuperpose:InvalidScoringMatrix'));
                end
            end
            swalignArgs = {swalignArgs{:}, 'scoringmatrix', ScoringMatrix}; %#ok<CCAT>
       
            
        case 10 % gapopen
            gapopen = pval;
            swalignArgs = {swalignArgs{:}, 'gapopen', gapopen}; %#ok<CCAT>
              
        case 11 % extendgap
            gapextend = pval;
            swalignArgs = {swalignArgs{:},'extend',gapextend}; %#ok<CCAT>
            
        case 12 % hetero
            doHetero = bioinfoprivate.opttf(pval, okargs{k}, mfilename);
            
    end
end

if ~doAlign && ~isempty(swalignArgs)
    error(message('bioinfo:pdbsuperpose:InconsistentAlignOption'));
end

