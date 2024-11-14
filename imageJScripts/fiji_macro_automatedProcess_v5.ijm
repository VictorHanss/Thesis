// Macro written by Victor HANSS
// Version: 30.01.23

//// Pop up window to choose data directory
dirAll = getDir("Open dir containing ESB & SESI folders");

//// Pop up window to select images to process according to dectector
Dialog.create("Selecting Stack");
label = "Chose the stack to process:";
items = newArray("SESI","ESB","BOTH");
Dialog.addRadioButtonGroup(label, items, 3, 1,"BOTH");
Dialog.show();

stackToProcess = Dialog.getRadioButton();


////////// VARIABLES

fileDirAll = getFileList(dirAll);
var recX = newArray(4); 
var recY = newArray(4); 
var ClaheYes = 10;
var MeanYes = 10;
var startAgain = 10;
var ClaheSlope = 1.5;
var MeanSigma = 0.8;
increment = 10;

// Initialize SESI or ESB folder and image Path in different  
// variables depending on they prensence in the data directory.
for (i = 0; i < lengthOf(fileDirAll); i++) {
    print(fileDirAll[i]);
    if (fileDirAll[i] == "ESB/") {
    	dirESB= dirAll + "ESB" ;
    	filesESB = getFileList(dirESB);
    	filesESB = Array.deleteValue(filesESB, "chips/");
    	imgFirst = 0;
		imgMid = round((lengthOf(filesESB))/2);
		imgEnd = lengthOf(filesESB)-1;
		// Array.show(filesESB);
    }
    
    if (fileDirAll[i] == "SESI/") {
    	dirSESI= dirAll + "SESI" ;
    	filesSESI = getFileList(dirSESI);
    	filesSESI = Array.deleteValue(filesSESI, "chips/");
    	imgFirst = 0;
		imgMid = round((lengthOf(filesSESI))/2);
		imgEnd = lengthOf(filesSESI)-1;
		// Array.show(filesSESI);
    }
}


////////// FUNCTIONS

function makeStackOfThree(dirDetector, fileImg, nameStack) { 
	// Opens 3 images, 1st, middle and last,
	// of the list of frames and put group 
	// them in a stack with a title.
	open(dirDetector + "/" + fileImg[imgFirst]);
	open(dirDetector + "/" + fileImg[imgMid]);
	open(dirDetector + "/" + fileImg[imgEnd]);
	run("Images to Stack", "use");
	rename(nameStack);
}
	
function getCropRoi(stackName) { 
	// Wait for user to select a ROI, record and get
	// its coordinates in recX and recY global variables
	selectWindow(stackName);
	waitForUser("Crop", "Select an area to crop");
	Roi.getCoordinates(recX, recY);
	// Array.show("title2", recX, recY);
	close(stackName);
}

function OpenCroppImg(pathImg, nameImg) { 
	// Open img given by pathImg and crop it according 
	// to the coordinates saved in recX and recY global variables
	open(pathImg); rename(nameImg); selectWindow(nameImg);
	// Array.show("title2", recX, recY);
	makeRectangle(recX[0], recY[0], recX[2]-recX[0] ,recY[2]-recY[0]);
	run("Crop"); run("Invert");
}

function windowsSelectionParameters() { 
	// Display a window to adjust CLAHESlope and MeanSigma
	// global variable values and modifies the ClaheYes and 
	// MeanYes global varibales for later processing.
	Dialog.create("Processing");
	Dialog.addMessage("Do you want CLAHE ?");
	Dialog.addCheckbox("Yes", false);
	Dialog.addNumber("Slope", ClaheSlope);
	Dialog.addMessage("Do you want Mean filtering ?\n");
	Dialog.addCheckbox("Yes", false);
	Dialog.addNumber("Sigma", MeanSigma);
	Dialog.show();
	ClaheYes = Dialog.getCheckbox();
	ClaheSlope = Dialog.getNumber();
	MeanYes = Dialog.getCheckbox();
	MeanSigma = Dialog.getNumber();
		
	if (ClaheYes == 1) {
		run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum="+ClaheSlope+" mask=*None* fast_(less_accurate)");
	}
	
	if (MeanYes == 1) {
		run("Mean...", "radius="+MeanSigma);
	}
	
	Dialog.create("Restart ?");
	Dialog.addMessage("Do you want to restart this step");
	Dialog.addCheckbox("Yes", false);
	Dialog.show();
	startAgain = Dialog.getCheckbox();
	close("Crop-Invert");
}

