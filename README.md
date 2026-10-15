# Chako Artefact

This is an artefact for the Chako evaluation of the paper
"Nunchaku: A Modular Higher-Order Model Finder".

## Using the Artefact
After downloading the artefact run
```sh
$ ./run.sh fetch
```
to ensure that all the dependencies are already downloaded at their correct SHA. If a dependency is
not downloaded (which should not be the case) this will also attempt to download it.

Then build the docker image and compile Chako inside of the image using:
```sh
$ ./run.sh image
$ ./run.sh build
```

> [!NOTE]
> The script will attempt to build the docker image with rootless podman if installed. If this is
> not the case you might have to run it with `sudo` to give it access to the Docker daemon.

For a small functionality check you can run
```sh
$ ./run.sh evaluate sound-quick
$ ./run.sh evaluate perf-quick
$ ./run.sh report
```

> [!NOTE]
> You can optionally pass a parallelism level by passing in a `PARALLEL` environment variable like so:
> `$ PARALLEL ./run.sh evaluate sound-quick`. Chako uses up to 4 CPU cores for each parallelism level
> so evaluating at $(nproc)/4 is a good value for stable measurement. If you are running the docker
> via `sudo` keep in mind to pass the variable *after* `sudo`.

This should copy `fin_basic.csv` into `generated/{sound-quick,perf-quick}`. If functioning the
file should look like this for sound:
```csv
theorem,mutant,result,encoding,nunchaku,recovery,cvc5,smbc,kodkod
Fin.neg_def,0,UNSAT,105,69,0,true,true,false
Fin.toNat_eq_val,0,UNSAT,35,59,0,true,true,false
Fin.val_ne_of_ne,0,UNSAT,56,55,0,true,false,false
Fin.Internal.ofNat_eq_ofNat,0,UNSAT,113,82,0,true,true,false
Fin.exists_iff,0,UNKNOWN,37,11030,0,false,false,false
Fin.val_add_one_le_of_gt,0,UNSAT,56,3170,0,true,false,false
Fin.pos,0,UNKNOWN,21,10779,0,false,false,false
Fin.val_congr,0,UNSAT,36,63,0,true,false,false
Fin.val_lt_of_le,0,UNKNOWN,44,11054,0,false,false,false
Fin.val_le_of_le,0,UNKNOWN,24,11089,0,false,false,false
Fin.val_inj,0,UNSAT,56,61,0,true,false,false
Fin.coe_neg,0,UNSAT,104,115,1,true,true,false
Fin.ne_of_val_ne,0,UNSAT,23,58,0,true,false,false
Fin.modn_lt,0,UNKNOWN,180,11087,0,false,false,false
Fin.val_le_of_ge,0,UNSAT,70,1550,2,true,false,false
Fin.zero_eta,0,UNSAT,115,113,0,true,true,false
Fin.val_add_one_le_of_lt,0,UNSAT,69,60,0,true,false,false
```
and like this for perf:
```csv
theorem,mutant,result,encoding,nunchaku,recovery,cvc5,smbc,kodkod
Fin.val_ne_of_ne,0,SAT,31,62,0,true,true,false
Fin.val_ne_of_ne,1,SAT,43,134,0,true,true,false
Fin.val_ne_of_ne,2,SAT,44,135,0,true,true,false
Fin.Internal.ofNat_eq_ofNat,0,SAT,112,61,0,true,true,false
Fin.exists_iff,0,SAT,32,133,1,true,false,false
Fin.val_add_one_le_of_gt,0,SAT,198,73,0,true,true,false
Fin.val_add_one_le_of_gt,1,SAT,282,1397,1,true,true,false
Fin.val_add_one_le_of_gt,2,SAT,205,1879,0,true,true,false
Fin.pos,0,SAT,166,65,0,true,true,false
Fin.val_congr,0,SAT,42,58,0,true,true,false
Fin.val_congr,1,UNSAT,112,62,0,true,true,false
Fin.val_congr,2,UNSAT,43,85,0,true,true,false
Fin.val_lt_of_le,0,SAT,100,67,0,true,true,false
Fin.val_lt_of_le,1,UNSAT,42,85,0,true,false,false
Fin.val_lt_of_le,2,SAT,179,114,0,true,true,false
Fin.val_le_of_le,0,SAT,119,110,0,true,true,false
Fin.val_le_of_le,1,UNSAT,119,72,0,true,true,false
Fin.val_le_of_le,2,UNSAT,136,92,1,true,true,false
Fin.val_inj,0,SAT,43,135,0,true,true,false
Fin.val_inj,1,SAT,42,35,1,true,true,false
Fin.val_inj,2,SAT,94,71,0,true,true,false
Fin.ne_of_val_ne,0,SAT,27,55,0,true,true,false
Fin.ne_of_val_ne,1,SAT,138,150,0,true,true,false
Fin.ne_of_val_ne,2,SAT,81,114,0,true,true,false
Fin.modn_lt,0,SAT,215,114,0,true,true,false
Fin.modn_lt,1,SAT,173,1238,0,true,true,false
Fin.modn_lt,2,SAT,217,1080,0,true,true,false
Fin.val_le_of_ge,0,SAT,136,93,0,true,true,false
Fin.val_le_of_ge,1,UNSAT,104,59,0,true,true,false
Fin.val_le_of_ge,2,UNSAT,79,55,0,true,true,false
Fin.val_add_one_le_of_lt,0,SAT,123,93,0,true,true,false
Fin.val_add_one_le_of_lt,1,SAT,183,56,0,true,true,false
Fin.val_add_one_le_of_lt,2,SAT,9,156,0,true,true,false
```

For a full evaluation run use:
```
$ PARALLEL=$YOURLEVEL ./run.sh evaluate sound
$ PARALLEL=$YOURLEVEL ./run.sh evaluate perf
$ ./run.sh report
```
At `PARALLEL=20` this takes a few hours and should ultimately return latex tables close to the
Chako performance tables presented in the paper.

## Packaging the Artefact
The artefact is supposed to be shipped with all of its vendored dependencies already downloaded.
For this run:
```sh
$ ./run.sh fetch
```
This will download every archive listed in `vendor.tsv` with its SHA-256. The repository in this
state should be enough to package up into an archive and upload. To validate that the artefact works
refer to "Using the Artefact above".

If you wish to inspect the artefact deeper you can run
```sh
$ ./run.sh shell
```
to obtain a shell inside of the container.
