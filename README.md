# Class Averaging via Spectral Analysis of Totally Disordered Macromolecules (CASA ToDiMo)

![CASAToDiMo_logo](https://github.com/TongGeorgeWang/CASA-ToDiMo/assets/160785251/faec1464-9021-42ef-bdf3-c71954510e9a)

Finding disordered macromolecules a home in a crowded, chaotic metropolis. <br /> 
Casa (Spanish - "House/Home/Dwelling") | Todimo (Greek, transliterated - "The Township/Municipality") <br />

If you use this code please cite: <br />
**Tong Wang, Kush Coshic, Mohsen Badiee, Maranda R. McDonald, Aleksei Aksimentiev, Lois Pollack, Anthony K. L. Leung, Cation-induced intramolecular coil-to-globule transition in poly(ADP-ribose). Nat Comm, 15(7901), 2024.** <br />
https://www.nature.com/articles/s41467-024-51972-9 <br />

**Background and applications** <br />
Class averaging is a technique originally implemented for single-particle cryo electron microscopy (EM) image processing, wherein 2D EM images of a macromolecule in different orientations are aligned and separated into categories (classes) based on visual similarity. Images are subseqently averaged within the classes to reconstruct a model of the macromolecule, commonly to high spatial resolution. Cryo-EM class averaging has usually been applied on proteins that are highly structured or that have short, flexible subregions. CASA-ToDiMo utilizes spectral clustering, a large-dataset reduction technique rooted in graph theory, to class average macromolecules in 3D space. While it works with structured or partially structured macromolecules, it thrives on disordered biopolymers with zero secondary or tertiary structure, which are represented with a broad conformational ensemble. The program can work with a pool of nucleic acid, protein, or coarse-grained bead structures in PDB format. <br />

**Overview** <br />
The program first performs a spatial alignment of all pairs of structures in the ensemble by minimizing the root mean square deviation (RMSD). The pairwise minimum RMSD values that result from this alignment are then tabulated into a matrix. An RMSD threshold is set in this matrix wherein pairs of structures with an RMSD value below this threshold are considered "connected". The thresholded pairwise RMSD matrix is effectively binarized, and serves as an adjacency matrix with which we may construct a network graph where nodes represent structures in the ensemble and edges are present between two connected structures. The graph is then spectrally clustered following the algorighm of Ng, Jordan, Weiss (NIPS, 2001) to identify unique classes of conformations. The macromolecule backbone is then coarse grained at each monomer (ie for proteins, the position of each alpha carbon is sampled; for RNA, the position of each backbone phosphorus is sampled). Coarse grained conformers within each class are then averaged at every monomer position to generate a characteristic conformer of that class. The variance in this averaging is taken as a metric of variability at every monomer position. <br />
A visual schematic of the method: 

![Box1](https://github.com/user-attachments/assets/0d409b59-fb0f-4751-99be-ff3c6c678167)



**Installation** <br />
This program requires MATLAB (Mathworks) v2023 or above, with the Bioinformatics toolbox and Statistics & Machine Learning toolbox. If the Parallel Computing Toolbox is also installed, the runtime will decrease. The program is run in the MATLAB user interface. An example conformational ensemble of a mixed sequence single-stranded RNA is provided. 
The source code may be downloaded/cloned from the current repository. The general input for the program is a folder, within the source code directory, containing a set of structures in PDB format. 
Open "classAveragingDisordered.m" in MATLAB - this is the only script that needs to be interacted with. <br />


**Please see the 'DetailedInstructions' file for information on how to run the program.**
