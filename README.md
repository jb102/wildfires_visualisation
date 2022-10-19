# wildfires_visualisation
Visualisation of geographic coordinates of wildfires in Australia in 2019 and 2020

# Explanation
The visualisation produced in this project, created using R and shown in the file Rplot07.png, attempts to convey the scale of fires in the 2019-2020 Australian bushfire season via comparison with the land area of other countries. This is achieved by displaying a blown up version of certain sections of the map outside of the main map plot, adjacent to countries which have a similar land area. The sections of the Australian map chosen for comparison correspond to areas which saw a high concentration of fire in NASA’s MODIS Thermal Anomalies data, which is contained in the file fire_nrt_M6_96062.csv.

Large sections of land where fire is concentrated are identified by choosing a group of hotspots and taking their convex hull to calculate the
coordinates of the smallest polygon which contains all of the hotspots. The density of fire is then calculated as the number of hotspots divided by the geographical area of the polygon in kilometres squared. It is not practical to measure this for every subset of the hotspots to find the most relevant ones, so for this project cluster analysis was used as a heuristic to find highly concentrated groups of hotspots.
K-means clustering was performed on the data using every degree of partitioning from 2 to 25.
To prevent the formation of clusters which include hotspots in both the Australian mainland and in
Tasmania and therefore stretch over the sea, hotspots in Tasmania were excluded from the input for
the clustering (but still displayed in the final visualisation). This was done by filtering out hotspots
with a latitude of < −39. The partitionings are not important so much as the individual clusters
themselves, regardless of which partitioning they are from, so every cluster from every partitioning
was ordered together by its density, with overlapping clusters removed (denser ones being kept).

The decision of which clusters to include in the visualisation was decided (arbitrarily) with three main objectives
in mind:
1. To convey how ubiquitous the fires are in high-concentration areas.
2. To convey the pervasiveness of the fires across the country as a whole.
3. To promote a good understanding of the geographical scale of areas with high densities of fire.

Based on these objectives, four clusters were chosen for inclusion, which were the first, sixth,
eleventh and twelfth densest (referred to as clusters 1, 6, 11 and 12 respectively). For each cluster,
the hotspots are displayed in a different colour (red) to hotspots in the rest of the map (orange) and a
black outline is drawn around its convex hull. These two measures are intended to make the clusters
easy to see.

Each of these clusters is shown in a blown up form next to the main map of Australia, with an
arrow pointing from the cluster on the map to its blown up version to avoid ambiguity. The hotspots
are repeated in the blown up version to give a better view of their distribution in the cluster, and
the density is displayed next to the cluster as “% covered in fire”, which helps achieve objective 1.
On the right of the cluster, a map of a country with a similar geographic size to it is shown at the
same scale, and the area in km^2
is given for both. This is an application of the visualisation principle
of juxtaposition which utilises the natural ability to see pattern in repeated objects, which was
deemed an effective supplement to giving the land area of the cluster, and helps to achieve objective
3.

The densest cluster shown, cluster 1, is the smallest, covering 8,021km^2 with 65.7% covered in fire
and is compared to Puerto Rico for reference. This helps to achieve objective 1 by evoking the scenario
of Puerto Rico experiencing this amount of fire, which is more intuitive and meaningful to conceive
of than an unmarked patch of land in Australia. Clusters 11 and 12 (South Korea and Greece) were
chosen to balance this out with the other objectives, as they are both far away from cluster 1 as well as
being remote from each other, which helps to achieve objective 2, and are both significantly larger than
cluster 1. The variation in geographic size between the clusters allows comparison to countries which
differ in size, helping to achieve objective 3 by providing a variety of frames of reference. Cluster 6
(Belgium) was chosen as an intermediate between these two opposites, with both a size and fire density
that is somewhere between the others, which supplements all of the objectives.
