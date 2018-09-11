let debug =ref true
type infile= string
type fieldname= string
type names= fieldname array
type data_line= string array
type separator= Str.regexp

type names_choice=
    NoNames
  | OnFirstLine
  | ParseHeader of (string list -> string array)

type header= (int * string) list
type comments= (int * string) list
type data= (int* data_line) list

module StrMap = Map.Make (struct type t = string let compare = compare end)

type index= int StrMap.t

let find_i key map =
  try StrMap.find key map
  with Not_found -> failwith (Printf.sprintf "Data_files.find_i %s" key)
(*
  try StrMap.find key map
  with Not_found ->
    try
      let i= int_of_string key in
      i-1
    with _-> failwith (Printf.sprintf "Data_files.find_i %s" key)
*)

let empty_index= StrMap.empty

let make_index names=
  let rec loop i map =
    if i>=Array.length names then map
    else loop (i+1) (StrMap.add names.(i) i map) in
  loop 0 StrMap.empty

let iter_index= StrMap.iter

let get_field index line name =
  try line.(find_i name index)
  with _-> failwith (Printf.sprintf "get_field %s" name)

let get_float index line name =
  try float_of_string (get_field index line name)
  with _->
    failwith (Printf.sprintf "get_float %s" name)
(*    failwith (Printf.sprintf "get_float %s" (get_field index line name)) *)

let get_int32 index line name=
  try Int32.of_string (get_field index line name)
  with _->
    Printf.printf "LINE:\n";
    Array.iteri (fun i s -> Printf.printf "%d: %s\n" i s) line;
    flush stdout;
    failwith (Printf.sprintf "get_int32 %s" name)

let get_int index line name=
  try int_of_string (get_field index line name)
  with _-> failwith (Printf.sprintf "get_int %s" name)


(*---------------------------*)

(*let regexp= Str.regexp ",\|;\|[ \t]+"*)

let comma= Str.regexp ","
let semicol= Str.regexp ";"
let colon= Str.regexp ":"
let space_tab= Str.regexp "[ \t]+"
let comma_semicol_spc_tab= Str.regexp ",;[ \t]+"

let string2data_line sep s=
  try
    let l = Str.split_delim sep s  in
    Array.of_list l
  with exc-> failwith (Printf.sprintf "string2data_item: %s : %s" s (Printexc.to_string exc))

(*---------------------------*)

let print_header l =
  Printf.printf "Header:\n";
  List.iter (fun (i,s) -> Printf.printf "%s\n" s) l;
  flush stdout;;

exception Interupt

(*type condition= int -> (line -> fieldname -> string) -> line -> bool *)

type condition= int -> index -> data_line -> bool

let is_comment sline = String.length sline>0 && sline.[0]='#'
(*
let read_and_fprintf do_something condition sep names_choice inchan outchan =
  let names= ref [||]
  and index= ref StrMap.empty in
  let lines= ref [] in
  let beginning= ref true in
  let count= ref 0 in
  let num_data= ref 0 in
  let header= ref [] in
  try
    while true do
      let sline= input_line inchan in
      if !beginning then (
	match names_choice with
        | ParseHeader parse_header ->
          header:= List.rev !header;
          print_header !header;
          names:= parse_header (List.map snd !header);
          index:= make_index !names
        | _-> () );
      let line = string2data_line sep sline in
      match line with
	[||] ->()
      | _->
	if !beginning && names_choice=OnFirstLine then (
          names:= line;
	  index:= make_index line)
	else (
	  if !num_data=1 && names_choice= NoNames then (
	    names:= Array.mapi (fun i _-> string_of_int (i+1)) line;
	    index:= make_index !names);
	  if condition !count !index  line then (
	    do_something !names !index (List.rev !lines);
	    lines:= [!count,line] )
	  else lines:= (!count,line):: !lines);
	beginning:= false;
      	incr num_data;
        incr count
    done;
    failwith "read_and_do : Unreachable"
  with
    End_of_file ->
    close_in inchan;
    do_something !names !index (List.rev !lines);
    close_out outchan;
    ()
  | x ->
    failwith (Printf.sprintf "data_files.ml:read_and_fprintf line processed:%d" !count);
    raise x*)

let read_and_do_channel do_something condition sep names_choice inchan =
(*  let inchan = open_in infile in*)
  let names= ref [||]
  and index= ref StrMap.empty in
  let lines= ref [] in
  let beginning= ref true in
  let count= ref 0 in
  let num_header= ref 0 in
  let num_comments= ref 0 in
  let num_data= ref 0 in
  let header= ref [] in
  let comments= ref [] in
  try
    while true do
      let sline= input_line inchan in
      (*      Printf.printf "%d: %s\n" !count sline;flush stdout; *)
      if is_comment sline then
	if !beginning then (
	  incr num_header;
	  header:= (!count, sline):: !header )
	else (
	  incr num_comments;
	  comments:= (!count, sline):: !comments)
      else (
	if !beginning then (
	  match names_choice with
	  | ParseHeader parse_header ->
	    header:= List.rev !header;
	    print_header !header;
	    names:= parse_header (List.map snd !header);
	    index:= make_index !names
	  | _-> () );
	let line = string2data_line sep sline in
	match line with
	  [||] ->
	  incr num_comments;
	  comments:= (!count,sline):: !comments
	(*() (* skip empty lines *)*)
	| _->
	  if !beginning && names_choice=OnFirstLine then (
	    names:= line;
	    index:= make_index line)
	  else (
	    if !num_data=1 && names_choice= NoNames then (
	      names:= Array.mapi (fun i _-> string_of_int (i+1)) line;
	      index:= make_index !names);
	    if condition !count !index (*get_field !index*) (*column_by_name !index*) line then (
	      do_something !names !index (List.rev !lines);
	      lines:= [(*!count,*)line] )
	    else lines:= ((*!count,*)line):: !lines);
	  beginning:= false;
      	  incr num_data);
      incr count
    done;
    failwith "read_and_do : Unreachable"
  with
    End_of_file ->
