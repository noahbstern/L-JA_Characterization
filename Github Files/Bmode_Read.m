function [BMode] = Bmode_Read(baseFolder, baseFilename, iFrames, modeName, varargin)
% A function to read B-Mode raw data.
%
% Input:
%   baseFolder = Folder containing the data (can be empty)
%   baseFilename = Filename containing the data (extensions not required)
%   iFrames = A vector specifying the desired frames, -1 to load all frames
%   modeName = Mode name, '.bmode' and '.3d.bmode' are valid
%   varargin = Extra parameters
%       'TimestampOnly' = Can be set to true or false. Default false
%
% Output:
%   BMode = Structure containing fields
%     BMode.FrameNum = Vector of frame number 
%     BMode.Timestamp = Vector of the timestamps for each frame
%     BMode.Data = Cell containing the data 
%     BMode.Width = Vector for the width axis
%     BMode.Depth = Vector for the depth axis
%
% Revision History
% ================
%   2018-04-01    1.0     Initial release (Vevo F2 5.5.0)
%   2021-03-18    1.1     Added version numbers and copyright information (Vevo F2 5.6.0)
%
% Copyright 2021 FUJIFILM VisualSonics, Inc.

BMode = struct(...
  'FrameNum', [], ...
  'Data', {}, ...
  'Width', [], ...
  'Depth', [], ...
  'Timestamp', []);

try
  paramList = {
    'TimestampOnly', @islogical, false };
  parsedResults = VsiParseVarargin(paramList, varargin{:});
  
  timestampOnly = parsedResults.TimestampOnly;
  
  % Get parameter xml  file name and read
  fnameXml = [baseFilename '.raw.xml'];
  
  param = VsiParse_BmodeXml(baseFolder, fnameXml, '.bmode');
  
  % Get raw file name and check if the file exists
  fname  = [baseFilename '.raw' modeName];
  
  if (~exist(fname, 'file'))
    fname = [baseFilename '.raw.3d.bmode'];
  end
  
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
  
  fileFormat = fread(fid, 1, 'uint32');
  if (1 == bitget(fileFormat, 4))
    fileFormat = 'uchar';
    dataByteSize = 1;
  else 
    fileFormat = 'uint32';
    dataByteSize = 4;
  end
  
  % Get short variable names
  numSamples = param.BmodeNumSamples;
  numLines = param.BmodeNumLines;
  depthOffset = param.BmodeDepthOffset; %Units: mm
  depth = param.BmodeDepth;   %Units: mm
  width = param.BmodeWidth;   %Units: mm
  center = param.BmodeCentre; %Units: mm
  
  % Get file header and datatype size
  file_header = 40; % Bytes
  line_header = 0;  % Bytes
  frame_header = 56; % Bytes
  
  % Pre-allocate memory for faster loading
  numFramesToRead = length(frameList);
  BMode(1).FrameNum = zeros(numFramesToRead, 1);
  BMode(1).Timestamp = zeros(numFramesToRead, 1);
  
  if (~timestampOnly)
    BMode(1).Depth = [depthOffset:(depth-depthOffset)/(numSamples-1):depth]; %#ok<NBRAK>
    BMode(1).Width = [0:width/(numLines-1):width] - width/2 + center; %#ok<NBRAK>
    BMode(1).Data = cell(numFramesToRead, 1);
  end
  
  % Read specified frames
  for j = 1:numFramesToRead    
    BMode.FrameNum(j) = frameList(j);
    
    header = file_header + frame_header*frameList(j) + ...
      (dataByteSize*numSamples*numLines + numLines*line_header)*(frameList(j)-1);
    
    fseek(fid, header - frame_header + 4, 'bof');
    BMode.Timestamp(j) = fread(fid, 1, 'double');
    
     if (~timestampOnly)
      fseek(fid, header ,'bof');
       [BMode.Data{j}(:,:)] = ...
         reshape(fread(fid, numSamples * numLines, fileFormat),[numSamples, numLines]);
     end
  end
  
  fclose(fid);
catch err
  if (exist('fid','var') && -1 ~= fid)
    fclose(fid);
  end
  
  rethrow(err);
end

end

