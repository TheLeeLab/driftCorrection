# driftCorrection

This repo contains some MATLAB functions and scripts for performing fiducial and RCC-based drift correction on SMLM data. Most localization software (e.g. ThunderStorm, Picasso, ...) already support drift-correction. For a reason, I can't always use these, so I wrote these matlab functions. I don't guarantee there isn't a mistake somewhere, so please don't trust this code blindly.

The two main files are:
* *correctDriftFiducial.m*: for use on real data. It reads in an SMLM localisation file that needs to have at least a column for frame, x- and y-coordinate. The user doesn't have to edit the script to input parameters. Pop-up windows will appear that ask to fill in parameters or navigate to a file.
* *testCorrectDriftFiducial.m*: for testing drift correction functions. It first simulates a dataset with drift and then performs analysis on it. For testing purpose only.

## Fiducial-based drift correction ##

This type of drift correction can be applied if the sample includes fiducials (e.g. fluorescent beads). The user can select multiple fiducials by dragging rectangles on a scatter plot. Drift will be calculated for each fiducial and the global average will be applied to the data. Figures will be generated of the estimated drift of each fiducial seperately, and a histogram of their displacements/frame. If the calculated drift for all fiducials is wildly different, something is wrong (either you selected something that's not a fiducial, localisation of fiducials failed, your fiducials saturated the camera at some point or your fiducials are not properly immobilized on the sample). If the histogram of displacement/frame of one of the fiducials is much broader compared to the others, it could be a good idea to redo the drift correction and leave that fiducial out.

## Redundant cross-correlation (RCC) ##

This type of drift correction can be used when there are no fiducials in the sample. Here is a [paper](https://doi.org/10.1364/OE.22.015982) on it and the [source code](https://github.com/yinawang28/RCC) that accompanied it (also MATLAB). RCC divides the localisation file into segments that are each N frames long (e.g. 1000 frames/segment; segment1 frames 1-1000, segment2 frames 1001-2000, etc.) and generates a seperate image from the localisations in each segment. Each image is registered on the image from the previous segment using cross-correlation. The displacements needed to register the images are proportional to the actual drift.

RCC works best when the dataset contains a lot of frames and many localisations per frame. This method can work really well for e.g. PAINT data if the drift is linear (fixed speed in x direction, fixed speed in y direction). It is important to make sure that the parameter N (number of frames in 1 segment) is not too low. The image reconstructed from one segment should be sampled well spatially, i.e. they shouldn't look very different except for one reason, drift. If not, the registration of segments will do strange things. The number of frames in one segment should also not be too large, because the drift-correction will be coarse. In general, if you have fiducials, it is safer to use fiducial-based drift-correction.
