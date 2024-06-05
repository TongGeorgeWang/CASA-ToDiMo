# CASA-ToDiMo

![CASAToDiMo_logo](https://github.com/TongGeorgeWang/CASA-ToDiMo/assets/160785251/faec1464-9021-42ef-bdf3-c71954510e9a)

**Class Averaging via Spectral Analysis of Totally Disordered Macromolecules (CASA ToDiMo)** <br />
Finding disordered macromolecules a home in a crowded, chaotic metropolis. <br /> 
Casa (Spanish - "House/Home/Dwelling") | Todimo (Greek - "Township") <br />

Class averaging is a technique originally implemented for single-particle cryo electron microscopy (EM) image processing, wherein 2D EM images of a macromolecule in different orientations are aligned and separated into categories (classes) based on visual similarity. Images are subseqently averaged within the classes to reconstruct a high resolution model of the macromolecule, commonly to high spatial resolution. Cryo-EM class averaging has usually been applied on proteins that are highly structured or that have short, flexible subregions. CASA-ToDiMo utilizes spectral clustering, a large-dataset reduction technique rooted in graph theory, to class average macromolecules in 3D space. While it works with structured or partially structured macromolecules, it thrives on disordered biopolymers with zero secondary or tertiary structure, which are represented with a broad conformational ensemble. <br />

**Overview**
The program first performs a spatial alignment of all pairs of structures in the ensemble by minimizing the root mean square deviation (RMSD). The pairwise minimum RMSD values that result from this alignment are then tabulated into a matrix. An RMSD threshold is set in this matrix wherein pairs of structures with an RMSD value below this threshold are considered "connected". The thresholded pairwise RMSD matrix is effectively binarized, and serves as an adjacency matrix with which we may construct a network graph where nodes represent structures in the ensemble and edges are present between two connected structures. The graph is then spectrally clustered following the algorighm of Ng, Jordan, Weiss (NIPS, 2001) to identify unique classes of conformations. The macromolecule backbone is then coarse grained at each monomer (ie for proteins, the position of each alpha carbon is sampled; for RNA, the position of each backbone phosphorus is sampled). Coarse grained conformers within each class are then averaged at every monomer position to generate a characteristic conformer of that class. The variance in this averaging is taken as a metric of variability at every monomer position. <br />
A visual schematic of the method: 

![CASAToDiMo_schematic](https://github.com/TongGeorgeWang/CASA-ToDiMo/assets/160785251/71a9ce14-055d-4be5-8006-1d897ac6fef4)


**Installation and use** <br />
This program requires MATLAB (Mathworks), with the Bioinformatics package. It is probably safest to upgrade to the most recent version if possible but it should work with v2019 and above. The program is run in the MATLAB user interface and does not require a terminal. An example conformational ensemble of a mixed sequence single-stranded RNA is provided. 
The source code may be downloaded/cloned from the current repository. The general input for the program is a folder, within the source code directory, containing a set of structures in PDB format. 
Open "classAveragingDisordered.m" in MATLAB - this is the only script that needs to be interacted with. 
In the first lines of the script after the initial documentation notes there is a set of modifiable input parameters that should be considered and changed accordingly before running the program: 

folderName: This is the name of the folder within the source code directory that contains the PDBs that make up the conformational ensemble to be processed.  
rmsdThreshold: Threshold RMSD value (in Angstroms) for two macromolecules to be considered "connected"; set=0 for program to determine this value for you via optimization of a graph "Okayness" metric. It is often good to run first with this set=0 to find a ballpark rmsdThreshold value and tweak it from there. 
nKmeans: Number of clusters to use for final K-means on the node/edge graph; set to 0 and the program will do a search between nKmeans=2-20 and choose nKmeans that maximizes the average silhouette
species: Either 'RNA', 'protein', 'PAR' (poly(ADP-ribose)), or 'CG' (already coarse grained from previous program)
spatialVarUpperLim: How high to set the colorbar when visualizing the classed averaged conformers (just a visual thing); 100 by default
PARtrueOrder: Only need to consider this if species='PAR', elsewise this variable does not matter. Sometimes in PAR PDBs the order of the subunits gets scrambled and you need to manually look in the pdb and enter correct subunit order.
rmsdThresholdSearchRange = (1:0.1:20): The range of RMSD values that will be tried if rmsdThreshold=0 (in Anstroms); this does not usually need to be changed unless you fail to find an optimal value during the optimization

Once you are satisfied with these input variables, RUN the "classAveragingDisordered.m" script (hit the play button at the top or press F5). 
The bulk of the computational time is spent aligning every pair of PDB structures and calculating RMSDs. The computation scales as the number of structures squared - an ensemble of 100 structures (a common magnitude for the size of a disordered macromolecular ensemble) typically takes 20 minutes to perform this calculation - 50 structures, for example, would thus take around 5 minutes and 500 structures around 8 hours. This is all by using a single CPU, which by default is whaT MATLAB will utilize, but if you know how to parallelize (for instance with the Parallel Computing Toolbox) then this calculation can be made much faster. 

All results will be saved in a subfolder called 'outputs'

**Example results**
Example of the first window, Figure 1, which is saved as 'SpectralAnalysis.png':
![FirstPass_SpectralAnalysis](https://github.com/TongGeorgeWang/CASA-ToDiMo/assets/160785251/16bf95e3-0e14-4f89-8704-b81a1a5d1bb4)

Description of plots that are output in Figure 1, going left to right starting with the top left: 
1) 
2) 
3) The spectral clustering result (K-means clustered graph) 
4) Heatmap showing pairwise RMSD matrix 
5) Binary pairwise RMSD matrix (used as an adjacency matrix to compute the graph)
6) (this serves as a relative metrix for the configurational entropy of the structural ensemble)
7) Graph colored by closeness centrality
8) Graph colored by degree centrality
       