(*    close_in inchan;*)
    do_something !names !index (List.rev !lines);
    if !debug
    then
      begin
        Printf.printf "\nEnd of file\n";
        Printf.printf "%d lines processed\n" !count;flush stdout;
        Printf.printf "Header: %d lines\n" !num_header;
        Printf.printf "Comments: %d lines\n" !num_comments;
        Printf.printf "Data: %d lines\n" !num_data;
      end;
    !header, !comments
  | x ->
    Printf.printf "\nInterupted before end of file\n";
    Printf.printf "%d lines processed\n" !count;
    flush stdout;
    raise x
    (*| x -> failwith ("read_and_do: "^Printexc.to_string x) *)
;;


(*----------------------------------------*)

let group_by name =
   if !debug
   then (Printf.printf "condition= group_by %s\n" name;flush stdout);
  let previous= ref None in
  fun _count index (*get_field*) line ->
    try
      match !previous,line with
	_,[||] -> true
      | None,_ ->
	previous:= Some (get_field index line name);
	false
      | Some value,_ ->
	let v= get_field index line name in
	let c= v<>value in
	if c then previous:= Some v;
	c
    with x ->
      Printf.printf "Index:\n";
      iter_index (fun key i-> Printf.printf "%s : %d\n" key i) index;
      flush stdout;
      failwith (Printf.sprintf "group_by %s: %s" name (Printexc.to_string x))


let read_and_do do_something condition sep names_choice infile =
  if !debug then Printf.printf "Reading file %s\n" infile;
  let inchan = open_in infile in
  let res = read_and_do_channel do_something condition sep names_choice inchan in
  close_in inchan;
  res

(*----------------------------------------*)

let read_lines infile=
  let result= ref [] in
  let count= ref 0 in
  let chan= open_in infile in
  try
    while true do
      incr count;
      result:= input_line chan :: !result
    done;
    failwith "Unreachable"
  with End_of_file -> List.rev !result
     | x ->
       Printf.printf "\nread_lines(%s) interupted at line %d\n" infile !count;
       flush stdout;
       raise x

(*----------------------------------------*)

let read sep names_choice infile =
  let result= ref ([||], StrMap.empty,[]) in
  let no_group= fun _count _index _line -> false(*true*)
  and return_lines=
    fun names index lines -> result:=(names,index,lines) in
  let header, comments=
    read_and_do return_lines no_group sep names_choice infile in
  let (names,index,lines)= !result in
  header, comments, names, index, lines

(*----------------------------------------*)

let fprint_array chan sep tab =
  let n= Array.length tab in
  let rec fprint chan i =
    if i>=n-1 then
      Printf.fprintf chan "%s\n" tab.(i)
    else Printf.fprintf chan "%s%s%a" tab.(i) sep fprint (i+1) in
  if n>0 then fprint chan 0

(*---------------------------------------------*)

let save_names names namesfile =
  let chan= open_out namesfile in
  Array.iteri
    (fun i name -> Printf.fprintf chan "%d: %s\n" (i+1) name)
    names;
  close_out chan

let fprint_data sep flag_names =
  (*  let count= ref 0 in *)
  fun count outchan names lines ->
    if lines <> []
    then
      begin
        incr count;
        if !debug && !count mod 10=0 then (
          Printf.printf "...fprinting block number %d        \r" !count;
          flush stdout);
        try
          if !count=1 && flag_names then (
	    fprint_array outchan sep names );
          List.iter (fprint_array outchan sep) lines
        with x ->
         if !debug
         then
           (Printf.printf "Skipping block number %d: %s\n"
	    !count (Printexc.to_string x);
            flush stdout);
      end


let fprint4gnuplot =
  (*  let count= ref 0 in *)
  fun count outchan lines ->
    incr count;
    if !count mod 10=0 then (
      Printf.printf "...fprint4gnuplot block number %d        \r" !count;
      flush stdout);
    try
      let sep= " " in
      List.iter (fprint_array outchan sep) lines;
      Printf.fprintf outchan "\n"
    with x ->
      Printf.printf "Skipping block number %d: %s\n"
	!count (Printexc.to_string x);
      flush stdout ;;

(*--------------------------------------*)
(* Process data blocks and save to file *)

type data_process= names -> index -> data_line list -> names * index * data_line list

let apply filters names index lines =
  (* [filters] est une liste de fonctions de transformation de données,
     renvoyant un triplet [(new_names,new_index,new_lines)] *)
  List.fold_left
    (fun (names,index,lines) process_lines ->
       process_lines names index lines )
    (names,index,lines) filters

let apply2 tagged_filters =
  let tags,data_processes=
    List.fold_right
      (fun (tag,data_process) (l1,l2) -> (tag::l1,data_process::l2))
      tagged_filters ([],[]) in
  let rec make_string l =
    match l with
      [] -> ""
    | s::ls -> Printf.sprintf "%s_%a" s (fun _-> make_string) ls in
  let tag= make_string tags in
  let process=
    fun names index lines -> apply data_processes names index lines in
  (tag,process)


let do_and_save process_lines fprint_data =
  let count= ref 0 in
  fun outchan names index lines ->
    let new_names,new_index,new_lines=
      process_lines names index lines in
    fprint_data count outchan new_names new_index new_lines
