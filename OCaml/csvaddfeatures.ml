
type config=unit

let argspecs,init=
  let argspecs=
    []
  in
  let init=
    fun ()->()
  in
  argspecs,init;;

Arg.parse (Arg.align argspecs) (fun _->()) "options possibles";;
let main config=
  let doIt=
    let newnames =
        [|"dayofweek";(*"denergypast";*)|]
        (*        (Array.init 8 (fun i->"energym"^(string_of_int (i+1))) )*)
    in
    let secondinday= 3600*24 in
    fun names index lines ->
    let newlines=
      List.map
        (fun line->
(*          let baro = Data_files.get_float index line "baroaltitude" in
          let baro9 = Data_files.get_float index line "baroaltitudem9" in*)
          let dayofweek =
            let time=Data_files.get_int index line "time" in
            (((time-1483228800)/secondinday) mod 7)+1
          in
(*          let energy=
            let dtas2=
              let tas=Data_files.get_float index line "tas" in
              let tas9=Data_files.get_float index line "tasm9" in
              tas*.tas-. tas9*.tas9
            in
            dtas2*.0.5+.(baro-.baro9)*.9.81
          in*)
          let newline=Array.make ((Array.length names)+(Array.length newnames)) "" in
          Array.blit line 0 newline 0 (Array.length line);
          let s=ref (Array.length line) in
          newline.(!s)<-string_of_int dayofweek;
          incr s;
(*          let dbaroaltitude =
            let barop40 = Data_files.get_field index line "baroaltitudep40" in
            if String.equal barop40 ""
            then ""
            else string_of_float ((float_of_string barop40) -. baro)
          in
          newline.(!s)<- dbaroaltitude;
          incr s;
          newline.(!s)<-string_of_float energy;
          incr s;
          Array.iter
            (fun energyvi->
              newline.(!s)<-string_of_float energyvi;
              incr s;
            ) energyv;*)
          newline
        )
        lines
    in
    let newnames = Array.append names newnames in
    let newindex = Data_files.make_index newnames in
    newnames,newindex, newlines
  in
  Data_files.debug := false;
  let sep="," in
  let segment="segment" in
  let regexp_sep= Data_files.comma in
  let fprint_data=
    (fun count outchan names _ lines ->
      Data_files.fprint_data sep true count outchan names lines;flush outchan)
  in
  let names_choice= Data_files.OnFirstLine in
  let condition= (*fun count  _ _-> count>1*) Data_files.group_by segment in
  let outchan= stdout in
  let do_something= Data_files.do_and_save doIt fprint_data in
  try
    ignore (Data_files.read_and_do_channel (do_something outchan) condition regexp_sep names_choice stdin);
    ()
  with x ->
    failwith (Printf.sprintf "trajdata: %s" (Printexc.to_string x))


let config=init();;
main config;;