function fullStackProcessing(nameWindow, pathSaveOutput) { 
	// Crop selected windows stored in the nameWindow variable according
	// to the recX and recY global variables.
	
	// Process cropped images with clahe and mean filtering through
	// the ClaheSlope and MeanSigma global varibales if ClaheYes and MeanYes 
	// global varibales equal 1.
	
	// Saves the final processed image in the path stored in the pathSaveOutput variable.
	selectWindow(nameWindow);
	makeRectangle(recX[0], recY[0], recX[2]-recX[0] ,recY[2]-recY[0]);
	
	run("Crop"); run("Invert");
	
	if (ClaheYes == 1) {
		run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum="+ClaheSlope+" mask=*None* fast_(less_accurate)");
	}

	if (MeanYes == 1) {
		run("Mean...", "radius="+MeanSigma);
	}
	
	save(pathSaveOutput + "slice_"+i+1);
	
	IJ.freeMemory();
	
	showProgress(i, lengthOf(filesESB));
}

function mergeEsbSESI(inSesi,inEsb,percent) { 
	// multiply inSesi and inEsb images by percent/100 and 1-(percent/100)
	// respectively to finaly add the multiplied together and get back 100% 
	// of intensity from the "merging" addition.
	selectWindow(inSesi); run("Duplicate...", "title=sesiMerge");
	selectWindow("sesiMerge"); run("Multiply...", "value="+percent/100);
	selectWindow(inEsb); run("Duplicate...", "title=esbMerge");
	selectWindow("esbMerge"); run("Multiply...", "value="+1-(percent/100));
	run("Calculator Plus", "i1=sesiMerge i2=esbMerge operation=[Add: i2 = (i1+i2) x k1 + k2] k1=1 k2=0 create");
	close("esbMerge"); close("sesiMerge");

}




////////// SESI and ESB img processing

if (stackToProcess == "BOTH") {
	
	// Opens the 3 images, 1st, middle and last to select cropped area
	makeStackOfThree(dirSESI, filesSESI, "sesistack");
	
	getCropRoi("sesistack");
	
	OpenCroppImg(dirSESI + "/" + filesSESI[imgMid], "sesiimg");
	OpenCroppImg(dirESB + "/" + filesESB[imgMid], "esbimg");
	
	
	//// SELECTION OF PROCESSING PARAMETERS
	for (i = 1; i < 10; i++) {
		// to get range of merge esb/sesi with sesi
		// weight going from 10% to 90% in the final image
		weight=i*increment;
		sesiFileName = "sesi-"+weight;
		mergeEsbSESI("sesiimg","esbimg",weight);
		getDimensions(width, height, channels, slices, frames);
		selectWindow("Result"); rename(sesiFileName);
		setFont("SansSerif", 95, "bold antialiased");
		drawString(weight+"% SESI", width/2, height*0.1, "white");
	}
	
	// creates the stack of 10 to 90% sesi weight images
	run("Concatenate...", "open image1=sesi-10 image2=sesi-20 image3=sesi-30 image4=sesi-40 image5=sesi-50 image6=sesi-60  image7=sesi-70  image8=sesi-80 image9=sesi-90  ");
	rename("merge");
	// Wait for user to select which frame of the stack they want to
	// proceed with
	waitForUser("Select","Select the image to proceed with");
	// Interestingly, the 1st frame will be 10%, the second 20 % and so on
	// until 90%. so getting the number of the frame in sthe stack and 
	// multiplying it by 10 gives the actual sesi weight of the img: allows 
	// to smoothly select.
	weight = getSliceNumber()*10; sesiFileName = "sesi-"+weight;
	mergeEsbSESI("sesiimg","esbimg",weight);
	rename(sesiFileName);
	close("merge"); close("esbimg"); close("sesiimg");
	
	run("Duplicate...", " ");
	rename("dupliFrame");
	
	waitForUser("Zoom","Zoom in a ROI");
	getZoom();
	// Get the displayed area coordinates to later display it
	// back if the user decides to try different clahe or mean
	// filter parameters.
	getDisplayedArea(x, y, width, height);
	// to display the area back, we use the set zoom commad (see line 224) which
	// display area from the center of the display but getDisplayedArea command
	// only gives the top left corner of the actual displayed area.
	zonex= x + (width/2); zoney= y + (height/2);
	
	
	do {	
		if (startAgain == 1) {
			// display gain the previous roi at the same magnification
			selectWindow(sesiFileName);
			run("Duplicate...", " ");
			rename("dupliFrame");
			run("Set... ", "zoom=150 x="+zonex+" y="+zoney);
		}
		windowsSelectionParameters();
		close("dupliFrame");
	}
	while (startAgain == 1)
	
	close(sesiFileName);
	
	
	//// PROCEED WITH FULL STACK PROCESSING
	Dialog.create("Full stack");
	Dialog.addMessage("Do you want to proceed with \nprocessing the complete stack ?");
	Dialog.addCheckbox("Yes", false);
	Dialog.show();
	fullStackYes = Dialog.getCheckbox();
	
	if (fullStackYes == 1) {
		File.makeDirectory(dirAll + "processing");
		setBatchMode(true);
		
		for (i = 0; i < lengthOf(filesESB); i++) {
			
			open(dirESB + "/" + filesESB[i]); rename("esbimg");
			open(dirSESI + "/" + filesSESI[i]); rename("sesiimg");
			
			mergeEsbSESI("sesiimg","esbimg",weight); print("weight: ",weight);
			
			rename("Result"); close("esbimg"); close("sesiimg");
			
			fullStackProcessing("Result", dirAll + "processing/");
			close("Result");
		}
		setBatchMode(false);
	}
}