NOTE: If rmsdThreshold =/= 0 and instead is set manually, plots 1) and 2) will not be output and there will be 6 plots instead of 8. 

At this point the program will pause (in the MATLAB Command Window) and allow you to assess the results. Generally, make sure that the graph (plot 3) looks reasonable and is not too disconnected or connected: 
![GraphOkayness](https://github.com/TongGeorgeWang/CASA-ToDiMo/assets/160785251/d169f4c0-f7af-465c-b9d9-4e7001f72394)

Also check if the proper number of K-means clusters is defined - for example if there are clusters that seem to have too many points, you can increase nKmeans.

In the first pass (shown above), I let the program try and optimize rmsdThreshold and nKmeans - it output rmsdThreshold=6.2 and nKmeans=2. The graph was not ideal so I elected to redo the analysis, typing 0. I saw that there was a stray node in the graph that was disconnected from everything else, so I increased the rmsdThreshold to 7. I also saw that 2 K-means clusters seemed too little to represent the graph, so I increased this to 4. I then ran the "classAveragingDisordered.m" script again, and this was the second pass output: 

![SecondPass_SpectralAnalysis](https://github.com/TongGeorgeWang/CASA-ToDiMo/assets/160785251/23beaf79-0988-480a-b4d7-eb48cde355ad)


The graph looks more reasonable now, so I entered '1' to advance the program to the next step, where the program accepts the spectral clustering result shown in Figure 1, saves the clustering information, and goes on to group the PDBs into separate subfolders corresponding to each identified cluster. For each of these clusters, the program then coarse grains the backbone and computes an average conformation. The outputs that are saved are:
![ClassAveragedEnsemble_example](https://github.com/TongGeorgeWang/CASA-ToDiMo/assets/160785251/8e2068c1-4370-496f-9e8a-3ab7b03fd0c5)

- Figure 2, which contains the resulting graph from Figure 1 along with the averaged conformation of each cluster, with titles colored according to their position in the spectrally clustered graph. This is saved as 'ClassAveragedEnsemble.fig', and you can use the MATLAB plot tools to rotate the models around, zoom in/out, etc.
- A model for each individual cluster is also saved in 'outputs/models'. These are saved as MATLAB .fig files and also contain each individual conformation in the cluster plotted in semi-transparent gray so a visual assessment of similarity within the cluster of structures can be made.
- A log.txt file containing information of the run. 

