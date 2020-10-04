"""
Example which simulates a simple DAGMC neutronics model using OpenMC
"""
import os

import openmc

class MinimalSimulation:
    """This is a minimal class that has a few tiny methods to demonstrate testing
    """

    def __init__(self):
        pass

    def simulate(self):
        """this runs a simple tbr simulation using openmc and returns the
        tritium breeding ratio"""

        universe = openmc.Universe()
        geom = openmc.Geometry(universe)

        breeder_material = openmc.Material(name="blanket_material")  # Pb84.2Li15.8
        breeder_material.add_element('Pb', 84.2, percent_type='ao')
        breeder_material.add_element('Li', 15.8, percent_type='ao', enrichment=50.0, enrichment_target='Li6', enrichment_type='ao')  # 50% enriched
        breeder_material.set_density('atom/b-cm', 3.2720171e-2)  # around 11 g/cm3

        magnet_material = openmc.Material(name="pf_coil_material")  # Pb84.2Li15.8
        magnet_material.add_element('Cu', 1, percent_type='ao')
        magnet_material.set_density('g/cm3', 8.96)  # around 11 g/cm3

        mats = openmc.Materials([breeder_material, magnet_material])

        settings = openmc.Settings()
        settings.batches = 10
        settings.inactive = 0
        settings.particles = 100
        settings.run_mode = "fixed source"
        settings.dagmc = True

        source = openmc.Source()
        source.space = openmc.stats.Point((0, 0, 0))
        source.angle = openmc.stats.Isotropic()
        source.energy = openmc.stats.Discrete([14e6], [1])
        settings.source = source

        tallies = openmc.Tallies()
        tbr_tally = openmc.Tally(name="TBR")
        tbr_tally.scores = ["(n,Xt)"]  # where X is a wild card
        tallies.append(tbr_tally)

        model = openmc.model.Model(geom, mats, settings, tallies)

        output_filename = model.run()

        # open the results file
        sp = openmc.StatePoint(output_filename)

        # access the tally using pandas dataframes
        tbr_tally = sp.get_tally(name='TBR')
        df = tbr_tally.get_pandas_dataframe()

        tbr_tally_result = df['mean'].sum()

        return tbr_tally_result
