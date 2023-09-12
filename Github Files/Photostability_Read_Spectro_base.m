function [PaMode] = Photostability_Read_Spectro_base(baseFolder, baseFilename, iFrames, modeName, varargin)
% A function to read PA-Mode raw data.
%
% Input:
%   baseFolder = Folder containing the data (can be empty)
%   baseFilename = Filename containing the data (extensions not required)
%   iFrames = A vector specifying the desired frames, -1 to load all frames
%   modeName = Mode name, '.pamode' and '.3d.pamode' are valid
%   varargin = Extra parameters
%       'TimestampOnly' = Can be set to true or false. Default false
%
% Output:
%   PaMode = Structure containing fields
%     PaMode.FrameNum = Vector of frame number
%     PaMode.Timestamp = Vector of the timestamps for each frame
%     PaMode.Data = Cell containing the data
%     PaMode.DataHbT = Cell containing the HbT data (Oxy-Hemo only)
%     PaMode.Width = Vector for the width axis
%     PaMode.Depth = Vector for the depth axis
%     PaMode.Wavelength = Vector containing the wavelength
%     PaMode.Energy = Cell containing a vector of 4 elements (regardless of 
%       how many quadrants were acquired). One element for each quadrant.
%     PaMode.AcqMode = String containing the acquisition mode. If the
%       acquisition mode is 'Oxy-Hemo' then the Wavelength and Energy fields
%       contain an addtion column for the secondary wavelength and energy.
%
% Revision History
% ================
%   2018-04-01    1.0     Initial release (Vevo F2 5.5.0)
%   2020-08-11    1.1     Added energy readings to the returned structure (Vevo F2 5.5.1)
%                         Added wavelength readings to the returned structure
%   2021-03-18    1.2     Added version numbers and copyright information (Vevo F2 5.6.0)
%
% Copyright 2021 FUJIFILM VisualSonics, Inc.

PaMode = struct(...
  'FrameNum', [], ...
  'Data', {}, ...
  'DataHbT', {}, ...
  'Width', [], ...
  'Depth', [], ...
  'Timestamp', [], ...
  'Wavelength', [], ...
  'Energy', [], ...
  'AcqMode', []);

try
  paramList = {
    'TimestampOnly', @islogical, false };
  parsedResults = VsiParseVarargin(paramList, varargin{:});
  
  timestampOnly = parsedResults.TimestampOnly;
  
  % Get parameter xml  file name and read
  fnameXml = [baseFilename '.raw.xml'];
  
  param = Spectro_XML_Photostability(baseFolder, fnameXml, '.pamode');
  
  % Get raw file name and check if the file exists
  
  
  fname = [baseFilename '.raw.pamode'];
