// ======================= USER SETTINGS =======================
inputDir    = getDirectory("Choose a Main Directory ");   // folder with 2D, 2-channel composite images
outCSVsum   = inputDir + "line_coloc_summary.csv";        // per-image summary (one row per image)
outCSVroi   = inputDir + "line_coloc_measurements.csv";   // per-ROI table (everything in Results)
saveROIs    = true;                                       // save REGION_# and BG_# lines per image
roiOutDir   = inputDir + "ROIs/";
rolling_bg  = 0;                                          // 0=skip; else rolling-ball radius (px), e.g., 40–80
lineWidthPx = getNumber("Enter LINE WIDTH (px) to use for all lines (e.g., 3–5):", 3);
// ============================================================

// ----------------------- Helpers ----------------------------
function ensureDir(path){ if (!File.exists(path)) File.makeDirectory(path); }

// use local loop var to avoid collisions with globals
function arrMean(a){
  if (a.length==0) return NaN;
  s = 0;
  for (jj=0; jj<a.length; jj++) s += a[jj];
  return s / a.length;
}

function addCurrentRoiAndGetIndex(name){
  if (selectionType()==-1) exit("No ROI selected.");
  pre = roiManager("count");
  roiManager("Add");
  idx = pre; roiManager("Deselect"); roiManager("Select", idx);
  if (name!="") roiManager("Rename", name);
  return idx;
}

function meanOnChannel(channel){
  Stack.setDisplayMode("composite");
  if (channel==1) Stack.setActiveChannels("10"); else Stack.setActiveChannels("01");
  Stack.setChannel(channel);
  getRawStatistics(nPixels, mean, min, max, std);
  return newArray(1.0*mean, 1.0*nPixels);  // [mean, nPixels]
}

function showComposite(){ Stack.setDisplayMode("composite"); Stack.setActiveChannels("11"); }
function log10v(x){ return log(x)/log(10.0); } // ImageJ macro has log(), not log10()

// ---- SUMMARY: read rows for THIS image from Results (use getResult for strings & numbers) ----
function summarizeCurrentImageByTitle(imgTitle, outPath){
  bg1 = newArray(); bg2 = newArray();
  reg1 = newArray(); reg2 = newArray();
  geno = "";

  for (rr=0; rr<nResults; rr++){
    f = getResult("File", rr);       // string ok
    if (f!=imgTitle) continue;
    typ  = getResult("ROI_Type", rr);   // string ok
    if (geno=="") geno = getResult("Genotype", rr);

    m1 = getResult("MeanCh1", rr);
    m2 = getResult("MeanCh2", rr);

    if (typ=="background"){
      bg1 = Array.concat(bg1, newArray(m1));
      bg2 = Array.concat(bg2, newArray(m2));
    } else if (typ=="region"){
      reg1 = Array.concat(reg1, newArray(m1));
      reg2 = Array.concat(reg2, newArray(m2));
    }
  }

  n_regions = reg1.length;
  if (n_regions==0 || bg1.length==0 || bg2.length==0) return;

  bgCh1_mean = arrMean(bg1);
  bgCh2_mean = arrMean(bg2);

  ratios = newArray(); logs = newArray(); ndis = newArray();
  m1cs = newArray(); m2cs = newArray();

  for (kk=0; kk<n_regions; kk++){
    m1c = reg1[kk] - bgCh1_mean; if (m1c<0) m1c=0;
    m2c = reg2[kk] - bgCh2_mean; if (m2c<0) m2c=0;

    ratio = (m1c + 1.0) / (m2c + 1.0);
    logR  = log10v(ratio);
    ndi   = (m1c - m2c) / (m1c + m2c + 1.0);

    ratios = Array.concat(ratios, newArray(ratio));
    logs   = Array.concat(logs,   newArray(logR));
    ndis   = Array.concat(ndis,   newArray(ndi));
    m1cs   = Array.concat(m1cs,   newArray(m1c));
    m2cs   = Array.concat(m2cs,   newArray(m2c));
  }

  avg_ratio       = arrMean(ratios);
  avg_log10_ratio = arrMean(logs);
  avg_NDI         = arrMean(ndis);
  avg_m1c         = arrMean(m1cs);
  avg_m2c         = arrMean(m2cs);

  File.append(
    imgTitle+","+geno+","+n_regions+","+
    bgCh1_mean+","+bgCh2_mean+","+
    avg_m1c+","+avg_m2c+","+
    avg_ratio+","+avg_log10_ratio+","+avg_NDI+"\n",
    outPath
  );
}
// ------------------------------------------------------------

ensureDir(inputDir);
if (saveROIs) ensureDir(roiOutDir);
setLineWidth(lineWidthPx);

