/*:
 # Black holes in general relativity

 In this playground book you’ll explore the physics of [black holes](https://en.wikipedia.org/wiki/Black_hole) in Albert Einstein's [theory of general relativity](https://en.wikipedia.org/wiki/General_relativity).

 > Every page has an _Explore_ section that helps you discover three fascinating phenomena of black holes in interactive simulations: **trajectories around black holes**, [**light deflection**](02) and [**gravitational waves**](03).

 A **[black hole](https://en.wikipedia.org/wiki/Black_hole)** is an astrophysical object that forms when gravity overwhelms massive stars at the end of their lifetime.

 - More information: [Formation of black holes](glossary://formation)

 Black holes have the extraordinary and defining property that neither particles nor light will ever escape it after they have crossed the black hole's [_Schwarzschild radius_](https://en.wikipedia.org/wiki/Schwarzschild_radius), hence they appear black. This close to the black hole, gravity is strong enough that an escape from its pull would require velocities larger than the speed of light, but superluminal velocities are out of reach with finite energy by the relativity principle.

 - More information: [Schwarzschild radius](glossary://schwarzschild_radius)

 ## 1  Trajectories and orbits

 The gravitational pull of a black hole is no different to that of any other spherically symmetric object such as a star or a planet. Their dynamics are determined by the [Schwarzschild solution](https://en.wikipedia.org/wiki/Schwarzschild_metric) of Albert Einstein's [gravitational field equations](https://en.wikipedia.org/wiki/Einstein_field_equations). The massive black hole, star or planet in the center warps spacetime in its vicinity so that straight lines through spacetime appear curved for a distant observer. Objects in free fall follow trajectories along such straight lines called _geodesics_.

 - callout(Explore): You can observe the possible trajectories of test particles around a spherically symmetric source in this simulation. The test particles may be planets and the source a black hole, where its size depicts the Schwarzschild horizon. The white particle traces the general relativistic geodesic and the yellow particle traces the corresponding trajectory in classical Newtonian gravity.

    Slide horizontally to adjust the angular momentum of the test particles, and vertically to adjust their energy. Observe how Newtonian gravity is a good approximation at large distances but deviates strongly at smaller distances. Try to change the parameters of the test particles to produce the following types of trajectories:

    - **Orbit**: The particle's angular momentum compensates the black hole's gravitational pull so that it moves on a bound orbit. Increasing the particle's energy makes the orbit elliptic. Note how the elliptic orbit slowly precesses around the source (white trace), but remains static in Newtonian gravity (yellow trace). This _perihelion shift_ has been measured for the planet Mercury for a long time, but astronomers were unable to explain it. When Einstein calculated this very effect in 1915, it was the first observational evidence for his theory of general relativity.

        ![Orbit](orbit.jpg)

    - **Fly-by**: With enough energy the particle will escape the gravitational pull of the source. It will pass by the source on a hyperbolic trajectory.

        ![Fly-by](flyby.jpg)

    - **Fall-in**: Increasing the energy further makes the particle approach the source closer. Since the gravitational pull in general relativity increases strongly at small distances to the source, at some point it will overcome the repelling effect of the particle's angular momentum. The particle will begin to fall into the black hole and, once it has passed its Schwarzschild horizon, never escape it.

        ![Fall-in](fallin.jpg)

    - **Catch**: At a specific energy between a fly-by and a fall-in the gravitational pull just compensates the angular momentum again. This makes another orbit very close to the black hole possible that does not exist in Newtonian gravity. This orbit is unstable, however, so any minor deviation from the orbit energy makes the particle either escape to infinity or fall into the black hole.

        ![Catch](catch.jpg)

 [Next, explore light deflection by a black hole >>](@next)

 ## References

 - B. Schutz, A First Course in General Relativity, Second Edition (2009)
 - Background image: default Mac OS X wallpaper "Milky Way"
*/
