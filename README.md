# CASA-ToDiMo

**Class Averaging via Spectral Analysis of Totally Disordered Macromolecules (CASA ToDiMo)** <br />
Finding disordered macromolecules a home in a chaotic metropolis. <br /> 
Casa (Spanish - "House/Home/Dwelling") | Todimo (Greek - "Township") <br />

Class averaging is a technique originally implemented for single-particle cryo electron microscopy image processing, where 2D images of a macromolecule in different orientations are aligned and separated into categories (classes) based on visual similarity. Images are subseqently averaged within the classes to reconstruct a high resolution model of the macromolecule, commonly to high spatial resolution. However, cryo-EM class averaging has usually been applied on proteins that are highly structured or that have short, flexible regions. This method utilizes spectral clustering, a large-dataset reduction technique rooted in graph theory, to class average macromolecules in 3D space. While it works with structured or partially structured macromolecules, it thrives on disordered biopolymers with zero secondary or tertiary structure, which are represented with a broad conformational ensemble. <br />

![CASAToDiMo_schematic](https://github.com/TongGeorgeWang/CASA-ToDiMo/assets/160785251/71a9ce14-055d-4be5-8006-1d897ac6fef4)


**Installation and use** <br />
This program requires MATLAB v2019 or later, with the Bioinformatics package. 
