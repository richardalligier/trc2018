

type config=
  {
    alt:string;
    tas:string;
    temp:string;
  }

let argspecs,init=
  let tas = ref ""
  and alt = ref ""
  and temp = ref ""
  in
  let argspecs=
    [
      "-alt", Arg.Set_string alt, "baroaltitude var";
      "-tas", Arg.Set_string tas, "baroaltitude var";
      "-temp", Arg.Set_string temp, "temperature var";
    ]
  in
  let init=
    fun ()->
    {
      alt= !alt;
      temp= !temp;
      tas= !tas;
    }
  in
  argspecs,init;;

Arg.parse (Arg.align argspecs) (fun _->()) "options possibles";;

let idTime = "timestep"



let deltaTime index line =
  Data_files.get_float index line idTime

let t_0 = 288.15
let beta_T_inf = -.0.0065
let alt_Hp_trop = 11000.
let g_0 = 9.80665 (* m/s2 *)

let deltaT altHp temp =
  temp-.t_0-.beta_T_inf*.(min altHp alt_Hp_trop)

let energyRateDeltaT config index lines i =
  let linei = lines.(i) in
  let linei1 = lines.(i+1) in
  let dt = (deltaTime index linei1) -. (deltaTime index linei) in
  let temp = Data_files.get_float index linei config.temp in
  let hi = Data_files.get_float index linei config.alt in
  let hi1 = Data_files.get_float index linei1 config.alt in
  let vi = Data_files.get_float index linei config.tas in
  let vi1 = Data_files.get_float index linei1 config.tas in
  let deltaT =deltaT hi temp in
  let tempISA =
    temp-.deltaT
  in
  let tau = temp/.tempISA in
  let denergy =
    g_0*.(hi1-.hi)*.tau +.(vi1*.vi1-.vi*.vi) *. 0.5
  in
  denergy /. dt, deltaT


let main config=
  let doIt=
    let newnames = [|"energyrate";"deltaT"|] in
    fun names index lines ->
      let newlines=
        let lines =Array.of_list lines in
        let n = Array.length lines in
        Array.mapi
          (fun i line ->
             if i+1 >= n
             then Array.append line [|"";""|]
             else
               begin
                 let e, deltaT = energyRateDeltaT config index lines i in
                 Array.append line (Array.map (Printf.sprintf "%g") [| e; deltaT|])
               end

          )
          lines
      in
      let newnames = Array.append names newnames in
      let newindex = Data_files.make_index newnames in
      newnames,newindex, Array.to_list newlines
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
    Data_files.read_and_do_channel (do_something outchan) condition regexp_sep names_choice stdin;
    ()
  with x ->
    failwith (Printf.sprintf "trajdata: %s" (Printexc.to_string x))


let config=init();;
main config;;
