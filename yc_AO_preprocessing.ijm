// you need to create a newfolder called "Report" before runing this Macro

//open a file
run("Bio-Formats Importer", "open= autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT")

//selection of the vessel to be straightened
directory = getDirectory("image");
path = directory + "/Report/"; // you need to create a newfolder called "Report" first
run("Grays");
run("Reslice [/]...", "output=0.500 start=Left avoid");
run("Z Project...", "projection=[Max Intensity]");
run("In [+]");
run("Enhance Contrast", "saturated=0.7");

title = getTitle();
title2 = substring(title, 4);

setTool('polyline');
waitForUser("Please draw a thick polyline along the vessel");

//save selected ROI
nROIs = roiManager("count");
roiManager("Add");
roiManager("Select", nROIs);
roiManager("Rename", substring(title, 15));
roiManager("Save", path + substring(title, 15) + ".roi");

selectWindow(title2);
roiManager("Select", nROIs);

//straightening
getLine(x1, y1, x2, y2, lineWidth)
run("Straighten...", "title=[" + title2 + "_Straightened] line=" + lineWidth + " process");
run("Reslice [/]...", "output=1.000 start=Top rotate avoid");

saveAs("Tiff", path + substring(title, 15) + "_Straightened.tif");

//To split the front and back side of the vessel
directory = getDirectory("image") + "//";
title = getTitle();
//run("Orthogonal Views");
waitForUser("Please scroll to a slice where to split the vessel"); //manual selection of split plane
splitPlane = getSliceNumber();
//selectWindow("YZ 1024");
//close();

//split and MIP the two sub-z-stacks
run("Z Project...", "stop=" + splitPlane + " projection=[Max Intensity]");
run("Invert LUT");
run("Enhance Contrast", "saturated=0.35");
nameA = getTitle();
saveAs("Tiff", directory + substring(title, 0,lengthOf(title) - 4) + "_MaxSplit_A.tif");

selectWindow(title);
run("Z Project...", "start=" + splitPlane + " projection=[Max Intensity]");
run("Invert LUT");
run("Enhance Contrast", "saturated=0.35");
nameB = getTitle();
saveAs("Tiff", directory + substring(title, 0,lengthOf(title) - 4) + "_MaxSplit_B.tif");

//To combine the two split images together
//run("Combine...", "stack1=[" + nameA + "] stack2=[" + nameB + "]");
//rename(title);
//run("Enhance Contrast", "saturated=0.7");
//saveAs("Tiff", directory + substring(title, 0,lengthOf(title) - 4) + "_MaxSplit.tif");