%   if (~exist(fname, 'file'))
%     error('File (%s) not found', fname);
%   end
  
  % Open the raw file and check if successful
  fid = fopen(fname, 'r');
  if (-1 == fid)
    error('Failed to open %s', fname);
  end
  
  % Read the file header to get the version number
  retVal = fseek(fid, 0, 'bof');
  if (-1 == retVal)
    error('Failed to read file %s', fname);
  end
  
  % Check the version (10 or greater is from the F2 system)
  version = fread(fid, 1, 'uint32');
  if (version < 10)
    error('Invalid file version.');
  end
  
  % Read the file header to get the number of frames
  retVal = fseek(fid, 4, 'bof');
  if (-1 == retVal)
    error('Failed to read file %s', fname);
  end
  
  % Make sure all the requested frames are within range
  numFrames = fread(fid, 1, 'uint32');
  if (~(any(iFrames == -1) || (all(iFrames >= 1) && all(iFrames <= numFrames))))
    str = ['Invalid frame number(s): ' ...
      num2str(iFrames(~(iFrames >= 1 & iFrames <= numFrames)))];
    error('Invalid frame number(s) (%s)', str);
  end
  
  % Figure out list of frames that will be loaded
  if (any(iFrames == -1))
    if (length(iFrames) > 1)
      warning('Frame list includes -1. Loading all data.');
    end
    frameList = 1:numFrames;
  else
    frameList = iFrames;
  end
  
  % Read the file header to get the file format (8 bits or 32 bits)
  retVal = fseek(fid, 8, 'bof');
  if (-1 == retVal)
    error('Failed to read file %s', fname);
  end
  
  % Get short variable names
  numSamples = param.PaNumSamples;
  numLines = param.PaNumLines;
  depthOffset = param.PaDepthOffset; %Units: mm
  depth = param.PaDepth;   %Units: mm
  width = param.PaWidth;   %Units: mm
  center = param.PaCentre; %Units: mm
  oxyHemo = strcmp(param.AcqMode, 'Oxy-Hemo');
  
  % Get file header and datatype size
  file_header = 40; % Bytes
  line_header = 0;  % Bytes
  frame_header = 56; % Bytes
  dataByteSize = 2; % Bytes
  
  % Pre-allocate memory for faster loading
  numFramesToRead = length(frameList);
  PaMode(1).AcqMode = param.AcqMode;
  PaMode(1).FrameNum = zeros(numFramesToRead, 1);
  PaMode(1).Timestamp = zeros(numFramesToRead, 1);
  
  if (~timestampOnly)
    PaMode(1).Depth = [depthOffset:(depth-depthOffset)/(numSamples-1):depth]; %#ok<NBRAK>
    PaMode(1).Width = [0:width/(numLines-1):width] - width/2 + center; %#ok<NBRAK>
    PaMode(1).Wavelength = zeros(numFramesToRead, 2);
    PaMode(1).Energy = cell(numFramesToRead, 2);
    PaMode(1).Data = cell(numFramesToRead, 1);
    PaMode(1).DataHbT = cell(numFramesToRead, 1);
  end
  
  % Read specified frames
  for j = 1:numFramesToRead
    PaMode.FrameNum(j) = frameList(j);
    
    % Oxy-Hemo stores both the sO2 data and HbT within the exported file
    if (oxyHemo)
      header = file_header + frame_header*frameList(j) + ...
        (2*dataByteSize*numSamples*numLines + numLines*line_header)*(frameList(j)-1);
    else
      header = file_header + frame_header*frameList(j) + ...
        (dataByteSize*numSamples*numLines + numLines*line_header)*(frameList(j)-1);
    end
    
    % Read timestamp
    fseek(fid, header - frame_header + 4, 'bof');
    PaMode.Timestamp(j) = fread(fid, 1, 'double');
    
    if (~timestampOnly)
      % Read wavelength
      fseek(fid, header - frame_header + 24, 'bof');
      PaMode.Wavelength(j, 1) = fread(fid, 1, 'uint32');
      
      % Read energy
      maxEnergy = fread(fid, 1, 'float');
      PaMode.Energy{j, 1} = fread(fid, 4, 'uint16') * maxEnergy / 65535.0;
      
      % Oxy-Hemo stores two wavelengths and energies
      if (oxyHemo)
        % Read wavelength
        PaMode.Wavelength(j, 2) = fread(fid, 1, 'uint32');

        % Read energy
        maxEnergy = fread(fid, 1, 'float');
        PaMode.Energy{j, 2} = fread(fid, 4, 'uint16') * maxEnergy / 65535.0;
      end
      
      % Read data
      fseek(fid, header ,'bof');
      [PaMode.Data{j}(:,:)] = ...
        reshape(fread(fid, numSamples * numLines, 'ushort'), ...
        [numSamples, numLines]);
      
      % Oxy-Hemo stores the sO2 data and HbT within the exported file, 
      if (oxyHemo)
        % The sO2 data is store from 0 to ushort maximum, change to 0-100%
        PaMode.Data{j} = PaMode.Data{j} / 65535 * 100;
        
        % Load the HbT data
        [PaMode.DataHbT{j}(:,:)] = ...
          reshape(fread(fid, numSamples * numLines, 'ushort'), ...
          [numSamples, numLines]);
      end
    end
  end
  
  % If Not Oxy-Hemo cleanup structures (remove second entry in matrices)
  if (~oxyHemo)
    PaMode.Wavelength = PaMode.Wavelength(:, 1); 
    PaMode.Energy = PaMode.Energy(:, 1);
    PaMode = rmfield(PaMode, 'DataHbT');
  end
  
  fclose(fid);
catch err
  if (exist('fid','var') && -1 ~= fid)
    fclose(fid);
  end
  
  rethrow(err);
end

end

