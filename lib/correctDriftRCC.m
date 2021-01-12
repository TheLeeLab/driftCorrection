function [x,y,dx,dy] = correctDriftRCC(frame,x,y,segmentation,pixelsize_hist)

frame = frame - min(frame) + 1;
numFrames = max(frame);
numSegments = floor(numFrames/segmentation);

% Get edges for 2d histogram rendering
xEdges = min(x)-pixelsize_hist:pixelsize_hist:max(x)+pixelsize_hist;
yEdges = min(y)-pixelsize_hist:pixelsize_hist:max(y)+pixelsize_hist;

% Divide the dataset into substacks of 'segmentation' number of frames and
% generate a 2d histogram of each substack
segments = zeros(length(xEdges)-1,length(yEdges)-1,numSegments);
for i=1:numSegments
    if i < numSegments
        lb = (i-1)*segmentation; % first frame substack
        ub = i*segmentation; % last frame substack
        keep = logical((frame > lb).*(frame < ub));
    else
        lb = (i-1)*segmentation; % first frame substack
        keep = logical((frame > lb));
    end
    [ASH,~,~] = histcounts2(x(keep),y(keep),xEdges,yEdges);
    imshow(flipud(ASH'),[0 0.01*max(ASH(:))]); colormap(hot)
    segments(:,:,i) = ASH;
    title(['Segment ' num2str(i) '/' num2str(numSegments)])
    pause(0.5)
end

% Initialize drift correction
dx = zeros(numSegments,1);
dy = zeros(numSegments,1);

% Loop over segments and calculate the shift between the images of
% sequentiql substacks using cross-correlation
for i=2:numSegments
    
    % Get the 2d histograms that will be registered
    segment1 = flipud(segments(:,:,i-1)');
    segment2 = flipud(segments(:,:,i)');
    
    % Calculate normalised cross-correlation
    c = normxcorr2(segment2,segment1);
    % surf(c); shading flat;
       
    % get peak for pixel-resolution shift in x and y
    [~, imax] = max(c(:));
    [ypeak, xpeak] = ind2sub(size(c),imax(1)); % pixel-level resolution
    
    % refine to sub-pixel resolution by getting weighted centroid around
    % the location of the cross-correlation peak
    w = 5;
    c_roi = c(ypeak-w:ypeak+w,xpeak-w:xpeak+w);
    c_roi = c_roi/sum(c_roi(:));
    [xCoord,yCoord] = meshgrid(1:size(c_roi,1),1:size(c_roi,2));
    x_centroid = sum(xCoord.*c_roi,'all');
    y_centroid = sum(yCoord.*c_roi,'all');
    
    x_peak_subpix = x_centroid - (w+1);
    y_peak_subpix = y_centroid - (w+1);
    
    % % pixel-resolution
    % corr_offset = [(xpeak-size(segment2,2)) 
    %                (ypeak-size(segment2,1))];

    % sub-pixel resolution
    corr_offset = [((xpeak + x_peak_subpix) - size(segment2,2)) 
                   ((ypeak + y_peak_subpix) - size(segment2,1))];
               
    % total offset
    dx(i) =  corr_offset(1)*pixelsize_hist;
    dy(i) = -corr_offset(2)*pixelsize_hist;

end

dx = -cumsum(dx);
dy = -cumsum(dy);

% Undo calculated drift
x_driftCorrected = zeros(size(x));
y_driftCorrected = zeros(size(y));
for i=1:numSegments
    if i < numSegments
        lb = (i-1)*segmentation; % first frame substack
        ub = i*segmentation; % last frame substack
        keep = logical((frame > lb).*(frame < ub));
        x_driftCorrected(keep) = x(keep) - dx(i);
        y_driftCorrected(keep) = y(keep) - dy(i);
    else
        lb = (i-1)*segmentation; % first frame substack
        keep = logical((frame > lb));
        x_driftCorrected(keep) = x(keep) - dx(i);
        y_driftCorrected(keep) = y(keep) - dy(i);
    end

end

x = x_driftCorrected;
y = y_driftCorrected;
end