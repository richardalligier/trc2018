
let () =
  let sep = ref "," in
  let field = ref "" in
  let remove = ref false in
  let removecol = ref false in
  let keep = ref false in
  let options =
    ("-c",Arg.Set_string field,"field to look at")
    ::("-sep",Arg.Set_string sep,"separator")
    ::("-empty",Arg.Set remove,"remove lines with empty values")
    ::("-all",Arg.Set removecol,"remove the column")
    ::("-nonempty",Arg.Set keep,"keep lines with empty values")
    ::[]
  in
  let anon_fun arg = () in
  let cmd= Sys.argv.(0) in

  let usage= Printf.sprintf "%s [options]" cmd in

  Arg.parse options anon_fun usage;
  let keep,remove, removecol =
    let conv b = if b then 1 else 0 in
    if (conv !keep) + (conv !remove) + (conv !removecol) = 1
    then !keep, !remove, !removecol
    else failwith "choose between -keep or -remove or -removecol"
  in
  let inchan = stdin in
  let first = ref true in

  let ifield= ref (-1) in
  let reg = Str.regexp !sep in
  let removecoli i l =
    let cpt = ref (-1) in
    List.filter (fun x -> incr cpt; !cpt != i) l
  in
  try
    while true do
      let sline= input_line inchan in
      if !first
      then
        begin
          let sl = Str.split_delim reg sline in
          let isl = List.mapi (fun i s-> (i,s)) sl in
          ifield := fst (List.find (fun (_,name) -> String.equal name !field) isl);
          first := false;
          if removecol
          then
            let l = removecoli !ifield sl in
            Printf.printf "%s" (String.concat !sep l)
          else Printf.fprintf stdout "%s" sline;
        end
      else
        let s = Str.split_delim reg sline in
        if removecol
        then
          let l = removecoli !ifield s in
          Printf.printf "\n%s" (String.concat !sep l);
        else
          begin
            let vfield = List.nth s !ifield in
            let is_empty = String.equal vfield "" in
            if keep && is_empty
            then Printf.fprintf stdout "\n%s" sline;
            if remove && (not is_empty)
            then Printf.fprintf stdout "\n%s" sline;
          end;
      ()
    done;
  with
    End_of_file ->
    ()
