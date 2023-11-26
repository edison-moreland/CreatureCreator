# Creature Creator Implicit Sampler

This is the heart of the project, a particle based implicit surface sampler which allows rendering complex moving implicit surfaces in real time.
A particle system was chosen over ray marching because it's cool.

## Citations
This wouldn't be possible without two very helpful papers.


This first paper describes a fast geometric approach to taking a rough sample of an implicit surface, similar to Delauany triangle.

    Floriant Levet, Xavier Granier, Christophe Schlick. Fast sampling of implicit surfaces by particle systems.
    SMI ’06: Proceedings of the IEEE International Conference on Shape Modeling and Applications
    2006, Jun 2006, Matsushima, Japan. pp.39, 10.1109/SMI.2006.13 . inria-00106853v1


The second paper describes a particle system that's used to refine the rough sample into an even distribution, and keep them on the surface as it moves.

    Using Particles to Sample and Control Implicit Surfaces.
    Andrew P. Witkin, Paul S. Heckbert
    https://dl.acm.org/doi/pdf/10.1145/192161.192227