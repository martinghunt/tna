func to_fasta(infile, outprefix):
	var stderr = []
	var mingap = Globals.userdata.config.get_value("other", "min_gap_length")
	var exit_code = OS.execute(Globals.userdata.zlhelper, ["import_seqfile", "-g", mingap, "-i", infile, "-o", outprefix], stderr, true)
	if exit_code != 0:
		print("Error importing sequence file: ", infile)
		print(stderr)
	return exit_code


func download_genome(accession, outprefix):
	var stderr = []
	var exit_code = OS.execute(Globals.userdata.zlhelper, ["download_genome", "-a", accession, "-o", outprefix], stderr, true)
	if exit_code != 0:
		print("Error downloading sequence file: ", accession)
		print(stderr)
	return exit_code


func load_fasta_file(filename):
	print("Loading fasta file: ", filename)
	var file = FileAccess.open(filename, FileAccess.READ)
	var lines = file.get_as_text().rstrip("\n").split("\n")
	var contigs = {"order": [], "contigs": []}

	for line in lines:
		if line[0] == ">":
			var fields = line.trim_prefix(">").split(" ", false, 1)
			contigs["order"].append(len(contigs["order"]))
			var descr
			if len(fields) > 1:
				descr = fields[1]
			else:
				descr = ""
			contigs["contigs"].append({"name": fields[0], "descr": descr})
		else:
			contigs["contigs"][-1]["seq"] = line
	print("Loaded fasta file ok: ", filename)
	return contigs


func revcomp(seq_in):
	var seq_out = Array([], TYPE_STRING, "", null)
	seq_out.resize(len(seq_in))
	for i in range(0, len(seq_in)):
		seq_out[i] = Globals.complement_dict.get(seq_in[-i-1], "N")
	return "".join(seq_out)


func search_one_strand(search_term, refseq):
	var hits = []
	var i = refseq.findn(search_term)
	while i != -1 and len(hits) < Globals.max_search_results:
		hits.append(i)
		if i != -1:
			i = refseq.findn(search_term, i+1)
	return hits


func search_for_seq(search_term, refseq):
	var new_hits = search_one_strand(search_term, refseq)
	var hits = []
	for x in new_hits:
		hits.append([x, false])
	if len(hits) >= Globals.max_search_results:
		hits.sort()
		return hits

	search_term = revcomp(search_term)
	new_hits = search_one_strand(search_term, refseq)
	for x in new_hits:
		hits.append([x, true])
		if len(hits) >= Globals.max_search_results:
			break

	hits.sort()
	return hits