////////// SESI img processing

if (stackToProcess == "SESI") {
	
	// Opens the 3 images, 1st, middle and last to select cropped area
	makeStackOfThree(dirSESI, filesSESI, "sesistack");
	
	getCropRoi("sesistack");
	
	OpenCroppImg(dirSESI + "/" + filesSESI[imgMid], "sesiimg");

	selectWindow("sesiimg");	
	run("Duplicate...", " ");
	rename("dupliFrame");
	
	
	//// SELECTION OF PROCESSING PARAMETERS
	do {	
		if (startAgain == 1) {
			selectWindow("sesiimg");
			run("Duplicate...", " ");
			rename("dupliFrame");
		}
		windowsSelectionParameters();
		close("dupliFrame");
	}
	while (startAgain == 1)
	
	close("sesiimg");
	
	
	//// PROCEED WITH FULL STACK PROCESSING
	Dialog.create("Full stack");
	Dialog.addMessage("Do you want to proceed with \nprocessing the complete stack ?");
	Dialog.addCheckbox("Yes", false);
	Dialog.show();
	fullStackYes = Dialog.getCheckbox();
	
	if (fullStackYes == 1) {
		File.makeDirectory(dirAll + "processing");
		setBatchMode(true);
		
		for (i = 0; i < lengthOf(filesSESI); i++) {
			
			open(dirSESI + "/" + filesSESI[i]); rename("sesiimg");
			
			fullStackProcessing("sesiimg", dirAll + "processing/");
			close("sesiimg");
		}
		setBatchMode(false);
	}
}




////////// ESB img processing

if (stackToProcess == "ESB") {
	
	// Opens the 3 images, 1st, middle and last to select cropped area
	makeStackOfThree(dirESB, filesESB, "esbstack");
			
	getCropRoi("esbstack");
	
	OpenCroppImg(dirESB + "/" + filesESB[imgMid], "esbimg");
	
	selectWindow("sesiimg");	
	run("Duplicate...", " ");
	rename("dupliFrame");
	
	
	//// SELECTION OF PROCESSING PARAMETERS
	do {	
		if (startAgain == 1) {
			selectWindow("esbimg");
			run("Duplicate...", " "); rename("dupliFrame");
		}
		windowsSelectionParameters();
		close("dupliFrame");
	}
	while (startAgain == 1)
	
	close("esbimg");
	
	
	//// PROCEED WITH FULL STACK PROCESSING
	Dialog.create("Full stack");
	Dialog.addMessage("Do you want to proceed with \nprocessing the complete stack ?");
	Dialog.addCheckbox("Yes", false);
	Dialog.show();
	fullStackYes = Dialog.getCheckbox();
	
	if (fullStackYes == 1) {
		File.makeDirectory(dirAll + "processing");
		setBatchMode(true);
		
		for (i = 0; i < lengthOf(filesESB); i++) {
			open(dirESB + "/" + filesESB[i]); rename("esbimg");
			
			fullStackProcessing("esbimg", dirAll + "processing/");	
			close("esbimg");
		}
		setBatchMode(false);
	}
}