// Prepare Results table (per-ROI) — will be saved to outCSVroi
if (isOpen("Results")) { selectWindow("Results"); run("Clear Results"); }
else { run("Results..."); run("Clear Results"); }

// Prepare SUMMARY CSV (per-image)
File.saveString(
  "file,genotype,n_regions,"+
  "bgCh1_mean,bgCh2_mean,"+
  "avg_meanCh1_corr,avg_meanCh2_corr,"+
  "avg_ratio,avg_log10_ratio,avg_NDI\n",
  outCSVsum
);

// ====== INTERACTIVE MEASUREMENT ======
files = getFileList(inputDir);
setBatchMode(false);

for (ii=0; ii<files.length; ii++){
  name = files[ii];
  if (!(endsWith(name,".tif")||endsWith(name,".tiff")||endsWith(name,".czi")||endsWith(name,".nd2"))) continue;

  open(inputDir + name);
  title = getTitle();

  // Must be 2D, 2-channel
  getDimensions(w,h,c,z,t);
  if (z>1 || t>1) { showMessage("Not 2D", name+"\nHas z="+z+" t="+t); close("*"); continue; }
  if (c!=2) { showMessage("Channels", name+"\nExpected 2 channels, found c="+c); close("*"); continue; }

  if (rolling_bg>0) run("Subtract Background...", "rolling="+rolling_bg);

  showComposite(); Stack.setChannel(1);
  genotype = getString("Genotype for this image (wt / het / hom, or leave blank):", "");

  // ---- REGION lines ----
  roiManager("reset");
  lineCount = 0;
  while (true){
    waitForUser("Draw a REGION line (segmented allowed), then click OK.\nCancel = skip this image.");
    if (selectionType()==-1){
      retry = getBoolean("No ROI detected. Try again? (OK=Yes, Cancel=Skip image)");
      if (retry) continue;
      close("*"); break;
    }

    idx = addCurrentRoiAndGetIndex("REGION_"+(lineCount+1));
    lineCount++;

    r1 = meanOnChannel(1);   // [mean, nPixels]
    r2 = meanOnChannel(2);

    // Write to Results (per-ROI)
    row = nResults;
    setResult("File",     row, title);
    setResult("Genotype", row, genotype);
    setResult("ROI_Type", row, "region");
    setResult("ROI_ID",   row, lineCount);
    setResult("nPixels",  row, r1[1]);
    setResult("MeanCh1",  row, r1[0]);
    setResult("MeanCh2",  row, r2[0]);
    updateResults();

    showComposite();

    more = getBoolean("Add another REGION line? (OK=Yes, Cancel=No)");
    if (!more) break;
  }

  if (lineCount==0){
    cont = getBoolean("No regions recorded. Next image? (OK=Next, Cancel=Quit)");
    close("*");
    if (cont) continue; else break;
  }

  // ---- BACKGROUND lines (single dialog per BG) ----
  bgCount = 0;
  while (true){
    waitForUser("BACKGROUND:\n- Draw a BG line in a dark area, then click OK to record it.\n- To proceed, click OK with NO selection.\n- Cancel aborts macro.");
    if (selectionType()==-1){
      break; // proceed
    }

    idxbg = addCurrentRoiAndGetIndex("BG_"+(bgCount+1));
    b1 = meanOnChannel(1);
    b2 = meanOnChannel(2);
    bgCount++;

    // Write BG to Results
    row = nResults;
    setResult("File",     row, title);
    setResult("Genotype", row, genotype);
    setResult("ROI_Type", row, "background");
    setResult("ROI_ID",   row, bgCount);
    setResult("nPixels",  row, b1[1]);
    setResult("MeanCh1",  row, b1[0]);
    setResult("MeanCh2",  row, b2[0]);
    updateResults();

    showComposite();
  }

  // === Create one summary row for THIS image by reading back from Results ===
  summarizeCurrentImageByTitle(title, outCSVsum);

  // Save ROIs for this image
  if (saveROIs){
    roiZip = roiOutDir + replace(title, ".tif", "") + "_regions_bg.zip";
    roiManager("Deselect"); roiManager("Save", roiZip);
  }

  nxt = getBoolean("Image done: "+title+"\nProceed to NEXT image? (OK=Next, Cancel=Quit)");
  close("*");
  if (!nxt) break;
}

// Save the entire Results table (all images) to the per-ROI CSV
if (!isOpen("Results")) run("Results...");
selectWindow("Results");
saveAs("Results", outCSVroi);

showMessage("All images analysed",
  "Per-image summary:\n"+outCSVsum+
  "\n\nPer-ROI measurements (Results):\n"+outCSVroi+
  "\n\nROIs (if enabled):\n"+roiOutDir);
