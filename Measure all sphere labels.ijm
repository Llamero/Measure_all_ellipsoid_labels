close("*");
labelDirectory = "E:\\Altan Lab\\Median Filtered Stacks (5x5x5)\\Results\\Edited Labels\\";
labelList = getFileList(labelDirectory);
setBatchMode(true);

//Create a 3D stack to store the measurement data in
newImage("Measurement Matrix", "32-bit black", 9, 50, labelList.length);

for(a=0; a<labelList.length; a++){
	open(labelDirectory + labelList[a]);
	showProgress(a/labelList.length);
	measureAllSpheres(labelList[a],"Measurement Matrix",a+1);
	close(labelList[a]);
}
selectWindow("Measurement Matrix");
saveAs("tiff", "E:\\Altan Lab\\Median Filtered Stacks (5x5x5)\\Measurement Matrix.tiff");
setBatchMode(false);

function measureAllSpheres(labelStack, resultMatrix, fileNumber){
	//Convert 8-bit color to 8-bit
	selectWindow(labelStack);
	run("Grays");
	run("8-bit");

	//Measure the stack dimensions
	getDimensions(stackWidth, stackHeight, stackChannels, stackSlices, stackFrames);
	
	//Set the measurement tool to find the mean, centroid and radius of sphere labels
	run("Set Measurements...", "mean centroid fit redirect=None decimal=9");
	
	//Measure stack max and search for spheres if the max is > 0 (i.e. there are spheres in the stack)
	for(a=1; a<=nSlices; a++){
		setSlice(a);
		getStatistics(dummy, dummy, dummy, stackMax);
		if(stackMax > 0){
			a = nSlices+1;
		}
	}

	//Initialize the sphere counter variable
	sphereCounter = 0;
	
	while(stackMax>0){
		//Search from the top of the stack down, looking for the top of a sphere
		for(a=nSlices; a>0; a--){
			setSlice(a);
			getStatistics(dummy, dummy, dummy, sliceMax);
			//If a top is found, find it's centroid and intensity (ID)
			if(sliceMax>0){
				setThreshold(sliceMax, sliceMax);
				run("Create Selection");
				run("Measure");
				run("Select None");
				
				//Record the centoid, ID, and cap
				xCen = getResult("X", nResults-1);
				yCen = getResult("Y", nResults-1);
				sphereTop = a;
			
				//Stop search and delete results
				a = 0;
				IJ.deleteRows(0, 0);
				resetThreshold();
			}
		}
		
		//Search for the bottom of the sphere
		for(a=sphereTop-1; a>0; a--){
			setSlice(a);
			pixelInt = getPixel(round(xCen), round(yCen));
			if(pixelInt != sliceMax){
				sphereBottom = a+1;
				a = 0;
			}
		}
	
		//Calculate the sphere Z-radius and Z-centroid
		zRadius = (sphereTop-sphereBottom)/2;
		zCen = sphereBottom + zRadius;
	
		//Measure the XY radius of the sphere
		setSlice(round(zCen));
		setThreshold(sliceMax, sliceMax);
		run("Create Selection");
		run("Measure");
		run("Select None");
		xyRadius = getResult("Major",0)/2;
	
		//Delete measurement
		IJ.deleteRows(0, 0);
		
		//Remove the measure sphere from the image
		makeOval(round(xCen-1.1*xyRadius), round(yCen-1.1*xyRadius), round(2.2*xyRadius), round(2.2*xyRadius));
		run("Macro...", "code=[if (v == " + sliceMax + ") v = 0;] stack");
		run("Select None");
	


		//Export the results to the result matrix
		selectWindow(resultMatrix);
		setSlice(fileNumber);
		setPixel(0, sphereCounter, sliceMax);
		setPixel(1, sphereCounter, xCen);
		setPixel(2, sphereCounter, yCen);
		setPixel(3, sphereCounter, zCen);
		setPixel(4, sphereCounter, xyRadius);
		setPixel(5, sphereCounter, zRadius);
		setPixel(6, sphereCounter, stackWidth);
		setPixel(7, sphereCounter, stackHeight);
		setPixel(8, sphereCounter, stackSlices);

		//Increment the sphere counter
		sphereCounter = sphereCounter + 1;

		selectWindow(labelStack);

		//Check to see if there are any more labels remaining
		for(a=1; a<=nSlices; a++){
			setSlice(a);
			getStatistics(dummy, dummy, dummy, stackMax);
			if(stackMax > 0){
				a = nSlices+1;
			}
		}
	}	
}