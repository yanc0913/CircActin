//check the scale in image properties:
scale = 0.0935328 //ZEISS LSM980, laser ablation


// Function for linear interpolation
function interpolate(array, t) {
    var index = t * (array.length - 1);
    var lowerIndex = Math.floor(index);
    var upperIndex = Math.ceil(index);
    var weight = index - lowerIndex;
    return array[lowerIndex] + weight * (array[upperIndex] - array[lowerIndex]);
}



///////////////////////////////////////////////////////////////////////////////////
//1. make a kymography from a ROI (draw a line across the vessel, with timelapse)//
///////////////////////////////////////////////////////////////////////////////////

directory = getDirectory("image");
Image_title = getTitle();
setTool('line');
run("Line Width...", "line=15");
//setLineWidth("60");
waitForUser("Please draw a thick line across the ablated region");

//save selected ROI
nROIs = roiManager("count");
roiManager("Add");
roiManager("Select", nROIs);
Dialog.create("Rename the ROI:");
Dialog.addString("Name of the KymoROI","KymoROI_1" );
Dialog.show();
ROIname = Dialog.getString();
roiManager("Rename", ROIname);
//roiManager("Save", directory + ROIname + ".roi");

////make kymograph
selectWindow(Image_title);
roiManager("Select", nROIs);
run("KymoResliceWide", "intensity=Maximum ignore ignore_0");
saveAs("Tiff", directory + ROIname + "_graph.tif");

run("Threshold...");

//Dialog.create("set threshold values");
//Dialog.addString("low","0" );
//Dialog.show();
//thres1 = Dialog.getString();
//thresLow = parseFloat(thres1);
//
//Dialog.create("set threshold values");
//Dialog.addString("high","10000" );
//Dialog.show();
//thres2 = Dialog.getString();
//thresHigh = parseFloat(thres2);
//
//setThreshold(thresLow, thresHigh, "raw"); 

waitForUser("Please adjust the threshold to highlight the gap\n\nclick Set\n\nTHEN: hit OK here\n\n\n");


setOption("BlackBackground", false);
run("Convert to Mask");
run("Fill Holes");
//run("Smooth");
saveAs("Tiff", directory + ROIname + "_binarymask.tif");

////ask if user want to proceed:
//waitForUser("Click OK to continue", "Proceed to measure Vessel diameter?");
//



///////////////////////////////////////////
////2. Measure Gap Distance ///////////
/////////////////////////////////////////

//use this if timelapses have different timepoint...
Dialog.create("Total Time of the kymograph");
Dialog.addString("Time","45" );
Dialog.show();
t1 = Dialog.getString();
desiredPoints= parseFloat(t1);


//if all timelapses have the same time length...
//desiredPoints= 28;


Kymo_title_tif = getTitle();
Kymo_title = substring(Kymo_title_tif, 0,lengthOf(Kymo_title_tif) - 4)
selectWindow(Kymo_title_tif);

//// measure the left edge of the vessel
setTool('polyline');
run("Line Width...", "line=1");
//setLineWidth("1");
waitForUser("Please draw a line on the LEFT edge of the vessel\n\nMake sure the line reaches the top and the bottom\n\nTHEN: hit OK\n\n\n");
//lengthDrawnLine1 = getValue('Length');
//run("Interpolate", "interval=2 smooth adjust");
nROIs = roiManager("count");
roiManager("Add");
roiManager("Select", nROIs);
roiManager("Rename", "Drawn_Left_Edge");
//roiManager("Save", directory + Kymo_title + "_Left.roi");
Roi.getCoordinates(xPoints1, yPoints1);

// Interpolate the polyline with a fixed number of points (desiredPoints)
new_x1 = newArray(desiredPoints);
new_y1 = newArray(desiredPoints);

// Interpolate x and y coordinates
for (i = 0; i < desiredPoints; i++) {
    normalizedIndex = i / (desiredPoints - 1); // Normalized index from 0 to 1
    // Linear interpolation for x
    new_x1[i] = interpolate(xPoints1, normalizedIndex);
    // Linear interpolation for y
    new_y1[i] = interpolate(yPoints1, normalizedIndex);
}

// Draw the interpolated polyline
makeSelection("polyline", new_x1, new_y1);
nROIs = roiManager("count");
roiManager("Add");
roiManager("Select", nROIs);
roiManager("Rename", "Interpolate_Left_Edge");
Roi.getCoordinates(new_x1, new_y1);


//print("x1-array size: "+x1.length);
//print("y1-array size: "+y1.length);
//Array.show("Results", x1, y1);

//left_y = newArray();
//left_x = newArray();
////need to exclude y coordinates that are smaller than 0
//minValue = 0;
//for (i = 0; i < y1.length; i++) {      
//    if(y1[i] > minValue){
//    	new_y1 = round(y1[i]);
//    	left_y = Array.concat(left_y, new_y1);
//    	new_x1 = round(x1[i]);
//    	left_x = Array.concat(left_x, new_x1);
//    }  
//}
//Array.show("Results", left_x, left_y);

////////////////////////////////////////////////////
//////// measure the right edge of the Gap///////
///////////////////////////////////////////////////

setTool('polyline');
setLineWidth("1");
waitForUser("Please draw a line on the RIGHT edge of the vessel\n\nMake sure the line reaches the top and the bottom\n\nTHEN: hit OK\n\n\n");
nROIs = roiManager("count");
roiManager("Add");
roiManager("Select", nROIs);
roiManager("Rename", "Drawn_Right_Edge");
//roiManager("Save", directory + Kymo_title + "_Left.roi");
Roi.getCoordinates(xPoints2, yPoints2);

// Interpolate the polyline with a fixed number of points (desiredPoints)
new_x2 = newArray(desiredPoints);
new_y2 = newArray(desiredPoints);

// Interpolate x and y coordinates
for (i = 0; i < desiredPoints; i++) {
    normalizedIndex = i / (desiredPoints - 1); // Normalized index from 0 to 1
    // Linear interpolation for x
    new_x2[i] = interpolate(xPoints2, normalizedIndex);
    // Linear interpolation for y
    new_y2[i] = interpolate(yPoints2, normalizedIndex);
}

// Draw the interpolated polyline
makeSelection("polyline", new_x2, new_y2);
nROIs = roiManager("count");
roiManager("Add");
roiManager("Select", nROIs);
roiManager("Rename", "Interpolate_Right_Edge");
Roi.getCoordinates(new_x2, new_y2);

////saveAs("Results", "C:\\Users\\Yan Chen\\Results.csv");

//calculate distance
//scale = 0.0481740 //Dragonfly 60xw lens, 2xCam

GapDistance = newArray();

j=0;
for (j = 0; j < new_y2.length; j++) { 
	distance = (new_x2[j] - new_x1[j]) * scale;
    GapDistance = Array.concat(GapDistance, distance);  	 
}


Array.show("Results", new_x1, new_y1, new_x2, new_y2, GapDistance);
saveAs("Results", directory + Kymo_title + "_XY_Coordinates.csv");
//close();

//save all ROIs
roiManager("deselect");
roiManager("save", directory + Kymo_title + "_RoiSet.zip");

run("Close All");
close("Results");
close("ROI Manager");


