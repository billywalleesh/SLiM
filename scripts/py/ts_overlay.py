import msprime, tskit, pyslim
path = r"C:\Users\WilliamWallisch\msc_workspace\SLiM\data\raw"
processed_path = r"C:\Users\WilliamWallisch\msc_workspace\SLiM\data\processed"

ts = tskit.load(path + r"\overlay.trees").simplify()
ts = pyslim.convert_alleles(pyslim.generate_nucleotides(ts))
mutated = msprime.sim_mutations(ts, rate=1e-7, random_seed=1, keep=True)
mutated.dump(processed_path + r"\final_overlaid.trees")