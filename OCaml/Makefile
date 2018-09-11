
OCAMLC = ocamlc -g
OCAMLMLI = ocamlc
OCAMLOPT = ocamlopt -inline 10000 -unsafe -noassert
OCAMLDEP = ocamldep
INCLUDES =

all : ./bin ./bin/csvaddfeatures ./bin/csvaddenergyrate ./bin/csvremove ./bin/csvfold

SOURCES = data_files.ml
LIBS = str.cmxa
OPTOBJS = $(SOURCES:.ml=.cmx)

./bin:
	mkdir -p ./bin

./bin/csvaddenergyrate: $(OPTOBJS) csvaddenergyrate.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ $(LIBS) $^

./bin/csvaddfeatures: $(OPTOBJS) csvaddfeatures.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ $(LIBS) $^

./bin/csvfold: $(OPTOBJS) csvfold.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ $(LIBS)  $^

./bin/csvremove: $(OPTOBJS) csvremove.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ $(LIBS)  $^

.SUFFIXES:
.SUFFIXES: .ml .mli .cmi .cmx

.mli.cmi :
	ocamlfind $(OCAMLMLI) $(INCLUDES) -c $< $(OCAMLFINDLIB)
.ml.cmx :
	ocamlfind $(OCAMLOPT) $(OPTOPT) $(INCLUDES) -c $< $(OCAMLFINDLIB)

clean:
	rm -f *.cm* *.o *.a *~ .depend ./bin/csvfold ./bin/csvaddfeatures ./bin/csvremove ./bin/csvaddenergyrate

.depend:
	$(OCAMLDEP) $(INCLUDES) *.mli *.ml > $@

include .depend
