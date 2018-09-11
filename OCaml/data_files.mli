(*===========================================================================*)
(*
    Data_files: basic library for reading and writing data files.

    Copyright (C) 2010 Direction Générale de l'Aviation Civile (France)

    Author: David Gianazza

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received, along with this program, a copy of the
    GNU General Public License (GPL) and the GNU Lesser General Public
    License (LGPL), which is a set of  additional permissions on top
    of the GPL. If not, see <http://www.gnu.org/licenses/>.
*)
(*===========================================================================*)

(** Read or write data from/to files. *)

(** Files should be organized in columns separated
    by a coma, semicolon, space, tab, or any user-defined separator. As an
    option, field names can be provided in the first line. *)

val debug: bool ref

type index

type infile= string
type fieldname= string
type names= fieldname array
type data_line= string array

type names_choice=
    NoNames
  | OnFirstLine
  | ParseHeader of (string list -> string array)


type header= (int * string) list
type comments= (int * string) list
type data= (int * data_line) list

(** {2 Access field by name in a line} *)

val find_i: fieldname -> index -> int
val empty_index: index
val make_index: names -> index
val iter_index: (fieldname -> int -> unit) -> index -> unit

val get_field: index -> data_line -> fieldname -> string
val get_float: index -> data_line -> fieldname -> float
val get_int32: index -> data_line -> fieldname -> int32
val get_int: index -> data_line -> fieldname -> int

(** {2 Standard separators (of type Str.regexp) and line splitting} *)

type separator= Str.regexp

val comma: separator
val semicol: separator
val colon: separator
val space_tab: separator
val comma_semicol_spc_tab: separator

val string2data_line: separator -> string -> data_line (* string array *)

(** {2 Read data from file} *)

exception Interupt

type condition= int -> index -> data_line -> bool


val group_by:
    fieldname -> condition
(** [group_by fieldname] returns a condition allowing to group
    successive lines by value of [fieldname]. This function can
    be used in [read_and_do] to read blocks of lines having the
    same value in one field (e.g. same aircraft id, when reading
    radar tracks) *)

val read_and_do_channel:
  (names -> index -> data_line list -> unit) -> condition -> separator ->
  names_choice -> in_channel -> header * comments

val read_and_do:
  (names -> index -> data_line list -> unit) -> condition -> separator ->
  names_choice -> infile -> header * comments
(** [read_and_do do_something condition sep names_choice infile] reads
    blocks of lines from file [infile] and applies [do_something] to
    each block. Lines are split into fields according to the chosen
    separator [sep].
    The three last arguments of the function [do_something] should be :
    - [names] an array containing the field names),
    - [index] a map (produced by [make_index]) allowing to find a data item
    by its name, in a line,
    - and [lines], a block of lines.

    If [names_choice] is [OnFirstLine], the first line is assumed
    to contain the field names, and the arguments [names] and [index] passed
    to [do_something] contain the field names and a map allowing to
    find a data item by its fieldname, respectively. Same thing if
    [names_choice] is [ParseHeader parse] except that the names are obtained
    by applying [parse] to the header (lines beginning by '#' at the
    beginning of the file).
    If [names_choice] is
    [NoNames], [names] is an empty array, and [index] is empty as well.
    [condition] is the function allowing to
    define the blocks when reading successive lines (e.g. blocks of fixed
    size, or blocks of lines having a same value in one field).

    Processing the input file by blocks allows the user to read big files
    and process the input data "on-the-fly". If you want to save the results
    in an output file, you can pass an out_channel as first argument of
    [do_something], and do some [Printf.fprint outchan] inside. *)


val read_lines:
  infile -> string list
(** [read_lines infile] returns the raw lines contained in [infile].
    Lines are not split into separate fields: each line is a string. *)

val read: separator -> names_choice -> infile -> header * comments * names * index * data_line list
(** [read sep names_choice condition infile] reads all lines in file [infile]
    splits them according to separator [sep], and returns a tuple
    [(names,index,lines)] where [names] is an array describing the
    field names, [index] is an index allowing to access data items in 
    a line by their field name, and [lines] is the list of lines where
    each line is an array of data items (strings).

    If [names_choice] is [OnFirstLine] (resp. [ParseHeader parse]), 
    the first line (resp. the header) is assumed to contain
    the field names, and [names] and [index] are updated accordingly.
    If [names_choice] is [NoNames], [names] and [index] are empty, but
    each data field can still be accessed by its column number, using
    for example [get_field _names _index "1"] to access to the first field. *)


(** {2 Write data to file} *)

val fprint_array: out_channel -> string -> data_line -> unit
(** [fprint_array chan sep line] prints [line] to channel [chan], inserting separator [sep] between each item of the table [line] *)
    
val fprint_data: string ->  bool -> int ref -> out_channel -> fieldname array -> data_line list -> unit

  
val fprint4gnuplot: int ref -> out_channel -> data_line list -> unit


(** {2 Process data blocks and save to file} *)

type data_process= names -> index -> data_line list -> names * index * data_line list
(** A data process is a function taking [names], [index] and [lines]
    as arguments, and returning a triple [(new_names,new_index,new_lines)]
    of new data. *)

val apply: data_process list -> data_process
(** [apply data_processes] folds a list of data processes into 
    and single data process. Supposing you have defined
    [f1], [f2], ... , [fn] data processes, [apply [f1;f2;...;fn]]
    will first apply [f1] to the initial data, then [f2] to the
    result of [f1], and so on. *)

val apply2: (string*data_process) list -> (string*data_process)
(** Same as [apply] except that it also returns a concatenation of
    the tags associated to each data process, in addition to
    the folded process. *)

val do_and_save:
    data_process
  -> (int ref -> out_channel -> names -> index -> data_line list -> unit)
      -> out_channel -> names -> index -> data_line list -> unit
(** When used as argument of [read_and_do], this function allows to
    process data "on the fly" (while reading the input file by blocks),
    and save the results to an output channel.
    [do_and_save data_process fprint_data] returns of function of arguments
    [outchan], [names], [index], and [lines] that applies [data_process] to
    the input data defined by [names], [index], [lines], and prints the results
    on channel [outchan] using [fprint_data]. *)
