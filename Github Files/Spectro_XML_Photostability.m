function [ReturnParam] = Spectro_XML_Photostability(baseFolder, baseFilename, modeName)
% A function to parse the xml parameter files exported from the Vevo F2
% and read selected parameters.
%
% Input:
%   baseFolder = Folder containing the data (can be empty)
%   baseFilename = Filename of the xml file (extension required)
%   modeName = Mode name to get the correct list of parameters. Valid
%       values:
%           '.bmode', '.3d.bmode',
%           '.color', '.3d.color',
%           '.power', '.3d.power',
%           '.mmode',
%           '.pw',
%           '.3d',
%           '.hw' (hardware parameters)
%           '.sw' (software parameters)
%           '.vada'
%
% Output:
%   ReturnParam = A structure containing the fields related to the
%       requested mode. Structure fields names depends on the mode.
%
% Revision History
% ================
%   2018-04-01    1.0     Initial release (Vevo F2 5.5.0)
%   2021-03-17    1.1     Additiona of Power Doppler mode (Vevo F2 5.6.0)
%                         Added version numbers and copyright information
%                         Added extra error checking
%
% Copyright 2021 FUJIFILM VisualSonics, Inc.

ReturnParam = [];
filename = baseFilename;

% try
%   if (~exist('baseFolder', 'var') || isempty(baseFolder))
%     filename = baseFilename;
%     disp(0)
%   else
%     filename = [baseFolder '/' baseFilename];
%   end
%   
%   if (~exist(filename, 'file'))
%     error('File (%s) not found', filename);
%   end
  
  % paramList represents the nodes to read from the xml.
  %   Column 1: Node name
  %   Column 2: Structure name for the return parameter
  %   Column 3: Type of data ('double' or 'char')
  switch (modeName)
    case {'.bmode', '.3d.bmode'}
      paramList = {
        'B-Mode/Samples',           'BmodeNumSamples',  'double';
        'B-Mode/Lines',             'BmodeNumLines',    'double';
        'B-Mode/Depth-Offset',      'BmodeDepthOffset', 'double';
        'B-Mode/Depth',             'BmodeDepth',       'double';
        'B-Mode/Width',             'BmodeWidth',       'double';
        'B-Mode/Centre',            'BmodeCentre',      'double';
        'B-Mode/Focal-Zones',       'FocalZones',       'doubleArray';
        'B-Mode/Compounding-Enabled',   'CompoundEnabled',  'boolean';
        'B-Mode/Compounding-Angles',    'CompoundAngles',   'doubleArray'};
    case {'.power', '.3d.power'}
      paramList = {
        'Power-Mode/Samples',       'PowerNumSamples',  'double';
        'Power-Mode/Lines',         'PowerNumLines',    'double';
        'Power-Mode/Depth-Offset',  'PowerDepthOffset', 'double';
        'Power-Mode/Depth',         'PowerDepth',       'double';
        'Power-Mode/Width',         'PowerWidth',       'double';
        'Power-Mode/Centre',        'PowerCentre',      'double';
        'Power-Mode/TX-PRF',        'PowerTxPrf',       'double';
        'Power-Mode/TX-Frequency',  'PowerTxFrequency', 'double';
        'Sample-Frequency',         'PowerRxFrequency', 'double';
        'Power-Mode/Ensemble-n',    'PowerNumEnsemble', 'double';
        'Power-Mode/Steering-Angle',    'PowerSteeringAngle', 'double';
        'Power-Mode/Group-Size',    'PowerGroupSize',   'double';
        'Power-Mode/Group-Count',   'PowerGroupCount',  'double' };
    case {'.pamode', '.3d.pamode'}
        paramList = {
        'Pa-Mode/Acquisition-Mode', 'AcqMode',          'char';
        'Pa-Mode/Samples',          'PaNumSamples',     'double';
        'Pa-Mode/Lines',            'PaNumLines',       'double';
        'Pa-Mode/Depth',            'PaDepth',          'double';
        'Pa-Mode/Depth-Offset',     'PaDepthOffset',    'double';
        'Pa-Mode/Width',            'PaWidth',          'double';
        'Pa-Mode/Centre',           'PaCentre',         'double'};
    case '.3d'
      paramList = {
        '3D-Scan-Distance',         'ScanDistance',     'double';
        '3D-Step-Size',             'ScanStepSize',     'double'};
    case '.hw'
      paramList = {
        'Time-Stamp-Clock',         'TimestampClock',   'double';
        'Number-Elements',          'NumElements',      'double';
        'Sample-Frequency',         'SampleFreq',       'double'};
    case '.sw'
      paramList = {
        'Sound-Speed-Tissue',       'SoSTissue',        'double'};
    case '.vada'
      paramList = {
          'Vada-Mode/Speed-Of-Sound-Media', 'VADASoSMedia',       'double';
          'Transducer-Name',                'TransducerName',     'char';
          'Class',                          'ArrayType',          'char';
          'Number-Elements',                'ArrayElementCount',  'double';
          'Element-Pitch',                  'ArrayPitch',         'double';
          'Lens-Thickness',                 'LensThickness',      'double';
          'Sound-Speed-Lens',               'LensSoS',            'double' };
    otherwise
      error('Mode (%s) not supported', modeName);
  end
  
  if (isempty(paramList))
    error('Parameter list is empty')
  end
  
  iCount = 0;
  
  xDoc = xmlread(filename);
  AllParameters = xDoc.getElementsByTagName('parameter');
  for i = 0:AllParameters.getLength-1
    node = AllParameters.item(i);
    for j = 1:size(paramList,1)
      if (strcmp(char(node.getAttribute('name')), paramList(j, 1)))
        switch (paramList{j,3})
          case 'boolean'
            javaTmp = node.getAttribute('value');
            ReturnParam.(paramList{j,2}) = strcmp('true', javaTmp);              
          case 'double'
            javaTmp = node.getAttribute('value');
            ReturnParam.(paramList{j,2}) = str2double(javaTmp);
          case 'doubleArray'
            javaTmp = node.getAttribute('value');
            
            % Use str2num as it converts the entire array
            ReturnParam.(paramList{j,2}) = str2num(javaTmp); %#ok<ST2NM>
          case 'char'
            javaTmp = node.getAttribute('value');
            ReturnParam.(paramList{j,2}) = char(javaTmp);
          otherwise
            warning('Unhandled conversion to %s', paramList{j,3});
        end
        
        iCount = iCount + 1;
        break;
      end
    end
  end
  
  if (iCount ~= size(paramList,1))
    % Write out parameters that are not available
    for i = 1:size(paramList,1)
      if (~isfield(ReturnParam, paramList{i,2}))
        warning('Did not read parameter: %s', paramList{i,2});
      end
    end
  end
  
% catch err
%   rethrow(err)
disp(ReturnParam)
end


