tsvPath = params.input

inputChan = Channel.empty()
tsvFile = file(tsvPath)
inputChan = extractFastq(tsvFile)

process KRAKEN{

	publishDir "${launchDir}/results/", mode: 'copy'
	
	memory 256.GB
		
	input:
	tuple val(idPatient), val(gender), val(status), val(idSample), val(idRun), val(file1)
	
	output:
	path "*"

	script:
	db=params.database
	
	"""
	kraken2 --db $db --output ${idPatient}.out $file1	
	"""

}


workflow {

	KRAKEN(inputChan)

}


/// Define input file in format: "subject gender status sample lane fastq1 fastq2"
def returnStatus(it) {
    if (!(it in [0, 1])) exit 1, "Status is not recognized in TSV file: ${it}, see --help for more information"
    return it
}

def returnFile(it) {
    if (!file(it).exists()) exit 1, "Missing file in TSV file: ${it}, see --help for more information"
    return file(it)
}

def extractFastq(tsvFile) {
    Channel.from(tsvFile)
        .splitCsv(sep: '\t')
        .map { row ->
            def idPatient  = row[0]
            def gender     = row[1]
            def status     = returnStatus(row[2].toInteger())
            def idSample   = row[3]
            def idRun      = row[4]
            def file1      = returnFile(row[5])

            [idPatient, gender, status, idSample, idRun, file1]
        }
}
