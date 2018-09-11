

let buildname name i =
  if i=0
  then failwith "unfold: time=0"
  else
  if i>0
  then name^"p"^(string_of_int i)
  else name^"m"^(string_of_int (-i))

let unfold variable times =
  fun names index lines ->
    let ivar  = Data_files.find_i variable index in
    let new_names = Array.concat [names;Array.map (buildname variable) times] in
    let new_index = Data_files.make_index new_names in
    let lines = Array.of_list lines in
    let n = Array.length lines in
    let new_lines =
        Array.mapi
        (fun i line ->
          let added =
            Array.map
              (fun t ->
                 let it = i+t in
                 if 0<=it && it< n
                 then lines.(it).(ivar)
                 else ""
              ) times
          in
          Array.append line added
        ) lines
    in
    new_names,new_index,Array.to_list new_lines

let () =
  Data_files.debug:=false;
  let sep = ref "," in
(*  let altField = ref "baroaltitude" in
  let velField = ref "velocity" in
  let vertratecorrField = ref "vertratecorr" in*)
  let segment = ref "segment" in
  let column = ref "" in
  let nfutur = ref "" in
  let npast = ref "" in
  let options =
    ("-sep",Arg.Set_string sep,"separator")::
    ("-c",Arg.Set_string column,"separator")::
    ("-nfutur",Arg.Set_string nfutur,"nfutur ['10:20' par exemple]")::
    ("-npast",Arg.Set_string npast,"npast ['10:20' par exemple]")::
    []
  in
  let anon_fun arg = () in
  let cmd= Sys.argv.(0) in

  let usage= Printf.sprintf "%s [options]" cmd in

  Arg.parse options anon_fun usage;
  if String.equal !column "" then failwith "csvunfold: no column specified -c";
  if (String.equal !npast "")&&(String.equal !nfutur "") then failwith "csvunfold: no past nor futur specified -npast or/and -nfutur";
  let inchan = stdin in
  let first = ref true in
  let reg = Str.regexp !sep in
(*
  let ialtField = ref (-1) in
  let ivelField = ref (-1) in
  let ivertratecorrField = ref (-1) in
  let pastVar =
    [ialtField,!altField;
                 ivelField,!velField;
                 ivertratecorrField,!vertratecorrField
                ] in
  let futureVar = [ialtField,!altField] in*)
  let icField = ref (-1) in
  let pastVar = [icField,!column;] in
  let futureVar = [icField,!column;] in
  let timeFuture=
    match !nfutur with
    |"" -> [||]
    | nfutur ->
      Array.map
        int_of_string
        (Array.of_list (Str.split_delim (Str.regexp ":") nfutur))

  in
  let timePast=
    match !npast with
    |"" -> [||]
    | nfutur ->
      Array.map
        (fun x -> -(int_of_string x))
        (Array.of_list (Str.split_delim (Str.regexp ":") nfutur))

  in
(*  let timePast= Array.init 9 (fun i-> -(i+1)) in*)
  let isegment = ref (-1) in
  let lines =ref [] in
  let currentsegment=ref "" in
  let print_segment lines =
    let lines = Array.of_list (List.map Array.of_list lines) in
    let n = Array.length lines in
    let unfold ivar times i =
      Array.iter
        (fun t ->
           let it = i+t in
(*           Printf.printf "\n%d %d %d\n" i t it;*)
           Printf.fprintf stdout "%s" !sep;
           if 0<=it && it< n
           then Printf.fprintf stdout "%s" lines.(it).(ivar)
        ) times
    in
    Array.iteri
      (fun i line->
         Printf.fprintf stdout "\n%s" (String.concat !sep (Array.to_list line));
         List.iter (fun (ivar,_)->
             unfold !ivar timePast i
           ) pastVar;
         List.iter (fun (ivar,_)->
             unfold !ivar timeFuture i
           ) futureVar;
      )
      lines
  in
  try
    while true do
      let sline= input_line inchan in
      if !first
      then
        begin
          Printf.fprintf stdout "%s" sline;
          if timePast <> [||]
          then
            begin
              Printf.fprintf stdout "%s" !sep;
              let new_names = List.map (fun (_,variable)->Array.map (buildname variable) timePast) pastVar in
              Printf.fprintf stdout "%s" (String.concat !sep (Array.to_list (Array.concat new_names)));
            end;
          if timeFuture <> [||]
          then
            begin
              Printf.fprintf stdout "%s" !sep;
              let new_names = List.map (fun (_,variable)->Array.map (buildname variable) timeFuture) futureVar in
              Printf.fprintf stdout "%s" (String.concat !sep (Array.to_list (Array.concat new_names)));
            end;
          let sline = Str.split_delim reg sline in
          let sline = List.mapi (fun i s-> (i,s)) sline in
          let search field sline =
            fst (List.find (fun (_,name) -> String.equal name field) sline)
          in
          List.iter (fun vars ->
              List.iter (fun (iref,field) ->
                  iref := search field sline;
                ) vars
            )
            [pastVar;futureVar];
          isegment := search !segment sline;
          first := false;
        end
      else
        let s = Str.split_delim reg sline in
        let seg = List.nth s !isegment in
        if String.equal !currentsegment seg
        then
          lines:= s :: !lines
        else
          begin
            currentsegment := seg;
            print_segment (List.rev !lines);
            lines:=[s];
          end;
(*        let s = Str.split_delim reg sline in
        if String.equal model !modelsel
        then
          begin
            Printf.fprintf stdout "\n%s" sline;
            if !dumptype then Printf.fprintf stdout "%s" (!sep^typ);
          end;*)
      ()
    done;
  with
    End_of_file ->
    print_segment (List.rev !lines);
    ()
